module PatternRuby
  class Router
    attr_reader :intents

    # Maximum input length for matching (100 KB). Inputs beyond this are truncated.
    MAX_INPUT_LENGTH = 100_000

    def initialize(&block)
      @intents = []
      @intent_names = {}
      @fallback_handler = nil
      @entity_registry = EntityTypes::Registry.new
      @compiler = PatternCompiler.new(entity_registry: @entity_registry)
      @mutex = Mutex.new
      instance_eval(&block) if block
    end

    def intent(name, &block)
      name_sym = name.to_sym
      if @intent_names.key?(name_sym)
        # Duplicate registration: return existing intent (idempotent)
        return @intent_names[name_sym]
      end

      i = Intent.new(name, compiler: @compiler)
      i.instance_eval(&block) if block
      @mutex.synchronize do
        @intents << i
        @intent_names[name_sym] = i
      end
      i
    end

    def fallback(&block)
      @fallback_handler = block
    end

    def entity_type(name, **options)
      @entity_registry.register(name, **options)
    end

    def match(input, context: nil)
      input = sanitize_input(input)
      return fallback_result(input) if input.empty?

      candidates = []

      @mutex.synchronize { @intents.dup }.each do |i|
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
      input = sanitize_input(input)
      return [] if input.empty?

      candidates = []

      @mutex.synchronize { @intents.dup }.each do |i|
        if i.context_requirement
          next unless context == i.context_requirement
        end

        result = i.match(input, entity_registry: @entity_registry)
        candidates << result if result
      end

      candidates.sort_by { |r| -r.score }
    end

    private

    def sanitize_input(input)
      text = input.to_s.strip
      text = text[0, MAX_INPUT_LENGTH] if text.length > MAX_INPUT_LENGTH
      text
    end

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
