module PatternRuby
  class Pipeline
    def initialize(&block)
      @steps = []
      @error_handler = nil
      instance_eval(&block) if block
    end

    def step(name, &block)
      @steps << { name: name, handler: block }
    end

    def on_error(&block)
      @error_handler = block
    end

    def process(input)
      result = input
      @steps.each do |s|
        result = s[:handler].call(result)
      rescue => e
        if @error_handler
          result = @error_handler.call(e, s[:name], result)
          break if result.nil?
        else
          raise
        end
      end
      result
    end

    def steps
      @steps.map { |s| s[:name] }
    end
  end
end
