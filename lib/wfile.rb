require 'set'

class WFile
  @@max_id = 0

  attr_reader :parts, :codes, :id

  def initialize parts, codes
    @parts, @codes = Set.new(parts), codes
    @id = (@@max_id += 1)
  end
end
