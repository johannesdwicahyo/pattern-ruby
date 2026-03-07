require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test" << "lib"
  t.pattern = "test/test_*.rb"
  t.warning = true
end

task default: :test
