import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/providers.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/widgets/pattern_lock_grid.dart';

class PatternSetupScreen extends ConsumerStatefulWidget {
  const PatternSetupScreen({super.key});

  @override
  ConsumerState<PatternSetupScreen> createState() => _PatternSetupScreenState();
}

class _PatternSetupScreenState extends ConsumerState<PatternSetupScreen> {
  String? _firstPattern;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定手勢密碼')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _firstPattern == null
            ? Column(
                children: [
                  const Text('請繪製新手勢（至少 4 點）'),
                  PatternLockGrid(
                    onPatternComplete: (p) {
                      setState(() => _firstPattern = p);
                    },
                  ),
                ],
              )
            : Column(
                children: [
                  const Text('請再次確認手勢'),
                  PatternLockGrid(
                    verifyPattern: _firstPattern,
                    onPatternComplete: (p) async {
                      final security =
                          await ref.read(securityServiceProvider.future);
                      await security.setGesturePattern(p);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('手勢已儲存')),
                        );
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
