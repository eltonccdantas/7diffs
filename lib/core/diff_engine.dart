import 'dart:math';

enum DiffType { equal, insert, delete }

class InlineSegment {
  final String text;
  final bool isChanged;
  const InlineSegment(this.text, this.isChanged);
}

class DiffLine {
  final DiffType type;
  final String text;
  final int? leftLineNum;
  final int? rightLineNum;
  final List<InlineSegment>? inlineSegments;

  const DiffLine({
    required this.type,
    required this.text,
    this.leftLineNum,
    this.rightLineNum,
    this.inlineSegments,
  });
}

class DiffHunk {
  final int startLine;
  final List<DiffLine> lines;
  const DiffHunk({required this.startLine, required this.lines});
}

class DiffResult {
  final List<DiffLine> lines;
  final List<DiffHunk> hunks;
  final int addedLines;
  final int removedLines;
  final int unchangedLines;

  const DiffResult({
    required this.lines,
    required this.hunks,
    required this.addedLines,
    required this.removedLines,
    required this.unchangedLines,
  });

  int get totalChangedLines => addedLines + removedLines;
  int get hunkCount => hunks.length;
  bool get isEmpty => lines.isEmpty;
  bool get hasChanges => totalChangedLines > 0;
}

class DiffEngine {
  static const int _maxLinesForLCS = 8000;
  static const int _maxCharsForInline = 600;

  DiffResult compute(String original, String modified) {
    final origLines = _splitLines(original);
    final modLines = _splitLines(modified);

    final rawChunks = origLines.length > _maxLinesForLCS || modLines.length > _maxLinesForLCS
        ? _naiveDiff(origLines, modLines)
        : _lcsDiff(origLines, modLines);

    final diffLines = _buildDiffLines(rawChunks, origLines, modLines);
    final processed = _addInlineDiffs(diffLines);
    final hunks = _extractHunks(processed);

    int added = 0, removed = 0, unchanged = 0;
    for (final l in processed) {
      switch (l.type) {
        case DiffType.insert:
          added++;
        case DiffType.delete:
          removed++;
        case DiffType.equal:
          unchanged++;
      }
    }

    return DiffResult(
      lines: processed,
      hunks: hunks,
      addedLines: added,
      removedLines: removed,
      unchangedLines: unchanged,
    );
  }

  List<String> _splitLines(String text) {
    if (text.isEmpty) return [];
    return text.split('\n');
  }

  // LCS-based diff O(m*n)
  List<_RawChunk> _lcsDiff(List<String> orig, List<String> mod) {
    final m = orig.length;
    final n = mod.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (orig[i - 1] == mod[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1];
        }
      }
    }

    final result = <_RawChunk>[];
    int i = m, j = n;
    while (i > 0 || j > 0) {
      if (i > 0 && j > 0 && orig[i - 1] == mod[j - 1]) {
        result.add(_RawChunk(DiffType.equal, i - 1, j - 1));
        i--;
        j--;
      } else if (j > 0 && (i == 0 || dp[i][j - 1] >= dp[i - 1][j])) {
        result.add(_RawChunk(DiffType.insert, null, j - 1));
        j--;
      } else {
        result.add(_RawChunk(DiffType.delete, i - 1, null));
        i--;
      }
    }
    return result.reversed.toList();
  }

  // Simple diff for very large files
  List<_RawChunk> _naiveDiff(List<String> orig, List<String> mod) {
    final result = <_RawChunk>[];
    for (int i = 0; i < orig.length; i++) {
      result.add(_RawChunk(DiffType.delete, i, null));
    }
    for (int j = 0; j < mod.length; j++) {
      result.add(_RawChunk(DiffType.insert, null, j));
    }
    return result;
  }

  List<DiffLine> _buildDiffLines(
    List<_RawChunk> chunks,
    List<String> orig,
    List<String> mod,
  ) {
    final lines = <DiffLine>[];
    int leftNum = 1, rightNum = 1;

    for (final chunk in chunks) {
      switch (chunk.type) {
        case DiffType.equal:
          lines.add(DiffLine(
            type: DiffType.equal,
            text: orig[chunk.origIdx!],
            leftLineNum: leftNum++,
            rightLineNum: rightNum++,
          ));
        case DiffType.delete:
          lines.add(DiffLine(
            type: DiffType.delete,
            text: orig[chunk.origIdx!],
            leftLineNum: leftNum++,
          ));
        case DiffType.insert:
          lines.add(DiffLine(
            type: DiffType.insert,
            text: mod[chunk.modIdx!],
            rightLineNum: rightNum++,
          ));
      }
    }
    return lines;
  }

  // Post-process: add inline char-level diffs for adjacent delete+insert pairs
  List<DiffLine> _addInlineDiffs(List<DiffLine> lines) {
    final result = <DiffLine>[];
    int i = 0;

    while (i < lines.length) {
      if (lines[i].type != DiffType.delete) {
        result.add(lines[i++]);
        continue;
      }

      final delStart = i;
      while (i < lines.length && lines[i].type == DiffType.delete) { i++; }
      final delEnd = i;

      final insStart = i;
      while (i < lines.length && lines[i].type == DiffType.insert) { i++; }
      final insEnd = i;

      final deletes = lines.sublist(delStart, delEnd);
      final inserts = lines.sublist(insStart, insEnd);
      final pairCount = min(deletes.length, inserts.length);

      for (int k = 0; k < pairCount; k++) {
        final del = deletes[k];
        final ins = inserts[k];

        final sim = _similarity(del.text, ins.text);
        if (sim > 0.3 &&
            del.text.length <= _maxCharsForInline &&
            ins.text.length <= _maxCharsForInline) {
          result.add(DiffLine(
            type: DiffType.delete,
            text: del.text,
            leftLineNum: del.leftLineNum,
            inlineSegments: _charLevelDiff(del.text, ins.text, keepSide: true),
          ));
          result.add(DiffLine(
            type: DiffType.insert,
            text: ins.text,
            rightLineNum: ins.rightLineNum,
            inlineSegments: _charLevelDiff(del.text, ins.text, keepSide: false),
          ));
        } else {
          result.add(del);
          result.add(ins);
        }
      }

      for (int k = pairCount; k < deletes.length; k++) { result.add(deletes[k]); }
      for (int k = pairCount; k < inserts.length; k++) { result.add(inserts[k]); }
    }

    return result;
  }

  // Returns inline segments for one side of a change pair.
  // keepSide=true → keep deletions (show what was removed)
  // keepSide=false → keep insertions (show what was added)
  List<InlineSegment> _charLevelDiff(String a, String b, {required bool keepSide}) {
    final aRunes = a.runes.toList();
    final bRunes = b.runes.toList();
    final m = aRunes.length;
    final n = bRunes.length;

    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        dp[i][j] = aRunes[i - 1] == bRunes[j - 1]
            ? dp[i - 1][j - 1] + 1
            : max(dp[i - 1][j], dp[i][j - 1]);
      }
    }

    // Collect operations as (isEqual, charCode)
    final ops = <(bool isEqual, int charCode)>[];
    int i = m, j = n;
    while (i > 0 || j > 0) {
      if (i > 0 && j > 0 && aRunes[i - 1] == bRunes[j - 1]) {
        ops.add((true, keepSide ? aRunes[i - 1] : bRunes[j - 1]));
        i--;
        j--;
      } else if (j > 0 && (i == 0 || dp[i][j - 1] >= dp[i - 1][j])) {
        if (!keepSide) ops.add((false, bRunes[j - 1]));
        j--;
      } else {
        if (keepSide) ops.add((false, aRunes[i - 1]));
        i--;
      }
    }

    final forward = ops.reversed.toList();
    final segments = <InlineSegment>[];
    final buf = StringBuffer();
    bool? changed;

    for (final op in forward) {
      final c = !op.$1;
      if (changed != c) {
        if (buf.isNotEmpty) {
          segments.add(InlineSegment(buf.toString(), changed!));
          buf.clear();
        }
        changed = c;
      }
      buf.writeCharCode(op.$2);
    }
    if (buf.isNotEmpty && changed != null) {
      segments.add(InlineSegment(buf.toString(), changed));
    }

    return segments.isEmpty ? [InlineSegment(keepSide ? a : b, false)] : segments;
  }

  double _similarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    // Fast character overlap heuristic
    final setA = a.runes.toSet();
    final setB = b.runes.toSet();
    final common = setA.intersection(setB).length;
    final total = setA.union(setB).length;
    return total == 0 ? 0.0 : common / total;
  }

  List<DiffHunk> _extractHunks(List<DiffLine> lines) {
    final hunks = <DiffHunk>[];
    int i = 0;

    while (i < lines.length) {
      if (lines[i].type == DiffType.equal) {
        i++;
        continue;
      }

      final start = i;
      final hunkLines = <DiffLine>[];
      while (i < lines.length && lines[i].type != DiffType.equal) {
        hunkLines.add(lines[i++]);
      }
      hunks.add(DiffHunk(startLine: start, lines: hunkLines));
    }

    return hunks;
  }
}

class _RawChunk {
  final DiffType type;
  final int? origIdx;
  final int? modIdx;
  const _RawChunk(this.type, this.origIdx, this.modIdx);
}

// Top-level function for compute() isolate
DiffResult runDiffInIsolate(({String original, String modified}) args) {
  return DiffEngine().compute(args.original, args.modified);
}
