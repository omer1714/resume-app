import 'package:flutter/material.dart';
import '../models/resume_models.dart';
import 'links_editor.dart';

class ContactEditor extends StatelessWidget {
  final TextEditingController emailController;
  final List<LinkRow> links;
  final ValueChanged<List<LinkRow>> onLinksChanged;
  final ValueChanged<String> onEmailChanged;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged; // NEW (for consistency)

  final TextEditingController? pdfEnController;
  final TextEditingController? pdfFrController;
  final bool showPdfButtons;
  final void Function(String url)? onOpenPdf;

  const ContactEditor({
    super.key,
    required this.emailController,
    required this.links,
    required this.onLinksChanged,
    required this.onEmailChanged,
    this.initiallyExpanded = false,
    this.onExpansionChanged, // NEW

    this.pdfEnController,
    this.pdfFrController,
    this.showPdfButtons = false,
    this.onOpenPdf,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      onExpansionChanged: onExpansionChanged, // NEW
      leading: const Icon(Icons.mail),
      title: const Text('Contact'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
          onChanged: onEmailChanged,
        ),
        const SizedBox(height: 8),

        // --- NEW: PDF URL editors (shown if controllers provided) ---
        if (pdfEnController != null || pdfFrController != null) ...[
          if (pdfEnController != null) ...[
            TextField(
              controller: pdfEnController,
              decoration: const InputDecoration(
                labelText: 'Resume PDF (EN) URL',
                hintText: 'https://…/omer_en.pdf',
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (pdfFrController != null) ...[
            TextField(
              controller: pdfFrController,
              decoration: const InputDecoration(
                labelText: 'Resume PDF (FR) URL',
                hintText: 'https://…/omer_fr.pdf',
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (showPdfButtons && onOpenPdf != null) Row(
            children: [
              if ((pdfEnController?.text ?? '').isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => onOpenPdf!(pdfEnController!.text),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('View Resume (EN)'),
                ),
              const SizedBox(width: 8),
              if ((pdfFrController?.text ?? '').isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => onOpenPdf!(pdfFrController!.text),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('View Resume (FR)'),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        LinksEditor(rows: links, onChanged: onLinksChanged),
      ],
    );
  }
}


/*

//const SizedBox(height: 12),
/* _ContactAccordion(
  storageKey: 'contact_${widget.lang}',
  emailController: _email,
  links: _links,
  onLinksChanged: (rows) { setState(() { _links = rows; _queueDebouncedSave(); }); },
  onEmailChanged: (_) => _queueDebouncedSave(),
  initiallyExpanded: false,
), */
ExpansionTile(
  //key: PageStorageKey(storageKey),
  //initiallyExpanded: initiallyExpanded,
  initiallyExpanded: _openContact,
  onExpansionChanged: (v) => setState(() => _openContact = v),
  leading: const Icon(Icons.mail),
  title: const Text('Contact'),
  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
  children: [
    TextField(
      controller: _email,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(labelText: 'Email'),
      onChanged: (_) => _queueDebouncedSave(),
    ),
    const SizedBox(height: 8),
    _LinksEditor(
      rows: _links, 
      onChanged: (rows) { setState(() { _links = rows; _queueDebouncedSave(); }); },
    ),
  ],
),

*/