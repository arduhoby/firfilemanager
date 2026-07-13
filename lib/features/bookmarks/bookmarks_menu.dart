import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../file_operations/file_operations_state.dart';
import '../shell_adaptive/panel_controller.dart';
import 'bookmark_repository.dart';

class BookmarksMenuIcon extends ConsumerWidget {
  final PanelSide side;

  const BookmarksMenuIcon({
    required this.side,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarkRepositoryProvider);
    final panelState = side == PanelSide.a ? ref.watch(panelAProvider) : ref.watch(panelBProvider);
    final currentPath = panelState.activeTab.currentPath;
    final isBookmarked = bookmarks.contains(currentPath);
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      icon: Icon(
        isBookmarked ? Icons.star : Icons.star_border,
        size: 18,
        color: isBookmarked ? Colors.amber : null,
      ),
      tooltip: 'Bookmarks',
      offset: const Offset(0, 30),
      onSelected: (value) {
        if (value == '__toggle__') {
          ref.read(bookmarkRepositoryProvider.notifier).toggleBookmark(currentPath);
        } else {
          ref.read(panelControllerProvider.notifier).navigate(side, value);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: '__toggle__',
          child: Row(
            children: [
              Icon(
                isBookmarked ? Icons.star_border : Icons.star,
                size: 18,
                color: isBookmarked ? null : Colors.amber,
              ),
              const SizedBox(width: 8),
              Text(isBookmarked ? 'Remove from Bookmarks' : 'Bookmark Current Directory'),
            ],
          ),
        ),
        if (bookmarks.isNotEmpty) const PopupMenuDivider(),
        ...bookmarks.map((path) => PopupMenuItem(
              value: path,
              child: Row(
                children: [
                  Icon(Icons.folder, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      path,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
