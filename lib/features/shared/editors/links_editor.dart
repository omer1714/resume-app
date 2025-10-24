import 'package:flutter/material.dart';
import '../models/resume_models.dart';
import '../utils/icon_registry.dart';

class LinksEditor extends StatelessWidget {
  final List<LinkRow> rows;
  final ValueChanged<List<LinkRow>> onChanged;

  const LinksEditor({
    super.key,
    required this.rows,
    required this.onChanged,
  });

  Future<void> _pickIcon(BuildContext context, LinkRow row) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => const IconPickerDialog(),
    );
    if (selected != null) {
      row.icon = selected;
      onChanged([...rows]);
    }
  }

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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  if (isWide) {
                    return Column(
                      children: [
                        Row(children: [
                          InkWell(
                            onTap: () => _pickIcon(context, r),
                            child: Container(
                              width: 44, height: 44, alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).dividerColor),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(iconForName(r.icon)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: r.label,
                              decoration: const InputDecoration(labelText: 'Label'),
                              onChanged: (v) { r.label = v; apply(); },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: r.url,
                              decoration: const InputDecoration(labelText: 'URL'),
                              onChanged: (v) { r.url = v; apply(); },
                            ),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          IconButton(
                            tooltip: 'Up',
                            icon: const Icon(Icons.arrow_upward),
                            onPressed: i == 0 ? null : () {
                              final tmp = items[i - 1]; items[i - 1] = items[i]; items[i] = tmp; apply();
                            },
                          ),
                          IconButton(
                            tooltip: 'Down',
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
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          InkWell(
                            onTap: () => _pickIcon(context, r),
                            child: Container(
                              width: 44, height: 44, alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).dividerColor),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(iconForName(r.icon)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: r.label,
                              decoration: const InputDecoration(labelText: 'Label'),
                              onChanged: (v) { r.label = v; apply(); },
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: r.url,
                          decoration: const InputDecoration(labelText: 'URL'),
                          onChanged: (v) { r.url = v; apply(); },
                        ),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          IconButton(
                            tooltip: 'Up',
                            icon: const Icon(Icons.arrow_upward),
                            onPressed: i == 0 ? null : () {
                              final tmp = items[i - 1]; items[i - 1] = items[i]; items[i] = tmp; apply();
                            },
                          ),
                          IconButton(
                            tooltip: 'Down',
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
                    );
                  }
                },
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () { items.add(LinkRow()); apply(); },
          icon: const Icon(Icons.add),
          label: const Text('Add link'),
        ),
      ],
    );
  }
}