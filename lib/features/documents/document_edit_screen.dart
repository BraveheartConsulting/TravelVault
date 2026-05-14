import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/providers.dart';
import '../../data/models/document.dart';
import 'document_display.dart';
import 'document_providers.dart';

/// Add or edit a document. Pass [existing] to edit; leave it null to create.
class DocumentEditScreen extends ConsumerStatefulWidget {
  const DocumentEditScreen({super.key, this.existing});

  final Document? existing;

  bool get isEditing => existing != null;

  @override
  ConsumerState<DocumentEditScreen> createState() => _DocumentEditScreenState();
}

class _DocumentEditScreenState extends ConsumerState<DocumentEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  late final TextEditingController _title;
  late final TextEditingController _documentNumber;
  late final TextEditingController _issuingCountry;
  late final TextEditingController _notes;

  late DocumentType _type;
  DateTime? _issueDate;
  DateTime? _expiryDate;

  /// Image storage ids carried over from the existing document.
  late List<String> _existingImageIds;

  /// Image storage ids the user removed in this edit session.
  final List<String> _removedImageIds = [];

  /// Filesystem paths of newly picked images, not yet encrypted into the vault.
  final List<String> _newImagePaths = [];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _documentNumber = TextEditingController(
      text: existing?.documentNumber ?? '',
    );
    _issuingCountry = TextEditingController(
      text: existing?.issuingCountry ?? '',
    );
    _notes = TextEditingController(text: existing?.notes ?? '');
    _type = existing?.type ?? DocumentType.passport;
    _issueDate = existing?.issueDate;
    _expiryDate = existing?.expiryDate;
    _existingImageIds = List.of(existing?.imagePaths ?? const []);
  }

  @override
  void dispose() {
    _title.dispose();
    _documentNumber.dispose();
    _issuingCountry.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(source: source);
    if (picked == null) return;
    setState(() => _newImagePaths.add(picked.path));
  }

  Future<void> _pickImageSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from library'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) {
      await _pickImage(source);
    }
  }

  Future<void> _pickDate({required bool isExpiry}) async {
    final initial = (isExpiry ? _expiryDate : _issueDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isExpiry) {
        _expiryDate = picked;
      } else {
        _issueDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final service = ref.read(documentServiceProvider);
    final notifier = ref.read(expiryNotifierProvider);

    try {
      // The OS notification prompt is only worth showing once the document
      // actually has an expiry date to alert on.
      if (_expiryDate != null) {
        await notifier.requestPermissions();
      }

      final existing = widget.existing;
      if (existing == null) {
        final profile = await ref.read(currentProfileProvider.future);
        await service.create(
          profileId: profile.id,
          type: _type,
          title: _title.text.trim(),
          documentNumber: _emptyToNull(_documentNumber.text),
          issuingCountry: _emptyToNull(_issuingCountry.text),
          issueDate: _issueDate,
          expiryDate: _expiryDate,
          notes: _emptyToNull(_notes.text),
          newImageSourcePaths: _newImagePaths,
        );
      } else {
        await service.update(
          existing,
          type: _type,
          title: _title.text.trim(),
          documentNumber: _emptyToNull(_documentNumber.text),
          issuingCountry: _emptyToNull(_issuingCountry.text),
          issueDate: _issueDate,
          expiryDate: _expiryDate,
          notes: _emptyToNull(_notes.text),
          newImageSourcePaths: _newImagePaths,
          removedImageIds: _removedImageIds,
        );
      }

      await ref.read(documentListProvider.notifier).reload();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit document' : 'Add document'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<DocumentType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                for (final type in DocumentType.values)
                  DropdownMenuItem(
                    value: type,
                    child: Text(documentTypeLabel(type)),
                  ),
              ],
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Give the document a title'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _documentNumber,
              decoration: const InputDecoration(labelText: 'Document number'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _issuingCountry,
              decoration: const InputDecoration(labelText: 'Issuing country'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Issue date',
              value: _issueDate,
              onTap: () => _pickDate(isExpiry: false),
              onClear: () => setState(() => _issueDate = null),
            ),
            _DateField(
              label: 'Expiry date',
              value: _expiryDate,
              onTap: () => _pickDate(isExpiry: true),
              onClear: () => setState(() => _expiryDate = null),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            _PhotosSection(
              existingImageIds: _existingImageIds,
              newImagePaths: _newImagePaths,
              onAdd: _pickImageSource,
              onRemoveExisting: (id) => setState(() {
                _existingImageIds.remove(id);
                _removedImageIds.add(id);
              }),
              onRemoveNew: (path) =>
                  setState(() => _newImagePaths.remove(path)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(formatDate(value)),
      trailing: value == null
          ? const Icon(Icons.calendar_today_outlined)
          : IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
      onTap: onTap,
    );
  }
}

class _PhotosSection extends StatelessWidget {
  const _PhotosSection({
    required this.existingImageIds,
    required this.newImagePaths,
    required this.onAdd,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });

  final List<String> existingImageIds;
  final List<String> newImagePaths;
  final VoidCallback onAdd;
  final void Function(String id) onRemoveExisting;
  final void Function(String path) onRemoveNew;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Photos', style: Theme.of(context).textTheme.titleMedium),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Add'),
            ),
          ],
        ),
        if (existingImageIds.isEmpty && newImagePaths.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No photos attached.'),
          ),
        for (final id in existingImageIds)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_outline),
            title: const Text('Encrypted photo'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => onRemoveExisting(id),
            ),
          ),
        for (final path in newImagePaths)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: SizedBox(
              width: 40,
              height: 40,
              child: Image.file(File(path), fit: BoxFit.cover),
            ),
            title: const Text('New photo'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => onRemoveNew(path),
            ),
          ),
      ],
    );
  }
}
