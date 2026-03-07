require_relative "test_helper"

class TestRouter < Minitest::Test
  def test_simple_match
    router = PatternRuby::Router.new do
      intent(:greeting) { pattern "hello" }
    end

    result = router.match("hello")
    assert result.matched?
    assert_equal :greeting, result.intent
  end

  def test_multiple_patterns_per_intent
    router = PatternRuby::Router.new do
      intent :greeting do
        pattern "hello"
        pattern "hi"
        pattern "hey"
        pattern "good morning"
      end
    end

    %w[hello hi hey].each do |word|
      result = router.match(word)
      assert result.matched?, "Expected #{word.inspect} to match"
      assert_equal :greeting, result.intent
    end

    result = router.match("good morning")
    assert result.matched?
    assert_equal :greeting, result.intent
  end

  def test_multiple_intents
    router = PatternRuby::Router.new do
      intent(:greeting) { pattern "hello" }
      intent(:farewell) { pattern "goodbye" }
    end

    assert_equal :greeting, router.match("hello").intent
    assert_equal :farewell, router.match("goodbye").intent
  end

  def test_entity_extraction
    router = PatternRuby::Router.new do
      intent :weather do
        pattern "weather in {city}"
        entity :city, type: :string
      end
    end

    result = router.match("weather in Tokyo")
    assert result.matched?
    assert_equal :weather, result.intent
    assert_equal "Tokyo", result.entities[:city]
  end

  def test_entity_with_default
    router = PatternRuby::Router.new do
      intent :weather do
        pattern "weather in {city}"
        entity :city, type: :string
        entity :time, type: :string, default: "today"
      end
    end

    result = router.match("weather in Tokyo")
    assert result.matched?
    assert_equal "today", result.entities[:time]
  end

  def test_regex_pattern
    router = PatternRuby::Router.new do
      intent :order_status do
        pattern(/order\s*#?\s*(?<order_id>\d{5,})/i)
      end
    end

    result = router.match("Where is order #12345?")
    assert result.matched?
    assert_equal "12345", result.entities[:order_id]
  end

  def test_regex_pattern_without_named_captures
    router = PatternRuby::Router.new do
      intent :order_status do
        pattern(/order\s*#?\s*(\d{5,})/i)
      end
    end

    result = router.match("order 99999")
    assert result.matched?
    assert_equal "99999", result.entities[:capture_0]
  end

  def test_no_match_returns_fallback
    router = PatternRuby::Router.new do
      intent(:greeting) { pattern "hello" }
    end

    result = router.match("what is quantum physics")
    refute result.matched?
    assert result.fallback?
  end

  def test_fallback_handler_called
    called = false
    received_input = nil

    router = PatternRuby::Router.new do
      intent(:greeting) { pattern "hello" }
      fallback do |input|
        called = true
        received_input = input
      end
    end

    router.match("unknown input")
    assert called
    assert_equal "unknown input", received_input
  end

  def test_response_text
    router = PatternRuby::Router.new do
      intent :greeting do
        pattern "hello"
        response "Hello! How can I help?"
      end
    end

    result = router.match("hello")
    assert_equal "Hello! How can I help?", result.response
  end

  def test_empty_input_returns_fallback
    router = PatternRuby::Router.new do
      intent(:greeting) { pattern "hello" }
    end

    result = router.match("")
    assert result.fallback?
    refute result.matched?
  end

  def test_case_insensitive_matching
    router = PatternRuby::Router.new do
      intent(:greeting) { pattern "hello" }
    end

    assert router.match("HELLO").matched?
    assert router.match("Hello").matched?
    assert router.match("hElLo").matched?
  end

  def test_match_all
    router = PatternRuby::Router.new do
      intent(:book_flight) { pattern "book a flight to {destination}" }
      intent(:book_generic) { pattern "book a {item}" }
    end

    results = router.match_all("book a flight to Paris")
    assert results.size >= 1
    assert results.all?(&:matched?)
    # Results should be sorted by score descending
    scores = results.map(&:score)
    assert_equal scores.sort.reverse, scores
  end

  def test_context_matching
    router = PatternRuby::Router.new do
      intent :confirm do
        pattern "yes"
        context :awaiting_confirmation
      end

      intent :greeting do
        pattern "yes"
      end
    end

    # Without context, matches greeting
    result = router.match("yes")
    assert_equal :greeting, result.intent

    # With context, matches confirm
    result = router.match("yes", context: :awaiting_confirmation)
    assert_equal :confirm, result.intent
  end

  def test_complex_pattern
    router = PatternRuby::Router.new do
      intent :book_flight do
        pattern "book [a] flight from {origin} to {destination} [on {date}]"
        entity :origin, type: :string
        entity :destination, type: :string
        entity :date, type: :string
      end
    end

    result = router.match("book a flight from NYC to London on Friday")
    assert result.matched?
    assert_equal "NYC", result.entities[:origin]
    assert_equal "London", result.entities[:destination]
    assert_equal "Friday", result.entities[:date]

    result2 = router.match("book flight from Paris to Berlin")
    assert result2.matched?
    assert_equal "Paris", result2.entities[:origin]
    assert_equal "Berlin", result2.entities[:destination]
  end

  def test_alternation_pattern
    router = PatternRuby::Router.new do
      intent :travel do
        pattern "i want to (fly|travel|go) to {destination}"
      end
    end

    assert router.match("i want to fly to Paris").matched?
    assert router.match("i want to travel to London").matched?
    assert router.match("i want to go to Tokyo").matched?
    refute router.match("i want to swim to Tokyo").matched?
  end

  def test_score_is_between_0_and_1
    router = PatternRuby::Router.new do
      intent(:greeting) { pattern "hello" }
      intent(:weather) { pattern "what is the weather in {city}" }
    end

    result = router.match("hello")
    assert result.score >= 0.0
    assert result.score <= 1.0

    result = router.match("what is the weather in London")
    assert result.score >= 0.0
    assert result.score <= 1.0
  end

  def test_match_result_to_h
    router = PatternRuby::Router.new do
      intent :weather do
        pattern "weather in {city}"
      end
    end

    result = router.match("weather in Tokyo")
    h = result.to_h
    assert_equal :weather, h[:intent]
    assert_equal({ city: "Tokyo" }, h[:entities])
    assert h.key?(:score)
    assert h.key?(:pattern)
  end

  def test_whitespace_handling
    router = PatternRuby::Router.new do
      intent(:greeting) { pattern "hello" }
    end

    assert router.match("  hello  ").matched?
    assert router.match("\thello\n").matched?
  end
end
