import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:flutter/material.dart';
import 'package:resume_app/features/shared/editors/about_editor.dart';
import 'package:resume_app/features/shared/editors/experiences_editor.dart';
import 'package:resume_app/features/shared/editors/projects_editor.dart';
import 'package:resume_app/features/shared/utils/icon_registry.dart';

import 'package:url_launcher/url_launcher.dart';

// import 'dart:typed_data';
// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;

import 'features/shared/widgets/labeled_text.dart';
import 'features/shared/editors/contact_editor.dart';
import 'features/shared/editors/links_editor.dart';
import 'features/shared/editors/skills_editor.dart';
import 'features/shared/editors/education_editor.dart';
import 'features/shared/models/resume_models.dart';

/// AdminDashboard shared by Admins and Editors.
/// - Admins see: Users + Resume(EN) + Resume(FR)
/// - Editors see: Resume(EN) + Resume(FR)
class AdminDashboard extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  final bool isAdmin;

  const AdminDashboard({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
    required this.isAdmin,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  late final TabController _tab =
      TabController(length: widget.isAdmin ? 3 : 2, vsync: this);

  @override
  Widget build(BuildContext context) {
    final tabs = <Tab>[
      if (widget.isAdmin) const Tab(text: 'Users', icon: Icon(Icons.group)),
      const Tab(text: 'Resume (EN)', icon: Icon(Icons.description)),
      const Tab(text: 'Resume (FR)', icon: Icon(Icons.description)),
    ];

    final views = <Widget>[
      if (widget.isAdmin) const _UsersTab(),
      const _ResumeEditor(lang: 'en'),
      const _ResumeEditor(lang: 'fr'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Admin' : 'Editor'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: widget.onToggleTheme,
            icon: Icon(
              widget.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => fa.FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: TabBar(controller: _tab, tabs: tabs),
      ),
      body: TabBarView(controller: _tab, children: views),
    );
  }
}

/// ---------------- USERS (admins only) ----------------
class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final selfUid = fa.FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('users').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No users yet'));

        final adminCount = docs.where((d) => (d.data()['role'] == 'admin')).length;

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final d = docs[i];
            final data = d.data();
            final email = (data['email'] ?? '') as String;
            final approved = (data['approved'] ?? false) as bool;
            final emailVerified = (data['emailVerified'] ?? false) as bool;

            final String roleDisplay = switch (data['role']) {
              'viewer' => 'viewer',
              'editor' => 'editor',
              'admin'  => 'admin',
              _        => 'unknown',
            };

            final bool isSelf = d.id == selfUid;
            final bool isThisAdmin = roleDisplay == 'admin';
            final bool lockThisRow = (isSelf && isThisAdmin && adminCount <= 1);

            return Card(
              child: ListTile(
                title: Row(
                  children: [
                    Expanded(child: Text(email.isEmpty ? d.id : email)),
                    if (!emailVerified)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Tooltip(
                          message: 'Email not verified',
                          child: Chip(label: Text('Unverified')),
                        ),
                      ),
                  ],
                ),
                subtitle: Text('uid: ${d.id}  •  role: $roleDisplay'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: roleDisplay,
                      items: const [
                        DropdownMenuItem(value: 'unknown', child: Text('unknown')),
                        DropdownMenuItem(value: 'viewer',  child: Text('viewer')),
                        DropdownMenuItem(value: 'editor',  child: Text('editor')),
                        DropdownMenuItem(value: 'admin',   child: Text('admin')),
                      ],
                      onChanged: (v) async {
                        if (v == null) return;
                        if (lockThisRow) return;
                        if (isThisAdmin && adminCount <= 1 && v != 'admin') {
                          // prevent removing the last admin
                          return;
                        }
                        await d.reference.update({'role': v == 'unknown' ? null : v});
                      },
                    ),
                    const SizedBox(width: 12),
                    FilterChip(
                      label: const Text('Approved'),
                      selected: approved,
                      onSelected: (!emailVerified || lockThisRow)
                          ? null
                          : (sel) => d.reference.update({'approved': sel}),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// ---------------- RESUME EDITOR (per language) ----------------
class _ResumeEditor extends StatefulWidget {
  final String lang; // 'en' or 'fr'
  const _ResumeEditor({required this.lang});

  @override
  State<_ResumeEditor> createState() => _ResumeEditorState();
}

class _ResumeEditorState extends State<_ResumeEditor> {
  final _name = TextEditingController();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _summary = TextEditingController();
  final _email = TextEditingController();

  final _pdfEn = TextEditingController();
  final _pdfFr = TextEditingController();

  bool _openAbout = false;
  bool _openExp = false;
  bool _openProj = false;
  bool _openSkills = false;
  bool _openEducation = false;
  bool _openContact = false;

  /// Links: list of { label, url }
  List<LinkRow> _links = [];

  /// Skills: simple string list
  List<SkillRow> _skills = [];

  /// Education: list of {school, dates, notes}
  List<EduRow> _education = [];

  /// Experience/projects are shown read-only here; you can expand later
  List<Map<String, dynamic>> _experience = [];
  List<Map<String, dynamic>> _projects = [];

  String? _error;
  bool _loading = true;
  bool _dirty = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _title.dispose();
    _location.dispose();
    _summary.dispose();
    _email.dispose();
    _pdfEn.dispose();
    _pdfFr.dispose();
    super.dispose();
  }

  void _queueDebouncedSave() {
    _dirty = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _save(merge: true, silent: true);
    });
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('resume')
          .doc(widget.lang)
          .get();
      final data = (snap.data() ?? <String, dynamic>{});

      _name.text = (data['name'] ?? '').toString();
      _title.text = (data['title'] ?? '').toString();
      _location.text = (data['location'] ?? '').toString();
      _summary.text = (data['summary'] ?? '').toString();
      _email.text = (data['email'] ?? '').toString();

      // Links
      final rawLinks = List<Map<String, dynamic>>.from(data['links'] ?? const []);
      _links = rawLinks
      .map((m) => LinkRow(
            label: (m['label'] ?? '').toString(),
            url: (m['url'] ?? '').toString(),
            icon: (m['icon'] ?? '').toString(),
          ))
      .toList();

      // Experience/projects (read-only UI for now)
      _experience = List<Map<String, dynamic>>.from(data['experience'] ?? const []);
      _projects = List<Map<String, dynamic>>.from(data['projects'] ?? const []);

      // Skills (backward compatible)
      final rawSkills = List.from(data['skills'] ?? const []);
      _skills = rawSkills.map((e) => SkillRow.fromJson(e)).toList();

      // Education (moved under Skills/Education)
      final rawEdu = List<Map<String, dynamic>>.from(data['education'] ?? const []);
      _education = rawEdu.map((e) => EduRow(
        school: (e['school'] ?? '').toString(),
        dates:  (e['dates']  ?? '').toString(),
        notes:  (e['notes']  ?? '').toString(),
      )).toList();

      final pdf = (data['pdf'] as Map<String, dynamic>?) ?? const {};
      _pdfEn.text = (pdf['en'] ?? '').toString();
      _pdfFr.text = (pdf['fr'] ?? '').toString();

      _dirty = false;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _confirmDiscardIfDirty() async {
    if (!_dirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Discard unsaved changes?'),
            content: const Text('You have unsaved edits. Leave anyway?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard')),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _save({required bool merge, bool silent = false}) async {
    final ref = FirebaseFirestore.instance.collection('resume').doc(widget.lang);
    final payload = <String, dynamic>{
      'name': _name.text,
      'title': _title.text,
      'location': _location.text,
      'summary': _summary.text,
      'email': _email.text.trim(),
      'links': _links
        .where((l) => l.label.trim().isNotEmpty || l.url.trim().isNotEmpty)
        .map((l) => {
              'label': l.label.trim(),
              'url': l.url.trim(),
              'icon': l.icon.trim(),
            })
        .toList(),
      'skills': _skills.map((s) => s.toJson()).toList(),
      'education': _education
          .where((e) => e.school.trim().isNotEmpty || e.dates.trim().isNotEmpty || e.notes.trim().isNotEmpty)
          .map((e) => {'school': e.school.trim(), 'dates': e.dates.trim(), 'notes': e.notes.trim()})
          .toList(),
      
      'pdf': {
        'en': _pdfEn.text.trim(),
        'fr': _pdfFr.text.trim(),
      },
    };

    try {
      await ref.set(payload, SetOptions(merge: merge));
      _dirty = false;
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved (${merge ? "merge" : "replace"}) for ${widget.lang.toUpperCase()}')),
        );
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid PDF URL')),
      );
      return;
    }

    // Open in a new tab on web, external app elsewhere
    final ok = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch PDF')),
      );
    }
  }

  // ---- Helpers for in-memory edits & UI controls ----
  void _moveUp(List list, int i) {
    if (i <= 0) return;
    setState(() {
      final tmp = list[i - 1];
      list[i - 1] = list[i];
      list[i] = tmp;
    });
  }

  void _moveDown(List list, int i) {
    if (i >= list.length - 1) return;
    setState(() {
      final tmp = list[i + 1];
      list[i + 1] = list[i];
      list[i] = tmp;
    });
  }

  Widget _chipIcon(IconData icon, VoidCallback? onTap, {String? tooltip}) {
    final btn = IconButton(icon: Icon(icon), onPressed: onTap);
    return tooltip == null ? btn : Tooltip(message: tooltip, child: btn);
  }

  Future<void> _saveExperience() async {
    final ref = FirebaseFirestore.instance.collection('resume').doc(widget.lang);
    await ref.set({'experience': _experience}, SetOptions(merge: true));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Experience saved for ${widget.lang.toUpperCase()}')),
    );
    _dirty = false;
  }

  Future<void> _saveProjects() async {
    final ref = FirebaseFirestore.instance.collection('resume').doc(widget.lang);
    await ref.set({'projects': _projects}, SetOptions(merge: true));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Projects saved for ${widget.lang.toUpperCase()}')),
    );
    _dirty = false;
  }

  // Single experience card editor
  Widget _experienceEditor(int index) {
    final item = _experience[index];
    final role     = TextEditingController(text: (item['role'] ?? '').toString());
    final company  = TextEditingController(text: (item['company'] ?? '').toString());
    final dates    = TextEditingController(text: (item['dates'] ?? '').toString());
    final bullets  = List<String>.from(item['bullets'] ?? const []);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(child: Text('Experience #${index + 1}', style: Theme.of(context).textTheme.titleSmall)),
              _chipIcon(Icons.arrow_upward,    () { _moveUp(_experience, index); _dirty = true; }, tooltip: 'Move up'),
              _chipIcon(Icons.arrow_downward,  () { _moveDown(_experience, index); _dirty = true; }, tooltip: 'Move down'),
              _chipIcon(Icons.delete_outline,  () {
                setState(() { _experience.removeAt(index); _dirty = true; });
              }, tooltip: 'Remove'),
            ]),
            const SizedBox(height: 8),
            TextField(controller: role, decoration: const InputDecoration(labelText: 'Role')),
            const SizedBox(height: 8),
            TextField(controller: company, decoration: const InputDecoration(labelText: 'Company')),
            const SizedBox(height: 8),
            TextField(controller: dates, decoration: const InputDecoration(labelText: 'Dates')),
            const SizedBox(height: 12),
            Text('Bullets', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),

            ...List.generate(bullets.length, (j) {
              final c = TextEditingController(text: bullets[j]);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: TextField(
                      controller: c,
                      decoration: InputDecoration(labelText: '• Bullet ${j + 1}'),
                      onChanged: (v) => bullets[j] = v,
                    )),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Remove bullet',
                      onPressed: () {
                        setState(() { bullets.removeAt(j); _dirty = true; });
                      },
                    ),
                  ],
                ),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () { setState(() { bullets.add(''); _dirty = true; }); },
                icon: const Icon(Icons.add),
                label: const Text('Add bullet'),
              ),
            ),

            const SizedBox(height: 8),
            // Apply local controller values back to list item (not saving to Firestore yet)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _experience[index] = {
                    'role': role.text,
                    'company': company.text,
                    'dates': dates.text,
                    'bullets': bullets,
                  };
                  _dirty = true;
                });
              },
              icon: const Icon(Icons.check),
              label: const Text('Apply changes to list'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Failed to load resume (${widget.lang}):\n$_error', textAlign: TextAlign.center),
        ),
      );
    }

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final ok = await _confirmDiscardIfDirty();
        if (ok && context.mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Editing locale: ${widget.lang.toUpperCase()}',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),

                  // ------------ ABOUT (Name/Title/Location/Summary)
                  AboutEditor(
                    initiallyExpanded: _openAbout,
                    nameController: _name, 
                    titleController: _title, 
                    locationController: _location, 
                    summaryController: _summary
                  ),

                  // ------------ EXPERIENCE (editable)
                  ExperiencesEditor(
                    initiallyExpanded: _openExp,
                    items: _experience,
                    onExpansionChanged: (v) => setState(() => _openExp = v),
                    onChanged: (list) => setState(() { _experience = list; _dirty = true; }),
                    onSave: _saveExperience,
                  ),

                  // ------------ PROJECTS (editable)
                  ProjectsEditor(
                    initiallyExpanded: _openProj,
                    items: _projects,
                    onExpansionChanged: (v) => setState(() => _openProj = v),
                    onChanged: (list) => setState(() { _projects = list; _dirty = true; }),
                    onSave: _saveProjects,
                  ),

                  // ------------ SKILLS
                  // SkillsEditor(
                  //   initiallyExpanded: _openSkills,
                  //   skills: _skills,
                  //   onExpansionChanged: (v) => setState(() => _openSkills = v),
                  //   onChanged: (s) => setState(() { _skills = s; _queueDebouncedSave(); }),
                  // ),
                  SkillsEditor(
                    initiallyExpanded: _openSkills,
                    skills: _skills,
                    onExpansionChanged: (v) => setState(() => _openSkills = v),
                    onChanged: (next) => setState(() {
                      _skills = next;
                      _queueDebouncedSave();
                    }),
                  ),

                  // ------------ EDUCATION
                  EducationEditor(
                    initiallyExpanded: _openEducation,
                    rows: _education,
                    onExpansionChanged: (v) => setState(() => _openEducation = v),
                    onChanged: (rows) => setState(() { _education = rows; _queueDebouncedSave(); }),
                  ),

                  // ------------ CONTACT (Email/LinkedIn/Github)
                  ContactEditor(
                    initiallyExpanded: _openContact,
                    onExpansionChanged: (v) => setState(() => _openContact = v),
                    emailController: _email,
                    links: _links,
                    onLinksChanged: (rows) => setState(() {
                      _links = rows;
                      _queueDebouncedSave();
                    }),
                    onEmailChanged: (_) => _queueDebouncedSave(),

                    pdfEnController: _pdfEn,
                    pdfFrController: _pdfFr,
                    showPdfButtons: true,
                    onOpenPdf: _openPdf,
                  ),

                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _save(merge: true),
                        icon: const Icon(Icons.save),
                        label: const Text('Save (merge)'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Replace entire document?'),
                              content: const Text('This will overwrite fields not present in the editor payload. Continue?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Replace')),
                              ],
                            ),
                          );
                          if (ok == true) _save(merge: false);
                        },
                        icon: const Icon(Icons.save_as),
                        label: const Text('Save (replace)'),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final ok = await _confirmDiscardIfDirty();
                          if (ok) _load();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reload'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Simple offline banner (Cloud Firestore provides this via snapshotsInSync too, but this is fine)
          StreamBuilder(
            stream: FirebaseFirestore.instance.snapshotsInSync(),
            builder: (_, __) {
              // This stream just ticks; for a real offline indicator you could use connectivity_plus.
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}