import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'bookmark_repository.g.dart';

const _kBookmarksKey = 'fir_bookmarks';

@Riverpod(keepAlive: true)
class BookmarkRepository extends _$BookmarkRepository {
  @override
  List<String> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_kBookmarksKey) ?? [];
    state = items;
  }

  Future<void> addBookmark(String path) async {
    if (state.contains(path)) return;
    
    final newState = [...state, path];
    state = newState;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kBookmarksKey, newState);
  }

  Future<void> removeBookmark(String path) async {
    if (!state.contains(path)) return;
    
    final newState = state.where((p) => p != path).toList();
    state = newState;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kBookmarksKey, newState);
  }

  Future<void> toggleBookmark(String path) async {
    if (state.contains(path)) {
      await removeBookmark(path);
    } else {
      await addBookmark(path);
    }
  }
}
