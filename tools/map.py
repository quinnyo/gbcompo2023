#!/usr/bin/env python3

import os
import sys
from pathlib import Path
from argparse import ArgumentParser
from math import floor

import pytiled_parser
from pytiled_parser import tiled_object
from pytiled_parser import layer as tiled_layer
from pytiled_parser.tiled_map import TiledMap, Tileset
from pytiled_parser.layer import TileLayer, ObjectLayer


# Tileset custom property key
PROP_TILESET = "gigantgolf_tileset"
# Identifies a tileset as the terrain/background tileset...
TILESET_BG = "bg"
# Identifies a tileset as the building/object tileset...
TILESET_FG = "fg"
CLASS_LAYER_FG = "fg"
CLASS_LAYER_BG = "bg"
# 'class' of the tee-off location object
CLASS_TEE_OFF = "tee_off"
CLASS_HEIGHTMAP_CONTOUR = "heightmap_contour"

MASK_GID = 0x0fffffff
MASK_GID_FLAGS = 0xf0000000
GID_FLIPPED_HORI = 0x80000000
GID_FLIPPED_VERT = 0x40000000
GID_FLIPPED_DIAG = 0x20000000
GID_ROTATED_HEX_120 = 0x10000000

OAM_PRIORITY = 0x80
OAM_FLIP_VERT = 0x40
OAM_FLIP_HORI = 0x20
OAM_PAL_DMG = 0x10
OAM_CHR_BANK = 0x08
OAM_PAL_COL = 0x07


LOG_LEVEL_VERBOSE = -1
log_level = LOG_LEVEL_VERBOSE


def logv(*values: object, sep: str = " "):
    if log_level <= LOG_LEVEL_VERBOSE:
        sys.stderr.write(sep.join(map(str, values)) + "\n")


def logwarn(*values: object, sep: str = " "):
    sys.stderr.write("WARN: " + sep.join(map(str, values)) + "\n")


class Map:
    def __init__(self):
        self.tiles = {}
        self.tee_x = 0
        self.tee_y = 0
        pass

    def process_tmx(self, tmx: TiledMap):
        map_name, _ext = os.path.splitext(tmx.map_file.name)
        self.map_name = map_name
        logv(f"map size: {tmx.map_size.width}, {tmx.map_size.height}")
        self.columns = tmx.map_size.width
        self.rows = tmx.map_size.height
        self.tilemap = []
        self.heightmap_contour = []
        self.heightmap = []
        self.things = []

        for y in range(self.rows):
            self.tilemap.append([0] * self.columns)

        for tileset in tmx.tilesets.values():
            self.process_tileset(tileset)

        assert self.bg_firstgid

        for layer in tmx.layers:
            self.process_layer(layer)

        if len(self.heightmap_contour) > 0:
            self.build_heightmap(self.heightmap_contour)

    def process_tileset(self, tileset: Tileset):
        if PROP_TILESET in tileset.properties:
            if tileset.properties[PROP_TILESET] == TILESET_BG:
                self.bg_firstgid = tileset.firstgid
                self.tileset_bg = tileset
            elif tileset.properties[PROP_TILESET] == TILESET_FG:
                self.fg_firstgid = tileset.firstgid
                self.tileset_fg = tileset
            else:
                logwarn(f"unrecognised tileset <{tileset.class_}|{tileset.name}> with {PROP_TILESET}: '{tileset.properties[PROP_TILESET]}'")
                return
        else:
            logv(f"skipping tileset <{tileset.class_}|{tileset.name}> with no {PROP_TILESET} property.")
            return

        for k in tileset.tiles:
            tile = tileset.tiles[k]
            gid = tileset.firstgid + k
            self.tiles[gid] = tile

    def process_layer(self, layer: tiled_layer.Layer):
        if isinstance(layer, TileLayer):
            self.process_tile_layer(layer)
        elif isinstance(layer, ObjectLayer):
            self.process_object_layer(layer)

    def process_object_layer(self, layer: ObjectLayer):
        for obj in layer.tiled_objects:
            if obj.class_ == CLASS_TEE_OFF:
                self.tee_x = round(obj.coordinates.x)
                self.tee_y = round(obj.coordinates.y)
                logv("Found tee-off location:",
                     f"<{obj.id}|{obj.name}>",
                     f"({self.tee_x}, {self.tee_y})")
            elif obj.class_ == CLASS_HEIGHTMAP_CONTOUR:
                if isinstance(obj, tiled_object.Polyline):
                    x, y = obj.coordinates
                    self.heightmap_contour = [(x + px, y + py)
                                              for px, py in obj.points]
                else:
                    logwarn("Non-polyline heightmap contour object found.")
            elif isinstance(obj, tiled_object.Tile):
                self.process_thing_object(obj)

    def process_thing_object(self, obj: tiled_object.Tile):
        """
        Add a SpriteThing based on a Tile object.
        """
        assert self.fg_firstgid, "FG tileset required for Object Layer Tiles -> SpriteThings"
        px = round(obj.coordinates.x)
        py = round(obj.coordinates.y)
        chr_code = (obj.gid & MASK_GID) - self.fg_firstgid
        oam_attr = 0
        if obj.gid & GID_FLIPPED_VERT:
            oam_attr |= OAM_FLIP_VERT
        if obj.gid & GID_FLIPPED_HORI:
            oam_attr |= OAM_FLIP_HORI
        thing = SpriteThing(py - 8, px, chr_code, oam_attr)
        self.things.append(thing)

    def process_tile_layer(self, layer: TileLayer):
        if layer.class_ == CLASS_LAYER_FG:
            pass
        elif layer.class_ == CLASS_LAYER_BG:
            assert layer.size.width == self.columns
            assert layer.size.height == self.rows
            for cy in range(layer.size.height):
                for cx in range(layer.size.width):
                    gid = layer.data[cy][cx]
                    # ignore empty cells
                    if gid > 0:
                        gid &= MASK_GID
                        self.tilemap[cy][cx] = gid
        else:
            logwarn(f"unrecognised layer '<{layer.class_}|{layer.name}>")

    def build_heightmap(self, points):
        """
        heightmap thing from polyline/contour (heightmap_contour)
        intersect contour at every X column
        """

        def get_segment(x):
            # get segment that contains `x`
            for i in range(len(points) - 1):
                if points[i][0] <= x and points[i+1][0] > x:
                    return i
            return None

        def sample(x):
            i = get_segment(x)
            if not i:
                return 255

            x0, y0 = points[i]
            x1, y1 = points[i + 1]

            segdx = x1 - x0
            sx = x - x0
            t = sx / segdx

            segdy = y1 - y0
            return floor(y0 + segdy * t)

        height_columns = self.columns * 8
        self.heightmap = [sample(x) for x in range(height_columns)]

    def write_asm(self, tile_offset: int = 128):
        chunks = []

        map_info = ASM_INFO.replace("%COLUMNS%", str(self.columns))
        map_info = map_info.replace("%ROWS%", str(self.rows))
        map_info = map_info.replace("%TEE_X%", str(self.tee_x))
        map_info = map_info.replace("%TEE_Y%", str(self.tee_y))
        chunks.append(map_info)

        if len(self.tilemap) > 0:
            asm_tile_lines = []
            for row in self.tilemap:
                asm_row = ", ".join(
                    [str(tile_offset + tile - self.bg_firstgid).rjust(3) for tile in row])
                asm_tile_lines.append("\t\tdb " + asm_row)

            chunks.append(ASM_TILES.replace("%TILES%", "\n".join(asm_tile_lines)))

        if len(self.heightmap) > 0:
            asm_heightmap_lines = []
            i = 0
            while i < len(self.heightmap):
                end = min(len(self.heightmap), i + 16)
                val_line = [str(x).rjust(3) for x in self.heightmap[i:end]]
                asm_heightmap_lines.append("\t\tdb " + ", ".join(val_line))
                i += len(val_line)

            asm_heightmap = ASM_HEIGHTMAP.replace(
                "%HEIGHTMAP_SIZE%", str(len(self.heightmap)))
            asm_heightmap = asm_heightmap.replace(
                "%HEIGHTMAP_DATA%", "\n".join(asm_heightmap_lines))

            chunks.append(asm_heightmap)

        if len(self.things) > 0:
            asm_things = []
            for thing in self.things:
                asm_things.append("\t\t" + thing.write_asm())

            things_chunk = ASM_THINGS.replace(
                "%THING_COUNT%", str(len(self.things)))
            things_chunk = things_chunk.replace("%THINGS%", "\n".join(asm_things))

            chunks.append(things_chunk)

        asm = ASM_TEMPLATE.replace("%MAP_NAME%", self.map_name)
        asm = asm.replace("%MAP_CHUNKS%", "\n".join(chunks))

        return asm


class Thing:
    def write_asm(self):
        return ""


class SpriteThing(Thing):
    def __init__(self, y: int, x: int, chr_code: int, oam_attr: int = 0):
        self.chr_code = chr_code
        self.pos_x = x
        self.pos_y = y
        self.oam_attr = oam_attr

    def write_asm(self):
        return f"db 0, {self.pos_y}, {self.pos_x}, {self.chr_code}, {self.oam_attr}"


ASM_INFO = """\tdb MapChunk_Info
\t.columns: db %COLUMNS%
\t.rows: db %ROWS%
\t.tee_x: db %TEE_X%
\t.tee_y: db %TEE_Y%
"""

ASM_TILES = """\tdb MapChunk_Tiles
\t.tiles:
%TILES%
"""

ASM_HEIGHTMAP = """\tdb MapChunk_Terrain
\t.heightmap_size: db %HEIGHTMAP_SIZE%
\t.heightmap:
%HEIGHTMAP_DATA%
"""

ASM_THINGS = """\tdb MapChunk_Things
\t.thing_count: db %THING_COUNT%
\t.things:
%THINGS%
"""

ASM_TEMPLATE = """include "world.inc"

section "map_%MAP_NAME%", romx

map_%MAP_NAME%::
%MAP_CHUNKS%

\tdb MapChunk_End
map_%MAP_NAME%_end::
"""


def process_map(infile: Path):
    tmx = pytiled_parser.parse_map(infile)

    logv(f"processing TMX '{tmx.map_file}'")

    out = Map()
    out.process_tmx(tmx)

    return out


def main():
    argp = ArgumentParser()
    # argp.add_argument("--bgtiles", type=int, default=128)
    argp.add_argument("--out", "-o", type=Path)
    argp.add_argument("infile", type=Path)

    args = argp.parse_args()
    assert args.infile and args.infile.exists()

    map_data = process_map(args.infile)
    asm = map_data.write_asm()

    if args.out:
        tempf = args.out.with_suffix(".tempf")
        with open(tempf, 'w') as fd:
            fd.write(asm)
        os.rename(tempf, args.out)
    else:
        print(asm)

    return 0


if __name__ == "__main__":
    main()
