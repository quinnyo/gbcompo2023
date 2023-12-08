ROMNAME := gigantgolf
ROMEXT  := gb
PADVALUE := 0xFF

## ROM Header, see https://gbdev.io/pandocs/The_Cartridge_Header.html

# Game title, up to 11 ASCII chars
TITLE := GIGANT_GOLF
# 4-ASCII letter game ID
GAMEID := GIGO
# New licensee, 2 ASCII chars
LICENSEE := Qx

VERSION := 1

MBC := MBC5+RAM+BATTERY
# 0x02 = 8KiB (1 bank)
SRAMSIZE := 0x02

# Disable automatic `nop` after `halt`
ASFLAGS += -h

# Game Boy Color compatible
FIXFLAGS += -c
