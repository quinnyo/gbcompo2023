
.SUFFIXES:

################################################
#                                              #
#             CONSTANT DEFINITIONS             #
#                                              #
################################################

## Directory constants
# These directories can be placed elsewhere if you want; directories whose placement
# must be fixed, lest this Makefile breaks, are hardcoded throughout this Makefile
TARGETDIR := target
BINDIR := $(TARGETDIR)/bin
OBJDIR := $(TARGETDIR)/obj
DEPDIR := $(TARGETDIR)/dep

# Program constants
ifneq ($(strip $(shell which rm)),)
    # POSIX OSes
    RM_RF := rm -rf
    MKDIR_P := mkdir -p
else
    # Windows
    RM_RF := -del /q
    MKDIR_P := -mkdir
endif

# Shortcut if you want to use a local copy of RGBDS
RGBDS   :=
RGBASM  := $(RGBDS)rgbasm
RGBLINK := $(RGBDS)rgblink
RGBFIX  := $(RGBDS)rgbfix
RGBGFX  := $(RGBDS)rgbgfx

PYTHON  ?= tools/pyenv/bin/python3
MAPPY   := $(PYTHON) tools/map.py

ROM = $(BINDIR)/$(ROMNAME).$(ROMEXT)

# Argument constants
INCDIRS  = src/ src/include/
WARNINGS = all extra error
DEFVARS  = DEBUG MKMBC=$(MBC)
ASFLAGS  = -p $(PADVALUE) $(addprefix -i,$(INCDIRS)) $(addprefix -W,$(WARNINGS)) $(addprefix -D,$(DEFVARS))
LDFLAGS  = -p $(PADVALUE)
FIXFLAGS = -p $(PADVALUE) -v -i "$(GAMEID)" -k "$(LICENSEE)" -l $(OLDLIC) -m $(MBC) -n $(VERSION) -r $(SRAMSIZE) -t $(TITLE)

# The list of "root" ASM files that RGBASM will be invoked on
SRCS = $(wildcard src/core/*.asm) $(wildcard src/*.asm) $(wildcard src/mus/*.asm)

## Project-specific configuration
# Use this to override the above
include project.mk

################################################
#                                              #
#                    TARGETS                   #
#                                              #
################################################

# `all` (Default target): build the ROM
all: $(ROM)
.PHONY: all

# `clean`: Clean temp and bin files
clean:
	$(RM_RF) $(BINDIR)
	$(RM_RF) $(OBJDIR)
	$(RM_RF) $(DEPDIR)
	$(RM_RF) $(TARGETDIR)
	$(RM_RF) res
.PHONY: clean

# `rebuild`: Build everything from scratch
# It's important to do these two in order if we're using more than one job
rebuild:
	$(MAKE) clean
	$(MAKE) all
.PHONY: rebuild

###############################################
#                                             #
#                 COMPILATION                 #
#                                             #
###############################################

# How to build a ROM
$(BINDIR)/%.$(ROMEXT) $(BINDIR)/%.sym $(BINDIR)/%.map: $(patsubst src/%,$(OBJDIR)/%.o,$(SRCS))
	@$(MKDIR_P) $(@D)
	$(RGBASM) $(ASFLAGS) -o $(OBJDIR)/build_date.o src/res/build_date.asm
	$(RGBLINK) $(LDFLAGS) -m $(BINDIR)/$*.map -n $(BINDIR)/$*.sym -o $(BINDIR)/$*.$(ROMEXT) $^ $(OBJDIR)/build_date.o \
	&& $(RGBFIX) -v $(FIXFLAGS) $(BINDIR)/$*.$(ROMEXT)

# Compile all the sources
$(OBJDIR)/%.o: src/%
	@$(MKDIR_P) $(@D)
	$(RGBASM) $(ASFLAGS) -o $(OBJDIR)/$*.o $<

# Generate dependency list (`mk` file)
$(DEPDIR)/%.mk: src/%
	@$(MKDIR_P) $(@D)
	$(RGBASM) $(ASFLAGS) -M $(DEPDIR)/$*.mk -MG -MP -MQ $(OBJDIR)/$*.o -MQ $(DEPDIR)/$*.mk $<

# Require `mk` dependency file for all source files
ifneq ($(MAKECMDGOALS),clean)
-include $(patsubst src/%,$(DEPDIR)/%.mk,$(SRCS))
endif

################################################
#                                              #
#                RESOURCE FILES                #
#                                              #
################################################


# By default, asset recipes convert files in `res/` into other files in `res/`
# This line causes assets not found in `res/` to be also looked for in `src/res/`
# "Source" assets can thus be safely stored there without `make clean` removing them
vpath res/% src

res/%.1bpp: res/%.png
	@$(MKDIR_P) $(@D)
	$(RGBGFX) -d 1 -o $@ $<

res/%.2bpp: res/%.png
	@$(MKDIR_P) $(@D)
	$(RGBGFX) -d 2 -o $@ $<

# "scrn" -- combined tile data + tilemap
res/%.scrn: tools/scrn.sh res/%.png
	@$(MKDIR_P) $(@D)
	$^ $@

res/map/%.asm: res/map/%.tmx
	@$(MKDIR_P) $(@D)
	$(MAPPY) -o $@ $<

# Catch non-existent files
# KEEP THIS LAST!!
%:
	@false
