#include "llvm/ADT/SmallSet.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/TableGen/Record.h"
#include "llvm/TableGen/TableGenBackend.h"
#include <cstdio>
#include <memory>

using namespace llvm;

typedef const std::pair<const std::string, std::unique_ptr<Record>> ClassEntry;

namespace {

// return the name of the var that initializes the given bit
static StringRef getSourceVarName(const VarBitInit *Bit) {
  const Init *BitVar = Bit->getBitVar();
  if (const auto *Var = dyn_cast_or_null<VarInit>(BitVar)) {
    StringRef Name = Var->getName();

    // If the name is compound, return the second component
    if (Name.contains(':'))
      return Name.split(':').second;

    // otherwise, just return the name
    return Name;
  }

  // If none of the above conversions apply, return the empty string
  return "";
}

static void writeInstAssignment(raw_ostream& OS, StringRef Name, unsigned I1, unsigned I2, unsigned V1, unsigned V2) {
  if (Name != "") {
    OS << "  - Bits " << I1 << ".." << I2
        << " := " << Name;
    if (Name != "Unset") {
      if (V1 - V2 != 0)
        OS << "{" << V2 << "-"
            << V1 << "}\n";
      else
        OS << "{" << V1 << "}\n";
    }
    else
      OS << "\n";
  }
}

static void enumerateInstFields(const BitsInit * In, raw_ostream& OS) {
    StringRef CurrentVar = "";
    unsigned CurrentVarStartIndex = 0;
    unsigned CurrentVarSourceIndexStart = 0;
    unsigned CurrentVarSourceIndexEnd = 0;
    ArrayRef<const Init *> InstBits = In->getBits();
    for (unsigned Index = 0; Index < InstBits.size(); ++Index) {
      const Init *Bit = InstBits[Index];
      if (const auto *VBI = dyn_cast_or_null<VarBitInit>(Bit)) {
        StringRef Name = getSourceVarName(VBI);
        if (Name == "")
          Name = "Unset";
        if (Name != CurrentVar) {
          writeInstAssignment(OS, CurrentVar, CurrentVarStartIndex, Index - 1, CurrentVarSourceIndexStart, CurrentVarSourceIndexEnd);
          CurrentVar = Name;
          CurrentVarStartIndex = Index;
          CurrentVarSourceIndexStart = VBI->getBitNum();
          CurrentVarSourceIndexEnd = VBI->getBitNum();
        }
        else if (Index == InstBits.size() - 1) {
            CurrentVarSourceIndexEnd = VBI->getBitNum();
            writeInstAssignment(OS, CurrentVar, CurrentVarStartIndex, Index, CurrentVarSourceIndexStart, CurrentVarSourceIndexEnd);
        } else {
          CurrentVarSourceIndexEnd = VBI->getBitNum();
        }
      }
    }
}

static SmallVector<const Record*> discoverInstructions(const RecordKeeper &RK, StringRef InstFormat) {
  SmallVector<const Record*> Insts;
  for (const Record* R : RK.getAllDerivedDefinitionsIfDefined(InstFormat)) {
    bool IsPseudo = R->getValueAsBit("isPseudo");
    bool IsCodeGenOnly = R->getValueAsBit("isCodeGenOnly");
    bool IsAsmParserOnly = R->getValueAsBit("isAsmParserOnly");
    if (IsPseudo || IsCodeGenOnly || IsAsmParserOnly)
      continue;
    Insts.push_back(R);
  }
  return Insts;
}

static bool isRegisterType(StringRef S) {
  return (S.starts_with("GR") || S.starts_with("ADDR") || S.starts_with("FP") ||
          S.starts_with("AR"));
}

typedef struct {
  unsigned short full_width;
  unsigned char signeness_char;
  unsigned short bit_width;
} ImmediateType;

unsigned char mergeSignedness(unsigned char L, unsigned char R) {
  if (L == R)
    return L;
  return 'x';
}

static bool parseImmediateType(StringRef Type, ImmediateType& Imm) {
  // type must start with "imm"
  if (!Type.consume_front("imm"))
    return false;
  // parse Integer for full_width
  if (Type.consumeInteger(10, Imm.full_width))
    return false;
  // merge signedness char: (z,z = z, s,s = s, z,s = s,z = x)
  Imm.signeness_char = mergeSignedness(Imm.signeness_char, Type.take_front(1)[0]);
  // 'x' must separate signedness char from bit width
  Type = Type.drop_front(1);
  // dbgs() << "Remaining Type pre-consuming x: " << Type << "\n";
  if (!Type.consume_front('x'))
    return false;
  // dbgs() << "Remaining Type pre-bit-width parsing: " << Type << "\n";
  if (!Type.consumeInteger(10, Imm.bit_width))
    return false;
  return true;
}

static bool mergeImmediateType(ImmediateType& Target, ImmediateType& Source) {
  Target.full_width = std::max(Target.full_width, Source.full_width);
  if (Target.bit_width != Source.bit_width)
    return false;
  Target.signeness_char = mergeSignedness(Target.signeness_char, Source.signeness_char);
  return true;
}

static std::string immediateAsmType(ImmediateType& Imm) {
  // StringRef S;
  char S;
  if (Imm.signeness_char == 'z')
    S = 'U';
  else // s,x
    S = toUpper(Imm.signeness_char);
  return (Twine(S) + "Imm" + Twine(Imm.bit_width)).str();
}

static std::string immediateTypeToString(ImmediateType& Imm) {
  return ("imm" + Twine(Imm.full_width) + Twine(Imm.signeness_char) + "x" + Twine(Imm.bit_width)).str();
}

static const Record *
deriveAsmOperandName(const RecordKeeper &RK,
                     SmallSet<std::string, 4> &OperandTypes) {
  StringRef FirstType = *OperandTypes.begin();
  if (isRegisterType(FirstType)) {
    // Register Operand - just use any register
    for (StringRef S : OperandTypes)
      if (!isRegisterType(S)) {
        dbgs() << S << " is not a register type.\n";
        return nullptr;
      }
    return RK.getDef("AnyReg");
  }
  if (FirstType.starts_with("imm32") || FirstType.starts_with("imm64")) {
    ImmediateType Imm;
    parseImmediateType(FirstType, Imm);
    for (StringRef Type : OperandTypes) {
      ImmediateType Now;
      parseImmediateType(Type, Now);
      if (!mergeImmediateType(Imm, Now)) {
        dbgs() << ("Could not merge immediate types " + FirstType + " (Imm=" + immediateTypeToString(Imm) + ", Now =" + immediateTypeToString(Now) + ")\n").str().c_str();
        return nullptr;
      }
    }
    dbgs() << "derivedAsmOperandName = " << immediateTypeToString(Imm) << ", " << immediateAsmType(Imm) << "\n";
    return RK.getClass(immediateAsmType(Imm));
  }
  return nullptr;
}

static void emitInsnDirectiveMatchTable(const RecordKeeper &RK,
                                        raw_ostream &OS) {
  // Get all SystemZ InstructionFormats
  const auto &AllClasses = RK.getClasses();
  const Record *InstSystemZ = RK.getClass("InstSystemZ");
  SmallVector<const Record *> InstructionFormats;

  // Output them
  for (ClassEntry &Entry : AllClasses) {
    const std::string &Name = Entry.first;
    auto &ClassRec = Entry.second;
    if (ClassRec->hasDirectSuperClass(InstSystemZ) &&
    ClassRec->getName().starts_with("Inst"))
    InstructionFormats.push_back(RK.getClass(Name));
  }
  OS << "## Instruction Formats\n";
  for (const Record *Format : InstructionFormats) {
    OS << "### " << Format->getName() << "\n";
    OS << "#### Composition of `Inst` Field\n";
    enumerateInstFields(Format->getValueAsBitsInit("Inst"), OS);
    OS << "\n";
    OS << "#### Derived Instructions\n";
    SmallVector<const Record*> DerivedInsts = discoverInstructions(RK, Format->getName());
    StringMap<SmallSet<std::string, 4>> OpNameToTypeList;
    for (const Record* R : DerivedInsts) {
      OS << "  - " << R->getName();
      try {
        const DagInit* Ins = R->getValueAsDag("InOperandList");
        OS << "( ";
        for (unsigned I = 0; I < Ins->getNumArgs(); ++I) {
          const StringInit* ArgName = Ins->getArgName(I);
          if (const DefInit * DefOp = dyn_cast_or_null<DefInit>(Ins->getArg(I))) {
            const Record * OpRecord = DefOp->getDef();
            StringRef TypeName = OpRecord->getValueAsDef("ParserMatchClass")->getName();
            OpNameToTypeList[ArgName->getAsString()].insert(std::string(TypeName));
            OS << DefOp->getAsString() << "(" << ArgName->getAsString() << ")" << ", ";
          } else if (const DagInit * DagOp = dyn_cast_or_null<DagInit>(Ins->getArg(I))) {
            if (const DefInit *DefOp = dyn_cast_or_null<DefInit>(DagOp->getOperator())) {
              OpNameToTypeList[ArgName->getAsString()].insert(std::string(DefOp->getAsString()));
              OS << DefOp->getAsString() << "[ ";
              for (unsigned J = 0; J < DagOp->getNumArgs(); ++J) {
                const StringInit* Name = DagOp->getArgName(J);
                OS << Name->getAsString() << " ";
              }
              OS << "], ";
            } else {
              OS << "|Unparsed::" << DagOp->getAsString() << "|, ";
            }
          } else {
            OS << "|Unparsed::" << Ins->getArg(I)->getAsString() << "|, ";
          }
        }
        OS << ")\n";
      }
      catch (const std::exception& E) {
        OS << "(Could not query InOperandList)\n";
      }
    }
    OS << "\n#### Observed Operands:\n";
    for (StringRef Name : OpNameToTypeList.keys()) {
      auto TypeSet = OpNameToTypeList[Name];
      OS << "  - " << Name << " ( ";
      for (StringRef Type : TypeSet) {
        OS << Type << " ";
      }
      OS << ")";
      if (TypeSet.size() > 1)
        OS << " <-- NEEDS MERGE";
      OS << "\n";
    }
  }
}
} // namespace

static TableGen::Emitter::Opt
    X("gen-insn-directive-match-table", emitInsnDirectiveMatchTable,
      "Generate SystemZ's match table for insn directives.");