require "pattern_ruby"

router = PatternRuby::Router.new do
  intent :greeting do
    pattern "hello"
    pattern "hi"
    pattern "hey"
    pattern "good morning"
    response "Hello! How can I help you today?"
  end

  intent :farewell do
    pattern "goodbye"
    pattern "bye"
    pattern "see you"
    response "Goodbye! Have a great day!"
  end

  intent :weather do
    pattern "weather in {city}"
    pattern "what's the weather in {city}"
    pattern "how's the weather in {city} {time:today|tomorrow|this week}"
    entity :city, type: :string
    entity :time, type: :string, default: "today"
  end

  intent :help do
    pattern "help"
    pattern "what can you do"
    response "I can help with weather, orders, and general questions."
  end

  fallback do |input|
    puts "  [Fallback] Would route to LLM: #{input}"
  end
end

puts "=== Chatbot Demo ==="
puts

inputs = [
  "Hello",
  "What's the weather in Tokyo",
  "how's the weather in London tomorrow",
  "help",
  "Tell me a joke",
  "bye"
]

inputs.each do |input|
  result = router.match(input)
  print "User: #{input}\n"

  if result.matched?
    print "  Intent: #{result.intent}"
    print " | Entities: #{result.entities}" unless result.entities.empty?
    print " | Score: #{result.score.round(2)}"
    print "\n  Response: #{result.response}" if result.response
    puts
  else
    puts "  [No match]"
  end
  puts
end
