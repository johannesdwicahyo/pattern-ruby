# pattern-ruby

A deterministic pattern detection and intent matching engine for Ruby. Built for chatbots and conversational AI where you need fast, predictable, rule-based matching — no API calls, no model inference, no latency.

**Why pattern-ruby?** LLMs are great but slow, expensive, and unpredictable. For the 80% of user inputs that follow predictable patterns ("track my order", "reset password", "what are your hours"), you don't need an LLM. Handle those deterministically in microseconds, and route the rest to your LLM.

## Installation

```ruby
# Gemfile
gem "pattern-ruby"
```

```bash
gem install pattern-ruby
```

## Quick Start

```ruby
require "pattern_ruby"

router = PatternRuby::Router.new do
  intent :greeting do
    pattern "hello"
    pattern "hi"
    pattern "good morning"
    response "Hello! How can I help you?"
  end

  intent :weather do
    pattern "weather in {city}"
    pattern "what's the weather in {city}"
    entity :city, type: :string
  end

  intent :order_status do
    pattern "track order {order_id:\\d+}"
    pattern "where is my order {order_id:\\d+}"
    pattern(/order\s*#?\s*(?<order_id>\d{5,})/i)
  end

  fallback { |input| puts "Route to LLM: #{input}" }
end

result = router.match("weather in Tokyo")
result.intent    # => :weather
result.entities  # => { city: "Tokyo" }
result.matched?  # => true
result.score     # => 0.9
```

## Pattern Syntax

| Syntax | Meaning | Example |
|---|---|---|
| `hello` | Literal match (case-insensitive) | matches "Hello", "HELLO" |
| `{name}` | Named entity capture | `{city}` captures any text |
| `{name:\\d+}` | Entity with regex constraint | `{id:\\d+}` captures digits only |
| `{name:a\|b\|c}` | Entity with enum constraint | `{time:today\|tomorrow}` |
| `[optional]` | Optional section | `book [a] flight` |
| `(a\|b\|c)` | Alternatives | `(fly\|travel\|go)` |
| `*` | Wildcard | `tell me *` matches anything |

### Combined Example

```ruby
# All of these match:
"book [a] flight from {origin} to {destination} [on {date}]"

# "book a flight from NYC to London on Friday"
# "book flight from Paris to Berlin"
# "book a flight from Tokyo to Seoul"
```

## Entity Types

Built-in: `:string`, `:number`, `:integer`, `:email`, `:phone`, `:url`, `:currency`

```ruby
router = PatternRuby::Router.new do
  # Custom entity types
  entity_type :zipcode, pattern: /\d{5}/, parser: ->(s) { s.to_i }

  intent :locate do
    pattern "stores near {zip}"
    entity :zip, type: :zipcode
  end

  # Default values
  intent :weather do
    pattern "weather in {city}"
    entity :city, type: :string
    entity :time, type: :string, default: "today"
  end
end
```

## Regex Patterns

For complex matching, use raw regex with named captures:

```ruby
intent :order_status do
  pattern(/order\s*#?\s*(?<order_id>\d{5,})/i)
end

result = router.match("Where is order #12345?")
result.entities[:order_id]  # => "12345"
```

## Context-Aware Matching

Route the same input differently based on conversation state:

```ruby
router = PatternRuby::Router.new do
  intent :confirm do
    pattern "yes"
    context :awaiting_confirmation  # only matches in this context
  end

  intent :affirmative_greeting do
    pattern "yes"  # matches when no context
  end
end

router.match("yes")                                    # => :affirmative_greeting
router.match("yes", context: :awaiting_confirmation)   # => :confirm
```

## Multi-Intent Matching

Get all matching intents ranked by score:

```ruby
results = router.match_all("book a flight to Paris")
results.each { |r| puts "#{r.intent}: #{r.score}" }
# book_flight: 0.92
# book_generic: 0.65
```

## Conversation State & Slot Filling

Track conversation context and fill missing entities across turns:

```ruby
convo = PatternRuby::Conversation.new(router)

result = convo.process("book a flight from NYC to London")
# => entities: { origin: "NYC", destination: "London" }

result = convo.process("Friday")
# => fills missing slot: { origin: "NYC", destination: "London", date: "Friday" }

convo.reset  # clear all state
```

## Pipeline

Chain preprocessing steps before matching:

```ruby
pipeline = PatternRuby::Pipeline.new do
  step(:normalize) { |input| input.strip.downcase.gsub(/[?!.]/, "") }
  step(:correct)   { |input| input.gsub(/wether/, "weather") }
  step(:match)     { |input| router.match(input) }
end

result = pipeline.process("Wether in Tokyo?")
# normalize → "wether in tokyo"
# correct   → "weather in tokyo"
# match     → intent: :weather, entities: { city: "tokyo" }
```

## Real-World Example: Support Bot

```ruby
router = PatternRuby::Router.new do
  intent :order_status do
    pattern "where is my order {order_id:\\d+}"
    pattern "track order {order_id:\\d+}"
    pattern(/order\s*#?\s*(?<order_id>\d{5,})/i)
  end

  intent :refund do
    pattern "i want [a] refund"
    pattern "refund [my] order {order_id:\\d+}"
  end

  intent :reset_password do
    pattern "reset [my] password"
    pattern "forgot [my] password"
    pattern "can't log in"
  end

  intent :cancel do
    pattern "cancel [my] (account|subscription|plan)"
    pattern "i want to cancel"
  end

  intent :contact do
    pattern "talk to [a] (human|person|agent)"
    pattern "i need [to talk to] a human"
  end

  intent :complaint do
    pattern "this is (terrible|awful|horrible)"
    pattern "i'm (unhappy|frustrated|angry)"
    pattern "i want to (complain|file a complaint)"
  end

  fallback { |input| route_to_llm(input) }
end

# In your controller/handler:
result = router.match(user_input)
case result.intent
when :order_status then lookup_order(result.entities[:order_id])
when :refund       then initiate_refund(result.entities[:order_id])
when :complaint    then escalate_to_human(user_input)
when nil           then ask_llm(user_input)  # fallback
end
```

Try the interactive demo: `ruby -Ilib examples/support_bot.rb`

## Test Helpers

```ruby
require "pattern_ruby/rails/test_helpers"

class ChatbotTest < Minitest::Test
  include PatternRuby::TestHelpers

  def test_greeting
    assert_matches_intent :greeting, "hello", router: @router
  end

  def test_entity_extraction
    assert_extracts_entity :city, "Tokyo", "weather in Tokyo", router: @router
  end

  def test_unknown_input
    refute_matches "quantum physics", router: @router
  end
end
```

## License

MIT
