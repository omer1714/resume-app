import 'package:flutter/material.dart';

class LinkRow {
  String label;
  String url;
  String icon; // material icon key from icon_registry
  LinkRow({this.label = '', this.url = '', this.icon = ''});

  Map<String, dynamic> toMap() => {'label': label, 'url': url, 'icon': icon};
  factory LinkRow.fromMap(Map<String, dynamic> m) =>
      LinkRow(label: '${m['label'] ?? ''}', url: '${m['url'] ?? ''}', icon: '${m['icon'] ?? ''}');
}

class EduRow {
  String school;
  String dates;
  String notes;
  EduRow({this.school = '', this.dates = '', this.notes = ''});

  Map<String, dynamic> toMap() => {'school': school, 'dates': dates, 'notes': notes};
  factory EduRow.fromMap(Map<String, dynamic> m) => EduRow(
    school: '${m['school'] ?? ''}',
    dates:  '${m['dates']  ?? ''}',
    notes:  '${m['notes']  ?? ''}',
  );
}

class SkillRow {
  String name;       // e.g. "React"
  String icon;       // e.g. "react" (a key in your icon registry). Empty = none.

  SkillRow({this.name = '', this.icon = ''});

  factory SkillRow.fromJson(dynamic raw) {
    // Backward compat: convert plain strings to {name, icon:''}
    if (raw is String) return SkillRow(name: raw, icon: '');
    final m = Map<String, dynamic>.from(raw ?? const {});
    return SkillRow(
      name: (m['name'] ?? '').toString(),
      icon: (m['icon'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'icon': icon.trim(),
  };
}