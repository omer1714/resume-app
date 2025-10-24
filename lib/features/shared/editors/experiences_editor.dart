import 'package:flutter/material.dart';

/// Public widget: renders the whole Experience section
/// (ExpansionTile + list of cards + add & save actions).
class ExperiencesEditor extends StatelessWidget {
  final bool initiallyExpanded;
  final List<Map<String, dynamic>> items; // [{role, company, dates, bullets: List<String>}]
  final ValueChanged<List<Map<String, dynamic>>> onChanged;
  final VoidCallback? onSave;
  final ValueChanged<bool>? onExpansionChanged;

  const ExperiencesEditor({
    super.key,
    required this.initiallyExpanded,
    required this.items,
    required this.onChanged,
    this.onSave,
    this.onExpansionChanged,
  });

  void _moveUp(List<Map<String, dynamic>> list, int i) {
    if (i <= 0) return;
    final tmp = list[i - 1];
    list[i - 1] = list[i];
    list[i] = tmp;
  }

  void _moveDown(List<Map<String, dynamic>> list, int i) {
    if (i >= list.length - 1) return;
    final tmp = list[i + 1];
    list[i + 1] = list[i];
    list[i] = tmp;
  }

  @override
  Widget build(BuildContext context) {
    // Work on a copy so we can emit a new list reference on each change.
    final itemsCopy = [...items];

    void apply() => onChanged([...itemsCopy]);

    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      onExpansionChanged: onExpansionChanged,
      leading: const Icon(Icons.work),
      title: const Text('Experience'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        const SizedBox(height: 8),
        ...List.generate(itemsCopy.length, (i) {
          return _ExperienceCardEditor(
            index: i,
            item: itemsCopy[i],
            onMoveUp: () {
              _moveUp(itemsCopy, i);
              apply();
            },
            onMoveDown: () {
              _moveDown(itemsCopy, i);
              apply();
            },
            onRemove: () {
              itemsCopy.removeAt(i);
              apply();
            },
            onApply: (val) {
              itemsCopy[i] = val;
              apply();
            },
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              itemsCopy.add({
                'role': '',
                'company': '',
                'dates': '',
                'bullets': <String>[],
              });
              apply();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add experience'),
          ),
        ),
        const SizedBox(height: 8),
        if (onSave != null)
          FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save),
            label: const Text('Save experience'),
          ),
      ],
    );
  }
}

/// Private: single experience card editor (your original ExperienceEditor,
/// unchanged in visuals/behavior).
class _ExperienceCardEditor extends StatelessWidget {
  final int index;
  final Map<String, dynamic> item; // {role, company, dates, bullets: List<String>}
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;
  final ValueChanged<Map<String, dynamic>> onApply;

  const _ExperienceCardEditor({
    required this.index,
    required this.item,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final role    = TextEditingController(text: '${item['role'] ?? ''}');
    final company = TextEditingController(text: '${item['company'] ?? ''}');
    final dates   = TextEditingController(text: '${item['dates'] ?? ''}');
    final bullets = List<String>.from(item['bullets'] ?? const <String>[]);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(
                child: Text('Experience #${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall),
              ),
              IconButton(tooltip: 'Move up',   icon: const Icon(Icons.arrow_upward),   onPressed: onMoveUp),
              IconButton(tooltip: 'Move down', icon: const Icon(Icons.arrow_downward), onPressed: onMoveDown),
              IconButton(tooltip: 'Remove',    icon: const Icon(Icons.delete_outline), onPressed: onRemove),
            ]),
            const SizedBox(height: 8),
            TextField(controller: role,    decoration: const InputDecoration(labelText: 'Role')),
            const SizedBox(height: 8),
            TextField(controller: company, decoration: const InputDecoration(labelText: 'Company')),
            const SizedBox(height: 8),
            TextField(controller: dates,   decoration: const InputDecoration(labelText: 'Dates')),
            const SizedBox(height: 12),
            Text('Bullets', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            ...List.generate(bullets.length, (j) {
              final c = TextEditingController(text: bullets[j]);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: c,
                      decoration: InputDecoration(labelText: '• Bullet ${j + 1}'),
                      onChanged: (v) => bullets[j] = v,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Remove bullet',
                    onPressed: () {
                      bullets.removeAt(j);
                      onApply({
                        'role': role.text,
                        'company': company.text,
                        'dates': dates.text,
                        'bullets': [...bullets],
                      });
                    },
                  ),
                ]),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  bullets.add('');
                  onApply({
                    'role': role.text,
                    'company': company.text,
                    'dates': dates.text,
                    'bullets': [...bullets],
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Add bullet'),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => onApply({
                'role': role.text,
                'company': company.text,
                'dates': dates.text,
                'bullets': [...bullets],
              }),
              icon: const Icon(Icons.check),
              label: const Text('Apply changes to list'),
            ),
          ],
        ),
      ),
    );
  }
}