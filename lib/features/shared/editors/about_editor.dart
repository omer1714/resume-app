import 'package:flutter/material.dart';
import '../widgets/labeled_text.dart';

class AboutEditor extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController titleController;
  final TextEditingController locationController;
  final TextEditingController summaryController;
  final VoidCallback? onAnyFieldChanged;
  final bool initiallyExpanded;

  const AboutEditor({
    super.key,
    required this.nameController,
    required this.titleController,
    required this.locationController,
    required this.summaryController,
    this.onAnyFieldChanged,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      leading: const Icon(Icons.person),
      title: const Text('About'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        LabeledText('Name', controller: nameController, onChanged: (_) => onAnyFieldChanged?.call()),
        LabeledText('Title', controller: titleController, onChanged: (_) => onAnyFieldChanged?.call()),
        LabeledText('Location', controller: locationController, onChanged: (_) => onAnyFieldChanged?.call()),
        LabeledText('Summary', controller: summaryController, maxLines: 5, onChanged: (_) => onAnyFieldChanged?.call()),
      ],
    );
  }
}

/*

ExpansionTile(
  //key: PageStorageKey('about_${widget.lang}'),
  //initiallyExpanded: true,
  initiallyExpanded: _openAbout,
  onExpansionChanged: (v) => setState(() => _openAbout = v),
  leading: const Icon(Icons.person),
  title: const Text('About'),
  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
  children: [
    _LabeledText('Name', controller: _name, onChanged: (_) => _queueDebouncedSave()),
    _LabeledText('Title', controller: _title, onChanged: (_) => _queueDebouncedSave()),
    _LabeledText('Location', controller: _location, onChanged: (_) => _queueDebouncedSave()),
    _LabeledText('Summary', controller: _summary, maxLines: 5, onChanged: (_) => _queueDebouncedSave()),
  ],
),

*/