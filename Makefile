SCHEME = Beacon
SDK = iphonesimulator
DESTINATION = platform=iOS Simulator,name=iPhone 17,OS=latest
XCBEAUTIFY = xcbeautify

SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c

.PHONY: build run test all clean

build:
	@echo "Building $(SCHEME)..."
	@set -o pipefail && xcodebuild build \
		-scheme $(SCHEME) \
		-sdk $(SDK) \
		-destination "$(DESTINATION)" \
		-quiet \
		2>&1 | $(XCBEAUTIFY)

test:
	@echo "Testing $(SCHEME)..."
	@set -o pipefail && NSUnbufferedIO=YES xcodebuild test \
		-scheme $(SCHEME) \
		-sdk $(SDK) \
		-destination "$(DESTINATION)" \
		2>&1 | $(XCBEAUTIFY)

run: build test

all: run

clean:
	@echo "Cleaning..."
	@set -o pipefail && xcodebuild clean \
		-scheme $(SCHEME) \
		-sdk $(SDK) \
		-destination "$(DESTINATION)" \
		2>&1 | $(XCBEAUTIFY)
