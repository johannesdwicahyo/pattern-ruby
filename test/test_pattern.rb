require_relative "test_helper"

class TestPatternCompiler < Minitest::Test
  def setup
    @compiler = PatternRuby::PatternCompiler.new
  end

  def test_literal_pattern
    cp = @compiler.compile("hello world")
    assert_instance_of PatternRuby::CompiledPattern, cp
    assert cp.match("hello world")
    assert cp.match("  Hello World  ")
    refute cp.match("goodbye world")
  end

  def test_entity_capture
    cp = @compiler.compile("weather in {city}")
    md = cp.match("weather in Tokyo")
    assert md
    assert_equal "Tokyo", md[:city]
  end

  def test_multiple_entities
    cp = @compiler.compile("fly from {origin} to {destination}")
    md = cp.match("fly from NYC to London")
    assert md
    assert_equal "NYC", md[:origin]
    assert_equal "London", md[:destination]
  end

  def test_entity_with_enum_constraint
    cp = @compiler.compile("remind me {when:today|tomorrow|next week}")
    assert cp.match("remind me today")
    assert cp.match("remind me tomorrow")
    assert cp.match("remind me next week")
    refute cp.match("remind me yesterday")
  end

  def test_entity_with_regex_constraint
    cp = @compiler.compile("order {id:\\d+}")
    md = cp.match("order 12345")
    assert md
    assert_equal "12345", md[:id]
    refute cp.match("order abc")
  end

  def test_optional_section
    cp = @compiler.compile("book [a] flight")
    assert cp.match("book a flight")
    assert cp.match("book flight")
  end

  def test_optional_section_with_entity
    cp = @compiler.compile("fly from {origin} to {destination} [on {date}]")
    md1 = cp.match("fly from NYC to London on Friday")
    assert md1
    assert_equal "Friday", md1[:date]

    md2 = cp.match("fly from NYC to London")
    assert md2
    assert_equal "NYC", md2[:origin]
  end

  def test_alternation
    cp = @compiler.compile("i want to (fly|travel|go) somewhere")
    assert cp.match("i want to fly somewhere")
    assert cp.match("i want to travel somewhere")
    assert cp.match("i want to go somewhere")
    refute cp.match("i want to run somewhere")
  end

  def test_wildcard
    cp = @compiler.compile("tell me *")
    assert cp.match("tell me about the weather")
    assert cp.match("tell me a joke")
  end

  def test_case_insensitive
    cp = @compiler.compile("Hello World")
    assert cp.match("hello world")
    assert cp.match("HELLO WORLD")
    assert cp.match("Hello World")
  end

  def test_counts
    cp = @compiler.compile("book [a] flight from {origin} to {destination}")
    assert_equal 7, cp.token_count  # book, [a], flight, from, {origin}, to, {destination}
    assert_equal 2, cp.entity_count
    assert cp.literal_count > 0
  end
end
