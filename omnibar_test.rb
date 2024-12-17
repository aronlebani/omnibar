#!/usr/bin/env ruby

# frozen_string_literal: true

require 'test/unit'

require_relative 'omnibar'

class TestString < Test::Unit::TestCase
  def test_lsplit
    assert_equal 'a,b,c'.lsplit(','), ['a', 'b,c']
  end

  def test_rsplit
    assert_equal 'a,b,c'.rsplit(','), ['a,b', 'c']
  end
end

class TestParser < Test::Unit::TestCase
  include Parser

  def test_whitespace?
    assert_not_nil whitespace?('')
    assert_nil whitespace?('hello')
  end

  def test_comment?
    assert_not_nil comment?('# hello')
    assert_nil comment?('')
    assert_nil comment?('hello')
  end
end

class TestSearchItem < Test::Unit::TestCase
  def test_to_launcher_s
    bookmark = SearchItem.new('example', 'https://example.com', nil, :bookmark)
    history = SearchItem.new('example', 'https://example.com', '2024-10-14', :history)
    search_engine = SearchItem.new('mdn', 'https://developer.mozilla.org/en-US/search?q=%s', nil, :search_engine)

    assert_equal bookmark.to_launcher_s, 'B example <https://example.com>'
    assert_equal history.to_launcher_s, 'H example <https://example.com> (2024-10-14)'
    assert_equal search_engine.to_launcher_s, 'mdn: '
  end

  def test_parse
    SearchItem.parse('B example <https://example.com>') do |url, st, se|
      assert_equal url, 'https://example.com'
      assert_nil st
      assert_nil se
    end

    SearchItem.parse('H example <https://example.com> (2024-10-14)') do |url, st, se|
      assert_equal url, 'https://example.com'
      assert_nil st
      assert_nil se
    end

    SearchItem.parse('mdn: background-color') do |url, st, se|
      assert_nil url
      assert_equal st, 'background-color'
      assert_equal se, 'mdn'
    end
  end
end

class TestMain < Test::Unit::TestCase
  def test_extract_url
    search_engines = [
      SearchItem.new('mdn', 'https://developer.mozilla.org/en-US/search?q=%s', nil, :search_engine),
      SearchItem.new('clhs', 'http://www.xach.com/clhs?q=%s', nil, :search_engine),
      SearchItem.new('*', 'https://html.duckduckgo.com/html?q=%s', nil, :search_engine),
    ]

    assert_equal extract_url('localhost:3000', search_engines), 'http://localhost:3000'
    assert_equal extract_url('https://lebani.dev', search_engines), 'https://lebani.dev'
    assert_equal extract_url('file:///home/aron/index.html', search_engines), 'file:///home/aron/index.html'
    assert_equal extract_url('B example <https://example.com>', search_engines), 'https://example.com'
    assert_equal extract_url('H example <https://example.com> (2024-10-14)', search_engines), 'https://example.com'
    assert_equal extract_url('clhs: defun', search_engines), 'http://www.xach.com/clhs?q=defun'
    assert_equal extract_url('mdn: hello world', search_engines), 'https://developer.mozilla.org/en-US/search?q=hello%20world'
    assert_equal extract_url('hello world', search_engines), 'https://html.duckduckgo.com/html?q=hello%20world'
  end
end
