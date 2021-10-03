# frozen_string_literal: true

require "minitest/autorun"
require "rcd_test"

class TestBasic < Minitest::Test

  def test_do_something
    assert_equal "something has been done", RcdTest.do_something
  end

end
