#include "rcd_test_ext.h"

VALUE rb_mRcdTest;

static VALUE
rcdt_do_something(VALUE self)
{
  return rb_str_new_cstr("something has been done");
}

void
Init_rcd_test_ext(void)
{
  rb_mRcdTest = rb_define_module("RcdTest");
  rb_define_singleton_method(rb_mRcdTest, "do_something", rcdt_do_something, 0);
}
