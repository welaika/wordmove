class Hash
  def recursive_symbolize_keys!
    symbolize_keys!
    values.select do |v|
      v.is_a? Hash
    end.each do |h|
      h.recursive_symbolize_keys!
    end
  end
end

