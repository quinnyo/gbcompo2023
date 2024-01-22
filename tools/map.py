#!/usr/bin/env python3

import os
import sys
from argparse import ArgumentParser
from pathlib import Path
from math import floor
from bisect import insort, bisect_left
from typing import List, NamedTuple, Tuple
import hashlib

from attrs import define
import attrs

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


def gid_to_bg_attr(gid: int) -> int:
    bg_attr = 0
    if gid & GID_FLIPPED_VERT:
        bg_attr |= BGATTR_FLIP_VERT
    if gid & GID_FLIPPED_HORI:
        bg_attr |= BGATTR_FLIP_HORI
    return bg_attr


def gid_to_oam_attr(gid: int) -> int:
    oam_attr = 0
    if gid & GID_FLIPPED_VERT:
        oam_attr |= OAM_FLIP_VERT
    if gid & GID_FLIPPED_HORI:
        oam_attr |= OAM_FLIP_HORI
    return oam_attr


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
        return (gid & MASK_GID) - self.tileset.firstgid

    def get_gid_range(self) -> range:
        """Return range of GIDs contained by this tileset."""
        return range(self.tileset.firstgid,
                     self.tileset.firstgid + self.tileset.tile_count)

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

    def get_res_label(self) -> str:
        return str(self.get_res_path()).replace("/", "_").replace(".", "_")


class MapTileset:
    def __init__(self, chr_offset: int = 0, fallback_chr: int = 0):
        self.used_gids: [int] = []
        self.chr_offset: int = chr_offset
        self.fallback_chr: int = fallback_chr

    def insert_gid(self, gid: int):
        gid = gid & MASK_GID
        if gid not in self.used_gids:
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
    def __init__(self, args):
        self.sources: [TileSource] = []
        self.bg: MapTileset = MapTileset(args.bg_tile_offset,
                                         args.bg_tile_default)
        self.obj: MapTileset = MapTileset()

    def gid_to_chr_bg(self, gid: int) -> int:
        return self.bg.gid_to_chr(gid)

    def gid_to_chr_obj(self, gid: int) -> int:
        return self.obj.gid_to_chr(gid)

    def add_source_tilesets(self, tmx: TiledMap):
        for tileset in tmx.tilesets.values():
            source = TileSource(tileset)
            self.sources.append(source)

    def require_gid_source(self, gid: int) -> TileSource:
        for source in self.sources:
            if source.has_gid(gid):
                return source
        return None

    def build_tileset_loadocode(self,
                                tileset: MapTileset,
                                block: int) -> [str]:
        if tileset.is_empty():
            return []

        lines = []
        lines.append("\tdb MapChunk_Loado")
        lines.append(f"\tdb LOADOCODE_CHRB_{block}")
        if block == 0:
            lines.append("\tdb LOADOCODE_DEST_CHR, tThings")

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
                reslabel = source.get_res_label()
                lines.append(f"\tdw {reslabel}")

            start, count = seqs.push(source.to_local_id(gid))
            _append_run(start, count)

        start, count = seqs.break_run()
        _append_run(start, count)
        lines.append("\tdb LOADOCODE_STOP")
        return lines


class Vec2i(NamedTuple):
    x: int = 0
    y: int = 0


@define(frozen=True)
class ThingDef:
    def get_def_id(self) -> str:
        raise NotImplementedError

    def get_def_label(self) -> str:
        return f".thing{self.get_def_id()}"

    def get_asm(self) -> [str]:
        raise NotImplementedError


@define(frozen=True)
class ThingParam:
    def get_thingcode(self) -> str:
        raise NotImplementedError

    def digest(self) -> str:
        typename = bytes(type(self).__name__, encoding="utf-8")
        h = hashlib.blake2s(typename, digest_size=8)
        h.update(bytes(attrs.astuple(self)))
        return h.hexdigest()

    def hashy(self):
        typename = bytes(type(self).__name__, encoding="utf-8")
        h: hashlib.blake2s = hashlib.blake2s(typename)
        h.update(bytes(attrs.astuple(self)))
        return h

    def tobytes(self) -> bytes:
        typename = bytes(type(self).__name__, encoding="utf-8")
        data = bytes(attrs.astuple(self))
        return typename + data


@define(frozen=True)
class Root(ThingParam):
    root: bool

    def get_thingcode(self) -> str:
        if self.root:
            return "ThingcNew"
        else:
            return ""


@define(frozen=True)
class Position(ThingParam):
    x: int = 0
    y: int = 0

    def get_thingcode(self) -> str:
        f"ThingcPosition {self.x}, {self.y}"

    @classmethod
    def from_vec(cls, vec: Vec2i):
        return cls(x=vec.x, y=vec.y)


@define(frozen=True)
class DrawTileObj(ThingParam):
    chr_code: int
    oam_attr: int

    def get_thingcode(self) -> str:
        return f"ThingcDrawOAM tThings + {self.chr_code}, {self.oam_attr}"


@define(frozen=True)
class DrawNone(ThingParam):
    def get_thingcode(self) -> str:
        return "ThingcDrawNone"


@define(frozen=True)
class CollideNone(ThingParam):
    def get_thingcode(self) -> str:
        return "ThingcCollideNone"


@define(frozen=True)
class CollideTile(ThingParam):
    def get_thingcode(self) -> str:
        return "ThingcCollideTile"


@define(frozen=True)
class CollideBox(ThingParam):
    x: int = 0
    y: int = 0
    w: int = 8
    h: int = 8

    def get_thingcode(self) -> str:
        l, r = self.x, self.x + self.w
        t, b = self.y, self.y + self.h
        return f"ThingcCollideBox {l}, {r}, {t}, {b}"


@define(frozen=True)
class Hits(ThingParam):
    hits: int

    def get_thingcode(self) -> str:
        return f"ThingcHits {self.hits}"


@define(frozen=True)
class EvecDie(ThingParam):
    die_into: ThingDef

    def tobytes(self) -> bytes:
        typename = bytes(type(self).__name__, encoding="utf-8")
        data = bytes(self.die_into.get_def_id(),
                     encoding="utf-8") if self.die_into else b"nodie_into"
        return typename + data

    def get_thingcode(self) -> str:
        return f"ThingcEvecDie {self.die_into.get_def_label()}"


class ThingPlacement:
    def __init__(self,
                 pos_x: int, pos_y: int,
                 tag: int,
                 thing_def: ThingDef):
        self.pos_x: int = pos_x
        self.pos_y: int = pos_y
        self.tag: int = tag
        self.thing_def: ThingDef = thing_def

    def get_asm(self) -> [str]:
        return [
            f"\tThingcInstance {self.thing_def.get_def_label()}",
            f"\tThingcPosition {self.pos_x}, {self.pos_y}",
            f"\tThingcTag {self.tag}",
            "\tThingcSave",
        ]


@define(frozen=True)
class ThingStateParams():
    root: Root = None
    position: Position = None
    drawable: ThingParam = None
    collider: ThingParam = None
    hits: Hits = None
    ev_die: EvecDie = None

    def get_thingcodes(self) -> List[str]:
        tc = []
        if self.root:
            tc.append(self.root.get_thingcode())
        if self.position:
            tc.append(self.position.get_thingcode())
        if self.drawable:
            tc.append(self.drawable.get_thingcode())
        if self.collider:
            tc.append(self.collider.get_thingcode())
        if self.hits:
            tc.append(self.hits.get_thingcode())
        if self.ev_die:
            tc.append(self.ev_die.get_thingcode())
        return tc

    def get_def_id(self) -> str:
        h = hashlib.blake2s(b"ThingStateParams", digest_size=9)
        h.update(self.root.tobytes() if self.root else b"noroot")
        h.update(self.position.tobytes() if self.position else b"noposition")
        h.update(self.drawable.tobytes() if self.drawable else b"nodrawable")
        h.update(self.collider.tobytes() if self.collider else b"nocollider")
        h.update(self.hits.tobytes() if self.hits else b"nohits")
        h.update(self.ev_die.tobytes() if self.ev_die else b"noev_die")
        return h.hexdigest()


@define
class ThingStateDef(ThingDef):
    params: ThingStateParams

    def get_def_id(self) -> str:
        return self.params.get_def_id()

    def get_asm(self) -> [str]:
        tc = []
        indent = 1

        def writeln(s: str):
            tc.append(indent * "\t" + s)

        # writeln(f"; {self}")
        writeln(f"{self.get_def_label()}:")
        indent += 1
        if self.params:
            stab = indent * "\t"
            tc.extend([stab + s for s in self.params.get_thingcodes()])
        writeln("ThingcSave")
        writeln("ThingcStop")
        return tc


@define
class ThingTile:
    gid: int
    position: Vec2i
    obid: int
    parentobid: int = None

    @classmethod
    def from_tile_obj(cls, obj: tiled_object.Tile):
        parentobid = None
        parentv = obj.properties.get("parent", None)
        if parentv:
            parentobid = parentv if parentv is int else int(parentv)

        return cls(
            gid=obj.gid,
            obid=obj.id,
            position=Vec2i(round(obj.coordinates.x),
                           round(obj.coordinates.y - 8)),
            parentobid=parentobid,
        )


class Things:
    SINGLE_LIDS = {
        0: (1, 2),
        3: (1, 2),
        6: (1, 2),
        9: (1, 2),
        12: (1, 2)
    }
    TALL_LIDS = {
        32: (-15, 1),
        34: (-15, 1),
        36: (-15, 1),
        38: (-15, 1),
        40: (-15, 1),
        42: (-15, 1)
    }
    OTHER_LIDS = {
        28: (1),
        44: (1),
        46: (-1)
    }

    def __init__(self):
        self.tiles = []
        self.thing_defs = {}
        self.thing_placements = []
        # list of (parent_obid, child_placement_tag) pairs
        self.unresolved_parents = []
        # map ThingTile obids (src object) to placement tags
        self.obid_tag_map = {}

    def add_tile(self, obj: tiled_object.Tile):
        tile = ThingTile.from_tile_obj(obj)
        self.tiles.append(tile)

    def add_state_def(self, params: ThingStateParams) -> ThingStateDef:
        tdid = params.get_def_id()
        if tdid in self.thing_defs:
            return self.thing_defs[tdid]
        else:
            td = ThingStateDef(params)
            self.thing_defs[tdid] = td
            return td

    def place(self,
              pos: Vec2i,
              td: ThingDef,
              src_obj: tiled_object.Tile) -> int:
        tag = len(self.thing_placements)
        placem = ThingPlacement(pos.x, pos.y, tag, td)
        self.thing_placements.append(placem)
        self.obid_tag_map[src_obj.obid] = tag
        return tag

    def process(self, tile_tracker: TileTracker):
        for tile in self.tiles:
            if tile.parentobid:
                self.unresolved_parents.append((tile.parentobid, tile.obid))

        # Collect required tiles
        for tile in self.tiles:
            tile_tracker.obj.insert_gid(tile.gid)
            source = tile_tracker.require_gid_source(tile.gid)
            if source.tileset.image.name == "buildings.png":
                loc = source.to_local_id(tile.gid)
                self.prepare_building_tile(loc, tile, tile_tracker)

        # Build Defs and Placements
        for tile in self.tiles:
            source = tile_tracker.require_gid_source(tile.gid)
            if source.tileset.image.name == "buildings.png":
                loc = source.to_local_id(tile.gid)
                self.place_building_tile(loc, tile, tile_tracker)

    def prepare_building_tile(self,
                              loc: int,
                              tile: ThingTile,
                              tile_tracker: TileTracker):
        if loc in self.SINGLE_LIDS:
            # single-tile buildings
            gid1, gid2 = tile.gid + 1, tile.gid + 2
            tile_tracker.obj.insert_gid(gid1)
            tile_tracker.obj.insert_gid(gid2)
        elif loc in self.TALL_LIDS:
            # tall (2 tile) buildings
            d1, d2 = self.TALL_LIDS[loc]
            gid1, gid2 = tile.gid + d1, tile.gid + d2
            tile_tracker.obj.insert_gid(gid1)
            tile_tracker.obj.insert_gid(gid2)
        elif loc in self.OTHER_LIDS and tile.parentobid is None:
            d1 = self.OTHER_LIDS[loc]
            gid1 = tile.gid + d1
            tile_tracker.obj.insert_gid(gid1)

    def place_building_tile(self,
                            loc: int,
                            tile: ThingTile,
                            tile_tracker: TileTracker):
        if loc in self.SINGLE_LIDS:
            # single-tile buildings
            d1, d2 = self.SINGLE_LIDS[loc]
            gid0, gid1, gid2 = tile.gid, tile.gid + d1, tile.gid + d2
            oam_attr = gid_to_oam_attr(tile.gid)
            dam2 = self.add_state_def(
                ThingStateParams(
                    drawable=DrawTileObj(
                        tile_tracker.obj.gid_to_chr(gid2),
                        oam_attr
                    ),
                    collider=CollideNone(),
                )
            )
            dam1 = self.add_state_def(
                ThingStateParams(
                    drawable=DrawTileObj(
                        tile_tracker.obj.gid_to_chr(gid1),
                        oam_attr
                    ),
                    hits=Hits(2),
                    ev_die=EvecDie(dam2)
                )
            )
            td = self.add_state_def(
                ThingStateParams(
                    root=Root(True),
                    drawable=DrawTileObj(
                        tile_tracker.obj.gid_to_chr(gid0),
                        oam_attr
                    ),
                    collider=CollideTile(),
                    hits=Hits(1),
                    ev_die=EvecDie(dam1)
                )
            )
            self.place(tile.position, td, tile)
        elif loc in self.TALL_LIDS:
            # tall (2 tile) buildings
            d1, d2 = self.TALL_LIDS[loc]
            gid0, gid1, gid2 = tile.gid, tile.gid + d1, tile.gid + d2
            basedam2 = self.add_state_def(
                ThingStateParams(
                    drawable=DrawTileObj(
                        tile_tracker.obj.gid_to_chr(gid2),
                        gid_to_oam_attr(gid2)
                    ),
                    collider=CollideNone(),
                )
            )
            basedam1 = self.add_state_def(
                ThingStateParams(
                    drawable=DrawTileObj(
                        tile_tracker.obj.gid_to_chr(gid1),
                        gid_to_oam_attr(gid1)
                    ),
                    hits=Hits(2),
                    ev_die=EvecDie(basedam2)
                )
            )
            td = self.add_state_def(
                ThingStateParams(
                    root=Root(True),
                    drawable=DrawTileObj(
                        tile_tracker.obj.gid_to_chr(gid0),
                        gid_to_oam_attr(gid0)
                    ),
                    collider=CollideTile(),
                    hits=Hits(1),
                    ev_die=EvecDie(basedam1)
                )
            )
            self.place(tile.position, td, tile)
        else:
            if loc in self.OTHER_LIDS and tile.parentobid is None:
                d1 = self.OTHER_LIDS[loc]
                gid1 = tile.gid + d1
                params1 = ThingStateParams(
                    drawable=DrawTileObj(
                        tile_tracker.obj.gid_to_chr(gid1),
                        gid_to_oam_attr(gid1)
                    ),
                    collider=CollideNone()
                )
            else:
                params1 = ThingStateParams(
                    drawable=DrawNone(),
                    collider=CollideNone()
                )
            dam1 = self.add_state_def(params1)
            td = self.add_state_def(
                ThingStateParams(
                    root=Root(True),
                    drawable=DrawTileObj(
                        tile_tracker.obj.gid_to_chr(tile.gid),
                        gid_to_oam_attr(tile.gid)
                    ),
                    collider=CollideTile(),
                    hits=Hits(1),
                    ev_die=EvecDie(dam1)
                )
            )
            self.place(tile.position, td, tile)

    def get_subthing_pairs(self) -> List[Tuple[int, int]]:
        """
        Resolve parent-child (subthing) relations.
        Return a list of placement tags (parent_tag, child_tag).
        """
        pairs: List[Tuple[int, int]] = []
        for parentobid, childobid in self.unresolved_parents:
            parent_tag = self.obid_tag_map.get(parentobid, None)
            child_tag = self.obid_tag_map.get(childobid, None)
            pairs.append((parent_tag, child_tag))
        return pairs

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
                    if gid & (GID_FLIPPED_DIAG | GID_ROTATED_HEX_120) != 0:
                        raise Exception("Diagonal flip is unsupported.")
                    # ignore empty cells
                    if gid > 0:
                        self.tile_tracker.bg.insert_gid(gid)
                        self.tilemap[cy][cx] = gid & MASK_GID
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


def main():
    argp = ArgumentParser()
    argp.add_argument("--bg_tile_offset",
                      type=int,
                      default=128,
                      help="BG tilemap CHR code offset. Defaults to 128.")
    argp.add_argument("--bg_tile_default",
                      type=int,
                      default=0,
                      help="BG tilemap fallback CHR code. Used to fill empty cells in source map.")
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
