module PatternRuby
  module EntityTypes
    BUILT_IN = {
      string: { pattern: nil, parser: nil },
      number: { pattern: /\d+(?:\.\d+)?/, parser: ->(s) { s.include?(".") ? s.to_f : s.to_i } },
      integer: { pattern: /\d+/, parser: ->(s) { s.to_i } },
      email: { pattern: /[\w.+\-]+@[\w\-]+\.[\w.]+/, parser: nil },
      phone: { pattern: /\+?\d[\d\s\-()]{7,}/, parser: nil },
      url: { pattern: %r{https?://\S+}, parser: nil },
      currency: { pattern: /\$[\d,]+(?:\.\d{2})?/, parser: ->(s) { s.delete(",").delete("$").to_f } },
    }.freeze

    # Standard NER entity types recognized in pattern constraints like {entity:PERSON}
    STANDARD_NER_TYPES = %w[
      PERSON PER
      LOCATION LOC
      ORGANIZATION ORG
      DATE TIME
      MONEY PERCENT
      MISC
    ].freeze

    # Validates an entity type string used in pattern constraints (e.g., "PERSON" from {name:PERSON}).
    # Returns true if the type is a standard NER type, a built-in type, or matches the custom type
    # format (UPPER_SNAKE_CASE).
    def self.valid_entity_type?(type_str)
      return false if type_str.nil? || type_str.strip.empty?

      normalized = type_str.strip
      return true if STANDARD_NER_TYPES.include?(normalized)
      return true if BUILT_IN.key?(normalized.downcase.to_sym)

      # Allow custom types that follow UPPER_SNAKE_CASE or CamelCase convention
      !!(normalized.match?(/\A[A-Z][A-Z0-9_]*\z/) || normalized.match?(/\A[A-Z][a-zA-Z0-9]*\z/))
    end

    class Registry
      def initialize
        @types = BUILT_IN.dup
        @mutex = Mutex.new
      end

      def register(name, pattern: nil, parser: nil)
        @mutex.synchronize do
          @types[name.to_sym] = { pattern: pattern, parser: parser }
        end
      end

      def get(name)
        @mutex.synchronize { @types[name.to_sym] }
      end

      def pattern_for(name)
        type = get(name)
        type && type[:pattern]
      end

      def parse(name, raw_value)
        type = get(name)
        return raw_value unless type && type[:parser]
        type[:parser].call(raw_value)
      end
    end
  end
end
