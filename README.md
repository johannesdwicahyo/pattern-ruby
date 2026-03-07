# pattern-ruby

A deterministic pattern detection and intent matching engine for Ruby. Built for chatbots and conversational AI where you need fast, predictable, rule-based matching — no API calls, no model inference, no latency.

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

  fallback { |input| puts "Unknown: #{input}" }
end

result = router.match("weather in Tokyo")
result.intent    # => :weather
result.entities  # => { city: "Tokyo" }
result.matched?  # => true
```

## Pattern Syntax

```
hello                        Literal match (case-insensitive)
{name}                       Named entity capture
{name:\d+}                   Entity with regex constraint
{name:opt1|opt2|opt3}        Entity with enum constraint
[optional words]             Optional section
(alt1|alt2|alt3)             Alternatives
*                            Wildcard (any text)
```

### Examples

```ruby
# Optional words
"book [a] flight"              # matches "book a flight" and "book flight"

# Entity with constraint
"order {id:\d+}"               # captures only digits

# Alternatives
"i want to (fly|travel|go)"    # matches any of the three verbs

# Combined
"book [a] flight from {origin} to {destination} [on {date}]"
```

## Entity Types

Built-in types: `:string`, `:number`, `:integer`, `:email`, `:phone`, `:url`, `:currency`

```ruby
# Register custom entity types
router = PatternRuby::Router.new do
  entity_type :zipcode, pattern: /\d{5}/, parser: ->(s) { s.to_i }

  intent :locate do
    pattern "find stores near {zip}"
    entity :zip, type: :zipcode
  end
end
```

Entities support defaults:

```ruby
intent :weather do
  pattern "weather in {city}"
  entity :city, type: :string
  entity :time, type: :string, default: "today"
end
```

## Regex Patterns

Use raw regex for complex matching:

```ruby
intent :order_status do
  pattern(/order\s*#?\s*(?<order_id>\d{5,})/i)
end

result = router.match("Where is order #12345?")
result.entities[:order_id]  # => "12345"
```

## Multi-Intent Matching

```ruby
results = router.match_all("book a flight to Paris")
results.each do |r|
  puts "#{r.intent}: #{r.score}"
end
```

## Context-Aware Matching

```ruby
router = PatternRuby::Router.new do
  intent :confirm do
    pattern "yes"
    context :awaiting_confirmation
  end

  intent :greeting do
    pattern "yes"  # only matches without context
  end
end

router.match("yes")                                    # => :greeting
router.match("yes", context: :awaiting_confirmation)   # => :confirm
```

## Conversation State

```ruby
convo = PatternRuby::Conversation.new(router)

result = convo.process("book a flight from NYC to London")
# => { origin: "NYC", destination: "London" }

result = convo.process("tomorrow")
# => fills missing date slot: { origin: "NYC", destination: "London", date: "tomorrow" }

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
# => intent: :weather, entities: { city: "tokyo" }
```

## Test Helpers

```ruby
require "pattern_ruby/rails/test_helpers"

class MyTest < Minitest::Test
  include PatternRuby::TestHelpers

  def test_greeting
    assert_matches_intent :greeting, "hello", router: @router
  end

  def test_entity
    assert_extracts_entity :city, "Tokyo", "weather in Tokyo", router: @router
  end

  def test_no_match
    refute_matches "quantum physics", router: @router
  end
end
```

## License

MIT
