# Cleaner cleans user input. It acts as a validation.
class Cleaner
  attr_reader :value

  def initialize(value)
    @value = value.delete(' ').gsub(/[^[a-zA-Z]]/, 'x').downcase.capitalize
  end
end
