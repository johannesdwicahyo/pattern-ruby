module PatternRuby
  class Intent
    attr_reader :name, :compiled_patterns, :entity_definitions, :response_text, :context_requirement

    def initialize(name, compiler:)
      @name = name.to_sym
      @compiler = compiler
      @compiled_patterns = []
      @entity_definitions = {}
      @response_text = nil
      @context_requirement = nil
    end

    def pattern(pat)
      if pat.is_a?(Regexp)
        @compiled_patterns << RegexPattern.new(pat)
      elsif pat.is_a?(String)
        raise ArgumentError, "pattern cannot be empty" if pat.strip.empty?
        @compiled_patterns << @compiler.compile(pat)
      else
        raise ArgumentError, "pattern must be a String or Regexp, got #{pat.class}"
      end
    end

    def entity(name, type: :string, **options)
      @entity_definitions[name.to_sym] = { type: type, **options }
    end

    def response(text)
      @response_text = text
    end

    def context(ctx)
      @context_requirement = ctx
    end

    def match(input, entity_registry: nil)
      @compiled_patterns.each do |cp|
        md = cp.match(input)
        next unless md

        entities = extract_entities(md, cp, entity_registry)
        score = compute_score(cp, md, input)

        return MatchResult.new(
          intent: @name,
          entities: entities,
          pattern: cp.source,
          score: score,
          input: input,
          response: @response_text
        )
      end
      nil
    end

    private

    def extract_entities(match_data, compiled_pattern, entity_registry)
      entities = {}

      if compiled_pattern.is_a?(RegexPattern)
        match_data.named_captures.each do |name, value|
          entities[name.to_sym] = parse_entity(name.to_sym, value, entity_registry)
        end
        # Also capture numbered groups if no named captures
        if entities.empty? && match_data.captures.any?
          match_data.captures.each_with_index do |cap, i|
            entities[:"capture_#{i}"] = cap
          end
        end
      else
        compiled_pattern.entity_names.each do |ename|
          raw = match_data[ename]
          next unless raw
          entities[ename] = parse_entity(ename, raw, entity_registry)
        end
      end

      # Apply defaults from entity definitions
      @entity_definitions.each do |ename, defn|
        next if entities.key?(ename)
        entities[ename] = defn[:default] if defn.key?(:default)
      end

      entities
    end

    def parse_entity(name, raw_value, entity_registry)
      defn = @entity_definitions[name]
      if defn && entity_registry
        parsed = entity_registry.parse(defn[:type], raw_value)
        return parsed if parsed
      end
      raw_value
    end

    def compute_score(compiled_pattern, match_data, input)
      if compiled_pattern.is_a?(RegexPattern)
        matched_length = match_data[0].length.to_f
        return (matched_length / input.length).clamp(0.0, 1.0)
      end

      score = 0.0

      # Literal ratio: more literal tokens = more specific
      if compiled_pattern.token_count > 0
        literal_ratio = compiled_pattern.literal_count.to_f / compiled_pattern.token_count
        score += literal_ratio * 0.5
      end

      # Entity fill ratio
      if compiled_pattern.entity_count > 0
        filled = compiled_pattern.entity_names.count { |n| match_data[n] && !match_data[n].empty? }
        entity_ratio = filled.to_f / compiled_pattern.entity_count
        score += entity_ratio * 0.3
      else
        score += 0.3
      end

      # Coverage: how much of the input was consumed
      matched_length = match_data[0].strip.length.to_f
      coverage = input.strip.empty? ? 0.0 : matched_length / input.strip.length
      score += coverage * 0.2

      score.clamp(0.0, 1.0)
    end
  end

  # Wraps a raw Regexp as a pattern
  class RegexPattern
    attr_reader :source, :regex, :entity_names, :literal_count, :token_count, :entity_count

    def initialize(regex)
      @source = regex.source
      @regex = regex
      @entity_names = regex.named_captures.keys.map(&:to_sym)
      @literal_count = 0
      @token_count = 1
      @entity_count = @entity_names.size
    end

    def match(input)
      @regex.match(input)
    end
  end
end
