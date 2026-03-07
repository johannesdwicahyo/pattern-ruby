module PatternRuby
  class Entity
    attr_reader :name, :type, :value, :raw, :span

    def initialize(name:, type: :string, value: nil, raw: nil, span: nil)
      @name = name.to_sym
      @type = type.to_sym
      @value = value
      @raw = raw
      @span = span
    end

    def to_h
      { name: @name, type: @type, value: @value, raw: @raw }
    end
  end
end
