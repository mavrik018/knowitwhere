import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../widgets/empty_state.dart';

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
    final repo = AppScope.of(context).repository;
    try {
      if (_isEdit) {
        await repo.update(
          _original!.copyWith(name: _name.text, location: _location.text),
        );
      } else {
        await repo.add(name: _name.text, location: _location.text);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          TextFormField(
            controller: _name,
            autofocus: !_isEdit,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'What is it?',
              hintText: 'e.g. Passport',
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
            validator: (v) => _required(v, 'Give it a name'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _location,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _save(),
            decoration: const InputDecoration(
              labelText: 'Where is it?',
              hintText: 'e.g. Desk, top drawer',
              prefixIcon: Icon(Icons.place_outlined),
            ),
            validator: (v) => _required(v, 'Where did you put it?'),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_isEdit ? 'Save changes' : 'Save item'),
          ),
        ],
      ),
    );
  }
}
