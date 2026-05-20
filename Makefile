.PHONY: build test

SCHEME := SwiftWork
DEST := platform=macOS

build:
	xcodebuild -scheme $(SCHEME) -destination '$(DEST)' build

test:
	xcodebuild -scheme $(SCHEME) -destination '$(DEST)' -only-testing:SwiftWorkTests test
