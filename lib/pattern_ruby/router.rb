module PatternRuby
  class Router
    attr_reader :intents

    def initialize(&block)
      @intents = []
      @fallback_handler = nil
      @entity_registry = EntityTypes::Registry.new
      @compiler = PatternCompiler.new(entity_registry: @entity_registry)
      instance_eval(&block) if block
    end

    def intent(name, &block)
      i = Intent.new(name, compiler: @compiler)
      i.instance_eval(&block) if block
      @intents << i
      i
    end

    def fallback(&block)
      @fallback_handler = block
    end

    def entity_type(name, **options)
      @entity_registry.register(name, **options)
    end

    def match(input, context: nil)
      input = input.to_s.strip
      return fallback_result(input) if input.empty?

      candidates = []

      @intents.each do |i|
        # Skip intents that require a specific context
        if i.context_requirement
          next unless context == i.context_requirement
        end

        result = i.match(input, entity_registry: @entity_registry)
        candidates << result if result
      end

      return candidates.max_by(&:score) unless candidates.empty?

      fallback_result(input)
    end

    def match_all(input, context: nil)
      input = input.to_s.strip
      return [] if input.empty?

      candidates = []

      @intents.each do |i|
        if i.context_requirement
          next unless context == i.context_requirement
        end

        result = i.match(input, entity_registry: @entity_registry)
        candidates << result if result
      end

      candidates.sort_by { |r| -r.score }
    end

    private

    def fallback_result(input)
      @fallback_handler&.call(input)

      MatchResult.new(
        intent: nil,
        input: input,
        fallback: true
      )
    end
  end
end
