//===--- Record.cpp - Record compiler events ------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "clang-include-cleaner/Record.h"
#include "clang-include-cleaner/Types.h"
#include "clang/AST/ASTConsumer.h"
#include "clang/AST/ASTContext.h"
#include "clang/AST/DeclGroup.h"
#include "clang/Basic/FileEntry.h"
#include "clang/Basic/FileManager.h"
#include "clang/Basic/LLVM.h"
#include "clang/Basic/SourceLocation.h"
#include "clang/Basic/SourceManager.h"
#include "clang/Basic/Specifiers.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Lex/DirectoryLookup.h"
#include "clang/Lex/MacroInfo.h"
#include "clang/Lex/PPCallbacks.h"
#include "clang/Lex/Preprocessor.h"
#include "clang/Tooling/Inclusions/HeaderAnalysis.h"
#include "clang/Tooling/Inclusions/StandardLibrary.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/iterator_range.h"
#include "llvm/Support/Allocator.h"
#include "llvm/Support/Error.h"
#include "llvm/Support/FileSystem/UniqueID.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/StringSaver.h"
#include <algorithm>
#include <assert.h>
#include <memory>
#include <optional>
#include <set>
#include <utility>
#include <vector>

namespace clang::include_cleaner {
namespace {

class PPRecorder : public PPCallbacks {
public:
  PPRecorder(RecordedPP &Recorded, const Preprocessor &PP)
      : Recorded(Recorded), PP(PP), SM(PP.getSourceManager()) {
    for (const auto &Dir : PP.getHeaderSearchInfo().search_dir_range())
      if (Dir.getLookupType() == DirectoryLookup::LT_NormalDir)
        Recorded.Includes.addSearchDirectory(Dir.getDirRef()->getName());
  }

  void FileChanged(SourceLocation Loc, FileChangeReason Reason,
                   SrcMgr::CharacteristicKind FileType,
                   FileID PrevFID) override {
    Active = SM.isWrittenInMainFile(Loc);
  }

  void InclusionDirective(SourceLocation Hash, const Token &IncludeTok,
                          StringRef SpelledFilename, bool IsAngled,
                          CharSourceRange FilenameRange,
                          OptionalFileEntryRef File, StringRef SearchPath,
                          StringRef RelativePath, const Module *SuggestedModule,
                          bool ModuleImported,
                          SrcMgr::CharacteristicKind) override {
    if (!Active)
      return;

    Include I;
    I.HashLocation = Hash;
    I.Resolved = File;
    I.Line = SM.getSpellingLineNumber(Hash);
    I.Spelled = SpelledFilename;
    I.Angled = IsAngled;
    Recorded.Includes.add(I);
  }

  void MacroExpands(const Token &MacroName, const MacroDefinition &MD,
                    SourceRange Range, const MacroArgs *Args) override {
    if (!Active)
      return;
    recordMacroRef(MacroName, *MD.getMacroInfo());
  }

  void MacroDefined(const Token &MacroName, const MacroDirective *MD) override {
    if (!Active)
      return;

    const auto *MI = MD->getMacroInfo();
    // The tokens of a macro definition could refer to a macro.
    // Formally this reference isn't resolved until this macro is expanded,
    // but we want to treat it as a reference anyway.
    for (const auto &Tok : MI->tokens()) {
      auto *II = Tok.getIdentifierInfo();
      // Could this token be a reference to a macro? (Not param to this macro).
      if (!II || !II->hadMacroDefinition() ||
          llvm::is_contained(MI->params(), II))
        continue;
      if (const MacroInfo *MI = PP.getMacroInfo(II))
        recordMacroRef(Tok, *MI);
    }
  }

  void MacroUndefined(const Token &MacroName, const MacroDefinition &MD,
                      const MacroDirective *) override {
    if (!Active)
      return;
    if (const auto *MI = MD.getMacroInfo())
      recordMacroRef(MacroName, *MI);
  }

  void Ifdef(SourceLocation Loc, const Token &MacroNameTok,
             const MacroDefinition &MD) override {
    if (!Active)
      return;
    if (const auto *MI = MD.getMacroInfo())
      recordMacroRef(MacroNameTok, *MI, RefType::Ambiguous);
  }

  void Ifndef(SourceLocation Loc, const Token &MacroNameTok,
              const MacroDefinition &MD) override {
    if (!Active)
      return;
    if (const auto *MI = MD.getMacroInfo())
      recordMacroRef(MacroNameTok, *MI, RefType::Ambiguous);
  }

  using PPCallbacks::Elifdef;
  using PPCallbacks::Elifndef;
  void Elifdef(SourceLocation Loc, const Token &MacroNameTok,
               const MacroDefinition &MD) override {
    if (!Active)
      return;
    if (const auto *MI = MD.getMacroInfo())
      recordMacroRef(MacroNameTok, *MI, RefType::Ambiguous);
  }
  void Elifndef(SourceLocation Loc, const Token &MacroNameTok,
                const MacroDefinition &MD) override {
    if (!Active)
      return;
    if (const auto *MI = MD.getMacroInfo())
      recordMacroRef(MacroNameTok, *MI, RefType::Ambiguous);
  }

  void Defined(const Token &MacroNameTok, const MacroDefinition &MD,
               SourceRange Range) override {
    if (!Active)
      return;
    if (const auto *MI = MD.getMacroInfo())
      recordMacroRef(MacroNameTok, *MI, RefType::Ambiguous);
  }

private:
  void recordMacroRef(const Token &Tok, const MacroInfo &MI,
                      RefType RT = RefType::Explicit) {
    if (MI.isBuiltinMacro())
      return; // __FILE__ is not a reference.
    Recorded.MacroReferences.push_back(
        SymbolReference{Macro{Tok.getIdentifierInfo(), MI.getDefinitionLoc()},
                        Tok.getLocation(), RT});
  }

  bool Active = false;
  RecordedPP &Recorded;
  const Preprocessor &PP;
  const SourceManager &SM;
};

} // namespace

class PragmaIncludes::RecordPragma : public PPCallbacks, public CommentHandler {
public:
  RecordPragma(const CompilerInstance &CI, PragmaIncludes *Out)
      : RecordPragma(CI.getPreprocessor(), Out) {}
  RecordPragma(const Preprocessor &P, PragmaIncludes *Out)
      : SM(P.getSourceManager()), HeaderInfo(P.getHeaderSearchInfo()), Out(Out),
        Arena(std::make_shared<llvm::BumpPtrAllocator>()),
        UniqueStrings(*Arena),
        MainFileStem(llvm::sys::path::stem(
            SM.getNonBuiltinFilenameForID(SM.getMainFileID()).value_or(""))) {}

  void FileChanged(SourceLocation Loc, FileChangeReason Reason,
                   SrcMgr::CharacteristicKind FileType,
                   FileID PrevFID) override {
    InMainFile = SM.isWrittenInMainFile(Loc);

    if (Reason == PPCallbacks::ExitFile) {
      // At file exit time HeaderSearchInfo is valid and can be used to
      // determine whether the file was a self-contained header or not.
      if (OptionalFileEntryRef FE = SM.getFileEntryRefForID(PrevFID)) {
        if (tooling::isSelfContainedHeader(*FE, SM, HeaderInfo))
          Out->NonSelfContainedFiles.erase(FE->getUniqueID());
        else
          Out->NonSelfContainedFiles.insert(FE->getUniqueID());
      }
    }
  }

  void EndOfMainFile() override {
    for (auto &It : Out->IWYUExportBy) {
      llvm::sort(It.getSecond());
      It.getSecond().erase(llvm::unique(It.getSecond()), It.getSecond().end());
    }
    Out->Arena.emplace_back(std::move(Arena));
  }

  void InclusionDirective(SourceLocation HashLoc, const Token &IncludeTok,
                          llvm::StringRef FileName, bool IsAngled,
                          CharSourceRange /*FilenameRange*/,
                          OptionalFileEntryRef File,
                          llvm::StringRef /*SearchPath*/,
                          llvm::StringRef /*RelativePath*/,
                          const clang::Module * /*SuggestedModule*/,
                          bool /*ModuleImported*/,
                          SrcMgr::CharacteristicKind FileKind) override {
    FileID HashFID = SM.getFileID(HashLoc);
    int HashLine = SM.getLineNumber(HashFID, SM.getFileOffset(HashLoc));
    std::optional<Header> IncludedHeader;
    if (IsAngled)
      if (auto StandardHeader =
              tooling::stdlib::Header::named("<" + FileName.str() + ">")) {
        IncludedHeader = *StandardHeader;
      }
    if (!IncludedHeader && File)
      IncludedHeader = *File;
    checkForExport(HashFID, HashLine, IncludedHeader, File);
    checkForKeep(HashLine, File);
    checkForDeducedAssociated(IncludedHeader);
  }

  void checkForExport(FileID IncludingFile, int HashLine,
                      std::optional<Header> IncludedHeader,
                      OptionalFileEntryRef IncludedFile) {
    if (ExportStack.empty())
      return;
    auto &Top = ExportStack.back();
    if (Top.SeenAtFile != IncludingFile)
      return;
    // Make sure current include is covered by the export pragma.
    if ((Top.Block && HashLine > Top.SeenAtLine) ||
        Top.SeenAtLine == HashLine) {
      if (IncludedFile)
        Out->IWYUExportBy[IncludedFile->getUniqueID()].push_back(Top.Path);
      if (IncludedHeader && IncludedHeader->kind() == Header::Standard)
        Out->StdIWYUExportBy[IncludedHeader->standard()].push_back(Top.Path);
      // main-file #include with export pragma should never be removed.
      if (Top.SeenAtFile == SM.getMainFileID() && IncludedFile)
        Out->ShouldKeep.insert(IncludedFile->getUniqueID());
    }
    if (!Top.Block) // Pop immediately for single-line export pragma.
      ExportStack.pop_back();
  }

  void checkForKeep(int HashLine, OptionalFileEntryRef IncludedFile) {
    if (!InMainFile || KeepStack.empty())
      return;
    KeepPragma &Top = KeepStack.back();
    // Check if the current include is covered by a keep pragma.
    if (IncludedFile && ((Top.Block && HashLine > Top.SeenAtLine) ||
                         Top.SeenAtLine == HashLine)) {
      Out->ShouldKeep.insert(IncludedFile->getUniqueID());
    }

    if (!Top.Block)
      KeepStack.pop_back(); // Pop immediately for single-line keep pragma.
  }

  // Consider marking H as the "associated header" of the main file.
  //
  // Our heuristic:
  // - it must be the first #include in the main file
  // - it must have the same name stem as the main file (foo.h and foo.cpp)
  // (IWYU pragma: associated is also supported, just not by this function).
  //
  // We consider the associated header as if it had a keep pragma.
  // (Unlike IWYU, we don't treat #includes inside the associated header as if
  // they were written in the main file.)
  void checkForDeducedAssociated(std::optional<Header> H) {
    namespace path = llvm::sys::path;
    if (!InMainFile || SeenAssociatedCandidate)
      return;
    SeenAssociatedCandidate = true; // Only the first #include is our candidate.
    if (!H || H->kind() != Header::Physical)
      return;
    if (path::stem(H->physical().getName(), path::Style::posix) == MainFileStem)
      Out->ShouldKeep.insert(H->physical().getUniqueID());
  }

  bool HandleComment(Preprocessor &PP, SourceRange Range) override {
    auto &SM = PP.getSourceManager();
    auto Pragma =
        tooling::parseIWYUPragma(SM.getCharacterData(Range.getBegin()));
    if (!Pragma)
      return false;

    auto [CommentFID, CommentOffset] = SM.getDecomposedLoc(Range.getBegin());
    int CommentLine = SM.getLineNumber(CommentFID, CommentOffset);

    if (InMainFile) {
      if (Pragma->starts_with("keep") ||
          // Limited support for associated headers: never consider unused.
          Pragma->starts_with("associated")) {
        KeepStack.push_back({CommentLine, false});
      } else if (Pragma->starts_with("begin_keep")) {
        KeepStack.push_back({CommentLine, true});
      } else if (Pragma->starts_with("end_keep") && !KeepStack.empty()) {
        assert(KeepStack.back().Block);
        KeepStack.pop_back();
      }
    }

    auto FE = SM.getFileEntryRefForID(CommentFID);
    if (!FE) {
      // This can only happen when the buffer was registered virtually into
      // SourceManager and FileManager has no idea about it. In such a scenario,
      // that file cannot be discovered by HeaderSearch, therefore no "explicit"
      // includes for that file.
      return false;
    }
    auto CommentUID = FE->getUniqueID();
    if (Pragma->consume_front("private")) {
      StringRef PublicHeader;
      if (Pragma->consume_front(", include ")) {
        // We always insert using the spelling from the pragma.
        PublicHeader =
            save(Pragma->starts_with("<") || Pragma->starts_with("\"")
                     ? (*Pragma)
                     : ("\"" + *Pragma + "\"").str());
      }
      Out->IWYUPublic.insert({CommentUID, PublicHeader});
      return false;
    }
    if (Pragma->consume_front("always_keep")) {
      Out->ShouldKeep.insert(CommentUID);
      return false;
    }
    auto Filename = FE->getName();
    // Record export pragma.
    if (Pragma->starts_with("export")) {
      ExportStack.push_back({CommentLine, CommentFID, save(Filename), false});
    } else if (Pragma->starts_with("begin_exports")) {
      ExportStack.push_back({CommentLine, CommentFID, save(Filename), true});
    } else if (Pragma->starts_with("end_exports")) {
      // FIXME: be robust on unmatching cases. We should only pop the stack if
      // the begin_exports and end_exports is in the same file.
      if (!ExportStack.empty()) {
        assert(ExportStack.back().Block);
        ExportStack.pop_back();
      }
    }
    return false;
  }

private:
  StringRef save(llvm::StringRef S) { return UniqueStrings.save(S); }

  bool InMainFile = false;
  const SourceManager &SM;
  const HeaderSearch &HeaderInfo;
  PragmaIncludes *Out;
  std::shared_ptr<llvm::BumpPtrAllocator> Arena;
  /// Intern table for strings. Contents are on the arena.
  llvm::StringSaver UniqueStrings;
  // Used when deducing associated header.
  llvm::StringRef MainFileStem;
  bool SeenAssociatedCandidate = false;

  struct ExportPragma {
    // The line number where we saw the begin_exports or export pragma.
    int SeenAtLine = 0; // 1-based line number.
    // The file where we saw the pragma.
    FileID SeenAtFile;
    // Name (per FileEntry::getName()) of the file SeenAtFile.
    StringRef Path;
    // true if it is a block begin/end_exports pragma; false if it is a
    // single-line export pragma.
    bool Block = false;
  };
  // A stack for tracking all open begin_exports or single-line export.
  std::vector<ExportPragma> ExportStack;

  struct KeepPragma {
    // The line number where we saw the begin_keep or keep pragma.
    int SeenAtLine = 0; // 1-based line number.
    // true if it is a block begin/end_keep pragma; false if it is a
    // single-line keep pragma.
    bool Block = false;
  };
  // A stack for tracking all open begin_keep pragmas or single-line keeps.
  std::vector<KeepPragma> KeepStack;
};

void PragmaIncludes::record(const CompilerInstance &CI) {
  auto Record = std::make_unique<RecordPragma>(CI, this);
  CI.getPreprocessor().addCommentHandler(Record.get());
  CI.getPreprocessor().addPPCallbacks(std::move(Record));
}

void PragmaIncludes::record(Preprocessor &P) {
  auto Record = std::make_unique<RecordPragma>(P, this);
  P.addCommentHandler(Record.get());
  P.addPPCallbacks(std::move(Record));
}

llvm::StringRef PragmaIncludes::getPublic(const FileEntry *F) const {
  auto It = IWYUPublic.find(F->getUniqueID());
  if (It == IWYUPublic.end())
    return "";
  return It->getSecond();
}

static llvm::SmallVector<FileEntryRef>
toFileEntries(llvm::ArrayRef<StringRef> FileNames, FileManager &FM) {
  llvm::SmallVector<FileEntryRef> Results;

  for (auto FName : FileNames) {
    // FIMXE: log the failing cases?
    if (auto FE = FM.getOptionalFileRef(FName))
      Results.push_back(*FE);
  }
  return Results;
}
llvm::SmallVector<FileEntryRef>
PragmaIncludes::getExporters(const FileEntry *File, FileManager &FM) const {
  auto It = IWYUExportBy.find(File->getUniqueID());
  if (It == IWYUExportBy.end())
    return {};

  return toFileEntries(It->getSecond(), FM);
}
llvm::SmallVector<FileEntryRef>
PragmaIncludes::getExporters(tooling::stdlib::Header StdHeader,
                             FileManager &FM) const {
  auto It = StdIWYUExportBy.find(StdHeader);
  if (It == StdIWYUExportBy.end())
    return {};
  return toFileEntries(It->getSecond(), FM);
}

bool PragmaIncludes::isSelfContained(const FileEntry *FE) const {
  return !NonSelfContainedFiles.contains(FE->getUniqueID());
}

bool PragmaIncludes::isPrivate(const FileEntry *FE) const {
  return IWYUPublic.contains(FE->getUniqueID());
}

bool PragmaIncludes::shouldKeep(const FileEntry *FE) const {
  return ShouldKeep.contains(FE->getUniqueID()) ||
         NonSelfContainedFiles.contains(FE->getUniqueID());
}

namespace {
template <typename T> bool isImplicitTemplateSpecialization(const Decl *D) {
  if (const auto *TD = dyn_cast<T>(D))
    return TD->getTemplateSpecializationKind() == TSK_ImplicitInstantiation;
  return false;
}
} // namespace

std::unique_ptr<ASTConsumer> RecordedAST::record() {
  class Recorder : public ASTConsumer {
    RecordedAST *Out;

  public:
    Recorder(RecordedAST *Out) : Out(Out) {}
    void Initialize(ASTContext &Ctx) override { Out->Ctx = &Ctx; }
    bool HandleTopLevelDecl(DeclGroupRef DG) override {
      const auto &SM = Out->Ctx->getSourceManager();
      for (Decl *D : DG) {
        if (!SM.isWrittenInMainFile(SM.getExpansionLoc(D->getLocation())))
          continue;
        if (isImplicitTemplateSpecialization<FunctionDecl>(D) ||
            isImplicitTemplateSpecialization<CXXRecordDecl>(D) ||
            isImplicitTemplateSpecialization<VarDecl>(D))
          continue;
        // FIXME: Filter out certain Obj-C as well.
        Out->Roots.push_back(D);
      }
      return ASTConsumer::HandleTopLevelDecl(DG);
    }
  };

  return std::make_unique<Recorder>(this);
}

std::unique_ptr<PPCallbacks> RecordedPP::record(const Preprocessor &PP) {
  return std::make_unique<PPRecorder>(*this, PP);
}

} // namespace clang::include_cleaner
