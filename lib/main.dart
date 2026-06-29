import 'package:flutter/material.dart';

import 'storage/local_db.dart';
import 'auth/admin_auth.dart';
import 'auth/lock_screen.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EasyQuoteApp());
}

class EasyQuoteApp extends StatefulWidget {
  const EasyQuoteApp({super.key});

  @override
  State<EasyQuoteApp> createState() => _EasyQuoteAppState();
}

class _EasyQuoteAppState extends State<EasyQuoteApp> {
  bool _dbReady = false;
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await LocalDB.instance.init();
    final alreadyActivated = AdminAuth.isActivated();
    setState(() {
      _dbReady = true;
      _unlocked = alreadyActivated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyQuote',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: !_dbReady
          ? const _SplashLoading()
          : (_unlocked
              ? const HomeShell()
              : LockScreen(onUnlocked: () => setState(() => _unlocked = true))),
    );
  }
}

class _SplashLoading extends StatelessWidget {
  const _SplashLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.slab,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.electricBlue),
      ),
    );
  }
}
