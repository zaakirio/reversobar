.PHONY: build run app dmg notarize release icon flags preview clean

## build   – debug build
build:
	swift build

## run     – build & run from the terminal (menu-bar app)
run:
	swift run

## app     – universal, signed Reversobar.app in build/
app:
	scripts/build_app.sh

## dmg     – package build/Reversobar.app into a signed DMG
dmg:
	scripts/make_dmg.sh

## notarize – notarize & staple build/Reversobar.app
notarize:
	scripts/notarize.sh

## release – full pipeline: build → notarize → DMG → notarize DMG
release:
	scripts/release.sh

## icon    – regenerate the app icon (.icns)
icon:
	tools/make_icon.sh

## flags   – regenerate bundled flag PNGs
flags:
	tools/make_flags.sh

## preview – open the UI in a window for inspection
preview:
	scripts/preview.sh

## clean   – remove build artefacts
clean:
	rm -rf .build build
