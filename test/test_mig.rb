require 'rake_compiler_dock'
require 'test/unit'

class TestMigCompile < Test::Unit::TestCase
  TEST_PLATFORM = ENV["TEST_PLATFORM"] || 'arm64-darwin'

  def test_mig_compile
    omit "only on darwin platform" unless TEST_PLATFORM =~ /darwin/

    RakeCompilerDock::Starter.sh "mig -header tmp/mig_test_rpc.h -user tmp/mig_test_rpc.c -sheader /dev/null -server /dev/null -I. test/fixtures/mig_test_rpc.defs ", platform: TEST_PLATFORM, verbose: false

    h_file = File.read("tmp/mig_test_rpc.h")
    assert_match /Request_mig_test_call/, h_file

    c_file = File.read("tmp/mig_test_rpc.c")
    assert_match /Reply__mig_test_call/, c_file
  end
end
