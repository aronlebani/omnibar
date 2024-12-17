RUBY ?= ruby
PREFIX ?= /usr/local

test:
	ruby omnibar_test.rb

install:
	install -m 755 omnibar.rb $(PREFIX)/bin/omnibar

uninstall:
	rm $(PREFIX)/bin/omnibar

.PHONY: test install uninstall
