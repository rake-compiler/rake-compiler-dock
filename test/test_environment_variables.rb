require 'rake_compiler_dock'
require 'rbconfig'
require 'test/unit'
begin
  require 'test/unit/notify'
rescue LoadError
end

class TestEnvironmentVariables < Test::Unit::TestCase
  @@rcd_env = nil

  def setup
    @@rcd_env ||= begin
      args = "bash -c 'set'"
      idir = File.join(File.dirname(__FILE__), '../lib')
      cmd = "#{RbConfig::CONFIG['RUBY_INSTALL_NAME']} -I#{idir.inspect} bin/rake-compiler-dock #{args}"
      output = `#{cmd}`

      output.split("\n").inject({}) do |hash, line|
        if line =~ /\A(\w+)=(.*)\z/
          hash[$1] = $2.chomp
        end
        hash
      end
    end
  end

  def rcd_env
    @@rcd_env
  end

  def test_IMAGE
    assert_equal "larskanis/rake-compiler-dock-mri:#{RakeCompilerDock::IMAGE_VERSION}", rcd_env['RCD_IMAGE']
  end

  def test_RUBY_CC_VERSION
    df = File.read(File.expand_path("../../Dockerfile.mri", __FILE__))
    df =~ /^ENV RUBY_CC_VERSION\s+(.*)\s+$/
    assert_equal $1, rcd_env['RUBY_CC_VERSION']
  end

  def test_HOST_RUBY_PLATFORM
    assert_equal RUBY_PLATFORM, rcd_env['RCD_HOST_RUBY_PLATFORM']
  end

  def test_HOST_RUBY_VERSION
    assert_equal RUBY_VERSION, rcd_env['RCD_HOST_RUBY_VERSION']
  end

  def test_PWD
    assert_equal Dir.pwd, rcd_env['PWD']
  end

end
