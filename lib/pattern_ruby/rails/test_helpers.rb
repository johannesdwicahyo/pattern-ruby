module PatternRuby
  module TestHelpers
    def assert_matches_intent(expected_intent, input, router:, message: nil)
      result = router.match(input)
      msg = message || "Expected input #{input.inspect} to match intent :#{expected_intent}, but got :#{result.intent}"
      assert result.matched?, msg
      assert_equal expected_intent, result.intent, msg
    end

    def assert_extracts_entity(entity_name, expected_value, input, router:, message: nil)
      result = router.match(input)
      msg = message || "Expected entity :#{entity_name} to be #{expected_value.inspect}"
      assert result.matched?, "Input #{input.inspect} did not match any intent"
      assert_equal expected_value, result.entities[entity_name.to_sym], msg
    end

    def refute_matches(input, router:, message: nil)
      result = router.match(input)
      msg = message || "Expected input #{input.inspect} not to match, but matched :#{result.intent}"
      refute result.matched?, msg
    end
  end
end
