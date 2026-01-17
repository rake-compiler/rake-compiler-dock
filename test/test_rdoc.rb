require 'rake_compiler_dock'
require 'test/unit'

class TestGemRdoc < Test::Unit::TestCase
  TEST_PLATFORM = ENV["TEST_PLATFORM"] || 'x86_64-linux'

  def test_gem_inst_rdoc
    # This verifies that gem install doesn't fail due to insufficient permissions to that rubygems plugin file:
    #   /usr/local/rbenv/versions/4.0.0/lib/ruby/gems/4.0.0/plugins/rdoc_plugin.rb
    RakeCompilerDock::Starter.sh "gem inst --silent rdoc", platform: TEST_PLATFORM, verbose: false
  end
end
