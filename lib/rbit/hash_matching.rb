class Hash
  def ===(other)
    return false unless other.is_a? Hash
    self.each do |k, v|
      return false unless v === other[k]
    end
    true
  end
end
