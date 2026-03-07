module PatternRuby
  class Pipeline
    def initialize(&block)
      @steps = []
      instance_eval(&block) if block
    end

    def step(name, &block)
      @steps << { name: name, handler: block }
    end

    def process(input)
      result = input
      @steps.each do |s|
        result = s[:handler].call(result)
      end
      result
    end

    def steps
      @steps.map { |s| s[:name] }
    end
  end
end
