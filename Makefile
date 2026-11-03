SYSTEM_RUBY ?= ruby

.PHONY: test verify

test:
	$(SYSTEM_RUBY) -Itest test/dotfiles_test.rb
	$(MAKE) -C skill test SYSTEM_RUBY=$(SYSTEM_RUBY)
	$(SYSTEM_RUBY) -Iagents/skills/pr-sweep/test agents/skills/pr-sweep/test/attention_test.rb

verify: test
	$(SYSTEM_RUBY) skill/src/cli.rb lint
	$(SYSTEM_RUBY) scripts/dotfiles verify
