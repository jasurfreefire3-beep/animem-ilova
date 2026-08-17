import fs from 'fs';

let loginFile = fs.readFileSync('ilova/lib/screens/auth/login_screen.dart', 'utf8');

const appLinksImport = "import 'package:app_links/app_links.dart';";
if (!loginFile.includes('app_links')) {
    loginFile = loginFile.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'dart:async';\n" + appLinksImport
    );
}

const loginLogic = `
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      if (uri.scheme == 'animem' && uri.host == 'auth') {
        final token = uri.queryParameters['token'];
        if (token != null) {
          final auth = context.read<AuthProvider>();
          final success = await auth.loginWithToken(token);
          if (mounted && success) {
            ToastUtils.showSuccess(context, 'Google orqali tizimga kirildi!');
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
              (route) => false,
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _loginWithGoogle() async {
    final url = Uri.parse('https://animem.uz/api/auth/google/mobile-login');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ToastUtils.showError(context, 'Brauzerni ochib bo\\'lmadi');
    }
  }
`;

loginFile = loginFile.replace(/@override\s*void dispose\(\)\s*\{[\s\S]*?super\.dispose\(\);\s*\}/, '');
loginFile = loginFile.replace(/Future<void> _loginWithGoogle\(\) async \{[\s\S]*?Future<void> _loginWithTelegram/m, loginLogic.trim() + '\n\n  Future<void> _loginWithTelegram');

fs.writeFileSync('ilova/lib/screens/auth/login_screen.dart', loginFile);


let regFile = fs.readFileSync('ilova/lib/screens/auth/register_screen.dart', 'utf8');

if (!regFile.includes('app_links')) {
    regFile = regFile.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'dart:async';\n" + appLinksImport
    );
}

const regLogic = `
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      if (uri.scheme == 'animem' && uri.host == 'auth') {
        final token = uri.queryParameters['token'];
        if (token != null) {
          final auth = context.read<AuthProvider>();
          final success = await auth.loginWithToken(token);
          if (mounted && success) {
            ToastUtils.showSuccess(context, 'Google orqali tizimga kirildi!');
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
              (route) => false,
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _registerWithGoogle() async {
    final url = Uri.parse('https://animem.uz/api/auth/google/mobile-login');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ToastUtils.showError(context, 'Brauzerni ochib bo\\'lmadi');
    }
  }
`;

regFile = regFile.replace(/@override\s*void dispose\(\)\s*\{[\s\S]*?super\.dispose\(\);\s*\}/, '');
regFile = regFile.replace(/Future<void> _registerWithGoogle\(\) async \{[\s\S]*?Future<void> _registerWithTelegram/m, regLogic.trim() + '\n\n  Future<void> _registerWithTelegram');

fs.writeFileSync('ilova/lib/screens/auth/register_screen.dart', regFile);

console.log("Flutter auth patched");
