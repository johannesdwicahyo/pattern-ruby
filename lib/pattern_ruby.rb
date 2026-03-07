require "strscan"

require_relative "pattern_ruby/version"
require_relative "pattern_ruby/match_result"
require_relative "pattern_ruby/entity"
require_relative "pattern_ruby/entity_types"
require_relative "pattern_ruby/pattern_compiler"
require_relative "pattern_ruby/intent"
require_relative "pattern_ruby/router"
require_relative "pattern_ruby/pipeline"
require_relative "pattern_ruby/conversation"

module PatternRuby
  class Error < StandardError; end
end
