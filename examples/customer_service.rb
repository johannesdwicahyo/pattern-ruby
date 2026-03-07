require "pattern_ruby"

router = PatternRuby::Router.new do
  intent :order_status do
    pattern "where is my order {order_id:\\d+}"
    pattern "track order {order_id:\\d+}"
    pattern(/order\s*#?\s*(?<order_id>\d{5,})/i)
    entity :order_id, type: :string
  end

  intent :refund do
    pattern "i want a refund"
    pattern "refund my order {order_id:\\d+}"
    pattern "can i get a refund"
    entity :order_id, type: :string
  end

  intent :book_flight do
    pattern "book [a] flight from {origin} to {destination} [on {date}]"
    pattern "fly from {origin} to {destination}"
    pattern "i want to (fly|travel|go) from {origin} to {destination}"
    entity :origin, type: :string
    entity :destination, type: :string
    entity :date, type: :string
  end

  fallback { |_| }
end

# Demonstrate conversation with slot filling
puts "=== Customer Service Conversation ==="
puts

convo = PatternRuby::Conversation.new(router)

messages = [
  "book a flight from NYC to London",
  "Friday",
  "where is my order #55678",
  "i want a refund"
]

messages.each do |msg|
  result = convo.process(msg)
  puts "Customer: #{msg}"
  if result.matched?
    puts "  Intent: #{result.intent}"
    puts "  Entities: #{result.entities}" unless result.entities.empty?
  else
    puts "  [Route to agent]"
  end
  puts
end
