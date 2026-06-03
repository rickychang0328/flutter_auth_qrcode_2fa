import 'package:flutter/material.dart';

/// 九宮格手勢（至少 4 點）— 儲存於 `gesture_pwd_key`（逗號分隔點索引 0-8）。
class PatternLockGrid extends StatefulWidget {
  const PatternLockGrid({
    super.key,
    required this.onPatternComplete,
    this.verifyPattern,
  });

  final void Function(String pattern) onPatternComplete;
  final String? verifyPattern;

  @override
  State<PatternLockGrid> createState() => _PatternLockGridState();
}

class _PatternLockGridState extends State<PatternLockGrid> {
  final List<int> _path = [];
  String? _error;

  static const int minPoints = 4;

  void _addPoint(int index) {
    if (_path.contains(index)) return;
    setState(() => _path.add(index));
  }

  void _finish() {
    if (_path.length < minPoints) {
      setState(() {
        _error = '至少需要 $minPoints 個點';
        _path.clear();
      });
      return;
    }
    final pattern = _path.join(',');
    if (widget.verifyPattern != null && widget.verifyPattern != pattern) {
      setState(() {
        _error = '手勢不符';
        _path.clear();
      });
      return;
    }
    widget.onPatternComplete(pattern);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 24,
              crossAxisSpacing: 24,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              final selected = _path.contains(index);
              return GestureDetector(
                onTap: () {
                  _addPoint(index);
                  if (_path.length >= minPoints) _finish();
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: Text(
                      selected ? '${_path.indexOf(index) + 1}' : '',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => setState(() {
                _path.clear();
                _error = null;
              }),
              child: const Text('重設'),
            ),
            FilledButton(
              onPressed: _path.length >= minPoints ? _finish : null,
              child: const Text('確認'),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            '依序點選至少 4 格（與 Android AES/ECB 舊格式不相容，僅本 App 使用）',
            style: TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
