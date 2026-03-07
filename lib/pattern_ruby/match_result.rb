module PatternRuby
  class MatchResult
    attr_reader :intent, :entities, :pattern, :score, :input, :metadata, :response

    def initialize(intent: nil, entities: {}, pattern: nil, score: 0.0,
                   input: nil, metadata: {}, response: nil, fallback: false)
      @intent = intent
      @entities = entities
      @pattern = pattern
      @score = score
      @input = input
      @metadata = metadata
      @response = response
      @fallback = fallback
    end

    def matched?
      @intent != nil && !fallback?
    end

    def fallback?
      @fallback
    end

    def to_h
      { intent: @intent, entities: @entities, score: @score, pattern: @pattern }
    end
  end
end
