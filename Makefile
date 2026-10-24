SYSTEM_RUBY ?= ruby

.PHONY: test verify

test:
	$(SYSTEM_RUBY) -Itest test/dotfiles_test.rb
	$(MAKE) -C skill test SYSTEM_RUBY=$(SYSTEM_RUBY)

verify: test
	$(SYSTEM_RUBY) skill/src/cli.rb lint
	$(SYSTEM_RUBY) scripts/dotfiles verify
