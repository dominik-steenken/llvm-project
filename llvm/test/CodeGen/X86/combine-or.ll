; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-unknown-linux-gnu -mcpu=corei7 | FileCheck %s -check-prefixes=CHECK,SSE
; RUN: llc < %s -mtriple=x86_64-unknown-linux-gnu -mcpu=corei7 -early-live-intervals | FileCheck %s -check-prefixes=CHECK,SSE
; RUN: llc < %s -mtriple=x86_64-unknown-linux-gnu -mcpu=corei7-avx | FileCheck %s -check-prefixes=CHECK,AVX,AVX1
; RUN: llc < %s -mtriple=x86_64-unknown-linux-gnu -mcpu=x86-64-v3 | FileCheck %s -check-prefixes=CHECK,AVX,AVX2

define i32 @or_self(i32 %x) {
; CHECK-LABEL: or_self:
; CHECK:       # %bb.0:
; CHECK-NEXT:    movl %edi, %eax
; CHECK-NEXT:    retq
  %or = or i32 %x, %x
  ret i32 %or
}

define <4 x i32> @or_self_vec(<4 x i32> %x) {
; CHECK-LABEL: or_self_vec:
; CHECK:       # %bb.0:
; CHECK-NEXT:    retq
  %or = or <4 x i32> %x, %x
  ret <4 x i32> %or
}

; fold (or x, c) -> c iff (x & ~c) == 0

define <2 x i64> @or_zext_v2i32(<2 x i32> %a0) {
; SSE-LABEL: or_zext_v2i32:
; SSE:       # %bb.0:
; SSE-NEXT:    movaps {{.*#+}} xmm0 = [4294967295,4294967295]
; SSE-NEXT:    retq
;
; AVX-LABEL: or_zext_v2i32:
; AVX:       # %bb.0:
; AVX-NEXT:    vmovddup {{.*#+}} xmm0 = [4294967295,4294967295]
; AVX-NEXT:    # xmm0 = mem[0,0]
; AVX-NEXT:    retq
  %1 = zext <2 x i32> %a0 to <2 x i64>
  %2 = or <2 x i64> %1, <i64 4294967295, i64 4294967295>
  ret <2 x i64> %2
}

define <4 x i32> @or_zext_v4i16(<4 x i16> %a0) {
; SSE-LABEL: or_zext_v4i16:
; SSE:       # %bb.0:
; SSE-NEXT:    movaps {{.*#+}} xmm0 = [65535,65535,65535,65535]
; SSE-NEXT:    retq
;
; AVX-LABEL: or_zext_v4i16:
; AVX:       # %bb.0:
; AVX-NEXT:    vbroadcastss {{.*#+}} xmm0 = [65535,65535,65535,65535]
; AVX-NEXT:    retq
  %1 = zext <4 x i16> %a0 to <4 x i32>
  %2 = or <4 x i32> %1, <i32 65535, i32 65535, i32 65535, i32 65535>
  ret <4 x i32> %2
}

; fold (or (and X, C1), (and (or X, Y), C2)) -> (or (and X, C1|C2), (and Y, C2))

define i32 @or_and_and_i32(i32 %x, i32 %y) {
; CHECK-LABEL: or_and_and_i32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    movl %edi, %eax
; CHECK-NEXT:    andl $-11, %esi
; CHECK-NEXT:    andl $-3, %eax
; CHECK-NEXT:    orl %esi, %eax
; CHECK-NEXT:    retq
  %xy = or i32 %x, %y
  %mx = and i32 %x, 8
  %mxy = and i32 %xy, -11
  %r = or i32 %mx, %mxy
  ret i32 %r
}

define i64 @or_and_and_commute_i64(i64 %x, i64 %y) {
; CHECK-LABEL: or_and_and_commute_i64:
; CHECK:       # %bb.0:
; CHECK-NEXT:    movq %rdi, %rax
; CHECK-NEXT:    orq %rsi, %rax
; CHECK-NEXT:    andq $-3, %rax
; CHECK-NEXT:    retq
  %xy = or i64 %x, %y
  %mx = and i64 %x, 8
  %mxy = and i64 %xy, -3
  %r = or i64 %mxy, %mx
  ret i64 %r
}

define <4 x i32> @or_and_and_v4i32(<4 x i32> %x, <4 x i32> %y) {
; SSE-LABEL: or_and_and_v4i32:
; SSE:       # %bb.0:
; SSE-NEXT:    andps {{\.?LCPI[0-9]+_[0-9]+}}(%rip), %xmm1
; SSE-NEXT:    andps {{\.?LCPI[0-9]+_[0-9]+}}(%rip), %xmm0
; SSE-NEXT:    orps %xmm1, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: or_and_and_v4i32:
; AVX:       # %bb.0:
; AVX-NEXT:    vandps {{\.?LCPI[0-9]+_[0-9]+}}(%rip), %xmm1, %xmm1
; AVX-NEXT:    vandps {{\.?LCPI[0-9]+_[0-9]+}}(%rip), %xmm0, %xmm0
; AVX-NEXT:    vorps %xmm1, %xmm0, %xmm0
; AVX-NEXT:    retq
  %xy = or <4 x i32> %x, %y
  %mx = and <4 x i32> %x, <i32 2, i32 4, i32 8, i32 16>
  %mxy = and <4 x i32> %xy, <i32 1, i32 -1, i32 -5, i32 -25>
  %r = or <4 x i32> %mx, %mxy
  ret <4 x i32> %r
}

define i32 @or_and_and_multiuse_i32(i32 %x, i32 %y) nounwind {
; CHECK-LABEL: or_and_and_multiuse_i32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    pushq %rbx
; CHECK-NEXT:    # kill: def $esi killed $esi def $rsi
; CHECK-NEXT:    # kill: def $edi killed $edi def $rdi
; CHECK-NEXT:    orl %edi, %esi
; CHECK-NEXT:    andl $8, %edi
; CHECK-NEXT:    andl $-11, %esi
; CHECK-NEXT:    leal (%rdi,%rsi), %ebx
; CHECK-NEXT:    movl %esi, %edi
; CHECK-NEXT:    callq use_i32@PLT
; CHECK-NEXT:    movl %ebx, %eax
; CHECK-NEXT:    popq %rbx
; CHECK-NEXT:    retq
  %xy = or i32 %x, %y
  %mx = and i32 %x, 8
  %mxy = and i32 %xy, -11
  %r = or i32 %mx, %mxy
  call void @use_i32(i32 %mxy)
  ret i32 %r
}

define i32 @or_and_multiuse_and_i32(i32 %x, i32 %y) nounwind {
; CHECK-LABEL: or_and_multiuse_and_i32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    pushq %rbx
; CHECK-NEXT:    # kill: def $esi killed $esi def $rsi
; CHECK-NEXT:    # kill: def $edi killed $edi def $rdi
; CHECK-NEXT:    orl %edi, %esi
; CHECK-NEXT:    andl $8, %edi
; CHECK-NEXT:    andl $-11, %esi
; CHECK-NEXT:    leal (%rsi,%rdi), %ebx
; CHECK-NEXT:    # kill: def $edi killed $edi killed $rdi
; CHECK-NEXT:    callq use_i32@PLT
; CHECK-NEXT:    movl %ebx, %eax
; CHECK-NEXT:    popq %rbx
; CHECK-NEXT:    retq
  %xy = or i32 %x, %y
  %mx = and i32 %x, 8
  %mxy = and i32 %xy, -11
  %r = or i32 %mx, %mxy
  call void @use_i32(i32 %mx)
  ret i32 %r
}

define i32 @or_and_multiuse_and_multiuse_i32(i32 %x, i32 %y) nounwind {
; CHECK-LABEL: or_and_multiuse_and_multiuse_i32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    pushq %rbp
; CHECK-NEXT:    pushq %rbx
; CHECK-NEXT:    pushq %rax
; CHECK-NEXT:    movl %esi, %ebx
; CHECK-NEXT:    # kill: def $edi killed $edi def $rdi
; CHECK-NEXT:    orl %edi, %ebx
; CHECK-NEXT:    andl $8, %edi
; CHECK-NEXT:    andl $-11, %ebx
; CHECK-NEXT:    leal (%rdi,%rbx), %ebp
; CHECK-NEXT:    # kill: def $edi killed $edi killed $rdi
; CHECK-NEXT:    callq use_i32@PLT
; CHECK-NEXT:    movl %ebx, %edi
; CHECK-NEXT:    callq use_i32@PLT
; CHECK-NEXT:    movl %ebp, %eax
; CHECK-NEXT:    addq $8, %rsp
; CHECK-NEXT:    popq %rbx
; CHECK-NEXT:    popq %rbp
; CHECK-NEXT:    retq
  %xy = or i32 %x, %y
  %mx = and i32 %x, 8
  %mxy = and i32 %xy, -11
  %r = or i32 %mx, %mxy
  call void @use_i32(i32 %mx)
  call void @use_i32(i32 %mxy)
  ret i32 %r
}

define i64 @or_build_pair_not(i32 %a0, i32 %a1) {
; CHECK-LABEL: or_build_pair_not:
; CHECK:       # %bb.0:
; CHECK-NEXT:    # kill: def $esi killed $esi def $rsi
; CHECK-NEXT:    shlq $32, %rsi
; CHECK-NEXT:    movl %edi, %eax
; CHECK-NEXT:    orq %rsi, %rax
; CHECK-NEXT:    notq %rax
; CHECK-NEXT:    retq
  %n0 = xor i32 %a0, -1
  %n1 = xor i32 %a1, -1
  %x0 = zext i32 %n0 to i64
  %x1 = zext i32 %n1 to i64
  %hi = shl i64 %x1, 32
  %r = or i64 %hi, %x0
  ret i64 %r
}

define i64 @PR89533(<64 x i8> %a0) {
; SSE-LABEL: PR89533:
; SSE:       # %bb.0:
; SSE-NEXT:    movdqa {{.*#+}} xmm4 = [95,95,95,95,95,95,95,95,95,95,95,95,95,95,95,95]
; SSE-NEXT:    pcmpeqb %xmm4, %xmm0
; SSE-NEXT:    pmovmskb %xmm0, %eax
; SSE-NEXT:    xorl $65535, %eax # imm = 0xFFFF
; SSE-NEXT:    pcmpeqb %xmm4, %xmm1
; SSE-NEXT:    pmovmskb %xmm1, %ecx
; SSE-NEXT:    notl %ecx
; SSE-NEXT:    shll $16, %ecx
; SSE-NEXT:    orl %eax, %ecx
; SSE-NEXT:    pcmpeqb %xmm4, %xmm2
; SSE-NEXT:    pmovmskb %xmm2, %eax
; SSE-NEXT:    xorl $65535, %eax # imm = 0xFFFF
; SSE-NEXT:    pcmpeqb %xmm4, %xmm3
; SSE-NEXT:    pmovmskb %xmm3, %edx
; SSE-NEXT:    notl %edx
; SSE-NEXT:    shll $16, %edx
; SSE-NEXT:    orl %eax, %edx
; SSE-NEXT:    shlq $32, %rdx
; SSE-NEXT:    orq %rcx, %rdx
; SSE-NEXT:    movl $64, %eax
; SSE-NEXT:    rep bsfq %rdx, %rax
; SSE-NEXT:    retq
;
; AVX1-LABEL: PR89533:
; AVX1:       # %bb.0:
; AVX1-NEXT:    vbroadcastss {{.*#+}} xmm2 = [95,95,95,95,95,95,95,95,95,95,95,95,95,95,95,95]
; AVX1-NEXT:    vpcmpeqb %xmm2, %xmm0, %xmm3
; AVX1-NEXT:    vpmovmskb %xmm3, %eax
; AVX1-NEXT:    xorl $65535, %eax # imm = 0xFFFF
; AVX1-NEXT:    vextractf128 $1, %ymm0, %xmm0
; AVX1-NEXT:    vpcmpeqb %xmm2, %xmm0, %xmm0
; AVX1-NEXT:    vpmovmskb %xmm0, %ecx
; AVX1-NEXT:    notl %ecx
; AVX1-NEXT:    shll $16, %ecx
; AVX1-NEXT:    orl %eax, %ecx
; AVX1-NEXT:    vpcmpeqb %xmm2, %xmm1, %xmm0
; AVX1-NEXT:    vpmovmskb %xmm0, %eax
; AVX1-NEXT:    xorl $65535, %eax # imm = 0xFFFF
; AVX1-NEXT:    vextractf128 $1, %ymm1, %xmm0
; AVX1-NEXT:    vpcmpeqb %xmm2, %xmm0, %xmm0
; AVX1-NEXT:    vpmovmskb %xmm0, %edx
; AVX1-NEXT:    notl %edx
; AVX1-NEXT:    shll $16, %edx
; AVX1-NEXT:    orl %eax, %edx
; AVX1-NEXT:    shlq $32, %rdx
; AVX1-NEXT:    orq %rcx, %rdx
; AVX1-NEXT:    movl $64, %eax
; AVX1-NEXT:    rep bsfq %rdx, %rax
; AVX1-NEXT:    vzeroupper
; AVX1-NEXT:    retq
;
; AVX2-LABEL: PR89533:
; AVX2:       # %bb.0:
; AVX2-NEXT:    vpbroadcastd {{.*#+}} ymm2 = [95,95,95,95,95,95,95,95,95,95,95,95,95,95,95,95,95,95,95,95,95,95,95,95,95,95,95,95,95,95,95,95]
; AVX2-NEXT:    vpcmpeqb %ymm2, %ymm0, %ymm0
; AVX2-NEXT:    vpmovmskb %ymm0, %eax
; AVX2-NEXT:    vpcmpeqb %ymm2, %ymm1, %ymm0
; AVX2-NEXT:    vpmovmskb %ymm0, %ecx
; AVX2-NEXT:    shlq $32, %rcx
; AVX2-NEXT:    orq %rax, %rcx
; AVX2-NEXT:    notq %rcx
; AVX2-NEXT:    xorl %eax, %eax
; AVX2-NEXT:    tzcntq %rcx, %rax
; AVX2-NEXT:    vzeroupper
; AVX2-NEXT:    retq
  %cmp = icmp ne <64 x i8> %a0, <i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95, i8 95>
  %mask = bitcast <64 x i1> %cmp to i64
  %tz = tail call i64 @llvm.cttz.i64(i64 %mask, i1 false)
  ret i64 %tz
}

declare void @use_i32(i32)

