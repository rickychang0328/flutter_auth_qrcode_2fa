import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/providers.dart';

class ShareHistoryScreen extends ConsumerWidget {
  const ShareHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('分享紀錄')),
      body: FutureBuilder(
        future: ref.read(shareHistoryProvider.future).then((r) => r.loadAll()),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('尚無分享紀錄'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return ExpansionTile(
                title: Text(item.actionContent),
                subtitle: Text(item.actionDate),
                children: item.shareAccountDetail
                    .map(
                      (d) => ListTile(
                        dense: true,
                        title: Text('${d.issuer} / ${d.account}'),
                        subtitle: d.group.isNotEmpty ? Text(d.group) : null,
                      ),
                    )
                    .toList(),
              );
            },
          );
        },
      ),
    );
  }
}
