require_relative "test_helper"

class TestEntityTypeValidation < Minitest::Test
  def test_standard_ner_types_are_valid
    %w[PERSON PER LOCATION LOC ORGANIZATION ORG DATE TIME MONEY PERCENT MISC].each do |t|
      assert PatternRuby::EntityTypes.valid_entity_type?(t), "#{t} should be a valid entity type"
    end
  end

  def test_built_in_types_are_valid
    %w[string number integer email phone url currency].each do |t|
      assert PatternRuby::EntityTypes.valid_entity_type?(t), "#{t} should be a valid entity type"
    end
  end

  def test_custom_upper_snake_case_types_are_valid
    assert PatternRuby::EntityTypes.valid_entity_type?("PRODUCT_ID")
    assert PatternRuby::EntityTypes.valid_entity_type?("CUSTOM_TYPE")
  end

  def test_custom_camel_case_types_are_valid
    assert PatternRuby::EntityTypes.valid_entity_type?("ProductId")
    assert PatternRuby::EntityTypes.valid_entity_type?("Custom")
  end

  def test_invalid_entity_types
    refute PatternRuby::EntityTypes.valid_entity_type?(nil)
    refute PatternRuby::EntityTypes.valid_entity_type?("")
    refute PatternRuby::EntityTypes.valid_entity_type?("  ")
    refute PatternRuby::EntityTypes.valid_entity_type?("lower_case")
    refute PatternRuby::EntityTypes.valid_entity_type?("123")
    refute PatternRuby::EntityTypes.valid_entity_type?("has space")
  end

  def test_pattern_with_ner_entity_type
    compiler = PatternRuby::PatternCompiler.new
    cp = compiler.compile("meet {name:PERSON} at {place:LOCATION}")
    md = cp.match("meet Alice at Park")
    assert md
    assert_equal "Alice", md[:name]
    assert_equal "Park", md[:place]
  end

  def test_pattern_with_ner_entity_type_in_router
    router = PatternRuby::Router.new do
      intent :introduce do
        pattern "my name is {name:PERSON}"
      end
    end

    result = router.match("my name is Alice")
    assert result.matched?
    assert_equal "Alice", result.entities[:name]
  end
end

class TestInputValidation < Minitest::Test
  def test_nil_pattern_raises
    compiler = PatternRuby::PatternCompiler.new
    assert_raises(ArgumentError) { compiler.compile(nil) }
  end

  def test_empty_pattern_raises
    compiler = PatternRuby::PatternCompiler.new
    assert_raises(ArgumentError) { compiler.compile("") }
    assert_raises(ArgumentError) { compiler.compile("   ") }
  end

  def test_non_string_pattern_in_intent_raises
    router = PatternRuby::Router.new
    intent = router.intent(:test)
    assert_raises(ArgumentError) { intent.pattern(123) }
    assert_raises(ArgumentError) { intent.pattern(nil) }
  end

  def test_empty_string_pattern_in_intent_raises
    router = PatternRuby::Router.new
    intent = router.intent(:test)
    assert_raises(ArgumentError) { intent.pattern("") }
    assert_raises(ArgumentError) { intent.pattern("   ") }
  end

  def test_nil_input_returns_fallback
    router = PatternRuby::Router.new do
      intent(:greeting) { pattern "hello" }
    end

    result = router.match(nil)
    assert result.fallback?
    refute result.matched?
  end

  def test_nil_input_match_all_returns_empty
    router = PatternRuby::Router.new do
      intent(:greeting) { pattern "hello" }
    end

    results = router.match_all(nil)
    assert_equal [], results
  end

  def test_numeric_input_coerced_to_string
    router = PatternRuby::Router.new do
      intent(:number) { pattern "42" }
    end

    result = router.match(42)
    assert result.matched?
    assert_equal :number, result.intent
  end

  def test_very_long_input_is_truncated_not_crashed
    router = PatternRuby::Router.new do
      intent(:greeting) { pattern "hello" }
    end

    long_input = "hello " * 50_000
    result = router.match(long_input)
    # Should not raise, should still attempt matching
    assert_kind_of PatternRuby::MatchResult, result
  end

  def test_pattern_max_length_exceeded
    compiler = PatternRuby::PatternCompiler.new
    long_pattern = "word " * 5_000
    assert_raises(ArgumentError) { compiler.compile(long_pattern) }
  end
end

class TestEdgeCases < Minitest::Test
  def test_empty_intent_list
    router = PatternRuby::Router.new
    result = router.match("hello")
    assert result.fallback?
    refute result.matched?
  end

  def test_empty_intent_list_match_all
    router = PatternRuby::Router.new
    results = router.match_all("hello")
    assert_equal [], results
  end

  def test_duplicate_intent_registration_is_idempotent
    router = PatternRuby::Router.new
    i1 = router.intent(:greeting) { pattern "hello" }
    i2 = router.intent(:greeting)

    assert_same i1, i2
    assert_equal 1, router.intents.size
  end

  def test_intent_without_patterns_does_not_match
    router = PatternRuby::Router.new do
      intent(:empty) {}
    end

    result = router.match("anything")
    assert result.fallback?
  end
end

class TestThreadSafety < Minitest::Test
  def test_concurrent_matching
    router = PatternRuby::Router.new do
      intent(:greeting) { pattern "hello" }
      intent(:farewell) { pattern "goodbye" }
      intent(:weather) { pattern "weather in {city}" }
    end

    errors = []
    threads = 10.times.map do |i|
      Thread.new do
        50.times do
          input = ["hello", "goodbye", "weather in Tokyo"][i % 3]
          result = router.match(input)
          unless result.matched?
            errors << "Thread #{i}: expected match for #{input.inspect}"
          end
        end
      rescue => e
        errors << "Thread #{i}: #{e.class}: #{e.message}"
      end
    end

    threads.each(&:join)
    assert errors.empty?, "Thread safety errors:\n#{errors.join("\n")}"
  end

  def test_concurrent_conversation_processing
    router = PatternRuby::Router.new do
      intent(:greeting) { pattern "hello" }
      intent(:farewell) { pattern "goodbye" }
    end

    convo = PatternRuby::Conversation.new(router)
    errors = []

    threads = 5.times.map do |i|
      Thread.new do
        20.times do
          input = i.even? ? "hello" : "goodbye"
          result = convo.process(input)
          unless result.matched?
            errors << "Thread #{i}: expected match for #{input.inspect}"
          end
        end
      rescue => e
        errors << "Thread #{i}: #{e.class}: #{e.message}"
      end
    end

    threads.each(&:join)
    assert errors.empty?, "Thread safety errors:\n#{errors.join("\n")}"
    assert_equal 100, convo.history.size
  end

  def test_concurrent_entity_registry_access
    registry = PatternRuby::EntityTypes::Registry.new
    errors = []

    threads = 5.times.map do |i|
      Thread.new do
        20.times do |j|
          registry.register(:"type_#{i}_#{j}", pattern: /test/)
          result = registry.get(:"type_#{i}_#{j}")
          unless result
            errors << "Thread #{i}: failed to get type_#{i}_#{j}"
          end
        end
      rescue => e
        errors << "Thread #{i}: #{e.class}: #{e.message}"
      end
    end

    threads.each(&:join)
    assert errors.empty?, "Thread safety errors:\n#{errors.join("\n")}"
  end
end
