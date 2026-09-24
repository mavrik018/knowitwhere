import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../util/relative_date.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/item_photo.dart';

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
    // Leave first so this screen never renders the "not found" state.
    context.pop();
    await repo.delete(item.id);
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (item.photoPath case final photoPath?) ...[
            Hero(
              tag: 'photo-${item.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ItemPhoto(
                    file: AppScope.of(context).photos.resolve(photoPath),
                    semanticLabel: 'Photo of ${item.name}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Semantics(
            header: true,
            child: Text(item.name, style: theme.textTheme.headlineMedium),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.place_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stored in',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
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
          ),
          const SizedBox(height: 12),
          Text(
            'Updated ${relativeDate(item.dateUpdated, DateTime.now())}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
