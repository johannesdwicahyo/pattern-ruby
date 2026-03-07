module PatternRuby
  class CompiledPattern
    attr_reader :source, :regex, :entity_names, :literal_count, :token_count, :entity_count

    def initialize(source:, regex:, entity_names:, literal_count:, token_count:, entity_count:)
      @source = source
      @regex = regex
      @entity_names = entity_names
      @literal_count = literal_count
      @token_count = token_count
      @entity_count = entity_count
    end

    def match(input)
      @regex.match(input)
    end
  end

  class PatternCompiler
    def initialize(entity_registry: nil)
      @entity_registry = entity_registry
    end

    def compile(pattern_string)
      tokens = tokenize(pattern_string)
      entity_names = []
      literal_count = 0
      regex_parts = []

      tokens.each do |token|
        case token
        when EntityToken
          entity_names << token.name.to_sym
          regex_parts << build_entity_regex(token)
        when OptionalToken
          inner = compile_inner(token.content)
          entity_names.concat(inner[:entity_names])
          regex_parts << "(?:\\s+#{inner[:regex]})?"
        when AlternationToken
          alts = token.alternatives.map { |a| Regexp.escape(a) }
          regex_parts << "(?:#{alts.join('|')})"
          literal_count += 1
        when WildcardToken
          regex_parts << "(.+)"
        when LiteralToken
          regex_parts << Regexp.escape(token.text)
          literal_count += 1
        end
      end

      token_count = tokens.size
      entity_count = entity_names.size

      # Join with \s+ but make whitespace before optional groups flexible
      regex_str = +""
      regex_parts.each_with_index do |part, i|
        if i > 0 && !part.start_with?("(?:\\s+") # optional groups already include leading \s+
          regex_str << "\\s+"
        end
        regex_str << part
      end

      regex = Regexp.new("\\A\\s*#{regex_str}\\s*\\z", Regexp::IGNORECASE)

      CompiledPattern.new(
        source: pattern_string,
        regex: regex,
        entity_names: entity_names,
        literal_count: literal_count,
        token_count: token_count,
        entity_count: entity_count
      )
    end

    private

    EntityToken = Struct.new(:name, :constraint)
    OptionalToken = Struct.new(:content)
    AlternationToken = Struct.new(:alternatives)
    WildcardToken = Class.new
    LiteralToken = Struct.new(:text)

    def tokenize(pattern_string)
      tokens = []
      scanner = StringScanner.new(pattern_string.strip)

      until scanner.eos?
        scanner.skip(/\s+/)
        break if scanner.eos?

        if scanner.scan(/\{([^}]+)\}/)
          # Entity: {name} or {name:constraint}
          content = scanner[1]
          name, constraint = content.split(":", 2)
          tokens << EntityToken.new(name.strip, constraint&.strip)
        elsif scanner.scan(/\[/)
          # Optional: [content]
          depth = 1
          content = +""
          until depth == 0 || scanner.eos?
            if scanner.scan(/\[/)
              depth += 1
              content << "["
            elsif scanner.scan(/\]/)
              depth -= 1
              content << "]" if depth > 0
            else
              content << scanner.getch
            end
          end
          tokens << OptionalToken.new(content.strip)
        elsif scanner.scan(/\(([^)]+)\)/)
          # Alternation: (a|b|c)
          alts = scanner[1].split("|").map(&:strip)
          tokens << AlternationToken.new(alts)
        elsif scanner.scan(/\*/)
          tokens << WildcardToken.new
        else
          # Literal word(s) — scan until next special token or whitespace
          word = scanner.scan(/[^\s\[\]{}()*]+/)
          tokens << LiteralToken.new(word) if word
        end
      end

      tokens
    end

    def build_entity_regex(token)
      if token.constraint
        if token.constraint.include?("|")
          # Enum constraint: {time:today|tomorrow|this week}
          alts = token.constraint.split("|").map { |a| Regexp.escape(a.strip) }
          "(?<#{token.name}>#{alts.join('|')})"
        else
          # Regex constraint: {order_id:\\d+}
          "(?<#{token.name}>#{token.constraint})"
        end
      else
        # Check entity registry for type-specific pattern
        type_pattern = @entity_registry&.pattern_for(token.name)
        if type_pattern
          "(?<#{token.name}>#{type_pattern.source})"
        else
          # Default: capture any non-greedy text
          "(?<#{token.name}>.+?)"
        end
      end
    end

    def compile_inner(content)
      inner_tokens = tokenize(content)
      entity_names = []
      parts = []

      inner_tokens.each do |token|
        case token
        when EntityToken
          entity_names << token.name.to_sym
          parts << build_entity_regex(token)
        when LiteralToken
          parts << Regexp.escape(token.text)
        when AlternationToken
          alts = token.alternatives.map { |a| Regexp.escape(a) }
          parts << "(?:#{alts.join('|')})"
        end
      end

      { regex: parts.join("\\s+"), entity_names: entity_names }
    end
  end
end
