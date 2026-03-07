require_relative "test_helper"
require "pattern_ruby/rails/test_helpers"

class TestIntegration < Minitest::Test
  def setup
    @router = PatternRuby::Router.new do
      intent :greeting do
        pattern "hello"
        pattern "hi"
        pattern "hey"
        pattern "good morning"
        pattern "good afternoon"
        response "Hello! How can I help you?"
      end

      intent :weather do
        pattern "what's the weather in {city}"
        pattern "weather forecast for {city}"
        pattern "weather in {city}"
        pattern "how's the weather in {city} {time:today|tomorrow|this week}"
        entity :city, type: :string
        entity :time, type: :enum, default: "today"
      end

      intent :order_status do
        pattern(/order\s*#?\s*(?<order_id>\d{5,})/i)
        pattern "where is my order {order_id:\\d+}"
        pattern "track order {order_id:\\d+}"
      end

      intent :book_flight do
        pattern "book [a] flight from {origin} to {destination} [on {date}]"
        pattern "fly [from] {origin} to {destination}"
        pattern "i want to (fly|travel|go) from {origin} to {destination}"
        entity :origin, type: :string
        entity :destination, type: :string
        entity :date, type: :string
      end

      fallback { |_| }
    end
  end

  # --- Greetings ---

  def test_greetings
    %w[hello hi hey].each do |word|
      result = @router.match(word)
      assert result.matched?, "#{word} should match greeting"
      assert_equal :greeting, result.intent
    end
  end

  def test_greeting_response
    result = @router.match("hello")
    assert_equal "Hello! How can I help you?", result.response
  end

  def test_multi_word_greeting
    result = @router.match("good morning")
    assert result.matched?
    assert_equal :greeting, result.intent
  end

  # --- Weather ---

  def test_weather_basic
    result = @router.match("weather in Paris")
    assert result.matched?
    assert_equal :weather, result.intent
    assert_equal "Paris", result.entities[:city]
  end

  def test_weather_with_time
    result = @router.match("how's the weather in Tokyo tomorrow")
    assert result.matched?
    assert_equal :weather, result.intent
    assert_equal "Tokyo", result.entities[:city]
    assert_equal "tomorrow", result.entities[:time]
  end

  def test_weather_default_time
    result = @router.match("weather in London")
    assert result.matched?
    assert_equal "today", result.entities[:time]
  end

  # --- Orders ---

  def test_order_regex
    result = @router.match("Where is order #12345?")
    assert result.matched?
    assert_equal :order_status, result.intent
    assert_equal "12345", result.entities[:order_id]
  end

  def test_order_pattern
    result = @router.match("track order 99999")
    assert result.matched?
    assert_equal :order_status, result.intent
    assert_equal "99999", result.entities[:order_id]
  end

  # --- Flights ---

  def test_book_flight_full
    result = @router.match("book a flight from NYC to London on Friday")
    assert result.matched?
    assert_equal :book_flight, result.intent
    assert_equal "NYC", result.entities[:origin]
    assert_equal "London", result.entities[:destination]
    assert_equal "Friday", result.entities[:date]
  end

  def test_book_flight_without_date
    result = @router.match("book flight from Paris to Berlin")
    assert result.matched?
    assert_equal :book_flight, result.intent
    assert_equal "Paris", result.entities[:origin]
    assert_equal "Berlin", result.entities[:destination]
  end

  def test_book_flight_alternation
    result = @router.match("i want to travel from Tokyo to Seoul")
    assert result.matched?
    assert_equal :book_flight, result.intent
    assert_equal "Tokyo", result.entities[:origin]
    assert_equal "Seoul", result.entities[:destination]
  end

  # --- Fallback ---

  def test_unknown_input_fallback
    result = @router.match("tell me a joke about elephants")
    refute result.matched?
    assert result.fallback?
  end

  # --- Full conversation ---

  def test_customer_service_conversation
    convo = PatternRuby::Conversation.new(@router)

    r1 = convo.process("hello")
    assert_equal :greeting, r1.intent

    r2 = convo.process("weather in Tokyo")
    assert_equal :weather, r2.intent
    assert_equal "Tokyo", r2.entities[:city]

    r3 = convo.process("where is order #55555?")
    assert_equal :order_status, r3.intent

    assert_equal 3, convo.history.size
  end
end

class TestTestHelpers < Minitest::Test
  include PatternRuby::TestHelpers

  def setup
    @router = PatternRuby::Router.new do
      intent :greeting do
        pattern "hello"
        pattern "hi"
      end

      intent :weather do
        pattern "weather in {city}"
      end
    end
  end

  def test_assert_matches_intent
    assert_matches_intent :greeting, "hello", router: @router
  end

  def test_assert_extracts_entity
    assert_extracts_entity :city, "Tokyo", "weather in Tokyo", router: @router
  end

  def test_refute_matches
    refute_matches "quantum physics", router: @router
  end
end
