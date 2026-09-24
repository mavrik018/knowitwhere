import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/item_photo.dart';

/// Add (FR1.1) and edit (FR1.2) share one form.
class ItemFormScreen extends StatefulWidget {
  const ItemFormScreen({super.key, this.itemId});

  /// Null when adding a new item.
  final String? itemId;

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _location = TextEditingController();

  bool get _isEdit => widget.itemId != null;
  Item? _original;
  bool _loading = false;
  bool _started = false;
  bool _saving = false;

  /// Stored photo (relative path) that will be kept on save.
  String? _photoPath;

  /// Newly picked photo (absolute temp path), copied into the store on save.
  String? _pickedPath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (_isEdit) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final item = await AppScope.of(context).repository.get(widget.itemId!);
    if (!mounted) return;
    setState(() {
      _original = item;
      _loading = false;
      if (item != null) {
        _name.text = item.name;
        _location.text = item.location;
        _photoPath = item.photoPath;
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final scope = AppScope.of(context);
    try {
      final photoPath = _pickedPath != null
          ? await scope.photos.save(_pickedPath!)
          : _photoPath;
      if (_isEdit) {
        await scope.repository.update(
          _original!.copyWith(
            name: _name.text,
            location: _location.text,
            photoPath: Value(photoPath),
          ),
        );
      } else {
        await scope.repository.add(
          name: _name.text,
          location: _location.text,
          photoPath: photoPath,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (picker.supportsImageSource(ImageSource.camera))
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
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
    if (source == null) return;
    try {
      // Downscale natively first; PhotoStore enforces the 1 MB cap (FR3.3).
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (picked != null && mounted) {
        setState(() => _pickedPath = picked.path);
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text("Couldn't open photos: ${e.message ?? e.code}"),
          ),
        );
    }
  }

  void _removePhoto() => setState(() {
    _pickedPath = null;
    _photoPath = null;
  });

  static String? _required(String? value, String message) =>
      (value == null || value.trim().isEmpty) ? message : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit item' : 'Add item')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_isEdit && _original == null) {
      return const Center(
        child: EmptyState(
          icon: Icons.help_outline,
          title: 'Item not found',
          message: 'It may have been deleted.',
        ),
      );
    }
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
        children: [
          TextFormField(
            controller: _name,
            autofocus: !_isEdit,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'What is it?',
              hintText: 'e.g. Passport',
              prefixIcon: const Icon(Icons.inventory_2_outlined),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _name,
                builder: (context, value, _) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    tooltip: 'Clear name',
                    icon: Icon(Icons.cancel_rounded, size: 20.r),
                    onPressed: () => _name.clear(),
                  );
                },
              ),
            ),
            validator: (v) => _required(v, 'Give it a name'),
          ),
          SizedBox(height: 12.h),
          TextFormField(
            controller: _location,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: 'Where is it?',
              hintText: 'e.g. Desk, top drawer',
              prefixIcon: const Icon(Icons.place_outlined),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _location,
                builder: (context, value, _) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    tooltip: 'Clear location',
                    icon: Icon(Icons.cancel_rounded, size: 20.r),
                    onPressed: () => _location.clear(),
                  );
                },
              ),
            ),
            validator: (v) => _required(v, 'Where did you put it?'),
          ),
          SizedBox(height: 16.h),
          _PhotoField(
            file: _pickedPath != null
                ? File(_pickedPath!)
                : _photoPath != null
                ? AppScope.of(context).photos.resolve(_photoPath!)
                : null,
            onPick: _pickPhoto,
            onRemove: _removePhoto,
          ),
          SizedBox(height: 24.h),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_isEdit ? 'Save changes' : 'Save item'),
          ),
        ],
      ),
    );
  }
}

/// Optional photo (FR3.1): a pick button, or a preview with change/remove.
class _PhotoField extends StatelessWidget {
  const _PhotoField({
    required this.file,
    required this.onPick,
    required this.onRemove,
  });

  final File? file;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = this.file;
    if (file == null) {
      final palette = AppPalette.of(context);
      return Semantics(
        button: true,
        label: 'Add a photo (optional)',
        excludeSemantics: true,
        child: Material(
          color: palette.accentSoft,
          borderRadius: BorderRadius.circular(22.r),
          child: InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(22.r),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
              child: Column(
                children: [
                  Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Add a photo (optional)',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: palette.accentText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'A quick shot of the spot helps later',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22.r),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: ItemPhoto(file: file, semanticLabel: 'Selected photo'),
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Change'),
            ),
            TextButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove'),
            ),
          ],
        ),
      ],
    );
  }
}
