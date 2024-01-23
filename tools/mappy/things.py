from typing import List, Tuple
import hashlib

from attrs import define
import attrs

from pytiled_parser import tiled_object

from .common import Vec2i
from .tiles import TileTracker, gid_to_oam_attr


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
