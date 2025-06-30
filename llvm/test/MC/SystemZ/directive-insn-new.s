# RUN: llvm-mc -triple s390x-linux-gnu -mcpu=zEC12 -filetype=obj %s | \
# RUN: llvm-objdump --mcpu=zEC12 -d - | FileCheck %s

# Test the .insn directive which provides a way of encoding an instruction
# directly. It takes a format, encoding, and operands based on the format.
# This file covers instruction formats newly supported.

#CHECK: 0a bc                 svc 188
  .insn i,0x0a00,0xbc

#CHECK: b2 fa 00 12           niai 1, 2
  .insn ie,0xb2fa0000,0x1,0x2

#CHECK: c5 f1 00 00 10 00  bprp 15, 0x206, 0x2006
  .insn mii,0xc50000000000,15,512,8192
  