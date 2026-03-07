require_relative "test_helper"

class TestPipeline < Minitest::Test
  def test_simple_pipeline
    pipeline = PatternRuby::Pipeline.new do
      step(:upcase) { |input| input.upcase }
    end

    assert_equal "HELLO", pipeline.process("hello")
  end

  def test_multi_step_pipeline
    pipeline = PatternRuby::Pipeline.new do
      step(:strip) { |input| input.strip }
      step(:downcase) { |input| input.downcase }
      step(:normalize) { |input| input.gsub(/\s+/, " ") }
    end

    assert_equal "hello world", pipeline.process("  Hello   World  ")
  end

  def test_pipeline_with_router
    router = PatternRuby::Router.new do
      intent(:greeting) { pattern "hello" }
    end

    pipeline = PatternRuby::Pipeline.new do
      step(:normalize) { |input| input.strip.downcase }
      step(:match) { |input| router.match(input) }
    end

    result = pipeline.process("  HELLO  ")
    assert result.matched?
    assert_equal :greeting, result.intent
  end

  def test_pipeline_steps_list
    pipeline = PatternRuby::Pipeline.new do
      step(:a) { |x| x }
      step(:b) { |x| x }
      step(:c) { |x| x }
    end

    assert_equal [:a, :b, :c], pipeline.steps
  end

  def test_pipeline_preprocessing_and_matching
    router = PatternRuby::Router.new do
      intent(:weather) { pattern "weather in {city}" }
    end

    pipeline = PatternRuby::Pipeline.new do
      step(:normalize) { |input| input.strip.downcase.gsub(/[?!.]/, "") }
      step(:correct) { |input| input.gsub(/wether/, "weather") }
      step(:match) { |input| router.match(input) }
    end

    result = pipeline.process("Wether in Tokyo?")
    assert result.matched?
    assert_equal :weather, result.intent
    assert_equal "tokyo", result.entities[:city]
  end
end
