require_relative "test_helper"

class TestEntity < Minitest::Test
  def test_entity_creation
    entity = PatternRuby::Entity.new(name: "city", type: :string, value: "Tokyo", raw: "Tokyo")
    assert_equal :city, entity.name
    assert_equal :string, entity.type
    assert_equal "Tokyo", entity.value
    assert_equal "Tokyo", entity.raw
  end

  def test_entity_to_h
    entity = PatternRuby::Entity.new(name: "city", value: "Tokyo", raw: "Tokyo")
    h = entity.to_h
    assert_equal :city, h[:name]
    assert_equal "Tokyo", h[:value]
  end

  def test_entity_name_symbolized
    entity = PatternRuby::Entity.new(name: "city_name")
    assert_equal :city_name, entity.name
  end
end

class TestEntityTypes < Minitest::Test
  def setup
    @registry = PatternRuby::EntityTypes::Registry.new
  end

  def test_built_in_number_type
    type = @registry.get(:number)
    assert type
    assert type[:pattern]
    assert type[:parser]
  end

  def test_number_parser_integer
    result = @registry.parse(:number, "42")
    assert_equal 42, result
    assert_instance_of Integer, result
  end

  def test_number_parser_float
    result = @registry.parse(:number, "3.14")
    assert_in_delta 3.14, result
    assert_instance_of Float, result
  end

  def test_currency_parser
    result = @registry.parse(:currency, "$1,234.56")
    assert_in_delta 1234.56, result
  end

  def test_string_type_no_parsing
    result = @registry.parse(:string, "hello")
    assert_equal "hello", result
  end

  def test_register_custom_type
    @registry.register(:zipcode, pattern: /\d{5}/, parser: ->(s) { s.to_i })
    type = @registry.get(:zipcode)
    assert type
    assert_equal 90210, @registry.parse(:zipcode, "90210")
  end

  def test_pattern_for
    pattern = @registry.pattern_for(:email)
    assert_instance_of Regexp, pattern
    assert pattern.match?("user@example.com")
  end

  def test_unknown_type_returns_nil
    assert_nil @registry.get(:nonexistent)
  end
end
