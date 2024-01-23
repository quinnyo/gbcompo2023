from typing import List
from pathlib import Path
from bisect import insort, bisect_left

from pytiled_parser.tiled_map import TiledMap, Tileset

from .common import Vec2i, Rect2i


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

    def get_tile_collision_shapes(self, lid: int) -> List[Rect2i]:
        from pytiled_parser.tiled_object import TiledObject
        if self.tileset.tiles is None:
            return []
        tile = self.tileset.tiles[lid]
        if not tile.objects or not tile.objects.visible:
            return []
        shapes = []
        if tile.objects and tile.objects.visible:
            for ob in tile.objects.tiled_objects:
                if ob.visible and ob.class_ == "CollisionShape":
                    if isinstance(ob, TiledObject):
                        x, y = ob.coordinates
                        w, h = ob.size
                        shapes.append(Rect2i(Vec2i.new(x, y), Vec2i.new(w, h)))

        return shapes


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
