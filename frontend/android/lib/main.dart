import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:hi_docs/providers/auth_provider.dart';
import 'package:hi_docs/providers/theme_provider.dart';
import 'package:hi_docs/providers/language_provider.dart';
import 'package:hi_docs/providers/form_provider.dart';
import 'package:hi_docs/providers/response_provider.dart';

import 'package:hi_docs/screens/auth/login_screen.dart';
import 'package:hi_docs/screens/auth/register_screen.dart';
import 'package:hi_docs/screens/auth/role_selection_screen.dart';
import 'package:hi_docs/screens/auth/admin_blocked_screen.dart';
import 'package:hi_docs/screens/home/user_home_screen.dart';
import 'package:hi_docs/screens/home/creator_home_screen.dart';
import 'package:hi_docs/screens/exam/scan_form_screen.dart';
import 'package:hi_docs/screens/exam/link_input_screen.dart';
import 'package:hi_docs/screens/exam/deep_link_form_screen.dart';
import 'package:hi_docs/services/deep_link_service.dart';
import 'package:hi_docs/utils/custom_page_route.dart';

import 'package:hi_docs/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}
  runApp(const FormMakerApp());
}

class FormMakerApp extends StatelessWidget {
  const FormMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => FormProvider()),
        ChangeNotifierProvider(create: (_) => ResponseProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, _) {
          return MaterialApp(
            title: 'HiDocs!',
            debugShowCheckedModeBanner: false,

            localizationsDelegates: const [
              ...GlobalMaterialLocalizations.delegates,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
              ...AppLocalizations.localizationsDelegates,
            ],

            supportedLocales: AppLocalizations.supportedLocales,
            locale: languageProvider.locale,

            theme: themeProvider.buildLightTheme(),
            darkTheme: themeProvider.buildDarkTheme(),
            themeMode: themeProvider.themeMode,

            builder: (context, child) {
              return child!;
            },

            home: const RoleGate(),

            initialRoute: '/',
            onUnknownRoute: (settings) {
              final slug =
                  DeepLinkService.slugFromRoute(settings.name);
              if (slug != null && slug.isNotEmpty) {
                return CustomPageRoute.forRoute(
                    settings, DeepLinkFormScreen(slug: slug));
              }
              return CustomPageRoute.forRoute(
                  settings, const NotFoundScreen());
            },

            onGenerateRoute: (settings) {
              Widget page;
              switch (settings.name) {
                case '/':
                  page = const RoleGate();
                  break;
                case '/login':
                  page = const LoginScreen();
                  break;
                case '/register':
                  page = const RegisterScreen();
                  break;
                case '/role-select':
                  page = const RoleSelectionScreen();
                  break;
                case '/user-home':
                  page = const UserHomeScreen();
                  break;
                case '/creator-home':
                  page = _GuardedRoute(
                    allow: (a) => a.isLoggedIn,
                    fallback: const LoginScreen(),
                    child: const CreatorHomeScreen(),
                  );
                  break;
                case '/admin-home':
                case '/super-admin-home':
                case '/admin-traffic':
                  // Dashboard admin TIDAK didukung di aplikasi Android
                  // (sebelumnya mem-blank-kan layar) → arahkan ke layar
                  // penjelasan.
                  page = const AdminBlockedScreen();
                  break;
                case '/scan-form':
                  page = const ScanFormScreen();
                  break;
                case '/link-input':
                  page = const LinkInputScreen();
                  break;
                default:
                  final slug =
                      DeepLinkService.slugFromRoute(settings.name);
                  if (slug != null && slug.isNotEmpty) {
                    page = DeepLinkFormScreen(slug: slug);
                    break;
                  }
                  page = const NotFoundScreen();
                  break;
              }
              return CustomPageRoute.forRoute(settings, page);
            },
          );
        },
      ),
    );
  }
}

class RoleGate extends StatefulWidget {
  const RoleGate({super.key});

  static bool canAccessAdmin(AuthProvider auth) =>
      auth.isLoggedIn && (auth.isSuperAdmin || auth.isAdmin);

  static bool canAccessCreator(AuthProvider auth) =>
      auth.isLoggedIn && auth.isCreatorMode;

  @override
  State<RoleGate> createState() => _RoleGateState();
}

class _RoleGateState extends State<RoleGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleInitialLink());
  }

  Future<void> _handleInitialLink() async {
    final link = await DeepLinkService.getInitialLink();
    final slug = DeepLinkService.extractSlug(link);
    if (!mounted || slug == null || slug.isEmpty) return;
    Navigator.pushNamed(context, '/f/$slug');
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }
    if (auth.isAdminRole) {
      // Dashboard admin tidak didukung di Android — layar penjelasan ini
      // menggantikan AdminDashboardScreen yang sebelumnya blank putih.
      return const AdminBlockedScreen();
    }
    if (auth.isCreatorMode) {
      return const CreatorHomeScreen();
    }
    return const UserHomeScreen();
  }
}

class _GuardedRoute extends StatelessWidget {
  final bool Function(AuthProvider auth) allow;
  final Widget fallback;
  final Widget child;

  const _GuardedRoute({
    required this.allow,
    required this.fallback,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (!allow(auth)) return fallback;
    return child;
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Halaman tidak ditemukan')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 48),
            const SizedBox(height: 12),
            const Text('Rute tidak dikenal.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/', (_) => false),
              child: const Text('Kembali ke Beranda'),
            ),
          ],
        ),
      ),
    );
  }
}

class ThemeBackground extends StatelessWidget {
  final Widget child;

  const ThemeBackground({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
