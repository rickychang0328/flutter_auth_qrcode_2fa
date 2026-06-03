import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/providers.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/screens/account_list_screen.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/screens/unlock_screen.dart';

class MustAuthApp extends ConsumerStatefulWidget {
  const MustAuthApp({super.key});

  @override
  ConsumerState<MustAuthApp> createState() => _MustAuthAppState();
}

class _MustAuthAppState extends ConsumerState<MustAuthApp>
    with WidgetsBindingObserver {
  final _appLinks = AppLinks();
  bool _locked = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
    _checkInitialLock();
  }

  Future<void> _checkInitialLock() async {
    final security = await ref.read(securityServiceProvider.future);
    setState(() {
      _locked = security.needsUnlock(isAppTerminate: true);
      _initialized = true;
    });
  }

  Future<void> _initDeepLinks() async {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) _handleLink(initial.toString());
    _appLinks.uriLinkStream.listen((uri) => _handleLink(uri.toString()));
  }

  void _handleLink(String uri) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = navigatorKey.currentState;
      if (nav == null) return;
      final ctx = nav.context;
      ref.read(deepLinkHandlerProvider).handleUri(ctx, uri);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(securityServiceProvider.future).then((security) async {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        await security.onEnterBackground();
      } else if (state == AppLifecycleState.resumed) {
        if (security.needsUnlock(
          isAppTerminate: security.isSecurityEnabled &&
              (await ref.read(appPreferencesProvider.future))
                  .isAppTerminateFlag,
        )) {
          setState(() => _locked = true);
        }
      } else if (state == AppLifecycleState.detached) {
        await security.onAppTerminate();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'MustAuth',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: _locked
          ? UnlockScreen(
              onUnlocked: () => setState(() => _locked = false),
            )
          : const AccountListScreen(),
      routes: {
        '/home': (_) => const AccountListScreen(),
      },
    );
  }
}
