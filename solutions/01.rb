class Array

  def to_hash
    result = {}
    self.each do |element|
      result[element[0]] = element[1]
    end
  result
  end
  
  def subarray_count(sub)
    result = 0
    (0..(self.length - sub.length)).each do |element|
      result += (sub == self[element, sub.length]) ? 1 : 0
    end
    result
  end
	
  def index_by
    result = {}
    each do |element|
     result[yield element] = element
    end
    result
  end
	
  def occurences_count
    result = Hash.new(0)
    each do |element|
      result[element] = count(element)
    end
    result
  end
  
end