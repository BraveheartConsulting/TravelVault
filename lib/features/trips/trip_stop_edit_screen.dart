import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/trip_stop.dart';
import 'trip_display.dart';
import 'trip_providers.dart';

/// Add or edit an itinerary stop on a trip. Pass [existing] to edit.
class TripStopEditScreen extends ConsumerStatefulWidget {
  const TripStopEditScreen({
    super.key,
    required this.tripId,
    this.existing,
  });

  final String tripId;
  final TripStop? existing;

  bool get isEditing => existing != null;

  @override
  ConsumerState<TripStopEditScreen> createState() =>
      _TripStopEditScreenState();
}

class _TripStopEditScreenState extends ConsumerState<TripStopEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _confirmationNumber;
  late final TextEditingController _notes;

  late TripStopType _type;
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _location = TextEditingController(text: existing?.location ?? '');
    _confirmationNumber =
        TextEditingController(text: existing?.confirmationNumber ?? '');
    _notes = TextEditingController(text: existing?.notes ?? '');
    _type = existing?.type ?? TripStopType.flight;
    _startsAt = existing?.startsAt;
    _endsAt = existing?.endsAt;
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _confirmationNumber.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final current = (isStart ? _startsAt : _endsAt) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;

    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (isStart) {
        _startsAt = combined;
      } else {
        _endsAt = combined;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final service = ref.read(tripServiceProvider);
    try {
      final existing = widget.existing;
      if (existing == null) {
        await service.addStop(
          tripId: widget.tripId,
          type: _type,
          title: _title.text.trim(),
          location: _emptyToNull(_location.text),
          startsAt: _startsAt,
          endsAt: _endsAt,
          confirmationNumber: _emptyToNull(_confirmationNumber.text),
          notes: _emptyToNull(_notes.text),
        );
      } else {
        await service.updateStop(
          existing,
          type: _type,
          title: _title.text.trim(),
          location: _emptyToNull(_location.text),
          startsAt: _startsAt,
          endsAt: _endsAt,
          confirmationNumber: _emptyToNull(_confirmationNumber.text),
          notes: _emptyToNull(_notes.text),
        );
      }
      ref.invalidate(tripStopsProvider(widget.tripId));
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
        title: Text(widget.isEditing ? 'Edit stop' : 'Add stop'),
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
            DropdownButtonFormField<TripStopType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                for (final type in TripStopType.values)
                  DropdownMenuItem(
                    value: type,
                    child: Text(tripStopTypeLabel(type)),
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
                  ? 'Give the stop a title'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(labelText: 'Location'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            _DateTimeField(
              label: 'Starts',
              value: _startsAt,
              onTap: () => _pickDateTime(isStart: true),
              onClear: () => setState(() => _startsAt = null),
            ),
            _DateTimeField(
              label: 'Ends',
              value: _endsAt,
              onTap: () => _pickDateTime(isStart: false),
              onClear: () => setState(() => _endsAt = null),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmationNumber,
              decoration:
                  const InputDecoration(labelText: 'Confirmation number'),
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

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
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
      subtitle: Text(formatDateTime(value)),
      trailing: value == null
          ? const Icon(Icons.schedule_outlined)
          : IconButton(
              icon: const Icon(Icons.clear),
              onPressed: onClear,
            ),
      onTap: onTap,
    );
  }
}
