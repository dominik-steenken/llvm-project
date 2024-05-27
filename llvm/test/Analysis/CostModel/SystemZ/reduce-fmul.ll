; RUN: opt < %s -mtriple=systemz-unknown -mcpu=z13 -passes="print<cost-model>" -cost-kind=throughput 2>&1 -disable-output | FileCheck %s

define void @reduce(float %fstart, double %dstart, ptr %src, ptr %dst) {
; CHECK-LABEL: 'reduce'
; CHECK:  Cost Model: Found an estimated cost of 3 for instruction: %R2_64 = call double @llvm.vector.reduce.fmul.v2f64(double %dstart, <2 x double> %V2_64)
; CHECK:  Cost Model: Found an estimated cost of 6 for instruction: %R4_64 = call double @llvm.vector.reduce.fmul.v4f64(double %dstart, <4 x double> %V4_64)
; CHECK:  Cost Model: Found an estimated cost of 12 for instruction: %R8_64 = call double @llvm.vector.reduce.fmul.v8f64(double %dstart, <8 x double> %V8_64)
; CHECK:  Cost Model: Found an estimated cost of 24 for instruction: %R16_64 = call double @llvm.vector.reduce.fmul.v16f64(double %dstart, <16 x double> %V16_64)
; CHECK:  Cost Model: Found an estimated cost of 3 for instruction: %R2_32 = call float @llvm.vector.reduce.fmul.v2f32(float %fstart, <2 x float> %V2_32)
; CHECK:  Cost Model: Found an estimated cost of 7 for instruction: %R4_32 = call float @llvm.vector.reduce.fmul.v4f32(float %fstart, <4 x float> %V4_32)
; CHECK:  Cost Model: Found an estimated cost of 14 for instruction: %R8_32 = call float @llvm.vector.reduce.fmul.v8f32(float %fstart, <8 x float> %V8_32)
; CHECK:  Cost Model: Found an estimated cost of 28 for instruction: %R16_32 = call float @llvm.vector.reduce.fmul.v16f32(float %fstart, <16 x float> %V16_32)

  ; REDUCEFADDDOUBLE

  %V2_64 = load <2 x double>, ptr %src, align 8
  %R2_64 = call double @llvm.vector.reduce.fmul.v2f64(double %dstart, <2 x double> %V2_64)
  store volatile double %R2_64, ptr %dst, align 4

  %V4_64 = load <4 x double>, ptr %src, align 8
  %R4_64 = call double @llvm.vector.reduce.fmul.v4f64(double %dstart, <4 x double> %V4_64)
  store volatile double %R4_64, ptr %dst, align 4

  %V8_64 = load <8 x double>, ptr %src, align 8
  %R8_64 = call double @llvm.vector.reduce.fmul.v8f64(double %dstart, <8 x double> %V8_64)
  store volatile double %R8_64, ptr %dst, align 4

  %V16_64 = load <16 x double>, ptr %src, align 8
  %R16_64 = call double @llvm.vector.reduce.fmul.v16f64(double %dstart, <16 x double> %V16_64)
  store volatile double %R16_64, ptr %dst, align 4

  ; REDUCEFADDFLOAT

  %V2_32 = load <2 x float>, ptr %src, align 8
  %R2_32 = call float @llvm.vector.reduce.fmul.v2f32(float %fstart, <2 x float> %V2_32)
  store volatile float %R2_32, ptr %dst, align 4

  %V4_32 = load <4 x float>, ptr %src, align 8
  %R4_32 = call float @llvm.vector.reduce.fmul.v4f32(float %fstart, <4 x float> %V4_32)
  store volatile float %R4_32, ptr %dst, align 4

  %V8_32 = load <8 x float>, ptr %src, align 8
  %R8_32 = call float @llvm.vector.reduce.fmul.v8f32(float %fstart, <8 x float> %V8_32)
  store volatile float %R8_32, ptr %dst, align 4

  %V16_32 = load <16 x float>, ptr %src, align 8
  %R16_32 = call float @llvm.vector.reduce.fmul.v16f32(float %fstart, <16 x float> %V16_32)
  store volatile float %R16_32, ptr %dst, align 4

  ret void
}

declare double @llvm.vector.reduce.fmul.v2f64(double, <2 x double>)
declare double @llvm.vector.reduce.fmul.v4f64(double, <4 x double>)
declare double @llvm.vector.reduce.fmul.v8f64(double, <8 x double>)
declare double @llvm.vector.reduce.fmul.v16f64(double, <16 x double>)
declare float @llvm.vector.reduce.fmul.v2f32(float, <2 x float>)
declare float @llvm.vector.reduce.fmul.v4f32(float, <4 x float>)
declare float @llvm.vector.reduce.fmul.v8f32(float, <8 x float>)
declare float @llvm.vector.reduce.fmul.v16f32(float, <16 x float>)
