# RUN: llvm-mc -triple s390x-linux-gnu -filetype=obj %s | \
# RUN: llvm-objdump --mcpu=z17 -d - | FileCheck %s

# Test the .insn directive which provides a way of encoding an instruction
# directly. It takes a format, encoding, and operands based on the format.
# This file covers instruction formats newly supported.

#CHECK: 0a bc                 svc 188
  .insn i,0x0a00,0xbc

