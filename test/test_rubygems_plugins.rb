require 'rake_compiler_dock'
require 'test/unit'

class TestRubygemsPlugins < Test::Unit::TestCase
  TEST_PLATFORM = ENV["TEST_PLATFORM"] || 'x86_64-linux'

  def test_gem_inst_with_plugin
    # This verifies that gem install doesn't fail due to insufficient permissions to some rubygems plugin file like:
    #   /usr/local/rbenv/versions/4.0.0/lib/ruby/gems/4.0.0/plugins/rdoc_plugin.rb
    RakeCompilerDock::Starter.sh "gem inst --silent rdoc gem-wrappers", platform: TEST_PLATFORM, verbose: false
  end
end
