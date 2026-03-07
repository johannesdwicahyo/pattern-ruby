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

    class Registry
      def initialize
        @types = BUILT_IN.dup
      end

      def register(name, pattern: nil, parser: nil)
        @types[name.to_sym] = { pattern: pattern, parser: parser }
      end

      def get(name)
        @types[name.to_sym]
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
