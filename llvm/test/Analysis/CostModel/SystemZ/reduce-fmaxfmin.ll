; RUN: opt < %s -mtriple=systemz-unknown -mcpu=z13 -passes="print<cost-model>" -cost-kind=throughput 2>&1 -disable-output | FileCheck %s

define void @reducemax(ptr %src, ptr %dst) {
; CHECK-LABEL: 'reducemax'
; CHECK:  Cost Model: Found an estimated cost of 2 for instruction: %R2_64 = call double @llvm.vector.reduce.fmax.v2f64(<2 x double> %V2_64)
; CHECK:  Cost Model: Found an estimated cost of 3 for instruction: %R4_64 = call double @llvm.vector.reduce.fmax.v4f64(<4 x double> %V4_64)
; CHECK:  Cost Model: Found an estimated cost of 5 for instruction: %R8_64 = call double @llvm.vector.reduce.fmax.v8f64(<8 x double> %V8_64)
; CHECK:  Cost Model: Found an estimated cost of 9 for instruction: %R16_64 = call double @llvm.vector.reduce.fmax.v16f64(<16 x double> %V16_64)
; CHECK:  Cost Model: Found an estimated cost of 2 for instruction: %R2_32 = call float @llvm.vector.reduce.fmax.v2f32(<2 x float> %V2_32)
; CHECK:  Cost Model: Found an estimated cost of 6 for instruction: %R4_32 = call float @llvm.vector.reduce.fmax.v4f32(<4 x float> %V4_32)
; CHECK:  Cost Model: Found an estimated cost of 7 for instruction: %R8_32 = call float @llvm.vector.reduce.fmax.v8f32(<8 x float> %V8_32)
; CHECK:  Cost Model: Found an estimated cost of 9 for instruction: %R16_32 = call float @llvm.vector.reduce.fmax.v16f32(<16 x float> %V16_32)

  ; REDUCEUMAX64

  %V2_64 = load <2 x double>, ptr %src, align 8
  %R2_64 = call double @llvm.vector.reduce.fmax.v2f64(<2 x double> %V2_64)
  store volatile double %R2_64, ptr %dst, align 4

  %V4_64 = load <4 x double>, ptr %src, align 8
  %R4_64 = call double @llvm.vector.reduce.fmax.v4f64(<4 x double> %V4_64)
  store volatile double %R4_64, ptr %dst, align 4

  %V8_64 = load <8 x double>, ptr %src, align 8
  %R8_64 = call double @llvm.vector.reduce.fmax.v8f64(<8 x double> %V8_64)
  store volatile double %R8_64, ptr %dst, align 4

  %V16_64 = load <16 x double>, ptr %src, align 8
  %R16_64 = call double @llvm.vector.reduce.fmax.v16f64(<16 x double> %V16_64)
  store volatile double %R16_64, ptr %dst, align 4

  ; REDUCEUMAX32

  %V2_32 = load <2 x float>, ptr %src, align 8
  %R2_32 = call float @llvm.vector.reduce.fmax.v2f32(<2 x float> %V2_32)
  store volatile float %R2_32, ptr %dst, align 4

  %V4_32 = load <4 x float>, ptr %src, align 8
  %R4_32 = call float @llvm.vector.reduce.fmax.v4f32(<4 x float> %V4_32)
  store volatile float %R4_32, ptr %dst, align 4

  %V8_32 = load <8 x float>, ptr %src, align 8
  %R8_32 = call float @llvm.vector.reduce.fmax.v8f32(<8 x float> %V8_32)
  store volatile float %R8_32, ptr %dst, align 4

  %V16_32 = load <16 x float>, ptr %src, align 8
  %R16_32 = call float @llvm.vector.reduce.fmax.v16f32(<16 x float> %V16_32)
  store volatile float %R16_32, ptr %dst, align 4

  ret void
}

define void @reducemin(ptr %src, ptr %dst) {
; CHECK-LABEL: 'reducemin'
; CHECK:  Cost Model: Found an estimated cost of 2 for instruction: %R2_64 = call double @llvm.vector.reduce.fmin.v2f64(<2 x double> %V2_64)
; CHECK:  Cost Model: Found an estimated cost of 3 for instruction: %R4_64 = call double @llvm.vector.reduce.fmin.v4f64(<4 x double> %V4_64)
; CHECK:  Cost Model: Found an estimated cost of 5 for instruction: %R8_64 = call double @llvm.vector.reduce.fmin.v8f64(<8 x double> %V8_64)
; CHECK:  Cost Model: Found an estimated cost of 9 for instruction: %R16_64 = call double @llvm.vector.reduce.fmin.v16f64(<16 x double> %V16_64)
; CHECK:  Cost Model: Found an estimated cost of 2 for instruction: %R2_32 = call float @llvm.vector.reduce.fmin.v2f32(<2 x float> %V2_32)
; CHECK:  Cost Model: Found an estimated cost of 6 for instruction: %R4_32 = call float @llvm.vector.reduce.fmin.v4f32(<4 x float> %V4_32)
; CHECK:  Cost Model: Found an estimated cost of 7 for instruction: %R8_32 = call float @llvm.vector.reduce.fmin.v8f32(<8 x float> %V8_32)
; CHECK:  Cost Model: Found an estimated cost of 9 for instruction: %R16_32 = call float @llvm.vector.reduce.fmin.v16f32(<16 x float> %V16_32)

  ; REDUCEUMIN64

  %V2_64 = load <2 x double>, ptr %src, align 8
  %R2_64 = call double @llvm.vector.reduce.fmin.v2f64(<2 x double> %V2_64)
  store volatile double %R2_64, ptr %dst, align 4

  %V4_64 = load <4 x double>, ptr %src, align 8
  %R4_64 = call double @llvm.vector.reduce.fmin.v4f64(<4 x double> %V4_64)
  store volatile double %R4_64, ptr %dst, align 4

  %V8_64 = load <8 x double>, ptr %src, align 8
  %R8_64 = call double @llvm.vector.reduce.fmin.v8f64(<8 x double> %V8_64)
  store volatile double %R8_64, ptr %dst, align 4

  %V16_64 = load <16 x double>, ptr %src, align 8
  %R16_64 = call double @llvm.vector.reduce.fmin.v16f64(<16 x double> %V16_64)
  store volatile double %R16_64, ptr %dst, align 4

  ; REDUCEUMIN32

  %V2_32 = load <2 x float>, ptr %src, align 8
  %R2_32 = call float @llvm.vector.reduce.fmin.v2f32(<2 x float> %V2_32)
  store volatile float %R2_32, ptr %dst, align 4

  %V4_32 = load <4 x float>, ptr %src, align 8
  %R4_32 = call float @llvm.vector.reduce.fmin.v4f32(<4 x float> %V4_32)
  store volatile float %R4_32, ptr %dst, align 4

  %V8_32 = load <8 x float>, ptr %src, align 8
  %R8_32 = call float @llvm.vector.reduce.fmin.v8f32(<8 x float> %V8_32)
  store volatile float %R8_32, ptr %dst, align 4

  %V16_32 = load <16 x float>, ptr %src, align 8
  %R16_32 = call float @llvm.vector.reduce.fmin.v16f32(<16 x float> %V16_32)
  store volatile float %R16_32, ptr %dst, align 4

  ret void
}

declare double @llvm.vector.reduce.fmax.v2f64(<2 x double>)
declare double @llvm.vector.reduce.fmax.v4f64(<4 x double>)
declare double @llvm.vector.reduce.fmax.v8f64(<8 x double>)
declare double @llvm.vector.reduce.fmax.v16f64(<16 x double>)
declare float @llvm.vector.reduce.fmax.v2f32(<2 x float>)
declare float @llvm.vector.reduce.fmax.v4f32(<4 x float>)
declare float @llvm.vector.reduce.fmax.v8f32(<8 x float>)
declare float @llvm.vector.reduce.fmax.v16f32(<16 x float>)

declare double @llvm.vector.reduce.fmin.v2f64(<2 x double>)
declare double @llvm.vector.reduce.fmin.v4f64(<4 x double>)
declare double @llvm.vector.reduce.fmin.v8f64(<8 x double>)
declare double @llvm.vector.reduce.fmin.v16f64(<16 x double>)
declare float @llvm.vector.reduce.fmin.v2f32(<2 x float>)
declare float @llvm.vector.reduce.fmin.v4f32(<4 x float>)
declare float @llvm.vector.reduce.fmin.v8f32(<8 x float>)
declare float @llvm.vector.reduce.fmin.v16f32(<16 x float>)


define void @reducemaximum(ptr %src, ptr %dst) {
; CHECK-LABEL: 'reducemaximum'
; CHECK:  Cost Model: Found an estimated cost of 2 for instruction: %R2_64 = call double @llvm.vector.reduce.fmaximum.v2f64(<2 x double> %V2_64)
; CHECK:  Cost Model: Found an estimated cost of 3 for instruction: %R4_64 = call double @llvm.vector.reduce.fmaximum.v4f64(<4 x double> %V4_64)
; CHECK:  Cost Model: Found an estimated cost of 5 for instruction: %R8_64 = call double @llvm.vector.reduce.fmaximum.v8f64(<8 x double> %V8_64)
; CHECK:  Cost Model: Found an estimated cost of 9 for instruction: %R16_64 = call double @llvm.vector.reduce.fmaximum.v16f64(<16 x double> %V16_64)
; CHECK:  Cost Model: Found an estimated cost of 2 for instruction: %R2_32 = call float @llvm.vector.reduce.fmaximum.v2f32(<2 x float> %V2_32)
; CHECK:  Cost Model: Found an estimated cost of 6 for instruction: %R4_32 = call float @llvm.vector.reduce.fmaximum.v4f32(<4 x float> %V4_32)
; CHECK:  Cost Model: Found an estimated cost of 7 for instruction: %R8_32 = call float @llvm.vector.reduce.fmaximum.v8f32(<8 x float> %V8_32)
; CHECK:  Cost Model: Found an estimated cost of 9 for instruction: %R16_32 = call float @llvm.vector.reduce.fmaximum.v16f32(<16 x float> %V16_32)

  ; REDUCEUMAX64

  %V2_64 = load <2 x double>, ptr %src, align 8
  %R2_64 = call double @llvm.vector.reduce.fmaximum.v2f64(<2 x double> %V2_64)
  store volatile double %R2_64, ptr %dst, align 4

  %V4_64 = load <4 x double>, ptr %src, align 8
  %R4_64 = call double @llvm.vector.reduce.fmaximum.v4f64(<4 x double> %V4_64)
  store volatile double %R4_64, ptr %dst, align 4

  %V8_64 = load <8 x double>, ptr %src, align 8
  %R8_64 = call double @llvm.vector.reduce.fmaximum.v8f64(<8 x double> %V8_64)
  store volatile double %R8_64, ptr %dst, align 4

  %V16_64 = load <16 x double>, ptr %src, align 8
  %R16_64 = call double @llvm.vector.reduce.fmaximum.v16f64(<16 x double> %V16_64)
  store volatile double %R16_64, ptr %dst, align 4

  ; REDUCEUMAX32

  %V2_32 = load <2 x float>, ptr %src, align 8
  %R2_32 = call float @llvm.vector.reduce.fmaximum.v2f32(<2 x float> %V2_32)
  store volatile float %R2_32, ptr %dst, align 4

  %V4_32 = load <4 x float>, ptr %src, align 8
  %R4_32 = call float @llvm.vector.reduce.fmaximum.v4f32(<4 x float> %V4_32)
  store volatile float %R4_32, ptr %dst, align 4

  %V8_32 = load <8 x float>, ptr %src, align 8
  %R8_32 = call float @llvm.vector.reduce.fmaximum.v8f32(<8 x float> %V8_32)
  store volatile float %R8_32, ptr %dst, align 4

  %V16_32 = load <16 x float>, ptr %src, align 8
  %R16_32 = call float @llvm.vector.reduce.fmaximum.v16f32(<16 x float> %V16_32)
  store volatile float %R16_32, ptr %dst, align 4

  ret void
}

define void @reduceminimum(ptr %src, ptr %dst) {
; CHECK-LABEL: 'reduceminimum'
; CHECK:  Cost Model: Found an estimated cost of 2 for instruction: %R2_64 = call double @llvm.vector.reduce.fminimum.v2f64(<2 x double> %V2_64)
; CHECK:  Cost Model: Found an estimated cost of 3 for instruction: %R4_64 = call double @llvm.vector.reduce.fminimum.v4f64(<4 x double> %V4_64)
; CHECK:  Cost Model: Found an estimated cost of 5 for instruction: %R8_64 = call double @llvm.vector.reduce.fminimum.v8f64(<8 x double> %V8_64)
; CHECK:  Cost Model: Found an estimated cost of 9 for instruction: %R16_64 = call double @llvm.vector.reduce.fminimum.v16f64(<16 x double> %V16_64)
; CHECK:  Cost Model: Found an estimated cost of 2 for instruction: %R2_32 = call float @llvm.vector.reduce.fminimum.v2f32(<2 x float> %V2_32)
; CHECK:  Cost Model: Found an estimated cost of 6 for instruction: %R4_32 = call float @llvm.vector.reduce.fminimum.v4f32(<4 x float> %V4_32)
; CHECK:  Cost Model: Found an estimated cost of 7 for instruction: %R8_32 = call float @llvm.vector.reduce.fminimum.v8f32(<8 x float> %V8_32)
; CHECK:  Cost Model: Found an estimated cost of 9 for instruction: %R16_32 = call float @llvm.vector.reduce.fminimum.v16f32(<16 x float> %V16_32)

  ; REDUCEUMIN64

  %V2_64 = load <2 x double>, ptr %src, align 8
  %R2_64 = call double @llvm.vector.reduce.fminimum.v2f64(<2 x double> %V2_64)
  store volatile double %R2_64, ptr %dst, align 4

  %V4_64 = load <4 x double>, ptr %src, align 8
  %R4_64 = call double @llvm.vector.reduce.fminimum.v4f64(<4 x double> %V4_64)
  store volatile double %R4_64, ptr %dst, align 4

  %V8_64 = load <8 x double>, ptr %src, align 8
  %R8_64 = call double @llvm.vector.reduce.fminimum.v8f64(<8 x double> %V8_64)
  store volatile double %R8_64, ptr %dst, align 4

  %V16_64 = load <16 x double>, ptr %src, align 8
  %R16_64 = call double @llvm.vector.reduce.fminimum.v16f64(<16 x double> %V16_64)
  store volatile double %R16_64, ptr %dst, align 4

  ; REDUCEUMIN32

  %V2_32 = load <2 x float>, ptr %src, align 8
  %R2_32 = call float @llvm.vector.reduce.fminimum.v2f32(<2 x float> %V2_32)
  store volatile float %R2_32, ptr %dst, align 4

  %V4_32 = load <4 x float>, ptr %src, align 8
  %R4_32 = call float @llvm.vector.reduce.fminimum.v4f32(<4 x float> %V4_32)
  store volatile float %R4_32, ptr %dst, align 4

  %V8_32 = load <8 x float>, ptr %src, align 8
  %R8_32 = call float @llvm.vector.reduce.fminimum.v8f32(<8 x float> %V8_32)
  store volatile float %R8_32, ptr %dst, align 4

  %V16_32 = load <16 x float>, ptr %src, align 8
  %R16_32 = call float @llvm.vector.reduce.fminimum.v16f32(<16 x float> %V16_32)
  store volatile float %R16_32, ptr %dst, align 4

  ret void
}

declare double @llvm.vector.reduce.fmaximum.v2f64(<2 x double>)
declare double @llvm.vector.reduce.fmaximum.v4f64(<4 x double>)
declare double @llvm.vector.reduce.fmaximum.v8f64(<8 x double>)
declare double @llvm.vector.reduce.fmaximum.v16f64(<16 x double>)
declare float @llvm.vector.reduce.fmaximum.v2f32(<2 x float>)
declare float @llvm.vector.reduce.fmaximum.v4f32(<4 x float>)
declare float @llvm.vector.reduce.fmaximum.v8f32(<8 x float>)
declare float @llvm.vector.reduce.fmaximum.v16f32(<16 x float>)

declare double @llvm.vector.reduce.fminimum.v2f64(<2 x double>)
declare double @llvm.vector.reduce.fminimum.v4f64(<4 x double>)
declare double @llvm.vector.reduce.fminimum.v8f64(<8 x double>)
declare double @llvm.vector.reduce.fminimum.v16f64(<16 x double>)
declare float @llvm.vector.reduce.fminimum.v2f32(<2 x float>)
declare float @llvm.vector.reduce.fminimum.v4f32(<4 x float>)
declare float @llvm.vector.reduce.fminimum.v8f32(<8 x float>)
declare float @llvm.vector.reduce.fminimum.v16f32(<16 x float>)
