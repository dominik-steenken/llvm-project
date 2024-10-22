; RUN: opt < %s -mtriple=systemz-unknown -mcpu=z13 -passes="print<cost-model>" -cost-kind=throughput 2>&1 -disable-output | FileCheck %s

define float @fmuladd_scalar_f32(float %a, float %b, float %c) {
; CHECK-LABEL: 'fmuladd_scalar_f32'
; CHECK:  Cost Model: Found an estimated cost of 1 for instruction: %F = call float @llvm.fmuladd.f32(float %a, float %b, float %c)

  %F = call float @llvm.fmuladd.f32(float %a, float %b, float %c)

  ret float %F
}

define double @fmuladd_scalar_f64(double %a, double %b, double %c) {
; CHECK-LABEL: 'fmuladd_scalar_f64'
; CHECK:  Cost Model: Found an estimated cost of 1 for instruction: %F = call double @llvm.fmuladd.f64(double %a, double %b, double %c)

  %F = call double @llvm.fmuladd.f64(double %a, double %b, double %c)

  ret double %F
}

define void @fmuladd_vector(ptr %src1, ptr %src2, ptr %src3, ptr %dst) {
; CHECK-LABEL: 'fmuladd_vector'
; CHECK:  Cost Model: Found an estimated cost of 1 for instruction: %FD2 = call <2 x float> @llvm.fmuladd.v2f32(<2 x float> %FA2, <2 x float> %FB2, <2 x float> %FC2)
; CHECK:  Cost Model: Found an estimated cost of 1 for instruction: %FD4 = call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %FA4, <4 x float> %FB4, <4 x float> %FC4)
; CHECK:  Cost Model: Found an estimated cost of 2 for instruction: %FD8 = call <8 x float> @llvm.fmuladd.v8f32(<8 x float> %FA8, <8 x float> %FB8, <8 x float> %FC8)
; CHECK:  Cost Model: Found an estimated cost of 4 for instruction: %FD16 = call <16 x float> @llvm.fmuladd.v16f32(<16 x float> %FA16, <16 x float> %FB16, <16 x float> %FC16)
; CHECK:  Cost Model: Found an estimated cost of 1 for instruction: %DD2 = call <2 x double> @llvm.fmuladd.v2f64(<2 x double> %DA2, <2 x double> %DB2, <2 x double> %DC2)
; CHECK:  Cost Model: Found an estimated cost of 2 for instruction: %DD4 = call <4 x double> @llvm.fmuladd.v4f64(<4 x double> %DA4, <4 x double> %DB4, <4 x double> %DC4)
; CHECK:  Cost Model: Found an estimated cost of 4 for instruction: %DD8 = call <8 x double> @llvm.fmuladd.v8f64(<8 x double> %DA8, <8 x double> %DB8, <8 x double> %DC8)
; CHECK:  Cost Model: Found an estimated cost of 8 for instruction: %DD16 = call <16 x double> @llvm.fmuladd.v16f64(<16 x double> %DA16, <16 x double> %DB16, <16 x double> %DC16)

  %FA2 = load <2 x float>, ptr %src1, align 8
  %FB2 = load <2 x float>, ptr %src2, align 8
  %FC2 = load <2 x float>, ptr %src3, align 8
  %FD2 = call <2 x float> @llvm.fmuladd.v2f32(<2 x float> %FA2, <2 x float> %FB2, <2 x float> %FC2)
  store volatile <2 x float> %FD2, ptr %dst, align 4

  %FA4 = load <4 x float>, ptr %src1, align 8
  %FB4 = load <4 x float>, ptr %src2, align 8
  %FC4 = load <4 x float>, ptr %src3, align 8
  %FD4 = call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %FA4, <4 x float> %FB4, <4 x float> %FC4)
  store volatile <4 x float> %FD4, ptr %dst, align 4

  %FA8 = load <8 x float>, ptr %src1, align 8
  %FB8 = load <8 x float>, ptr %src2, align 8
  %FC8 = load <8 x float>, ptr %src3, align 8
  %FD8 = call <8 x float> @llvm.fmuladd.v8f32(<8 x float> %FA8, <8 x float> %FB8, <8 x float> %FC8)
  store volatile <8 x float> %FD8, ptr %dst, align 4

  %FA16 = load <16 x float>, ptr %src1, align 8
  %FB16 = load <16 x float>, ptr %src2, align 8
  %FC16 = load <16 x float>, ptr %src3, align 8
  %FD16 = call <16 x float> @llvm.fmuladd.v16f32(<16 x float> %FA16, <16 x float> %FB16, <16 x float> %FC16)
  store volatile <16 x float> %FD16, ptr %dst, align 4

  %DA2 = load <2 x double>, ptr %src1, align 8
  %DB2 = load <2 x double>, ptr %src2, align 8
  %DC2 = load <2 x double>, ptr %src3, align 8
  %DD2 = call <2 x double> @llvm.fmuladd.v2f64(<2 x double> %DA2, <2 x double> %DB2, <2 x double> %DC2)
  store volatile <2 x double> %DD2, ptr %dst, align 4

  %DA4 = load <4 x double>, ptr %src1, align 8
  %DB4 = load <4 x double>, ptr %src2, align 8
  %DC4 = load <4 x double>, ptr %src3, align 8
  %DD4 = call <4 x double> @llvm.fmuladd.v4f64(<4 x double> %DA4, <4 x double> %DB4, <4 x double> %DC4)
  store volatile <4 x double> %DD4, ptr %dst, align 4

  %DA8 = load <8 x double>, ptr %src1, align 8
  %DB8 = load <8 x double>, ptr %src2, align 8
  %DC8 = load <8 x double>, ptr %src3, align 8
  %DD8 = call <8 x double> @llvm.fmuladd.v8f64(<8 x double> %DA8, <8 x double> %DB8, <8 x double> %DC8)
  store volatile <8 x double> %DD8, ptr %dst, align 4

  %DA16 = load <16 x double>, ptr %src1, align 8
  %DB16 = load <16 x double>, ptr %src2, align 8
  %DC16 = load <16 x double>, ptr %src3, align 8
  %DD16 = call <16 x double> @llvm.fmuladd.v16f64(<16 x double> %DA16, <16 x double> %DB16, <16 x double> %DC16)
  store volatile <16 x double> %DD16, ptr %dst, align 4

  ret void 
}

declare float @llvm.fmuladd.f32(float, float, float)
declare double @llvm.fmuladd.f64(double, double, double)
declare <2 x float> @llvm.fmuladd.v2f32(<2 x float>, <2 x float>, <2 x float>)
declare <4 x float> @llvm.fmuladd.v4f32(<4 x float>, <4 x float>, <4 x float>)
declare <8 x float> @llvm.fmuladd.v8f32(<8 x float>, <8 x float>, <8 x float>)
declare <16 x float> @llvm.fmuladd.v16f32(<16 x float>, <16 x float>, <16 x float>)

declare <2 x double> @llvm.fmuladd.v2f64(<2 x double>, <2 x double>, <2 x double>)
declare <4 x double> @llvm.fmuladd.v4f64(<4 x double>, <4 x double>, <4 x double>)
declare <8 x double> @llvm.fmuladd.v8f64(<8 x double>, <8 x double>, <8 x double>)
declare <16 x double> @llvm.fmuladd.v16f64(<16 x double>, <16 x double>, <16 x double>)
