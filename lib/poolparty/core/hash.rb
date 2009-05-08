=begin rdoc
  Hash extentions
=end
class Hash
  
  alias_method :_reader, :[]
  # Treat string and symbols the same
  def [](key)
    return _reader(key) if _reader(key)
    if key.is_a? Symbol
      _reader(key.to_s)
    elsif key.is_a? String
      _reader(key.to_sym) rescue _reader(key)
    else
      _reader(key)
    end
  end
  
  def choose(&block)
    Hash[*self.select(&block).inject([]){|res,(k,v)| res << k << v}]
  end

  def to_instance_variables(inst=nil)
    each do |k,v|
      inst.instance_variable_set "@#{k}", v
      inst.class.send :attr_reader, k if inst
    end
  end
  
  # extracted from activesupport
  # Returns an array of the values at the specified indices:
  #
  #   hash = HashWithIndifferentAccess.new
  #   hash[:a] = "x"
  #   hash[:b] = "y"
  #   hash.values_at("a", "b") # => ["x", "y"]
  def values_at(*indices)
    indices.collect {|key| self[key]}
  end
  
  #TODO: deprecate
  # def extract!(&block)
  #   o = Hash[*select(&block).flatten]
  #   o.keys.each {|k| self.delete(k) }
  #   o
  # end
  
  def append(other_hash)
    returning Hash.new do |h|
      h.merge!(self)
      other_hash.each do |k,v|
        h[k] = has_key?(k) ? [self[k], v].flatten.uniq : v
      end
    end
  end
  
  def append!(other_hash)
    other_hash.each do |k,v|
      self[k] = has_key?(k) ? [self[k], v].flatten.uniq : v
    end
    self
  end
  
  def safe_merge(other_hash)
    merge(other_hash.delete_if {|k,v| has_key?(k) })
  end
  
  def safe_merge!(other_hash)
    merge!(other_hash.delete_if {|k,v| has_key?(k) && !v.nil? })
  end
  
  def to_os
    m={}
    each {|k,v| m[k] = v.to_os }
    MyOpenStruct.new(m)
  end
  
  def next_sorted_key(from)
    idx = (size - keys.sort.index(from))
    keys.sort[idx - 1]
  end
  
  def method_missing(sym, *args, &block)
    if has_key?(sym)
      fetch(sym)
    elsif has_key?(sym.to_s)
      fetch(sym.to_s)
    else
      super
    end
  end
end