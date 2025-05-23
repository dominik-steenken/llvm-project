; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc --mtriple=riscv64-linux-gnu --mattr=+v,+zvfh < %s | FileCheck %s --check-prefixes=CHECK,ZVFH
; RUN: llc --mtriple=riscv64-linux-gnu --mattr=+v,+zvfhmin,+zfh < %s | FileCheck %s --check-prefixes=CHECK,ZVFHMIN

define <2 x double> @min_v2f64(<2 x double> %a, <2 x double> %b) {
; CHECK-LABEL: min_v2f64:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; CHECK-NEXT:    vfmin.vv v8, v8, v9
; CHECK-NEXT:    ret
entry:
  %c = call <2 x double> @llvm.minimumnum.v2f64(<2 x double> %a, <2 x double> %b)
  ret <2 x double> %c
}

define <3 x double> @min_v3f64(<3 x double> %a, <3 x double> %b) {
; CHECK-LABEL: min_v3f64:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    vsetivli zero, 4, e64, m2, ta, ma
; CHECK-NEXT:    vfmin.vv v8, v8, v10
; CHECK-NEXT:    ret
entry:
  %c = call <3 x double> @llvm.minimumnum.v3f64(<3 x double> %a, <3 x double> %b)
  ret <3 x double> %c
}

define <4 x double> @min_v4f64(<4 x double> %a, <4 x double> %b) {
; CHECK-LABEL: min_v4f64:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    vsetivli zero, 4, e64, m2, ta, ma
; CHECK-NEXT:    vfmin.vv v8, v8, v10
; CHECK-NEXT:    ret
entry:
  %c = call <4 x double> @llvm.minimumnum.v4f64(<4 x double> %a, <4 x double> %b)
  ret <4 x double> %c
}

define <2 x float> @min_v2f32(<2 x float> %a, <2 x float> %b) {
; CHECK-LABEL: min_v2f32:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    vsetivli zero, 2, e32, mf2, ta, ma
; CHECK-NEXT:    vfmin.vv v8, v8, v9
; CHECK-NEXT:    ret
entry:
  %c = call <2 x float> @llvm.minimumnum.v2f32(<2 x float> %a, <2 x float> %b)
  ret <2 x float> %c
}

define <3 x float> @min_v3f32(<3 x float> %a, <3 x float> %b) {
; CHECK-LABEL: min_v3f32:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; CHECK-NEXT:    vfmin.vv v8, v8, v9
; CHECK-NEXT:    ret
entry:
  %c = call <3 x float> @llvm.minimumnum.v3f32(<3 x float> %a, <3 x float> %b)
  ret <3 x float> %c
}

define <4 x float> @min_v4f32(<4 x float> %a, <4 x float> %b) {
; CHECK-LABEL: min_v4f32:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; CHECK-NEXT:    vfmin.vv v8, v8, v9
; CHECK-NEXT:    ret
entry:
  %c = call <4 x float> @llvm.minimumnum.v4f32(<4 x float> %a, <4 x float> %b)
  ret <4 x float> %c
}

define <5 x float> @min_v5f32(<5 x float> %a, <5 x float> %b) {
; CHECK-LABEL: min_v5f32:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    vsetivli zero, 8, e32, m2, ta, ma
; CHECK-NEXT:    vfmin.vv v8, v8, v10
; CHECK-NEXT:    ret
entry:
  %c = call <5 x float> @llvm.minimumnum.v5f32(<5 x float> %a, <5 x float> %b)
  ret <5 x float> %c
}

define <8 x float> @min_v8f32(<8 x float> %a, <8 x float> %b) {
; CHECK-LABEL: min_v8f32:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    vsetivli zero, 8, e32, m2, ta, ma
; CHECK-NEXT:    vfmin.vv v8, v8, v10
; CHECK-NEXT:    ret
entry:
  %c = call <8 x float> @llvm.minimumnum.v8f32(<8 x float> %a, <8 x float> %b)
  ret <8 x float> %c
}

define <2 x half> @min_v2f16(<2 x half> %a, <2 x half> %b) {
; ZVFH-LABEL: min_v2f16:
; ZVFH:       # %bb.0: # %entry
; ZVFH-NEXT:    vsetivli zero, 2, e16, mf4, ta, ma
; ZVFH-NEXT:    vfmin.vv v8, v8, v9
; ZVFH-NEXT:    ret
;
; ZVFHMIN-LABEL: min_v2f16:
; ZVFHMIN:       # %bb.0: # %entry
; ZVFHMIN-NEXT:    vsetivli zero, 2, e16, mf4, ta, ma
; ZVFHMIN-NEXT:    vfwcvt.f.f.v v10, v9
; ZVFHMIN-NEXT:    vfwcvt.f.f.v v9, v8
; ZVFHMIN-NEXT:    vsetvli zero, zero, e32, mf2, ta, ma
; ZVFHMIN-NEXT:    vfmin.vv v9, v9, v10
; ZVFHMIN-NEXT:    vsetvli zero, zero, e16, mf4, ta, ma
; ZVFHMIN-NEXT:    vfncvt.f.f.w v8, v9
; ZVFHMIN-NEXT:    ret
entry:
  %c = call <2 x half> @llvm.minimumnum.v2f16(<2 x half> %a, <2 x half> %b)
  ret <2 x half> %c
}

define <4 x half> @min_v4f16(<4 x half> %a, <4 x half> %b) {
; ZVFH-LABEL: min_v4f16:
; ZVFH:       # %bb.0: # %entry
; ZVFH-NEXT:    vsetivli zero, 4, e16, mf2, ta, ma
; ZVFH-NEXT:    vfmin.vv v8, v8, v9
; ZVFH-NEXT:    ret
;
; ZVFHMIN-LABEL: min_v4f16:
; ZVFHMIN:       # %bb.0: # %entry
; ZVFHMIN-NEXT:    vsetivli zero, 4, e16, mf2, ta, ma
; ZVFHMIN-NEXT:    vfwcvt.f.f.v v10, v9
; ZVFHMIN-NEXT:    vfwcvt.f.f.v v9, v8
; ZVFHMIN-NEXT:    vsetvli zero, zero, e32, m1, ta, ma
; ZVFHMIN-NEXT:    vfmin.vv v9, v9, v10
; ZVFHMIN-NEXT:    vsetvli zero, zero, e16, mf2, ta, ma
; ZVFHMIN-NEXT:    vfncvt.f.f.w v8, v9
; ZVFHMIN-NEXT:    ret
entry:
  %c = call <4 x half> @llvm.minimumnum.v4f16(<4 x half> %a, <4 x half> %b)
  ret <4 x half> %c
}

define <8 x half> @min_v8f16(<8 x half> %a, <8 x half> %b) {
; ZVFH-LABEL: min_v8f16:
; ZVFH:       # %bb.0: # %entry
; ZVFH-NEXT:    vsetivli zero, 8, e16, m1, ta, ma
; ZVFH-NEXT:    vfmin.vv v8, v8, v9
; ZVFH-NEXT:    ret
;
; ZVFHMIN-LABEL: min_v8f16:
; ZVFHMIN:       # %bb.0: # %entry
; ZVFHMIN-NEXT:    vsetivli zero, 8, e16, m1, ta, ma
; ZVFHMIN-NEXT:    vfwcvt.f.f.v v10, v9
; ZVFHMIN-NEXT:    vfwcvt.f.f.v v12, v8
; ZVFHMIN-NEXT:    vsetvli zero, zero, e32, m2, ta, ma
; ZVFHMIN-NEXT:    vfmin.vv v10, v12, v10
; ZVFHMIN-NEXT:    vsetvli zero, zero, e16, m1, ta, ma
; ZVFHMIN-NEXT:    vfncvt.f.f.w v8, v10
; ZVFHMIN-NEXT:    ret
entry:
  %c = call <8 x half> @llvm.minimumnum.v8f16(<8 x half> %a, <8 x half> %b)
  ret <8 x half> %c
}

define <9 x half> @min_v9f16(<9 x half> %a, <9 x half> %b) {
; ZVFH-LABEL: min_v9f16:
; ZVFH:       # %bb.0: # %entry
; ZVFH-NEXT:    vsetivli zero, 16, e16, m2, ta, ma
; ZVFH-NEXT:    vfmin.vv v8, v8, v10
; ZVFH-NEXT:    ret
;
; ZVFHMIN-LABEL: min_v9f16:
; ZVFHMIN:       # %bb.0: # %entry
; ZVFHMIN-NEXT:    vsetivli zero, 16, e16, m2, ta, ma
; ZVFHMIN-NEXT:    vfwcvt.f.f.v v12, v10
; ZVFHMIN-NEXT:    vfwcvt.f.f.v v16, v8
; ZVFHMIN-NEXT:    vsetvli zero, zero, e32, m4, ta, ma
; ZVFHMIN-NEXT:    vfmin.vv v12, v16, v12
; ZVFHMIN-NEXT:    vsetvli zero, zero, e16, m2, ta, ma
; ZVFHMIN-NEXT:    vfncvt.f.f.w v8, v12
; ZVFHMIN-NEXT:    ret
entry:
  %c = call <9 x half> @llvm.minimumnum.v9f16(<9 x half> %a, <9 x half> %b)
  ret <9 x half> %c
}

define <16 x half> @min_v16f16(<16 x half> %a, <16 x half> %b) {
; ZVFH-LABEL: min_v16f16:
; ZVFH:       # %bb.0: # %entry
; ZVFH-NEXT:    vsetivli zero, 16, e16, m2, ta, ma
; ZVFH-NEXT:    vfmin.vv v8, v8, v10
; ZVFH-NEXT:    ret
;
; ZVFHMIN-LABEL: min_v16f16:
; ZVFHMIN:       # %bb.0: # %entry
; ZVFHMIN-NEXT:    vsetivli zero, 16, e16, m2, ta, ma
; ZVFHMIN-NEXT:    vfwcvt.f.f.v v12, v10
; ZVFHMIN-NEXT:    vfwcvt.f.f.v v16, v8
; ZVFHMIN-NEXT:    vsetvli zero, zero, e32, m4, ta, ma
; ZVFHMIN-NEXT:    vfmin.vv v12, v16, v12
; ZVFHMIN-NEXT:    vsetvli zero, zero, e16, m2, ta, ma
; ZVFHMIN-NEXT:    vfncvt.f.f.w v8, v12
; ZVFHMIN-NEXT:    ret
entry:
  %c = call <16 x half> @llvm.minimumnum.v16f16(<16 x half> %a, <16 x half> %b)
  ret <16 x half> %c
}
