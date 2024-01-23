import os
from argparse import ArgumentParser
from pathlib import Path

import pytiled_parser

from mappy.convert import MapConvert


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
    map_data = MapConvert()
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
    import sys
    sys.exit(main())
