import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_app/features/events/domain/event_model.dart';
import 'package:mobile_app/features/events/presentation/events_provider.dart';

class EventFormDialog extends ConsumerStatefulWidget {
  final EventModel? eventToEdit;
  final VoidCallback onSuccess;

  const EventFormDialog({
    super.key,
    this.eventToEdit,
    required this.onSuccess,
  });

  @override
  ConsumerState<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends ConsumerState<EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _venueController;
  late TextEditingController _externalAlbumUrlController;

  late DateTime _eventDate;
  DateTime? _endDate;
  TimeOfDay _eventTime = const TimeOfDay(hour: 10, minute: 0);

  String _category = 'general';
  bool _isActive = true;

  String? _mainImageUrl;
  List<String> _galleryUrls = [];
  bool _isUploadingImages = false;
  bool _isSaving = false;

  final List<String> _categories = [
    'general',
    'festival',
    'meeting',
    'cultural',
    'sports',
    'samaj_update',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.eventToEdit;

    _titleController = TextEditingController(text: e?.title ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _venueController = TextEditingController(text: e?.venue ?? '');
    _externalAlbumUrlController = TextEditingController(text: e?.externalAlbumUrl ?? '');

    _eventDate = e?.eventDate ?? DateTime.now().add(const Duration(days: 1));
    _endDate = e?.endDate;
    if (e != null) {
      _eventTime = TimeOfDay(hour: e.eventDate.hour, minute: e.eventDate.minute);
      _category = e.category;
      _isActive = e.isActive;
      _mainImageUrl = e.imageUrl;
      _galleryUrls = List.from(e.galleryUrls);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _externalAlbumUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 85);
    if (pickedFiles.isEmpty) return;

    setState(() {
      _isUploadingImages = true;
    });

    try {
      final eventsService = ref.read(eventsServiceProvider);
      final uploadedUrls = await eventsService.uploadMultipleImages(pickedFiles);

      setState(() {
        if (_mainImageUrl == null || _mainImageUrl!.isEmpty) {
          if (uploadedUrls.isNotEmpty) {
            _mainImageUrl = uploadedUrls.first;
            _galleryUrls.addAll(uploadedUrls.skip(1));
          }
        } else {
          _galleryUrls.addAll(uploadedUrls);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload images: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImages = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() {
        _eventDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _eventDate.add(const Duration(days: 1)),
      firstDate: _eventDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      helpText: 'Select End Date (for multi-day events)',
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _eventTime,
    );
    if (picked != null) {
      setState(() {
        _eventTime = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final combinedDateTime = DateTime(
      _eventDate.year,
      _eventDate.month,
      _eventDate.day,
      _eventTime.hour,
      _eventTime.minute,
    );

    final eventsService = ref.read(eventsServiceProvider);
    bool success = false;

    if (widget.eventToEdit == null) {
      success = await eventsService.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _mainImageUrl,
        galleryUrls: _galleryUrls,
        externalAlbumUrl: _externalAlbumUrlController.text.trim(),
      endDate: _endDate,
        eventDate: combinedDateTime,
        venue: _venueController.text.trim(),
        category: _category,
        isActive: _isActive,
      );
    } else {
      success = await eventsService.updateEvent(
        widget.eventToEdit!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _mainImageUrl,
        galleryUrls: _galleryUrls,
        externalAlbumUrl: _externalAlbumUrlController.text.trim(),
        endDate: _endDate,
        eventDate: combinedDateTime,
        venue: _venueController.text.trim(),
        category: _category,
        isActive: _isActive,
      );
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (success) {
        widget.onSuccess();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.eventToEdit == null
                ? 'Event created successfully! / कार्यक्रम बनाया गया'
                : 'Event updated successfully! / विवरण अपडेट किया गया'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save event. Please check inputs.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dateFormat = DateFormat('dd MMM yyyy');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 550,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.eventToEdit == null ? 'Add Community Event' : 'Edit Event',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Input
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Event Title / शीर्षक *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.title),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Please enter event title' : null,
                      ),
                      const SizedBox(height: 16),

                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: InputDecoration(
                          labelText: 'Category / श्रेणी',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.category_outlined),
                        ),
                        items: _categories
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.toUpperCase(), style: GoogleFonts.inter(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Active Status Switch Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.visibility_outlined, size: 20, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 10),
                                Text(
                                  'Active Status (Visible to public)',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            Switch(
                              value: _isActive,
                              activeTrackColor: colorScheme.primary,
                              onChanged: (val) => setState(() => _isActive = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date & Time Picker Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectDate,
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(
                                dateFormat.format(_eventDate),
                                style: GoogleFonts.inter(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectTime,
                              icon: const Icon(Icons.access_time, size: 18),
                              label: Text(
                                _eventTime.format(context),
                                style: GoogleFonts.inter(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // End Date Row (optional — for multi-day events like Samelan)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: _endDate != null
                              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _endDate != null
                                ? colorScheme.primary.withValues(alpha: 0.4)
                                : colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.date_range_rounded,
                              size: 18,
                              color: _endDate != null
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: _selectEndDate,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'End Date (optional)',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      _endDate != null
                                          ? dateFormat.format(_endDate!)
                                          : 'Tap to set — for multi-day events (e.g. Samelan)',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: _endDate != null
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: _endDate != null
                                            ? colorScheme.primary
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (_endDate != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_endDate!.difference(_eventDate).inDays + 1} day event',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            if (_endDate != null)
                              IconButton(
                                icon: Icon(Icons.close_rounded,
                                    size: 18, color: colorScheme.onSurfaceVariant),
                                tooltip: 'Remove end date (single day event)',
                                onPressed: () => setState(() => _endDate = null),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _venueController,
                        decoration: InputDecoration(
                          labelText: 'Venue / स्थान (Location)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description Input
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description / विवरण',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // MULTI-IMAGE UPLOADER SECTION
                      Text(
                        'Event Banner & Photo Gallery',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Upload images (Cloudflare R2). First photo is main banner, extra photos go to event gallery.',
                        style: GoogleFonts.inter(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 10),

                      // Upload Button & Preview List
                      OutlinedButton.icon(
                        onPressed: _isUploadingImages ? null : _pickAndUploadImages,
                        icon: _isUploadingImages
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(_isUploadingImages ? 'Uploading images...' : '📸 Add Photos (Pick Multiple)'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Image Thumbnails Row
                      if (_mainImageUrl != null || _galleryUrls.isNotEmpty) ...[
                        SizedBox(
                          height: 90,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              if (_mainImageUrl != null)
                                Container(
                                  width: 90,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: _mainImageUrl!,
                                          fit: BoxFit.cover,
                                          width: 90,
                                          height: 90,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        left: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.amber[800],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('Banner', style: TextStyle(color: Colors.white, fontSize: 9)),
                                        ),
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (_galleryUrls.isNotEmpty) {
                                                _mainImageUrl = _galleryUrls.removeAt(0);
                                              } else {
                                                _mainImageUrl = null;
                                              }
                                            });
                                          },
                                          child: Container(
                                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                            child: const Icon(Icons.close, size: 18, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ..._galleryUrls.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final url = entry.value;
                                return Container(
                                  width: 90,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: url,
                                          fit: BoxFit.cover,
                                          width: 90,
                                          height: 90,
                                        ),
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _galleryUrls.removeAt(idx);
                                            });
                                          },
                                          child: Container(
                                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                            child: const Icon(Icons.close, size: 18, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // EXTERNAL PHOTO ALBUM LINK (GOOGLE PHOTOS / DROPBOX)
                      Text(
                        'External Photo Album Link',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _externalAlbumUrlController,
                        decoration: InputDecoration(
                          labelText: 'Google Photos / Dropbox / Drive Link',
                          hintText: 'https://photos.app.goo.gl/... or https://dropbox.com/...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.insert_link_rounded),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        onPressed: (_isSaving || _isUploadingImages) ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                widget.eventToEdit == null ? 'Create Event' : 'Save Changes',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
