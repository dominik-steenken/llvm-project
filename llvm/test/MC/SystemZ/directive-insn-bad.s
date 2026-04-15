# RUN: not llvm-mc -triple s390x-linux-gnu %s 2>&1 | FileCheck %s

# CHECK: error: unrecognized format
# CHECK: .insn not_a_format,0x0
        .insn not_a_format,0x0

# CHECK: error: unexpected token in directive
# CHECK: .insn rr,0x0101
        .insn rr,0x0101

# CHECK: error: unexpected token at start of statement
# CHECK: .insn e,0x0101,0
        .insn e,0x0101,0

# CHECK: error: unexpected token in directive
# CHECK: .insn rr,0x1800,0
        .insn rr,0x1800,0

# CHECK: error: unexpected token at start of statement
# CHECK: .insn rr,0x1800,%r1,0(%r2)
        .insn rr,0x1800,%r1,0(%r2)

# CHECK: error: unknown token in expression
# CHECK: .insn rxy_a,0xe30000000016,%r1,%r2,0
        .insn rxy_a,0xe30000000016,%r1,%r2,0

# CHECK: error: unknown token in expression
# CHECK: .insn ril_c,0xc00400000000,%r1,0
        .insn ril_c,0xc00400000000,%r1,0

# CHECK: error: invalid operand for instruction
# CHECK: .insn vri_e,0xe7000000004a,%r1,%v2,837,7,6
        .insn vri_e,0xe7000000004a,%r1,%v2,837,7,6

