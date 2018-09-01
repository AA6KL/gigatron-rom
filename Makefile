CFLAGS:=-std=c11 -O3 -Wall
DEV:=ROMv3x

# Latest released version as default target
ROMv2.rom: Core/* Apps/* Images/* Makefile interface.json
	# Development towards ROMv2 (minor changes only)
	env romType="0x20"\
	    PYTHONPATH="Core:$(PYTHONPATH)"\
	    python Core/ROMv2.py\
		Apps/Snake_v2.gcl\
		Apps/Racer_v1.gcl\
		Apps/Mandelbrot_v1.gcl\
		Apps/Pictures_v1.gcl\
		Apps/Credits_v1.gcl\
		Apps/Loader_v1.gcl\
		Apps/TinyBASIC_v1.gcl\
		Apps/WozMon_v1.gcl\
		Apps/Main_v2.gcl\
		Core/Reset_v2.gcl

# ROM v1 shipped with first batches of kits
ROMv1.rom: Core/* Apps/* Images/* Makefile interface.json
	# ROMv1 gets 0x1c. Further numbers to be decided.
	env romType="0x1c"\
	    PYTHONPATH="Core:$(PYTHONPATH)"\
	    python Core/ROMv1.py\
		Apps/Snake_v1.gcl\
		Apps/Racer_v1.gcl\
		Apps/Mandelbrot_v1.gcl\
		Apps/Pictures_v1.gcl\
		Apps/Credits_v1.gcl\
		Apps/Loader_v1.gcl\
		Apps/Screen_v1.gcl\
		Apps/Main_v1.gcl\
		Core/Reset_v1.gcl

# Work in progress
dev: $(DEV).rom
$(DEV).rom: Core/* Apps/* Images/* Makefile interface.json
	# Development towards ROMv2 (minor changes only)
	env romType="0x28"\
	    PYTHONPATH="Core:$(PYTHONPATH)"\
	    python Core/$(DEV).py\
		Apps/Snake_v2.gcl\
		Apps/Racer_v1.gcl\
		Apps/Mandelbrot_v1.gcl\
		Apps/Pictures_v1.gcl\
		Apps/Credits_v1.gcl\
		Apps/Loader_v1.gcl\
		Apps/TinyBASIC.gcl\
		Apps/WozMon.gcl\
		Apps/Main_v3.gcl\
		Core/Reset_v3.gcl

run: Docs/gtemu $(DEV).rom
	Docs/gtemu $(DEV).rom

test: Docs/gtemu $(DEV).rom
	# Check for hSync errors in first ~30 seconds of emulation
	Docs/gtemu $(DEV).rom | head -999999 | grep \~

basic: Apps/TinyBASIC.gt1 Apps/TinyBASIC.h
	mv Apps/TinyBASIC.h Utils/BabelFish

Utils/BabelFish/tinyfont.h: Utils/BabelFish/tinyfont.py
	python "$<" > "$@"

compiletest: Apps/*.gt1
	# Test compilation
	# (Use 'git diff' afterwards to detect unwanted changes)
	for GT1 in Apps/*.gt1; do rm "$${GT1}"; make "$${GT1}"; done

time: Docs/gtemu $(DEV).rom
	# Run emulation until first sound
	Docs/gtemu $(DEV).rom | grep -m 1 'xout [^0]'

burn: $(DEV).rom
	minipro -p 'AT27C1024 @DIP40' -w "$<" -y -s

%.gt1: %.gcl
	Core/compilegcl.py "$<" `dirname ./"$@"`

%.h: %.gt1
	# Convert GT1 file into header for including as PROGMEM data
	od -t x1 -v < "$<" |\
	awk 'BEGIN {print "// Converted from $< by Makefile"}\
	     {for (i=2; i<=NF; i++) printf "0x%s,\n", $$i}' > "$@"

%.rgb: %.png
	# Uses ImageMagick
	convert "$<" "$@"

todo:
	@git ls-files | sed 's/ /\\ /g' | xargs grep -I -E '(TODO|XXX)'

# Show simplified git log
log:
	git log --oneline --decorate --graph --all

# vi: noexpandtab
