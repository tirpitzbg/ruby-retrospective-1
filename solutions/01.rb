class Array

  def to_hash
    res = {}
    self.each do |v|
      res[v[0]] = v[1]
    end
  res
  end
  
  def subarray_count(sub)
    res = 0
    (0..(self.length - sub.length)).each do |v|
      res += (sub == self[v, sub.length]) ? 1 : 0
    end
    res
  end
  
  def index_by
    res = {}
    self.each do |v|
     res[yield v] = v
    end
    res
  end
	
  def occurences_count
    res = Hash.new(0)
    self.each do |v|
      res[v] = self.count(v)
    end
    res
  end
  
end