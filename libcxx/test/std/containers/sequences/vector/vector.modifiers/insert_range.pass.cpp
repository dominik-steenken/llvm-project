//===----------------------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

// UNSUPPORTED: c++03, c++11, c++14, c++17, c++20
// ADDITIONAL_COMPILE_FLAGS(has-fconstexpr-steps): -fconstexpr-steps=2000000

// template<container-compatible-range<T> R>
//   constexpr iterator insert_range(const_iterator position, R&& rg); // C++23

#include <sstream>
#include <vector>

#include "../../insert_range_sequence_containers.h"
#include "asan_testing.h"
#include "test_macros.h"

// Tested cases:
// - different kinds of insertions (inserting an {empty/one-element/mid-sized/long range} into an
//   {empty/one-element/full} container at the {beginning/middle/end});
// - inserting move-only elements;
// - an exception is thrown when copying the elements or when allocating new elements.

constexpr bool test() {
  for_all_iterators_and_allocators<int, const int*>([]<class Iter, class Sent, class Alloc>() {
    test_sequence_insert_range<std::vector<int, Alloc>, Iter, Sent>([]([[maybe_unused]] auto&& c) {
      LIBCPP_ASSERT(c.__invariants());
      LIBCPP_ASSERT(is_contiguous_container_asan_correct(c));
    });
  });
  test_sequence_insert_range_move_only<std::vector>();

  {   // Vector may or may not need to reallocate because of the insertion -- make sure to test both cases.
    { // Ensure reallocation happens.
      int in[]           = {-1, -2, -3, -4, -5, -6, -7, -8, -9, -10};
      std::vector<int> v = {1, 2, 3, 4, 5, 6, 7, 8};
      v.shrink_to_fit();
      assert(v.capacity() < v.size() + std::ranges::size(in));

      v.insert_range(v.end(), in);
      assert(std::ranges::equal(v, std::array{1, 2, 3, 4, 5, 6, 7, 8, -1, -2, -3, -4, -5, -6, -7, -8, -9, -10}));
    }

    { // Ensure no reallocation happens.
      int in[]           = {-1, -2, -3, -4, -5, -6, -7, -8, -9, -10};
      std::vector<int> v = {1, 2, 3, 4, 5, 6, 7, 8};
      v.reserve(v.size() + std::ranges::size(in));
      assert(v.capacity() >= v.size() + std::ranges::size(in));

      v.insert_range(v.end(), in);
      assert(std::ranges::equal(v, std::array{1, 2, 3, 4, 5, 6, 7, 8, -1, -2, -3, -4, -5, -6, -7, -8, -9, -10}));
    }

    { // Ensure input-only sized ranges are accepted.
      using input_iter = cpp20_input_iterator<const int*>;
      const int in[]{1, 2, 3, 4};
      std::vector<int> v{-5, -6};
      v.insert_range(v.begin(), std::views::counted(input_iter{std::ranges::begin(in)}, std::ranges::ssize(in)));
      assert(std::ranges::equal(v, std::vector<int>{1, 2, 3, 4, -5, -6}));
    }
  }

  { // Ensure that insert_range doesn't use unexpected assignment.
    struct Wrapper {
      constexpr Wrapper(int n) : n_(n) {}
      void operator=(int) = delete;

      int n_;
    };

    int a[]{1, 2, 3, 4, 5};
    std::vector<Wrapper> v;
    v.insert_range(v.end(), a);
    assert(v.size() == std::size(a));
    for (std::size_t i = 0; i != std::size(a); ++i)
      assert(v[i].n_ == a[i]);
  }

  return true;
}

#ifndef TEST_HAS_NO_LOCALIZATION
void test_counted_istream_view() {
  std::istringstream is{"1 2 3 4"};
  auto vals = std::views::istream<int>(is);
  std::vector<int> v;
  v.insert_range(v.end(), std::views::counted(vals.begin(), 3));
  assert(v == (std::vector{1, 2, 3}));
}
#endif

int main(int, char**) {
  test();
  static_assert(test());

  static_assert(test_constraints_insert_range<std::vector, int, double>());

  test_insert_range_exception_safety_throwing_copy<std::vector>();
  test_insert_range_exception_safety_throwing_allocator<std::vector, int>();

#ifndef TEST_HAS_NO_LOCALIZATION
  test_counted_istream_view();
#endif

  return 0;
}
