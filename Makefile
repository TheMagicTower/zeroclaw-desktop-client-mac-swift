.PHONY: setup generate open clean

setup:
	brew install xcodegen

generate:
	xcodegen generate

open: generate
	open ZeroClawDesktop.xcodeproj

clean:
	rm -rf ZeroClawDesktop.xcodeproj
