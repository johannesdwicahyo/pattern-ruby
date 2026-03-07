require_relative "test_helper"

class TestConversation < Minitest::Test
  def test_single_turn
    router = PatternRuby::Router.new do
      intent(:greeting) { pattern "hello" }
    end

    convo = PatternRuby::Conversation.new(router)
    result = convo.process("hello")
    assert result.matched?
    assert_equal :greeting, result.intent
  end

  def test_slot_filling
    router = PatternRuby::Router.new do
      intent :book_flight do
        pattern "book a flight from {origin} to {destination}"
        entity :origin, type: :string
        entity :destination, type: :string
        entity :date, type: :string
      end
    end

    convo = PatternRuby::Conversation.new(router)

    result1 = convo.process("book a flight from NYC to London")
    assert result1.matched?
    assert_equal "NYC", result1.entities[:origin]
    assert_equal "London", result1.entities[:destination]
    assert_nil result1.entities[:date]

    # Follow-up fills the missing date slot
    result2 = convo.process("tomorrow")
    assert_equal :book_flight, result2.intent
    assert_equal "NYC", result2.entities[:origin]
    assert_equal "London", result2.entities[:destination]
    assert_equal "tomorrow", result2.entities[:date]
  end

  def test_context_switching
    router = PatternRuby::Router.new do
      intent :confirm do
        pattern "yes"
        context :awaiting_confirmation
      end

      intent :greeting do
        pattern "hello"
      end
    end

    convo = PatternRuby::Conversation.new(router)
    convo.set_context(:awaiting_confirmation)

    result = convo.process("yes")
    assert_equal :confirm, result.intent
  end

  def test_reset
    router = PatternRuby::Router.new do
      intent(:greeting) { pattern "hello" }
    end

    convo = PatternRuby::Conversation.new(router)
    convo.process("hello")
    assert_equal 1, convo.history.size

    convo.reset
    assert_equal 0, convo.history.size
    assert convo.slots.empty?
    assert_nil convo.context
  end

  def test_history_tracking
    router = PatternRuby::Router.new do
      intent(:greeting) { pattern "hello" }
      intent(:farewell) { pattern "bye" }
    end

    convo = PatternRuby::Conversation.new(router)
    convo.process("hello")
    convo.process("bye")

    assert_equal 2, convo.history.size
    assert_equal :greeting, convo.history[0].intent
    assert_equal :farewell, convo.history[1].intent
  end

  def test_accumulated_slots
    router = PatternRuby::Router.new do
      intent :order do
        pattern "order {item}"
        entity :item, type: :string
        entity :quantity, type: :string
      end
    end

    convo = PatternRuby::Conversation.new(router)
    convo.process("order pizza")
    assert_equal "pizza", convo.slots[:item]
  end
end
