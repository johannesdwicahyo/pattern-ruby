module PatternRuby
  class Conversation
    attr_reader :context, :history, :slots

    def initialize(router)
      @router = router
      @context = nil
      @history = []
      @slots = {}
      @mutex = Mutex.new
    end

    def process(input)
      @mutex.synchronize do
        result = @router.match(input, context: @context)

        if result.matched?
          # Merge new entities into accumulated slots
          result.entities.each do |k, v|
            @slots[k] = v unless v.nil?
          end

          # Build enriched result with accumulated slots
          result = MatchResult.new(
            intent: result.intent,
            entities: @slots.dup,
            pattern: result.pattern,
            score: result.score,
            input: result.input,
            response: result.response
          )
        elsif !@history.empty? && @slots.any?
          # Try to fill a missing slot from context
          last = @history.last
          if last&.matched?
            filled = try_slot_fill(input, last.intent)
            if filled
              result = MatchResult.new(
                intent: last.intent,
                entities: @slots.dup,
                pattern: last.pattern,
                score: last.score,
                input: input,
                response: last.response
              )
            end
          end
        end

        @history << result
        result
      end
    end

    def set_context(ctx)
      @mutex.synchronize { @context = ctx }
    end

    def clear_context
      @mutex.synchronize { @context = nil }
    end

    def reset
      @mutex.synchronize do
        @context = nil
        @history = []
        @slots = {}
      end
    end

    private

    def try_slot_fill(input, intent_name)
      intent = @router.intents.find { |i| i.name == intent_name }
      return false unless intent

      # Find entity definitions that don't have a slot value yet
      unfilled = intent.entity_definitions.select { |name, _| !@slots.key?(name) || @slots[name].nil? }
      return false if unfilled.empty?

      # Try the input as a value for the first unfilled slot
      name, _defn = unfilled.first
      @slots[name] = input.strip
      true
    end
  end
end
