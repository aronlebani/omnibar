# Omnibar

An extensible, browser-agnostic, dmenu omnibar.

## Installation

Omnibar is a single-file exectuable written in Ruby. To install it, simply
clone the repo, and move the `omnibar.rb` file to somewhere in your `$PATH`.
For example:

    git clone https://github.com/aronlebani/omnibar.git
    mv omnibar/omnibar.rb ~/bin/omnibar

The only runtime dependency is dmenu, which should be available in your systems
package manager. I think it's also quite straightforward to build from source.

## Usage

For command line options, run `omnibar --help`. For all supported browsers,
omnibar will collect your bookmarks and history across all browsers installed
on your system, and search through everything using dmenu.

By default, URLs are opened in `$BROWSER`. Alternatively, you can supply the
path of your preferred browser using the `--browser` command line option.

### Search engines

Omnibar also supports searching using custom search engines. To enable this,
create a `$XDG_CONFIG_HOME/search_engines` file. Each line is a search engine
in the format `<name> = <url>`. `Name` should be a short mnemonic using only
alpha characters. `Url` should be the URL to search, using `%s` as a
placeholder for the search term. An entry `* = <url>` is the default search
engine. For example:

      mdn = https://developer.mozilla.org/en-US/search?q=%s'
      clhs = http://www.xach.com/clhs?q=%s
      * = https://html.duckduckgo.com/html?q=%s

### Custom bookmarks

Omnibar also supports a custom bookmarks file. To enable this, create a
`$XDG_CONFIG_HOME/bookmarks` file. Each line is a bookmark in the form

    example <https://example.com>

Blank lines and lines starting with `#` are ignored.

## Extending

Since it's hard to maintain support for browsers I don't use, my hope is that
people will contribute extensions to support a variety of browsers. It has been
designed to make extending as simple as possible. To add support for a new
browser, simply subclass the `Browser` class, and implement the methods
`bookmarks` and `history`. Each of these methods take no parameters, and return
an array of `SearchItem` objects. For example:

```ruby
class Chrome < Browser
    self.history
        get_history_items.map do |item|
            SearchItem.new item.title, item.url, item.date, :history
        end
    end

    self.bookmarks
        get_bookmarks.map do |item|
            SearchItem.new item.title, item.url, nil, :bookmark
        end
    end
end
```

You don't have to implement both methods, any methods that are not implemented
are gracefully ignored.

PRs with extensions for supporting new browsers, as well as general features
and bug fixes are much appreciated.

## Testing

To run the unit tests, install the `unit-test` gem, and run
    
    ruby omnibar_test.rb

## License

This software is licensed under the MIT license.
