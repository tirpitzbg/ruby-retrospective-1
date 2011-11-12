class Song

  attr_accessor :name, :artist, :genre, :subgenre, :tags
  def initialize(_name, _artist, _genre, _subgenre, _tags)
    @name = _name
    @artist = _artist
    @genre = _genre
    @subgenre = _subgenre
    @tags = _tags
  end
  
  def add_tags(tag_list)
    @tags += tag_list
  end
	
  def satisfies_tags(tag_list)
    has_them = true
    y = lambda {|s| @tags.index(s) != nil}
    n = lambda {|s| @tags.index(s) == nil}
    p = lambda {|e| e[-1] == '!' ? n.call(e[0, e.length - 1]) : y.call(e)}
    tag_list.each do |tag|
      has_them = has_them && p.call(tag)
    end
  has_them
  end
	
  def satisfy_single(field, value)
    if field == :tags and value.kind_of? String
      value = value.split(',').map {|x| x.lstrip}
    end
    case field
      when :name then (@name == value)
      when :artist then (@artist == value)
      when :filter then value.call(self)
      when :tags then satisfies_tags(value)
    end
  end

  def satisfy_all(criteria)
    isgood = true
    criteria.each do |k, v| 
      isgood = isgood && satisfy_single(k, v)
    end
    isgood
  end
end

class Collection
	
  def add_entry(es, name, artist, genre, sub, tags)
    if es[3] != nil
      tags = tags + es[3].lstrip.split(',')
    end
      tags.map {|v| v.lstrip!}
      @entries << Song.new(name, artist, genre, sub, tags + [genre.downcase])
    end
    def parse_entry(entry)
      es = entry.split('.').map {|v| v.gsub("\n", "")}
      name, artist = es[0].lstrip, es[1].lstrip
      genre = (es[2].split(',')[0]).lstrip
      sub = (es[2].split(',')[1] == nil) ? nil : (es[2].split(',')[1]).lstrip
      tags = (sub == nil ? [] : [sub.downcase])
      add_entry(es, name, artist, genre, sub, tags)
    end
    def add_tags(entry, adds)
      if adds[entry.artist] != nil
        entry.add_tags(adds[entry.artist])
      end
    end
    def initialize(data, adds)
      @entries = []
      data.each_line do |entry|
        parse_entry(entry)
      end
      @entries.each do |entry|
      add_tags(entry, adds)
    end
  end
  def get_songs
    @entries
  end
	
    def find(criteria)
      res = []
      @entries.each do |song|
      if song.satisfy_all(criteria)
        res << song
      end
    end
  res
  end
end
