import 'package:flutter/material.dart';

/// Public widget: the whole Projects section (ExpansionTile + list + add/save).
class ProjectsEditor extends StatelessWidget {
  final bool initiallyExpanded;
  final List<Map<String, dynamic>> items; // [{name, desc, url, tech: List<String>}]
  final ValueChanged<List<Map<String, dynamic>>> onChanged;
  final VoidCallback? onSave;
  final ValueChanged<bool>? onExpansionChanged;

  const ProjectsEditor({
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
    final itemsCopy = [...items];
    void apply() => onChanged([...itemsCopy]);

    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      onExpansionChanged: onExpansionChanged,
      leading: const Icon(Icons.apps),
      title: const Text('Projects'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        const SizedBox(height: 8),
        ...List.generate(itemsCopy.length, (i) {
          return _ProjectCardEditor(
            index: i,
            item: itemsCopy[i],
            onMoveUp: () { _moveUp(itemsCopy, i); apply(); },
            onMoveDown: () { _moveDown(itemsCopy, i); apply(); },
            onRemove: () { itemsCopy.removeAt(i); apply(); },
            onApply: (val) { itemsCopy[i] = val; apply(); },
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              itemsCopy.add({'name': '', 'desc': '', 'url': '', 'tech': <String>[]});
              apply();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add project'),
          ),
        ),
        const SizedBox(height: 8),
        if (onSave != null)
          FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save),
            label: const Text('Save projects'),
          ),
      ],
    );
  }
}

/// Private: single project card editor (your original ProjectEditor, unchanged visually).
class _ProjectCardEditor extends StatelessWidget {
  final int index;
  final Map<String, dynamic> item; // {name, desc, url, tech: List<String>}
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;
  final ValueChanged<Map<String, dynamic>> onApply;

  const _ProjectCardEditor({
    required this.index,
    required this.item,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final name = TextEditingController(text: '${item['name'] ?? ''}');
    final desc = TextEditingController(text: '${item['desc'] ?? ''}');
    final url  = TextEditingController(text: '${item['url']  ?? ''}');
    final tech = List<String>.from(item['tech'] ?? const <String>[]);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(child: Text('Project #${index + 1}', style: Theme.of(context).textTheme.titleSmall)),
              IconButton(tooltip: 'Move up',   icon: const Icon(Icons.arrow_upward),   onPressed: onMoveUp),
              IconButton(tooltip: 'Move down', icon: const Icon(Icons.arrow_downward), onPressed: onMoveDown),
              IconButton(tooltip: 'Remove',    icon: const Icon(Icons.delete_outline), onPressed: onRemove),
            ]),
            const SizedBox(height: 8),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: desc, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
            const SizedBox(height: 8),
            TextField(controller: url,  decoration: const InputDecoration(labelText: 'URL')),
            const SizedBox(height: 12),
            Text('Tech (chips)', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            ...List.generate(tech.length, (j) {
              final c = TextEditingController(text: tech[j]);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: c,
                      decoration: InputDecoration(labelText: 'Tag ${j + 1}'),
                      onChanged: (v) => tech[j] = v,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Remove',
                    onPressed: () {
                      tech.removeAt(j);
                      onApply({'name': name.text, 'desc': desc.text, 'url': url.text, 'tech': [...tech]});
                    },
                  ),
                ]),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  tech.add('');
                  onApply({'name': name.text, 'desc': desc.text, 'url': url.text, 'tech': [...tech]});
                },
                icon: const Icon(Icons.add),
                label: const Text('Add tag'),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => onApply({'name': name.text, 'desc': desc.text, 'url': url.text, 'tech': [...tech]}),
              icon: const Icon(Icons.check),
              label: const Text('Apply changes to list'),
            ),
          ],
        ),
      ),
    );
  }
}