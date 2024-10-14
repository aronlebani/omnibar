#!/usr/bin/env ruby

# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'open3'
  gem 'optparse'
end

require 'open3'
require 'optparse'
require 'uri'

class String
  def lsplit(char)
    parts = self.split char
    [] << parts[0] << parts[1..].join(char)
  end

  def rsplit(char)
    parts = self.split char
    [] << parts[0..-2].join(char) << parts[-1]
  end
end

module SQLite
  def query_sql(file, query)
    Open3.popen3('sqlite3', '-init', '/dev/null', file) do |stdin, stdout|
      stdin.puts query
      stdin.close
      stdout.readlines
    end
  end
end

module Parser
  def whitespace?(line)
    /^$/.match line
  end

  def comment?(line)
    /^#/.match line
  end
end

class SearchItem
  TYPES = [:bookmark, :history, :search_engine]

  attr_reader :title, :url, :date, :type

  def initialize(title, url, date, type)
    unless TYPES.include? type
      raise ArguementError.new "title must be one of #{TYPES.join ' '}"
    end

    @title = title.strip
    @url = url.strip
    @date = date
    @type = type
  end

  def to_launcher_s
    case @type
    when :bookmark
      "B #{@title} <#{@url}>"
    when :history
      if @date
        "H #{@title} <#{@url}> (#{@date})"
      else
        "H #{@title} <#{@url}>"
      end
    when :search_engine
      "#{@title.strip}: "
    end
  end

  def self.parse_url(str)
    return unless str[0] == 'H' or str[0] == 'B'

    match = /<(.*)>/.match str

    if match and match.captures.length > 0
      match.captures[0].strip
    end
  end

  def self.parse_search_term(str)
    return if str[0] == 'H' or str[0] == 'B'

    parts = str.lsplit ':'

    if parts.length > 1
      parts[1].strip
    end
  end

  def self.parse_search_engine(str)
    return if str[0] == 'H' or str[0] == 'B'

    parts = str.lsplit ':'

    if parts.length > 1
      parts[0].strip
    end
  end
end

class Browser
  extend Parser
  extend SQLite

  def self.history
    []
  end

  def self.bookmarks
    []
  end

  def self.search_engines
    []
  end
end

class UserDefined < Browser
  def self.history
    hist_file = File.join ENV['XDG_CONFIG_HOME'], 'history'

    return [] unless File.exist? hist_file

    File.readlines(hist_file)
      .filter { |line| !whitespace? line and !comment? line}
      .map { |line| /([^<>]*)\s+<(.*)>/.match(line).captures }
      .map { |title, url| SearchItem.new title, url, nil, :history }
  end

  def self.bookmarks
    bm_file = File.join ENV['XDG_CONFIG_HOME'], 'bookmarks'

    return [] unless File.exist? bm_file

    File.readlines(bm_file)
      .filter { |line| !whitespace? line and !comment? line}
      .map { |line| /([^<>]*)\s+<(.*)>/.match(line).captures }
      .map { |title, url| SearchItem.new title, url, nil, :bookmark }
  end

  def self.search_engines
    se_file = File.join ENV['XDG_CONFIG_HOME'], 'search_engines'

    return [] unless File.exist? se_file 

    File.readlines(se_file)
      .filter { |line| !whitespace? line and !comment? line}
      .map { |line| line.lsplit '=' }
      .map { |title, url| SearchItem.new title, url, nil, :search_engine }
  end
end

class Luakit < Browser
  def self.history
    hist_file = File.join ENV['XDG_DATA_HOME'], 'luakit', 'history.db'

    return [] unless File.exist? hist_file 

    query = <<~SQL
      SELECT title, uri, last_visit
      FROM history
      ORDER BY last_visit DESC;
    SQL

    query_sql(hist_file, query)
      .filter { |line| !whitespace? line and !comment? line }
      .map { |line| line.split '|' }
      .map { |item| SearchItem.new(
        item[0..-3].join('|'),
        item[-2],
        Time.at(item[-1].to_i).to_s,
        :history,
      ) }
  end
end

LAUNCHER = ['dmenu', '-i', '-l', '10', '-p', 'Search:']
SCHEMES = ['http://', 'https://', 'file://']

def extract_url(str, search_engines)
  search_engine_prefix = SearchItem.parse_search_engine str
  search_term = SearchItem.parse_search_term str
  selected_url = SearchItem.parse_url str

  selected_se = search_engines.find { |se| se.title == search_engine_prefix }
  default_se = search_engines.find { |se| se.title == '*' }

  if str.start_with? 'localhost'
    "http://#{str}"
  elsif SCHEMES.any? { |scheme| str.start_with? scheme }
    str
  elsif selected_se
    selected_se.url.gsub('%s', URI.encode_uri_component(search_term))
  elsif selected_url
    selected_url
  else
    default_se.url.gsub('%s', URI.encode_uri_component(str))
  end
end

def main(opts)
  browser = opts[:browser] || ENV['BROWSER']

  bookmarks = Browser.subclasses.reduce([]) { |acc, b| acc + b.bookmarks }
  history = Browser.subclasses.reduce([]) { |acc, b| acc + b.history }
  search_engines = Browser.subclasses.reduce([]) { |acc, b| acc + b.search_engines}

  items = search_engines
  items += bookmarks unless opts[:"no-bookmarks"]
  items += history unless opts[:"no-history"]

  selection = Open3.popen3(*LAUNCHER) do |stdin, stdout|
    stdin.puts items.map { |item| item.to_launcher_s }
    stdin.close
    begin
      stdout.readline
    rescue EOFError
      exit 0
    end
  end

  url = extract_url(selection, search_engines)

  exec "#{browser} #{url}"
end

def info
  Browser.subclasses.each do |b|
    puts <<~TEXT
      #{b.name}
      ---------
      bookmarks: #{b.bookmarks.length}
      history items: #{b.history.length}

    TEXT
  end
end

if __FILE__ == $0
  opts = {}

  parser = OptionParser.new
  parser.banner = 'Usage: omnibar [OPTIONS]'
  parser.on '--no-bookmarks', 'Exclude bookmarks'
  parser.on '--no-history', 'Exclude history'
  parser.on '--info', 'Print info'
  parser.on '--browser=BROWSER', 'Browser path'
  parser.parse! into: opts

  if opts[:info]
    info
    exit 0
  end

  main opts
end
