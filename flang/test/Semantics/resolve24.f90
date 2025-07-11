! RUN: %python %S/test_errors.py %s %flang_fc1
subroutine test1
  !WARNING: Generic interface 'foo' has both a function and a subroutine [-Wsubroutine-and-function-specifics]
  interface foo
    subroutine s1(x)
    end subroutine
    subroutine s2(x, y)
    end subroutine
    function f()
    end function
  end interface
end subroutine

subroutine test2
  !WARNING: Generic interface 'foo' has both a function and a subroutine [-Wsubroutine-and-function-specifics]
  interface foo
    function t2f1(x)
    end function
    subroutine s()
    end subroutine
    function t2f2(x, y)
    end function
  end interface
end subroutine

module test3
  !WARNING: Generic interface 'foo' has both a function and a subroutine [-Wsubroutine-and-function-specifics]
  interface foo
    module procedure s
    module procedure f
  end interface
contains
  subroutine s(x)
  end subroutine
  function f()
  end function
end module

subroutine test4
  type foo
  end type
  !WARNING: Generic interface 'foo' should only contain functions due to derived type with same name [-Wsubroutine-and-function-specifics]
  interface foo
    subroutine s()
    end subroutine
  end interface
end subroutine

subroutine test5
  interface foo
    function t5f1()
    end function
  end interface
  interface bar
    subroutine t5s1()
    end subroutine
    subroutine t5s2(x)
    end subroutine
  end interface
  !ERROR: Cannot call function 'foo' like a subroutine
  call foo()
  !ERROR: Cannot call subroutine 'bar' like a function
  x = bar()
end subroutine
