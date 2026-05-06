import 'package:flutter_test/flutter_test.dart';
import 'package:sevendiffs/core/diff_engine.dart';

void main() {
  late DiffEngine engine;

  setUp(() => engine = DiffEngine());

  // ── DiffResult properties ──────────────────────────────────────────────────

  group('DiffResult', () {
    test('isEmpty is true only when there are no lines', () {
      final result = engine.compute('', '');
      expect(result.isEmpty, isTrue);
      expect(result.hasChanges, isFalse);
    });

    test('hasChanges is false for identical texts', () {
      final result = engine.compute('hello', 'hello');
      expect(result.hasChanges, isFalse);
      expect(result.addedLines, 0);
      expect(result.removedLines, 0);
    });

    test('totalChangedLines equals addedLines + removedLines', () {
      final result = engine.compute('a\nb', 'a\nc');
      expect(result.totalChangedLines, result.addedLines + result.removedLines);
    });

    test('hunkCount matches number of change blocks', () {
      // Two separate change blocks separated by equal lines
      final result = engine.compute('a\nb\nc\nd', 'x\nb\nc\ny');
      expect(result.hunkCount, 2);
    });
  });

  // ── Empty / blank inputs ───────────────────────────────────────────────────

  group('empty inputs', () {
    test('both empty → isEmpty', () {
      expect(engine.compute('', '').isEmpty, isTrue);
    });

    test('original empty, modified not → all insertions', () {
      final result = engine.compute('', 'hello');
      expect(result.addedLines, 1);
      expect(result.removedLines, 0);
    });

    test('modified empty, original not → all deletions', () {
      final result = engine.compute('hello', '');
      expect(result.addedLines, 0);
      expect(result.removedLines, 1);
    });

    test('blank lines are treated as content', () {
      final result = engine.compute('\n\n', '\n');
      expect(result.hasChanges, isTrue);
    });
  });

  // ── Additions and deletions ────────────────────────────────────────────────

  group('additions and deletions', () {
    test('single line added at end', () {
      final result = engine.compute('a', 'a\nb');
      expect(result.addedLines, 1);
      expect(result.removedLines, 0);
    });

    test('single line removed from middle', () {
      final result = engine.compute('a\nb\nc', 'a\nc');
      expect(result.removedLines, 1);
      expect(result.addedLines, 0);
    });

    test('single line replaced', () {
      final result = engine.compute('hello', 'world');
      expect(result.addedLines, 1);
      expect(result.removedLines, 1);
    });

    test('unchanged lines are counted correctly', () {
      final result = engine.compute('a\nb\nc', 'a\nx\nc');
      expect(result.unchangedLines, 2);
      expect(result.addedLines, 1);
      expect(result.removedLines, 1);
    });

    test('all lines replaced', () {
      final result = engine.compute('a\nb\nc', 'x\ny\nz');
      expect(result.removedLines, 3);
      expect(result.addedLines, 3);
      expect(result.unchangedLines, 0);
    });

    test('multiline block inserted in the middle', () {
      final result = engine.compute('a\nd', 'a\nb\nc\nd');
      expect(result.addedLines, 2);
      expect(result.removedLines, 0);
    });
  });

  // ── Line numbers ───────────────────────────────────────────────────────────

  group('line numbers', () {
    test('equal lines have both left and right line numbers', () {
      final result = engine.compute('a\nb', 'a\nb');
      for (final line in result.lines) {
        expect(line.leftLineNum, isNotNull);
        expect(line.rightLineNum, isNotNull);
      }
    });

    test('deleted lines have only left line number', () {
      final result = engine.compute('a\nb', 'a');
      final deleted = result.lines.where((l) => l.type == DiffType.delete);
      for (final line in deleted) {
        expect(line.leftLineNum, isNotNull);
        expect(line.rightLineNum, isNull);
      }
    });

    test('inserted lines have only right line number', () {
      final result = engine.compute('a', 'a\nb');
      final inserted = result.lines.where((l) => l.type == DiffType.insert);
      for (final line in inserted) {
        expect(line.rightLineNum, isNotNull);
        expect(line.leftLineNum, isNull);
      }
    });

    test('line numbers start at 1', () {
      final result = engine.compute('x', 'y');
      final del = result.lines.firstWhere((l) => l.type == DiffType.delete);
      final ins = result.lines.firstWhere((l) => l.type == DiffType.insert);
      expect(del.leftLineNum, 1);
      expect(ins.rightLineNum, 1);
    });

    test('line numbers are sequential and contiguous', () {
      final result = engine.compute('a\nb\nc', 'a\nb\nc\nd');
      final leftNums = result.lines
          .where((l) => l.leftLineNum != null)
          .map((l) => l.leftLineNum!)
          .toList();
      final rightNums = result.lines
          .where((l) => l.rightLineNum != null)
          .map((l) => l.rightLineNum!)
          .toList();
      expect(leftNums, equals(List.generate(leftNums.length, (i) => i + 1)));
      expect(rightNums, equals(List.generate(rightNums.length, (i) => i + 1)));
    });
  });

  // ── Hunks ──────────────────────────────────────────────────────────────────

  group('hunks', () {
    test('no hunks when texts are identical', () {
      expect(engine.compute('a\nb', 'a\nb').hunkCount, 0);
    });

    test('one hunk for a single contiguous change', () {
      expect(engine.compute('a\nb\nc', 'a\nX\nY\nc').hunkCount, 1);
    });

    test('exactly 7 hunks detectable', () {
      final orig = List.generate(14, (i) => 'line$i').join('\n');
      final mod = List.generate(14, (i) => i.isEven ? 'changed$i' : 'line$i').join('\n');
      final result = engine.compute(orig, mod);
      expect(result.hunkCount, 7);
    });
  });

  // ── Inline diffs ───────────────────────────────────────────────────────────

  group('inline diffs', () {
    test('similar lines get inline segments', () {
      final result = engine.compute('hello world', 'hello dart');
      final del = result.lines.firstWhere((l) => l.type == DiffType.delete);
      final ins = result.lines.firstWhere((l) => l.type == DiffType.insert);
      expect(del.inlineSegments, isNotNull);
      expect(ins.inlineSegments, isNotNull);
    });

    test('inline segments cover the full original text on delete side', () {
      final result = engine.compute('abcdef', 'abcxyz');
      final del = result.lines.firstWhere((l) => l.type == DiffType.delete);
      if (del.inlineSegments != null) {
        final reconstructed = del.inlineSegments!.map((s) => s.text).join();
        expect(reconstructed, 'abcdef');
      }
    });

    test('inline segments cover the full modified text on insert side', () {
      final result = engine.compute('abcdef', 'abcxyz');
      final ins = result.lines.firstWhere((l) => l.type == DiffType.insert);
      if (ins.inlineSegments != null) {
        final reconstructed = ins.inlineSegments!.map((s) => s.text).join();
        expect(reconstructed, 'abcxyz');
      }
    });

    test('completely different lines do not get inline segments', () {
      // similarity below 0.3 threshold — no shared chars
      final result = engine.compute('aaaa', 'zzzz');
      final del = result.lines.firstWhere((l) => l.type == DiffType.delete);
      expect(del.inlineSegments, isNull);
    });

    test('identical lines in a pair get fast-path inline (no changed segments)', () {
      // Lines that are equal shouldn't produce any changed inline segment
      final result = engine.compute('same line\nold', 'same line\nnew');
      final equal = result.lines.firstWhere((l) => l.type == DiffType.equal);
      expect(equal.inlineSegments, isNull);
    });
  });

  // ── Unicode & special content ──────────────────────────────────────────────

  group('unicode and special content', () {
    test('emoji in content', () {
      final result = engine.compute('hello 🎯', 'hello 🚀');
      expect(result.hasChanges, isTrue);
    });

    test('Chinese characters', () {
      final result = engine.compute('你好世界', '你好地球');
      expect(result.hasChanges, isTrue);
    });

    test('tabs and spaces are treated as content', () {
      final result = engine.compute('a\tb', 'a b');
      expect(result.hasChanges, isTrue);
    });

    test('single character diff', () {
      final result = engine.compute('a', 'b');
      expect(result.addedLines, 1);
      expect(result.removedLines, 1);
    });

    test('very long single line', () {
      final longLine = 'x' * 10000;
      final result = engine.compute(longLine, '${longLine}y');
      expect(result.hasChanges, isTrue);
    });
  });

  // ── LCS vs naive fallback ──────────────────────────────────────────────────

  group('large file fallback', () {
    test('files over 8000 lines use naive diff and still produce a result', () {
      final lines = List.generate(8001, (i) => 'line $i');
      final orig = lines.join('\n');
      final mod = [...lines, 'extra line'].join('\n'); // ignore: prefer_interpolation_to_compose_strings
      final result = engine.compute(orig, mod);
      // Naive diff marks everything as delete+insert, so changes > 0
      expect(result.hasChanges, isTrue);
    });

    test('files exactly at 8000 lines use LCS', () {
      final lines = List.generate(8000, (i) => 'line $i');
      final orig = lines.join('\n');
      // Change only one line — LCS should detect exactly 1 add + 1 remove
      lines[4000] = 'changed';
      final mod = lines.join('\n');
      final result = engine.compute(orig, mod);
      expect(result.addedLines, 1);
      expect(result.removedLines, 1);
    });
  });

  // ── runDiffInIsolate (top-level entry point) ───────────────────────────────

  group('runDiffInIsolate', () {
    test('produces same result as DiffEngine.compute', () {
      const original = 'foo\nbar\nbaz';
      const modified = 'foo\nqux\nbaz';
      final direct = DiffEngine().compute(original, modified);
      final viaIsolate = runDiffInIsolate((original: original, modified: modified));
      expect(viaIsolate.addedLines, direct.addedLines);
      expect(viaIsolate.removedLines, direct.removedLines);
      expect(viaIsolate.unchangedLines, direct.unchangedLines);
      expect(viaIsolate.hunkCount, direct.hunkCount);
    });
  });
}
