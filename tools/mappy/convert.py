import sys
import os
from math import floor

from pytiled_parser import tiled_object
from pytiled_parser import layer as tiled_layer
from pytiled_parser.tiled_map import TiledMap
from pytiled_parser.layer import TileLayer, ObjectLayer

from .things import Things
from .tiles import TileTracker
from . import tiles


LOG_LEVEL_VERBOSE = -1
log_level = 0


def logv(*values: object, sep: str = " "):
    if log_level <= LOG_LEVEL_VERBOSE:
        sys.stderr.write(sep.join(map(str, values)) + "\n")


def logwarn(*values: object, sep: str = " "):
    sys.stderr.write("WARN: " + sep.join(map(str, values)) + "\n")


CLASS_LAYER_FG = "fg"
CLASS_LAYER_BG = "bg"
# 'class' of the tee-off location object
CLASS_TEE_OFF = "tee_off"
CLASS_HEIGHTMAP_CONTOUR = "heightmap_contour"


class MapConvert:
    def process_tmx(self, tmx: TiledMap, args):
        print(tmx.map_file)
        self.tee_x = 0
        self.tee_y = 0
        map_name, _ext = os.path.splitext(tmx.map_file.name)
        self.map_name = map_name
        self.columns = tmx.map_size.width
        self.rows = tmx.map_size.height
        self.tilemap = []
        self.heightmap_contour = []
        self.heightmap = []
        self.tile_tracker: TileTracker = TileTracker(args)
        self.things: Things = Things()

        for y in range(self.rows):
            self.tilemap.append([0] * self.columns)

        self.tile_tracker.add_source_tilesets(tmx)

        for layer in tmx.layers:
            self.process_layer(layer)

        self.things.process(self.tile_tracker)

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
                self.things.add_tile(obj)

    def process_tile_layer(self, layer: TileLayer):
        if not layer.visible:
            return
        elif layer.class_ == CLASS_LAYER_BG:
            assert layer.size.width == self.columns
            assert layer.size.height == self.rows
            for cy in range(layer.size.height):
                for cx in range(layer.size.width):
                    gid = layer.data[cy][cx]
                    if gid & (tiles.GID_FLIPPED_DIAG | tiles.GID_ROTATED_HEX_120) != 0:
                        raise Exception("Diagonal flip is unsupported.")
                    # ignore empty cells
                    if gid > 0:
                        self.tile_tracker.bg.insert_gid(gid)
                        self.tilemap[cy][cx] = gid & tiles.MASK_GID
        elif layer.class_ == CLASS_LAYER_FG:
            pass
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
        if not self.tile_tracker.bg.is_empty():
            lines = self.tile_tracker.build_tileset_loadocode(
                self.tile_tracker.bg, 1)
            builder.append_chunk_text("\n".join(lines))

        if not self.tile_tracker.obj.is_empty():
            lines = self.tile_tracker.build_tileset_loadocode(
                self.tile_tracker.obj, 0)
            builder.append_chunk_text("\n".join(lines))

        # Tilemap
        if len(self.tilemap) > 0:
            asm_tile_lines = []
            for row in self.tilemap:
                converted = [
                    self.tile_tracker.bg.gid_to_chr(gid) for gid in row
                ]
                asm_row = ", ".join([f"${idx:02X}" for idx in converted])
                asm_tile_lines.append("\t\tdb " + asm_row)

            builder.append_chunk_text(
                ASM_TILES.replace("%TILES%",
                                  "\n".join(asm_tile_lines)))

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

        # Rules
        multithings = {}
        for parent, child in self.things.get_subthing_pairs():
            if parent not in multithings:
                multithings[parent] = []
            multithings[parent].append(child)
        for parent, children in multithings.items():
            rule_data_len = len(children) + 1
            assert rule_data_len < 256
            rule_type = 0
            rule_bytes = [parent] + children
            rule_str_bytes = ", ".join((f"{x}" for x in rule_bytes))
            rules_lines = [
                "\tdb MapChunk_Rule",
                f"\tdb {rule_type}, {rule_data_len}",
                "\tdw rule_multithing",
                f"\tdb {rule_str_bytes}",
            ]

            builder.append_chunk_text("\n".join(rules_lines))

        # End
        builder.append_chunk_text(ASM_END)
        return builder.build(self.map_name)


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
            asm += f"\tdw {next_chunk}\n"
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
