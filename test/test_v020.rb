require_relative "test_helper"

class TestOptionalAtStart < Minitest::Test
  def test_optional_at_start_matches_without_optional
    router = PatternRuby::Router.new do
      intent(:polite_booking) { pattern "[please] book a flight" }
    end

    result = router.match("book a flight")
    assert result.matched?
    assert_equal :polite_booking, result.intent
  end

  def test_optional_at_start_matches_with_optional
    router = PatternRuby::Router.new do
      intent(:polite_booking) { pattern "[please] book a flight" }
    end

    result = router.match("please book a flight")
    assert result.matched?
    assert_equal :polite_booking, result.intent
  end

  def test_optional_in_middle_still_works
    router = PatternRuby::Router.new do
      intent(:booking) { pattern "book [a] flight" }
    end

    assert router.match("book flight").matched?
    assert router.match("book a flight").matched?
  end

  def test_optional_at_end_still_works
    router = PatternRuby::Router.new do
      intent(:booking) { pattern "book a flight [now]" }
    end

    assert router.match("book a flight").matched?
    assert router.match("book a flight now").matched?
  end
end

class TestEmptyEntity < Minitest::Test
  def test_empty_entity_raises
    compiler = PatternRuby::PatternCompiler.new
    assert_raises(ArgumentError) { compiler.compile("hello {}") }
  end

  def test_whitespace_only_entity_raises
    compiler = PatternRuby::PatternCompiler.new
    assert_raises(ArgumentError) { compiler.compile("hello {  }") }
  end
end

class TestPatternValidation < Minitest::Test
  def test_validate_bang_returns_true_for_valid
    assert PatternRuby::PatternCompiler.validate!("hello {name}")
  end

  def test_validate_bang_raises_for_empty_entity
    assert_raises(ArgumentError) { PatternRuby::PatternCompiler.validate!("hello {}") }
  end

  def test_validate_bang_raises_for_unbalanced_brackets
    assert_raises(ArgumentError) { PatternRuby::PatternCompiler.validate!("hello [world") }
    assert_raises(ArgumentError) { PatternRuby::PatternCompiler.validate!("hello (a|b") }
    assert_raises(ArgumentError) { PatternRuby::PatternCompiler.validate!("hello {name") }
  end

  def test_validate_bang_raises_for_empty
    assert_raises(ArgumentError) { PatternRuby::PatternCompiler.validate!("") }
    assert_raises(ArgumentError) { PatternRuby::PatternCompiler.validate!("   ") }
  end
end

class TestPipelineErrorHandling < Minitest::Test
  def test_pipeline_error_propagates_without_handler
    pipeline = PatternRuby::Pipeline.new do
      step(:boom) { |_| raise "kaboom" }
    end

    assert_raises(RuntimeError) { pipeline.process("input") }
  end

  def test_pipeline_error_caught_with_on_error
    errors = []
    pipeline = PatternRuby::Pipeline.new do
      step(:boom) { |_| raise "kaboom" }
      step(:transform) { |x| x.upcase }
      on_error { |e, name, _| errors << [name, e.message]; "recovered" }
    end

    result = pipeline.process("input")
    # Error handler returns "recovered", then :transform step runs .upcase on it
    assert_equal "RECOVERED", result
    assert_equal [[:boom, "kaboom"]], errors
  end

  def test_pipeline_on_error_nil_stops_processing
    pipeline = PatternRuby::Pipeline.new do
      step(:boom) { |_| raise "kaboom" }
      step(:never) { |x| x }
      on_error { |_e, _name, _result| nil }
    end

    result = pipeline.process("input")
    assert_nil result
  end
end

class TestSlotFillValidation < Minitest::Test
  def test_slot_fill_rejects_invalid_enum_value
    router = PatternRuby::Router.new do
      intent(:weather) do
        pattern "weather in {city}"
        entity :city, type: :string
        entity :time, type: :enum, values: %w[today tomorrow]
      end
    end

    convo = PatternRuby::Conversation.new(router)
    convo.process("weather in Tokyo")
    # Try to fill :time slot with invalid value
    result = convo.process("never")
    # Should fallback since "never" is not in the enum
    assert result.fallback?
  end

  def test_slot_fill_accepts_valid_enum_value
    router = PatternRuby::Router.new do
      intent(:weather) do
        pattern "weather in {city}"
        entity :city, type: :string
        entity :time, type: :enum, values: %w[today tomorrow]
      end
    end

    convo = PatternRuby::Conversation.new(router)
    convo.process("weather in Tokyo")
    result = convo.process("tomorrow")
    assert result.matched?
    assert_equal "tomorrow", result.entities[:time]
  end
end

class TestMoreEdgeCases < Minitest::Test
  def test_special_regex_chars_in_literal
    router = PatternRuby::Router.new do
      intent(:price) { pattern "price is $10.00" }
    end

    result = router.match("price is $10.00")
    assert result.matched?
  end

  def test_unicode_input
    router = PatternRuby::Router.new do
      intent(:greeting) { pattern "hello" }
    end

    result = router.match("hello")
    assert result.matched?
  end

  def test_unicode_entity_extraction
    router = PatternRuby::Router.new do
      intent(:city) { pattern "weather in {city}" }
    end

    result = router.match("weather in Zürich")
    assert result.matched?
    assert_equal "Zürich", result.entities[:city]
  end

  def test_whitespace_only_input
    router = PatternRuby::Router.new do
      intent(:greeting) { pattern "hello" }
    end

    result = router.match("   ")
    assert result.fallback?
  end

  def test_multiple_spaces_between_words
    router = PatternRuby::Router.new do
      intent(:greeting) { pattern "hello world" }
    end

    result = router.match("hello    world")
    assert result.matched?
  end
end
