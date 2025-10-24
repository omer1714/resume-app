import 'package:flutter/material.dart';
import '../models/resume_models.dart';

/// Public widget: the whole Education section with ExpansionTile
class EducationEditor extends StatelessWidget {
  final bool initiallyExpanded;
  final List<EduRow> rows;
  final ValueChanged<List<EduRow>> onChanged;
  final ValueChanged<bool>? onExpansionChanged;

  const EducationEditor({
    super.key,
    required this.initiallyExpanded,
    required this.rows,
    required this.onChanged,
    this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      onExpansionChanged: onExpansionChanged,
      leading: const Icon(Icons.school),
      title: const Text('Education'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _EducationList(rows: rows, onChanged: onChanged),
      ],
    );
  }
}

/// Private widget: the actual editor list (unchanged logic)
class _EducationList extends StatelessWidget {
  final List<EduRow> rows;
  final ValueChanged<List<EduRow>> onChanged;

  const _EducationList({
    required this.rows,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = [...rows];
    void apply() => onChanged([...items]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(items.length, (i) {
          final r = items[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextFormField(
                    initialValue: r.school,
                    decoration: const InputDecoration(labelText: 'School'),
                    onChanged: (v) { r.school = v; apply(); },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: r.dates,
                          decoration: const InputDecoration(labelText: 'Dates'),
                          onChanged: (v) { r.dates = v; apply(); },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: r.notes,
                          decoration: const InputDecoration(labelText: 'Notes'),
                          onChanged: (v) { r.notes = v; apply(); },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    IconButton(
                      tooltip: 'Move up',
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: i == 0 ? null : () {
                        final tmp = items[i - 1]; items[i - 1] = items[i]; items[i] = tmp; apply();
                      },
                    ),
                    IconButton(
                      tooltip: 'Move down',
                      icon: const Icon(Icons.arrow_downward),
                      onPressed: i == items.length - 1 ? null : () {
                        final tmp = items[i + 1]; items[i + 1] = items[i]; items[i] = tmp; apply();
                      },
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () { items.removeAt(i); apply(); },
                    ),
                  ]),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () { items.add(EduRow()); apply(); },
          icon: const Icon(Icons.add),
          label: const Text('Add education'),
        ),
      ],
    );
  }
}