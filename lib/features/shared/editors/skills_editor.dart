import 'package:flutter/material.dart';
import '../models/resume_models.dart';
import '../utils/icon_registry.dart';

class SkillsEditor extends StatelessWidget {
  final bool initiallyExpanded;
  final List<SkillRow> skills;
  final ValueChanged<List<SkillRow>> onChanged;
  final ValueChanged<bool>? onExpansionChanged;

  const SkillsEditor({
    super.key,
    required this.initiallyExpanded,
    required this.skills,
    required this.onChanged,
    this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      onExpansionChanged: onExpansionChanged,
      leading: const Icon(Icons.star),
      title: const Text('Skills'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        const SizedBox(height: 8),
        _SkillsScope(
          skills: skills,
          onChanged: onChanged,
          child: const _SkillsListEditor(),
        ),
      ],
    );
  }
}

class _SkillsListEditor extends StatelessWidget {
  const _SkillsListEditor();

  @override
  Widget build(BuildContext context) {
    final scope = _SkillsScope.of(context);
    final theme = Theme.of(context);

    void apply(List<SkillRow> next) => scope.onChanged([...next]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: scope.skills.length,
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex -= 1;
            final next = [...scope.skills];
            final moved = next.removeAt(oldIndex);
            next.insert(newIndex, moved);
            apply(next);
          },
          proxyDecorator: (child, index, animation) {
            Widget core = child;
            if (child is Padding && child.child != null) core = child.child!;
            return AnimatedBuilder(
              animation: animation,
              child: core,
              builder: (context, proxyChild) {
                final t = Curves.easeOut.transform(animation.value);
                return Transform.scale(
                  scale: 1.0 + 0.015 * t,
                  child: Material(
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    color: theme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(0.45),
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: proxyChild,
                  ),
                );
              },
            );
          },
          itemBuilder: (context, i) {
            final row = scope.skills[i];
            return Padding(
              key: ValueKey('skill-$i-${row.name}-${row.icon}'),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Drag handle
                      ReorderableDragStartListener(
                        index: i,
                        child: const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.drag_handle),
                        ),
                      ),
                      // Icon picker button (keeps its own width; no wrap issues)
                      _IconChip(
                        iconKey: row.icon,
                        onPick: (newKey) {
                          final next = [...scope.skills];
                          next[i] = SkillRow(name: row.name, icon: newKey);
                          apply(next);
                        },
                      ),
                      const SizedBox(width: 8),
                      // Name field (responsive; fills space)
                      Expanded(
                        child: TextFormField(
                          initialValue: row.name,
                          decoration: const InputDecoration(labelText: 'Skill'),
                          onChanged: (v) {
                            final next = [...scope.skills];
                            next[i] = SkillRow(name: v, icon: row.icon);
                            apply(next);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          final next = [...scope.skills]..removeAt(i);
                          apply(next);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => apply([...scope.skills, SkillRow(name: '', icon: '')]),
          icon: const Icon(Icons.add),
          label: const Text('Add skill'),
        ),
      ],
    );
  }
}

class _IconChip extends StatelessWidget {
  final String iconKey;
  final ValueChanged<String> onPick;

  const _IconChip({required this.iconKey, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final icon = skillIconFor(iconKey);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final picked = await showDialog<String>(
          context: context,
          builder: (_) => const _IconPickerDialog(),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        width: 44, height: 44, alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon),
      ),
    );
  }
}

class _IconPickerDialog extends StatelessWidget {
  const _IconPickerDialog();

  @override
  Widget build(BuildContext context) {
    final keys = allSkillIconKeys();
    return AlertDialog(
      title: const Text('Choose a skill icon'),
      content: SizedBox(
        width: 420,
        height: 320,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5, mainAxisSpacing: 12, crossAxisSpacing: 12,
          ),
          itemCount: keys.length,
          itemBuilder: (_, i) {
            final key = keys[i];
            return InkWell(
              onTap: () => Navigator.of(context).pop(key),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(skillIconFor(key)),
                  const SizedBox(height: 6),
                  Text(key.isEmpty ? 'none' : key,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ],
    );
  }
}

class _SkillsScope extends InheritedWidget {
  final List<SkillRow> skills;
  final ValueChanged<List<SkillRow>> onChanged;

  const _SkillsScope({
    required this.skills,
    required this.onChanged,
    required super.child,
    super.key,
  });

  static _SkillsScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_SkillsScope>();
    assert(scope != null, 'No _SkillsScope found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(_SkillsScope old) =>
      old.skills != skills || old.onChanged != onChanged;
}



/*

ExpansionTile(
  //key: PageStorageKey('skills_${widget.lang}'),
  //initiallyExpanded: false,
  initiallyExpanded: _openSkills,
  onExpansionChanged: (v) => setState(() => _openSkills = v),
  leading: const Icon(Icons.star),
  title: const Text('Skills & Education'),
  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
  children: [
    const Text('Skills', style: TextStyle(fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    _SkillsEditor(
      skills: _skills,
      onChanged: (s) { setState(() { _skills = s; _queueDebouncedSave(); }); },
    ),
    const SizedBox(height: 16),
    const Text('Education', style: TextStyle(fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    _EducationEditor(
      rows: _education,
      onChanged: (rows) { setState(() { _education = rows; _queueDebouncedSave(); }); },
    ),
  ],
),

*/