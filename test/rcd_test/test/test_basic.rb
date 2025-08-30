# frozen_string_literal: true

require "minitest/autorun"
require "rcd_test"

class TestBasic < Minitest::Test

  def test_do_something
    assert_equal "something has been done", RcdTest.do_something
  end

  def test_check_darwin_compiler_rt_symbol_resolution
    skip("jruby should not run libc-specific tests") if RUBY_ENGINE == "jruby"

    if RUBY_PLATFORM.include?("darwin")
      assert(RcdTest.darwin_builtin_available?)
    else
      e = assert_raises(RuntimeError) { RcdTest.darwin_builtin_available? }
      assert_equal("__builtin_available is not defined", e.message)
    end
  end

  def test_floating_point_classification_macros
    skip("jruby should not run libc-specific tests") if RUBY_ENGINE == "jruby"

    refute(RcdTest.isinf?(42.0))
    assert(RcdTest.isinf?(Float::INFINITY))
    refute(RcdTest.isnan?(42.0))
    assert(RcdTest.isnan?(Float::NAN))
  end

  def test_largefile_op_removed_from_musl
    skip("jruby should not run libc-specific tests") if RUBY_ENGINE == "jruby"

    is_linux = RUBY_PLATFORM.include?("linux")
    assert_equal(is_linux, RcdTest.largefile_op_removed_from_musl)
  end

  def test_disabled_rpath
    skip("jruby uses jar files without rpath") if RUBY_ENGINE == "jruby"

    cext_fname = $LOADED_FEATURES.grep(/rcd_test_ext/).first
    refute_nil(cext_fname, "the C-ext should be loaded")
    cext_text = File.binread(cext_fname)
    assert_match(/Init_rcd_test_ext/, cext_text, "C-ext shoud contain the init function")
    refute_match(/usr\/local/, cext_text, "there should be no rpath to /usr/local/rake-compiler/ruby/x86_64-unknown-linux-musl/ruby-3.4.5/lib or so")
    refute_match(/home\//, cext_text, "there should be no path to /home/ or so")
  end
end
