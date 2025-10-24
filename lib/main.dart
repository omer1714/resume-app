import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Aliases (important!)
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as fui;

// Admin dashboard
import 'admin_dashboard.dart';

// Firebase offline persistence (all platforms)
Future<void> initFirestorePersistence() async {
  fs.FirebaseFirestore.instance.settings = const fs.Settings(
    persistenceEnabled: true,
    cacheSizeBytes: fs.Settings.CACHE_SIZE_UNLIMITED,
  );
}

// --- Link icon helpers (viewer side) ---
const Map<String, IconData> _iconRegistry = {
  'link': Icons.link,
  'email': Icons.email,
  'github': Icons.code,
  'linkedin': Icons.business,
  'web': Icons.language,
  'twitter': Icons.alternate_email,
  'youtube': Icons.ondemand_video,
  'portfolio': Icons.web_stories,
  'phone': Icons.phone,
  'location': Icons.location_on,
  'resume': Icons.description,

  'react': Icons.blur_circular,
  'flutter': Icons.flutter_dash,
  'node': Icons.developer_mode,
  'dart': Icons.bolt,
  'firebase': Icons.fireplace,
};

IconData _iconForName(String? name) {
  if (name == null || name.isEmpty) return Icons.link;
  return _iconRegistry[name] ?? Icons.link;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initFirestorePersistence();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('fr')],
      path: 'assets/lang',
      fallbackLocale: const Locale('en'),
      child: const ResumeApp(),
    ),
  );
}

class ResumeApp extends StatefulWidget {
  const ResumeApp({super.key});
  @override
  State<ResumeApp> createState() => _ResumeAppState();
}

class _ResumeAppState extends State<ResumeApp> {
  ThemeMode _mode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    final light = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F80ED)),
      textTheme: GoogleFonts.interTextTheme(),
    );
    final dark = ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2F80ED), brightness: Brightness.dark),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );

    return MaterialApp(
      title: 'Resume',
      debugShowCheckedModeBanner: false,
      theme: light,
      darkTheme: dark,
      themeMode: _mode,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: AuthGate(
        onToggleTheme: () => setState(() {
          _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
        }),
        themeMode: _mode,
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  const AuthGate({super.key, required this.onToggleTheme, required this.themeMode});

  Future<void> _ensureUserDoc(fa.User user) async {
    final ref = fs.FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await ref.get();

    // Keep role nullable (unknown) until you assign it in Admin
    final data = {
      'email': user.email,
      'emailVerified': user.emailVerified,
      'createdAt': fs.FieldValue.serverTimestamp(),
      'approved': false,
      'role': null, // null = unknown
    };

    if (!snap.exists) {
      await ref.set(data);
    } else {
      // Keep emailVerified in sync on each login/refresh
      await ref.update({'emailVerified': user.emailVerified});
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<fa.User?>(
      stream: fa.FirebaseAuth.instance.authStateChanges(),
      builder: (_, auth) {
        final user = auth.data;

        if (user == null) {
          return fui.SignInScreen(
            providers: [fui.EmailAuthProvider()],
            headerBuilder: (_, __, ___) => const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sign in please', style: TextStyle(fontSize: 18)),
            ),
            actions: [
              fui.AuthStateChangeAction<fui.SignedIn>((context, state) async {
                await _ensureUserDoc(state.user!);
              }),
            ],
          );
        }

        // Ensure we have a user doc and keep emailVerified in sync
        _ensureUserDoc(user);

        // If not verified, force verification screen
        if (!user.emailVerified) {
          return VerifyEmailScreen(onToggleTheme: onToggleTheme, themeMode: themeMode);
        }

        // Once verified, WATCH Firestore approval + role live
        return StreamBuilder<fs.DocumentSnapshot<Map<String, dynamic>>>(
          stream: fs.FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final u = snap.data!.data() ?? {};
            final approved = (u['approved'] == true);
            final role = u['role'] as String?;
            final isAdmin  = role == 'admin';
            final isEditor = role == 'editor';

            if (!approved) return const PendingApproval();

            if (isAdmin || isEditor) {
              return AdminDashboard(
                onToggleTheme: onToggleTheme,
                themeMode: themeMode,
                isAdmin: isAdmin,
              );
            }

            // viewer
            return ResumeHome(
              onToggleTheme: onToggleTheme,
              themeMode: themeMode,
              isEditor: false,
            );
          },
        );
      },
    );
  }
}

/// Prompts user to verify their email before anything else
class VerifyEmailScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  const VerifyEmailScreen({super.key, required this.onToggleTheme, required this.themeMode});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _sent = false;
  bool _checking = false;

  Future<void> _send() async {
    final u = fa.FirebaseAuth.instance.currentUser!;
    await u.sendEmailVerification();
    if (mounted) {
      setState(() => _sent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent. Please check your inbox.')),
      );
    }
  }

  Future<void> _refresh() async {
    setState(() => _checking = true);
    final u = fa.FirebaseAuth.instance.currentUser!;
    await u.reload();
    final nu = fa.FirebaseAuth.instance.currentUser!;
    setState(() => _checking = false);

    if (nu.emailVerified) {
      // 🔑 Force refresh ID token so Firestore rules see it immediately
      await nu.getIdToken(true);

      // Pop back to AuthGate so it re-checks role/approval
      if (mounted) Navigator.of(context).pop();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Still not verified. Click the link in your email and try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = fa.FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify your email'),
        actions: [
          IconButton(
            tooltip: tr('toggle_theme'),
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            tooltip: tr('sign_out'),
            onPressed: () => fa.FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('We sent a verification link to ${u.email}.'),
                const SizedBox(height: 12),
                const Text('Please verify your email, then tap "I’ve verified".'),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _send,
                  icon: const Icon(Icons.mark_email_read),
                  label: Text(_sent ? 'Resend verification email' : 'Send verification email'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _checking ? null : _refresh,
                  child: _checking ? const CircularProgressIndicator() : const Text('I’ve verified'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PendingApproval extends StatelessWidget {
  const PendingApproval({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Access requested', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('An admin must approve your account before you can view the résumé.'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => fa.FirebaseAuth.instance.signOut(),
                child: const Text('Sign out'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class ResumeHome extends StatefulWidget {
  final bool isEditor;
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  const ResumeHome({super.key, required this.onToggleTheme, required this.themeMode, required this.isEditor, });

  @override
  State<ResumeHome> createState() => _ResumeHomeState();
}

class _ResumeHomeState extends State<ResumeHome> {
  int _index = 0;

  fs.DocumentReference<Map<String, dynamic>> _docRef(BuildContext context) {
    final code = context.locale.languageCode; // 'en' or 'fr'
    return fs.FirebaseFirestore.instance.collection('resume').doc(code);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      {'icon': Icons.person, 'label': tr('tab_about')},
      {'icon': Icons.work,   'label': tr('tab_experience')},
      {'icon': Icons.apps,   'label': tr('tab_projects')},
      {'icon': Icons.star,   'label': tr('tab_skills')},
      {'icon': Icons.mail,   'label': tr('tab_contact')},
    ];

    return StreamBuilder<fs.DocumentSnapshot<Map<String, dynamic>>>(
      stream: _docRef(context).snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.hasData || !snap.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              leading: const _LangToggle(),
              title: const Text('…'),
              actions: [
                IconButton(
                  tooltip: tr('toggle_theme'),
                  onPressed: widget.onToggleTheme,
                  icon: Icon(widget.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
                ),
                IconButton(
                  tooltip: tr('sign_out'),
                  onPressed: () => fa.FirebaseAuth.instance.signOut(),
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
            body: Center(child: Text('No résumé data for "${context.locale.languageCode}".')),
          );
        }

        final data = snap.data!.data()!;
        return Scaffold(
          appBar: AppBar(
            leading: const _LangToggle(),
            title: Text(data['name']?.toString() ?? '…'),
            actions: [
              IconButton(
                tooltip: tr('toggle_theme'),
                onPressed: widget.onToggleTheme,
                icon: Icon(widget.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
              ),
              IconButton(
                tooltip: tr('sign_out'),
                onPressed: () => fa.FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: Builder(
              key: ValueKey(_index),
              builder: (_) {
                switch (_index) {
                  case 0:
                    return AboutTab(data);
                  case 1:
                    return ExperienceTab(
                      List<Map<String, dynamic>>.from(
                          data['experience'] ?? const []),
                    );
                  case 2:
                    return ProjectsTab(
                      List<Map<String, dynamic>>.from(
                          data['projects'] ?? const []),
                    );
                  case 3:
                    return SkillsTab(
                      List<dynamic>.from(data['skills'] ?? const []), // can be String or Map
                      education: List<Map<String, dynamic>>.from(
                          data['education'] ?? const []),
                    );
                  case 4:
                    return ContactTab(data);
                  default:
                    return AboutTab(data);
                }
              },
            ),
          ),

          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            destinations: [
              const NavigationDestination(icon: Icon(Icons.person), label: 'About'),
              const NavigationDestination(icon: Icon(Icons.work),   label: 'Experience'),
              const NavigationDestination(icon: Icon(Icons.apps),   label: 'Projects'),
              const NavigationDestination(icon: Icon(Icons.star),   label: 'Skills'),
              const NavigationDestination(icon: Icon(Icons.mail),   label: 'Contact'),
            ],
            onDestinationSelected: (i) {
              setState(() => _index = i);
            },
          ),
          floatingActionButton: (data['email'] ?? '').toString().isEmpty ? null : FloatingActionButton.extended(
            onPressed: () async {
              final email = (data['email'] ?? '').toString();
              final uri = Uri.parse('mailto:$email?subject=${Uri.encodeComponent(tr('contact_subject', args: [data['name'] ?? '']))}');
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
            label: Text(tr('contact')),
            icon: const Icon(Icons.send),
          ),
        );
      },
    );
  }
}

class _LangToggle extends StatelessWidget {
  const _LangToggle({super.key}); // const _LangToggle({super.key}); //- this gave a warning as it was not being used
  @override
  Widget build(BuildContext context) {
    final isFr = context.locale.languageCode == 'fr';
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 6, bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.setLocale(Locale(isFr ? 'en' : 'fr')),
        child: Container(
          width: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Text(isFr ? 'FR' : 'EN', style: Theme.of(context).textTheme.labelLarge),
        ),
      ),
    );
  }
}

// --- Tabs unchanged (use the same AboutTab / ExperienceTab / ProjectsTab / SkillsTab / ContactTab) ---

class AboutTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const AboutTab(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    final links = List<Map<String, dynamic>>.from(data['links'] ?? const []);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(data['title'] ?? '', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if ((data['location'] ?? '').toString().isNotEmpty)
          Text('${data['location']}', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        if ((data['summary'] ?? '').toString().isNotEmpty)
          Text(data['summary'], style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: links.map((l) => ActionChip(
            label: Text(l['label'] ?? ''),
            onPressed: () => launchUrl(Uri.parse((l['url'] ?? '').toString())),
          )).toList(),
        ),
      ],
    );
  }
}

class ExperienceTab extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const ExperienceTab(this.items, {super.key});
  @override
  Widget build(BuildContext context) { /* same as you had */ 
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final e = items[i];
        final bullets = List<String>.from(e['bullets'] ?? const []);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${e['role']} • ${e['company']}', style: Theme.of(context).textTheme.titleMedium),
              if ((e['dates'] ?? '').toString().isNotEmpty)
                Text(e['dates'], style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              ...bullets.map((b) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(child: Text(b)),
                    ],
                  ),
                  const SizedBox(height: 6), // adjust spacing here
                ],
              )),
            ]),
          ),
        );
      },
    );
  }
}

class ProjectsTab extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const ProjectsTab(this.items, {super.key});
  @override
  Widget build(BuildContext context) { /* same as you had */ 
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final p = items[i];
        final tech = List<String>.from(p['tech'] ?? const []);
        final url = (p['url'] ?? '').toString();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['name'] ?? '', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              if (tech.isNotEmpty) Wrap(spacing: 6, children: tech.map((t) => Chip(label: Text(t))).toList()),
              const SizedBox(height: 8),
              if ((p['desc'] ?? '').toString().isNotEmpty) Text(p['desc']),
              const SizedBox(height: 8),
              if (url.isNotEmpty)
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse(url)),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open'),
                ),
            ]),
          ),
        );
      },
    );
  }
}

class SkillsTab extends StatelessWidget {
  final List<dynamic> skills; // may be String or Map
  final List<Map<String, dynamic>> education;
  const SkillsTab(this.skills, {super.key, this.education = const []});

  String _labelFrom(dynamic s) {
    if (s is String) return s.trim();
    if (s is Map) {
      for (final k in const ['label', 'name', 'text', 'title']) {
        final v = s[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      // last-resort: first stringy value
      for (final v in s.values) {
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    }
    return '';
  }

  String _iconNameFrom(dynamic s) {
    if (s is Map) {
      final v = s['icon'] ?? s['iconName'] ?? s['icon_key'];
      return v?.toString() ?? '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    for (final s in skills) {
      final label = _labelFrom(s);
      if (label.isEmpty) continue; // drop empty entries

      final iconName = _iconNameFrom(s);
      final icon = iconName.isEmpty ? null : Icon(_iconForName(iconName));

      chips.add(Chip(avatar: icon, label: Text(label)));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: chips),

        if (education.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(tr('education'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...education.map((e) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.school),
                title: Text((e['school'] ?? '').toString()),
                subtitle: Text([
                  e['dates'],
                  e['notes'],
                ].where((x) => (x ?? '').toString().isNotEmpty).join(' • ')),
              )),
        ],
      ],
    );
  }
}

class ContactTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const ContactTab(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    final email = (data['email'] ?? '').toString();
    final links = List<Map<String, dynamic>>.from(data['links'] ?? const []);

    final lang = Localizations.localeOf(context).languageCode.toLowerCase(); // 'en' | 'fr'
    const baseUrl = 'https://resume-app-omer.web.app';
    final siteUrl = '$baseUrl?lang=$lang';

    final pdf = (data['pdf'] as Map<String, dynamic>?) ?? const {};
    final fallback = lang == 'fr' ? (pdf['fr'] ?? pdf['en']) : (pdf['en'] ?? pdf['fr']);
    final pdfUrl = (fallback ?? '').toString();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (email.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.email),
            title: Text(email),
            onTap: () => launchUrl(Uri.parse('mailto:$email')),
          ),
        ...links.map((l) => ListTile(
              leading: Icon(_iconForName((l['icon'] ?? '').toString())),
              title: Text((l['label'] ?? '').toString()),
              subtitle: Text((l['url'] ?? '').toString()),
              onTap: () => launchUrl(Uri.parse((l['url'] ?? '').toString())),
            )),
        const SizedBox(height: 24),
        Text(
          lang == 'fr'
              ? 'Scanner le code QR pour voir mon CV en ligne'
              : 'Scan the QR Code to view my live Resume',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),

        // Dynamic QR (no asset needed)
        Center(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: QrImageView(
                      data: siteUrl,                 // must be non-empty
                      version: QrVersions.auto,
                      size: 180,
                      // These two help visibility in dark/light themes:
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square),
                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square),

                      // If anything fails, you'll see why instead of an empty box:
                      errorStateBuilder: (context, err) => SizedBox(
                        width: 180, height: 180,
                        child: Center(
                          child: Text(
                            'QR error:\n$err',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
