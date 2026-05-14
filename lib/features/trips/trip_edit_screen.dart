import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/trip.dart';
import 'trip_display.dart';
import 'trip_providers.dart';

/// Add or edit a trip. Pass [existing] to edit; leave it null to create.
class TripEditScreen extends ConsumerStatefulWidget {
  const TripEditScreen({super.key, this.existing});

  final Trip? existing;

  bool get isEditing => existing != null;

  @override
  ConsumerState<TripEditScreen> createState() => _TripEditScreenState();
}

class _TripEditScreenState extends ConsumerState<TripEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _destination;
  late final TextEditingController _notes;

  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _destination = TextEditingController(text: existing?.destination ?? '');
    _notes = TextEditingController(text: existing?.notes ?? '');
    _startDate = existing?.startDate;
    _endDate = existing?.endDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _destination.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  String? _validateDates() {
    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      return 'The end date is before the start date.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final dateError = _validateDates();
    if (dateError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(dateError)));
      return;
    }

    setState(() => _saving = true);
    final service = ref.read(tripServiceProvider);
    try {
      final existing = widget.existing;
      if (existing == null) {
        await service.createTrip(
          name: _name.text.trim(),
          destination: _emptyToNull(_destination.text),
          startDate: _startDate,
          endDate: _endDate,
          notes: _emptyToNull(_notes.text),
        );
      } else {
        await service.updateTrip(
          existing,
          name: _name.text.trim(),
          destination: _emptyToNull(_destination.text),
          startDate: _startDate,
          endDate: _endDate,
          notes: _emptyToNull(_notes.text),
        );
      }
      await ref.read(tripListProvider.notifier).reload();
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
        title: Text(widget.isEditing ? 'Edit trip' : 'Add trip'),
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
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Trip name'),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Give the trip a name'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _destination,
              decoration: const InputDecoration(labelText: 'Destination'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Start date',
              value: _startDate,
              onTap: () => _pickDate(isStart: true),
              onClear: () => setState(() => _startDate = null),
            ),
            _DateField(
              label: 'End date',
              value: _endDate,
              onTap: () => _pickDate(isStart: false),
              onClear: () => setState(() => _endDate = null),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
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
