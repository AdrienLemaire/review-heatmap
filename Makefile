# Makefile for Anki add-ons
#
# Prepares zip file for upload to AnkiWeb
# 
# Copyright: (c) 2017-2018 Glutanimate <https://glutanimate.com/>
# License: GNU AGPLv3 <https://www.gnu.org/licenses/agpl.html>

SHELL := /bin/bash

VERSION = `git describe HEAD --tags --abbrev=0`
ADDON = review-heatmap
ADDONDIR = review_heatmap


###

all: zip

clean: cleanbuild cleanzips

zip: cleanbuild ui builddir buildzip

release: cleanbuild builddir buildrelease cleanbuild

###

cleanzips:
	rm -f *-anki2*.zip

cleanbuild:
	rm -rf build
	find . \( -name '*.pyc' -o -name '*.pyo' -o -name '__pycache__' \) -delete

ui:
	PYENV_VERSION=anki20tools ./tools/build_ui.sh "$(ADDONDIR)" anki20
	PYENV_VERSION=anki21tools ./tools/build_ui.sh "$(ADDONDIR)" anki21

builddir:
	mkdir -p build/dist build/dist21

buildzip:
	rm -f *-current-anki2*.zip
	cp src/*.py build/dist/
	cp -r "src/$(ADDONDIR)" build/dist/
	cp -r "src/$(ADDONDIR)/"* build/dist21/
	rm -rf "build/dist/$(ADDONDIR)/forms5" build/dist21/forms4
	cd build/dist && zip -r "../../$(ADDON)-current-anki20.zip" *
	cd build/dist21 && zip -r "../../$(ADDON)-current-anki21.zip" *
	rm -rf build

buildrelease:
    # Remove existing release build of same version
	rm -f *-release-$(VERSION)-anki2*.zip

	# Create a git snapshot of source files at $(VERSION) tag
	git archive --format tar $(VERSION) | tar -x -C build/dist/

	# Copy licenses to module directory
	for license in build/dist/LICENSE* build/dist/resources/LICENSE*; do \
		name=$$(basename $$license) ; \
		ext="$${name##*.}" ; \
		fname="$${name%.*}" ; \
		echo "build/dist/src/$(ADDONDIR)/$${fname}.txt" ; \
		cp $$license "build/dist/src/$(ADDONDIR)/$${fname}.txt" ; \
	done

	# Include referenced assets that are not part of version control
	cp -r resources/icons/optional build/dist/resources/icons/
	
	# Duplicate build folder for both build targets
	cp -r build/dist/* build/dist21

	# Build for Anki 2.0
	cd build/dist &&  \
		PYENV_VERSION=anki20tools ../../tools/build_ui.sh "$(ADDONDIR)" anki20 &&\
		cd src && \
		zip -r "../../../$(ADDON)-release-$(VERSION)-anki20.zip" "$(ADDONDIR)" *.py
	# Build for Anki 2.1
	#   GitHub release contains module folder, whereas files in the AnkiWeb release
	#   are all placed at the top-level of the zip file.
	cd build/dist21 &&  \
		PYENV_VERSION=anki21tools ../../tools/build_ui.sh "$(ADDONDIR)" anki21 && \
		cd src && \
		zip -r "../../../$(ADDON)-release-$(VERSION)-anki21.zip" "$(ADDONDIR)" && \
		cd "$(ADDONDIR)" && \
		zip -r "../../../../$(ADDON)-release-$(VERSION)-anki21-ankiweb.zip" *
	