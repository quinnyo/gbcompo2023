from typing import NamedTuple


class Vec2i(NamedTuple):
    x: int = 0
    y: int = 0

    @classmethod
    def new(cls, x: int, y: int):
        return cls(round(x), round(y))


class Rect2i(NamedTuple):
    pos: Vec2i = Vec2i()
    size: Vec2i = Vec2i()
