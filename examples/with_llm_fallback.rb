require "pattern_ruby"

# This example shows how to use pattern-ruby as a first-pass filter
# before routing to an LLM for complex queries.

router = PatternRuby::Router.new do
  intent :greeting do
    pattern "hello"
    pattern "hi"
    pattern "hey"
    response "Hello! How can I help you?"
  end

  intent :hours do
    pattern "what are your hours"
    pattern "when are you open"
    pattern "business hours"
    response "We're open Monday-Friday, 9am-5pm EST."
  end

  intent :pricing do
    pattern "how much does {product} cost"
    pattern "price of {product}"
    pattern "pricing"
    entity :product, type: :string
  end

  fallback { |_| }
end

pipeline = PatternRuby::Pipeline.new do
  step(:normalize) { |input| input.strip }

  step(:match) do |input|
    result = router.match(input)

    if result.matched?
      # Deterministic response — no LLM needed
      puts "  [Pattern Match] Intent: #{result.intent}"
      if result.response
        puts "  Response: #{result.response}"
      else
        puts "  Entities: #{result.entities}"
        puts "  [Would look up #{result.entities} in database]"
      end
    else
      # Route to LLM
      puts "  [LLM Fallback] Sending to LLM: #{input}"
      puts "  [LLM would generate a contextual response here]"
    end

    result
  end
end

puts "=== Hybrid Pattern + LLM Demo ==="
puts

inputs = [
  "hello",
  "what are your hours",
  "how much does the Pro plan cost",
  "Can you explain the difference between your plans?",
  "What's your refund policy for annual subscriptions?",
]

inputs.each do |input|
  puts "User: #{input}"
  pipeline.process(input)
  puts
end
