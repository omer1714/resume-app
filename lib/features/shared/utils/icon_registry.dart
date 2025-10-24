import 'package:flutter/material.dart';

const Map<String, IconData> kIconRegistry = {
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
};

IconData iconForName(String? name) => name == null || name.isEmpty
    ? Icons.link
    : (kIconRegistry[name] ?? Icons.link);

class IconPickerDialog extends StatelessWidget {
  const IconPickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final names = kIconRegistry.keys.toList();
    return AlertDialog(
      title: const Text('Choose an icon'),
      content: SizedBox(
        width: 420,
        height: 320,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5, mainAxisSpacing: 12, crossAxisSpacing: 12,
          ),
          itemCount: names.length,
          itemBuilder: (_, i) {
            final name = names[i];
            return InkWell(
              onTap: () => Navigator.of(context).pop(name),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(iconForName(name)),
                  const SizedBox(height: 6),
                  Text(name, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
    );
  }
}

const Map<String, IconData> skillIconRegistry = {
  // Popular techs — add more over time
  'react': Icons.restart_alt,        // replace with a better match if you have a custom icon font
  'flutter': Icons.flutter_dash,
  'nodejs': Icons.javascript,        // placeholder
  'python': Icons.pets,              // placeholder
  'dart': Icons.data_object,
  'typescript': Icons.code,
  'javascript': Icons.javascript,
  'aws': Icons.cloud,
  'gcp': Icons.cloud_queue,
  'docker': Icons.layers,
  'kubernetes': Icons.dns,
  'postgres': Icons.storage,
  'mysql': Icons.storage,
  'mongodb': Icons.storage,
  // fallback:
  '': Icons.circle,                  // none
};

IconData skillIconFor(String key) =>
    skillIconRegistry[key] ?? Icons.circle;

List<String> allSkillIconKeys() => skillIconRegistry.keys.toList();