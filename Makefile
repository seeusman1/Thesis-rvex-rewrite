
.PHONY: help
help:
	@less README

.PHONY: conformance
conformance:
	# This is by no means complete.
	cd platform/core-tests && make conformance

