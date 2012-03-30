class HashObj
  def initialize hash
    @hash
  end

  def method_missing name, *args, &block
    name = name.to_s
    if name =~ /(.*)=$/
      name = $1
      hash[name] = args[0]
    else
      hash[name]
    end
  end

  def to_hash
    @hash
  end
end

class Hash
  def to_obj
    HashObj.new self
  end
end
