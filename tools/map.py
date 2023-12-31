#!/usr/bin/env python3

import os
import sys
from argparse import ArgumentParser
from pathlib import Path
from math import floor
from bisect import insort, bisect_left
from typing import Dict

import pytiled_parser
from pytiled_parser import tiled_object
from pytiled_parser import layer as tiled_layer
from pytiled_parser.tiled_map import TiledMap, Tileset
from pytiled_parser.layer import TileLayer, ObjectLayer


CLASS_LAYER_FG = "fg"
CLASS_LAYER_BG = "bg"
# 'class' of the tee-off location object
CLASS_TEE_OFF = "tee_off"
CLASS_HEIGHTMAP_CONTOUR = "heightmap_contour"


MASK_GID             = 0x0fffffff
GID_FLIPPED_HORI     = 0x80000000
GID_FLIPPED_VERT     = 0x40000000
GID_FLIPPED_DIAG     = 0x20000000
GID_ROTATED_HEX_120  = 0x10000000

BGATTR_PRIORITY      = 0x80
BGATTR_FLIP_VERT     = 0x40
BGATTR_FLIP_HORI     = 0x20
_BGATTR_UNUSED       = 0x10
BGATTR_BANK          = 0x08
BGATTR_PAL_COL       = 0x07

OAM_PRIORITY         = 0x80
OAM_FLIP_VERT        = 0x40
OAM_FLIP_HORI        = 0x20
OAM_PAL_DMG          = 0x10
OAM_CHR_BANK         = 0x08
OAM_PAL_COL          = 0x07


LOG_LEVEL_VERBOSE = -1
log_level = 0


def logv(*values: object, sep: str = " "):
    if log_level <= LOG_LEVEL_VERBOSE:
        sys.stderr.write(sep.join(map(str, values)) + "\n")


def logwarn(*values: object, sep: str = " "):
    sys.stderr.write("WARN: " + sep.join(map(str, values)) + "\n")


class TileSource:
    def __init__(self, tileset: Tileset):
        self.tileset: Tileset = tileset

    def to_local_id(self, gid: int) -> int:
        return gid - self.tileset.firstgid

    def get_gid_range(self) -> range:
        """Return range of GIDs contained by this tileset."""
        return range(self.tileset.firstgid, self.tileset.firstgid + self.tileset.tile_count)

    def has_gid(self, gid: int) -> bool:
        return (gid & MASK_GID) in self.get_gid_range()

    def get_res_path(self) -> Path:
        """
        return Tileset source image ChrSource resource path
        (tileset image converted to CHR data 2bpp ROM resource file)
        """
        src_root = Path.joinpath(Path.cwd(), "src")
        image_rel = self.tileset.image.relative_to(src_root)
        return image_rel.with_suffix(".2bpp")


class MapTileset:
    def __init__(self, chr_offset: int = 0, fallback_chr: int = 0):
        self.used_gids: [int] = []
        self.chr_offset: int = chr_offset
        self.fallback_chr: int = fallback_chr

    def insert_gid(self, gid: int):
        gid = gid & MASK_GID
        if not gid in self.used_gids:
            insort(self.used_gids, gid)

    def is_empty(self) -> bool:
        return len(self.used_gids) == 0

    def gid_to_chr(self, gid: int) -> int:
        gid = gid & MASK_GID
        if gid == 0:
            return self.fallback_chr
        i = bisect_left(self.used_gids, gid)
        assert i < len(self.used_gids) and self.used_gids[i] == gid
        return i + self.chr_offset


class TileTracker:
    def __init__(self):
        self.sources: [TileSource] = []

    def add_source_tilesets(self, tmx: TiledMap):
        for tileset in tmx.tilesets.values():
            source = TileSource(tileset)
            self.sources.append(source)

    def require_gid_source(self, gid: int) -> TileSource:
        for source in self.sources:
            if source.has_gid(gid):
                return source
        return None

    def build_tileset_loadocode(self, tileset: MapTileset, block: int) -> [str]:
        if tileset.is_empty():
            return []

        lines = []
        lines.append("\tdb MapChunk_Loado")
        lines.append(f"\tdb LOADOCODE_CHRB_{block}")
        if block == 0:
            lines.append(f"\tdb LOADOCODE_DEST_CHR, tThings")

        def _append_run(start: int, count: int):
            if count > 0:
                lines.append(f"\tdb LOADOCODE_SRC_CHR, {start}")
                lines.append(f"\tdb LOADOCODE_CHRCOPY, {count}")

        source = None
        seqs = SequenceEncoder()
        for gid in tileset.used_gids:
            new_source = self.require_gid_source(gid)
            if new_source != source:
                # changing source, always break
                start, count = seqs.break_run()
                _append_run(start, count)
                source = new_source
                lines.append(f'\tLoadocodeROMB "{source.get_res_path()}"')
                lines.append("\tdb LOADOCODE_SRC")
                reslabel = str(source.get_res_path()).replace("/", "_").replace(".", "_")
                lines.append(f"\tdw {reslabel}")

            start, count = seqs.push(source.to_local_id(gid))
            _append_run(start, count)

        start, count = seqs.break_run()
        _append_run(start, count)
        lines.append("\tdb LOADOCODE_STOP")
        return lines


class LegacyThingDef:
    def __init__(self, chr_code: int, oam_attr: int):
        self.chr_code: int = chr_code
        self.oam_attr: int = oam_attr

    def get_def_id(self) -> int:
        import ctypes
        h = hash(f"LegacyThingDef{self.chr_code}{self.oam_attr}howdopython?")
        return ctypes.c_ulong(h).value

    def get_def_label(self) -> str:
        keyword = self.get_def_id()
        return f".thing{keyword:x}"

    def get_asm(self) -> [str]:
        return [
            f"\t{self.get_def_label()}:",
            f"\t\tDefThingLegacy tThings + {self.chr_code}, {self.oam_attr}"
        ]


class ThingPlacement:
    def __init__(self, pos_x: int, pos_y: int, tag: int, thing_def):
        self.pos_x: int = pos_x
        self.pos_y: int = pos_y
        self.tag: int = tag
        self.thing_def: int = thing_def

    def get_asm(self) -> [str]:
        return [
            f"\tThingcInstance {self.thing_def.get_def_label()}",
            f"\tThingcPosition {self.pos_x}, {self.pos_y}",
            f"\tThingcTag {self.tag}",
            f"\tThingcSave",
        ]


class Things:
    def __init__(self):
        self.thing_defs = {}
        self.thing_placements = []

    def place_legacy_thing(self, pos_x: int, pos_y: int, chr_code: int, oam_attr: int) -> int:
        td = LegacyThingDef(chr_code, oam_attr)
        self.thing_defs[td.get_def_id()] = td
        tag = len(self.thing_placements)
        self.thing_placements.append(ThingPlacement(pos_x, pos_y, tag, td))
        return tag

    def get_defs_asm(self) -> [str]:
        if len(self.thing_defs) == 0:
            return []
        lines: [str] = [
            f"\t;       defs ({len(self.thing_defs)})",
        ]
        for td in self.thing_defs.values():
            lines.extend(td.get_asm())
        lines.append("\tThingcStop")
        return lines

    def get_placements_asm(self) -> [str]:
        if len(self.thing_placements) == 0:
            return []
        lines: [str] = [
            f"\t; placements ({len(self.thing_placements)})",
        ]
        for tp in self.thing_placements:
            lines.extend(tp.get_asm())
        lines.append("\tThingcStop")
        return lines

    def get_chunk_asm(self) -> [str]:
        if len(self.thing_placements) == 0 and len(self.thing_defs) == 0:
            return None
        lines: [str] = [
            "\tdb MapChunk_Things",
        ]
        lines.extend(self.get_placements_asm())
        lines.extend(self.get_defs_asm())
        return lines


class Map:
    def process_tmx(self, tmx: TiledMap, args):
        self.tee_x = 0
        self.tee_y = 0
        map_name, _ext = os.path.splitext(tmx.map_file.name)
        self.map_name = map_name
        logv(f"map size: {tmx.map_size.width}, {tmx.map_size.height}")
        self.columns = tmx.map_size.width
        self.rows = tmx.map_size.height
        self.tilemap = []
        self.heightmap_contour = []
        self.heightmap = []
        self.tile_tracker: TileTracker = TileTracker()
        self.tileset_bg: MapTileset = MapTileset(args.bg_tile_offset, args.bg_tile_default)
        self.tileset_obj: MapTileset = MapTileset()
        self.thing_tiles: [tiled_object.Tile] = []
        self.things: Things = Things()
        self.subthing_pairs: [(int, int)] = []

        for y in range(self.rows):
            self.tilemap.append([0] * self.columns)

        self.tile_tracker.add_source_tilesets(tmx)

        for layer in tmx.layers:
            self.process_layer(layer)

        self.process_things()

        if len(self.heightmap_contour) > 0:
            self.build_heightmap(self.heightmap_contour)

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
                self.thing_tiles.append(obj)
                self.tileset_obj.insert_gid(obj.gid)
                self.hack_damaged_things(obj.gid & MASK_GID)

    def hack_damaged_things(self, gid: int):
        """Add damaged variants of things to the tileset"""
        source = self.tile_tracker.require_gid_source(gid)
        if source.tileset.image.name == "buildings.png":
            loc = source.to_local_id(gid)
            if loc <= 12:
                # single-tile buildings
                self.tileset_obj.insert_gid(gid + 1)
                self.tileset_obj.insert_gid(gid + 2)
            else:
                self.tileset_obj.insert_gid(gid + 1)

    def process_things(self):
        """Add the gathered thing tile objects to Things builder.
        Resolve parents by converting TiledObject ID into Thing Tag.
        Add (parent, child) relations to subthing_pairs.
        """
        oid_tag_map = {} # oid -> tag
        unresolved_subthings = [] # (parent_oid, child_tag)
        for obj in self.thing_tiles:
            chrid = self.tileset_obj.gid_to_chr(obj.gid)
            oam_attr = self.gid_to_oam_attr(obj.gid)
            pos_x = round(obj.coordinates.x)
            pos_y = round(obj.coordinates.y - 8)
            tag = self.things.place_legacy_thing(pos_x, pos_y, chrid, oam_attr)
            oid_tag_map[obj.id] = tag
            parentval = obj.properties.get("parent", None)
            if not parentval:
                continue

            if type(parentval) == int:
                parentid = parentval
            else:
                parentid = int(parentval)
            unresolved_subthings.append((parentid, tag))

        for parent_oid, child_tag in unresolved_subthings:
            parent_tag = oid_tag_map[parent_oid]
            self.subthing_pairs.append((parent_tag, child_tag))

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
                        assert gid & (GID_FLIPPED_DIAG | GID_ROTATED_HEX_120) == 0, "Diagonal flip/rotation is unsupported."
                        self.tileset_bg.insert_gid(gid)
                        self.tilemap[cy][cx] = gid & MASK_GID
        else:
            logv(f"unrecognised layer '<{layer.class_}|{layer.name}>")

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

    def write_asm(self, args):
        builder = AsmBuilder()

        # MapInfo
        map_info = ASM_INFO.replace("%COLUMNS%", str(self.columns))
        map_info = map_info.replace("%ROWS%", str(self.rows))
        map_info = map_info.replace("%TEE_X%", str(self.tee_x))
        map_info = map_info.replace("%TEE_Y%", str(self.tee_y))
        builder.append_chunk_text(map_info)

        # Tileset
        if not self.tileset_bg.is_empty():
            lines = self.tile_tracker.build_tileset_loadocode(self.tileset_bg, 1)
            builder.append_chunk_text("\n".join(lines))

        if not self.tileset_obj.is_empty():
            lines = self.tile_tracker.build_tileset_loadocode(self.tileset_obj, 0)
            builder.append_chunk_text("\n".join(lines))

        # Tilemap
        if len(self.tilemap) > 0:
            asm_tile_lines = []
            for row in self.tilemap:
                converted = [self.tileset_bg.gid_to_chr(gid) for gid in row]
                asm_row = ", ".join([f"${idx:02X}" for idx in converted])
                asm_tile_lines.append("\t\tdb " + asm_row)

            builder.append_chunk_text(ASM_TILES.replace("%TILES%", "\n".join(asm_tile_lines)))

        # Heightmap
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

            builder.append_chunk_text(asm_heightmap)

        # Things
        things_lines = self.things.get_chunk_asm()
        if things_lines and len(things_lines) > 0:
            builder.append_chunk_text("\n".join(things_lines))

        # End
        builder.append_chunk_text(ASM_END)
        return builder.build(self.map_name)

    @staticmethod
    def gid_to_bg_attr(gid: int) -> int:
        oam_attr = 0
        if gid & GID_FLIPPED_VERT:
            bg_attr |= BG_FLIP_VERT
        if gid & GID_FLIPPED_HORI:
            bg_attr |= BG_FLIP_HORI
        return oam_attr

    @staticmethod
    def gid_to_oam_attr(gid: int) -> int:
        oam_attr = 0
        if gid & GID_FLIPPED_VERT:
            oam_attr |= OAM_FLIP_VERT
        if gid & GID_FLIPPED_HORI:
            oam_attr |= OAM_FLIP_HORI
        return oam_attr


class SequenceEncoder:
    def __init__(self):
        self.seq = []
        self.runs: [(int, int)] = []

    def continues(self, x: int) -> bool:
        return len(self.seq) == 0 or self.seq[-1] + 1 == x

    def push(self, x: int) -> (int, int):
        ret = (None, 0)
        if not self.continues(x):
            ret = self.break_run()
        self.seq.append(x)
        return ret

    def break_run(self) -> (int, int):
        if len(self.seq) == 0:
            return (None, 0)
        run = (self.seq[0], len(self.seq))
        self.runs.append(run)
        self.seq.clear()
        return run


class AsmBuilder:
    """Builds the map code!"""
    def __init__(self):
        self.chunks = []

    def append_chunk_text(self, chunk: str):
        self.chunks.append(chunk)

    def build(self, map_name: str):
        chunk_labels = [f".chunk{i}" for i in range(len(self.chunks))]
        asm = self.build_map_header(map_name, chunk_labels)
        for i, chunk in enumerate(self.chunks):
            asm += f"\n.chunk{i}:\n"
            if i + 1 < len(self.chunks):
                next_chunk = f".chunk{i + 1}"
            else:
                next_chunk = "0"
            asm += f"\tdw {next_chunk} ; next chunk\n"
            asm += chunk
        return asm

    def build_map_header(self, map_name: str, chunk_labels: [str]):
        asm = MAP_HEADER_TEMPLATE.replace("%MAP_NAME%", map_name)
        asm = asm.replace("%CHUNK_COUNT%", str(len(chunk_labels)))
        asm = asm.replace("%CHUNK_LIST%", ", ".join(chunk_labels))
        return asm


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

ASM_END = """\tdb MapChunk_End
"""

MAP_HEADER_TEMPLATE = """; Generated by map.py
include "app/world.inc"
include "core/loado.inc"
include "gfxmap.inc"

section "map_%MAP_NAME%", romx

map_%MAP_NAME%::
"""

MAP_FOOTER_TEMPLATE = """
map_%MAP_NAME%_end::
"""


def main():
    argp = ArgumentParser()
    argp.add_argument("--bg_tile_offset", type=int, default=128, help="BG tilemap CHR code offset. Defaults to 128.")
    argp.add_argument("--bg_tile_default", type=int, default=0, help="BG tilemap fallback CHR code. Used to fill empty cells in source map.")
    argp.add_argument("--out", "-o", type=Path, help="Map ASM output file")
    argp.add_argument("infile", type=Path, help="Input Tiled map (TMX) file")

    args = argp.parse_args()
    assert args.infile and args.infile.exists()

    tmx = pytiled_parser.parse_map(args.infile)
    map_data = Map()
    map_data.process_tmx(tmx, args)
    asm = map_data.write_asm(args)

    if args.out:
        tempf = args.out.with_suffix(".tempf")
        with open(tempf, 'w') as fd:
            fd.write(asm)
        os.rename(tempf, args.out)
    else:
        print(asm)

    return 0


if __name__ == "__main__":
    sys.exit(main())
