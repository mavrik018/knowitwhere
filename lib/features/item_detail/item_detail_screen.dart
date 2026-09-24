import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../util/relative_date.dart';
import '../../widgets/empty_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pinned_photo.dart';
import '../../widgets/section_label.dart';
import '../../widgets/siri_bar.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  Stream<Item?>? _item;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _item ??= AppScope.of(context).repository.watch(widget.itemId);
  }

  Future<void> _confirmDelete(Item item) async {
    final repo = AppScope.of(context).repository;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${item.name}"?'),
        content: const Text('This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    // Leave first so this screen never renders the "not found" state.
    context.pop();
    await repo.delete(item.id);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(
            'Deleted "${item.name}"',
            style: const TextStyle(
              color: Color(0xFFFBF8F2),
              fontWeight: FontWeight.w500,
            ),
          ),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.orange,
            onPressed: () => repo.restore(item),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Item?>(
      stream: _item,
      builder: (context, snapshot) {
        if (!snapshot.hasData &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold();
        }
        final item = snapshot.data;
        if (item == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: EmptyState(
                icon: Icons.help_outline,
                title: 'Item not found',
                message: 'It may have been deleted.',
              ),
            ),
          );
        }
        return _buildItem(context, item);
      },
    );
  }

  Widget _buildItem(BuildContext context, Item item) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/item/${item.id}/edit'),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(item),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          PinnedPhoto(
            item: item,
            aspectRatio: item.photoPath == null ? 2.2 : 4 / 3,
            radius: 28,
            heroTag: 'photo-${item.id}',
            semanticLabel: 'Photo of ${item.name}',
          ),
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(item.name, style: theme.textTheme.headlineMedium),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.place, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stored in',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: palette.accentText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(item.location, style: theme.textTheme.titleLarge),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Updated ${relativeDate(item.dateUpdated, DateTime.now())}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Eyebrow('Ask Siri'),
          const SizedBox(height: 10),
          SiriBar(phrase: 'Hey Siri, where’s my ${item.name} in KnowItWhere?'),
        ],
      ),
    );
  }
}
