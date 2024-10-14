#!/usr/bin/env ruby

# frozen_string_literal: true

require 'test/unit'

require_relative 'omnibar'

class TestString < Test::Unit::TestCase
  def test_lsplit
    assert 'a,b,c'.lsplit(',') == ['a', 'b,c']
  end

  def test_rsplit
    assert 'a,b,c'.rsplit(',') == ['a,b', 'c']
  end
end

class TestParser < Test::Unit::TestCase
  include Parser

  def test_whitespace?
    assert whitespace?('') != nil
    assert whitespace?('hello') == nil
  end

  def test_comment?
    assert comment?('# hello') != nil
    assert comment?('') == nil
    assert comment?('hello') == nil
  end
end

class TestSearchItem < Test::Unit::TestCase
  def test_to_launcher_s
    bookmark = SearchItem.new 'example', 'https://example.com', nil, :bookmark
    history = SearchItem.new 'example', 'https://example.com', '2024-10-14', :history
    search_engine = SearchItem.new 'mdn', 'https://developer.mozilla.org/en-US/search?q=%s', nil, :search_engine

    assert bookmark.to_launcher_s == 'B example <https://example.com>'
    assert history.to_launcher_s == 'H example <https://example.com> (2024-10-14)'
    assert search_engine.to_launcher_s == 'mdn: '
  end

  def test_parse_url
    bookmark = 'B example <https://example.com>'
    history = 'H example <https://example.com> (2024-10-14)'
    search_engine = 'mdn: background-color'

    assert SearchItem.parse_url(bookmark) == 'https://example.com'
    assert SearchItem.parse_url(history) == 'https://example.com'
    assert SearchItem.parse_url(search_engine) == nil
  end

  def test_parse_search_term
    bookmark = 'B example <https://example.com>'
    history = 'H example <https://example.com> (2024-10-14)'
    search_engine = 'mdn: background-color'

    assert SearchItem.parse_search_term(bookmark) == nil
    assert SearchItem.parse_search_term(history) == nil
    assert SearchItem.parse_search_term(search_engine) == 'background-color'
  end

  def test_parse_search_engine
    bookmark = 'B example <https://example.com>'
    history = 'H example <https://example.com> (2024-10-14)'
    search_engine = 'mdn: background-color'

    assert SearchItem.parse_search_engine(bookmark) == nil
    assert SearchItem.parse_search_engine(history) == nil
    assert SearchItem.parse_search_engine(search_engine) == 'mdn'
  end
end

class TestMain < Test::Unit::TestCase
  def test_extract_url
    search_engines = [
      SearchItem.new('mdn', 'https://developer.mozilla.org/en-US/search?q=%s', nil, :search_engine),
      SearchItem.new('clhs', 'http://www.xach.com/clhs?q=%s', nil, :search_engine),
      SearchItem.new('*', 'https://html.duckduckgo.com/html?q=%s', nil, :search_engine),
    ]

    assert extract_url('localhost:3000', search_engines) == 'http://localhost:3000'
    assert extract_url('https://lebani.dev', search_engines) == 'https://lebani.dev'
    assert extract_url('file:///home/aron/index.html', search_engines) == 'file:///home/aron/index.html'
    assert extract_url('B example <https://example.com>', search_engines) == 'https://example.com'
    assert extract_url('H example <https://example.com> (2024-10-14)', search_engines) == 'https://example.com'
    assert extract_url('clhs: defun', search_engines) == 'http://www.xach.com/clhs?q=defun'
    assert extract_url('mdn: hello world', search_engines) == 'https://developer.mozilla.org/en-US/search?q=hello%20world'
    assert extract_url('hello world', search_engines) == 'https://html.duckduckgo.com/html?q=hello%20world'
  end
end
