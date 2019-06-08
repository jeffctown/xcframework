#!/usr/bin/xcrun make -f

TOOL_TEMPORARY_FOLDER?=/tmp/xcframework.dst
PREFIX?=/usr/local

OUTPUT_PACKAGE=xcframework.pkg
FRAMEWORK_NAME=XCFrameworkKit

TOOL_EXECUTABLE=./.build/release/xcframework
BINARIES_FOLDER=/usr/local/bin

# ZSH_COMMAND · run single command in `zsh` shell, ignoring most `zsh` startup files.
ZSH_COMMAND := ZDOTDIR='/var/empty' zsh -o NO_GLOBAL_RCS -c
# RM_SAFELY · `rm -rf` ensuring first and only parameter is non-null, contains more than whitespace, non-root if resolving absolutely.
RM_SAFELY := $(ZSH_COMMAND) '[[ ! $${1:?} =~ "^[[:space:]]+\$$" ]] && [[ $${1:A} != "/" ]] && [[ $${\#} == "1" ]] && noglob rm -rf $${1:A}' --

VERSION_STRING=$(shell git describe --abbrev=0 --tags)

RM=rm -f
MKDIR=mkdir -p
SUDO=sudo
CP=cp

.PHONY: all clean test installables package install uninstall xcodeproj xcodetest codecoverage archive release

all: installables

clean:
	swift package clean
	
test:
	swift test

installables:
	swift build -c release

package: installables archive
	$(MKDIR) "$(TOOL_TEMPORARY_FOLDER)$(BINARIES_FOLDER)"
	$(CP) "$(TOOL_EXECUTABLE)" "$(TOOL_TEMPORARY_FOLDER)$(BINARIES_FOLDER)"

	pkgbuild \
		--identifier "com.jefflett.xcframework" \
		--install-location "/" \
		--root "$(TOOL_TEMPORARY_FOLDER)" \
		--version "$(VERSION_STRING)" \
		"$(OUTPUT_PACKAGE)"

install: installables
	$(SUDO) $(CP) -f "$(TOOL_EXECUTABLE)" "$(BINARIES_FOLDER)"

uninstall:
	$(RM) "$(BINARIES_FOLDER)/xcframework"

xcodeproj:
	swift package generate-xcodeproj

xcodetest: xcodeproj
	xcodebuild -scheme xcframework build test

codecoverage: xcodeproj
	xcodebuild -scheme xcframework -enableCodeCoverage YES build test -quiet

archive:
	carthage build --no-skip-current --platform mac
	carthage archive $(FRAMEWORK_NAME)

release: | test xcodetest archive package install





