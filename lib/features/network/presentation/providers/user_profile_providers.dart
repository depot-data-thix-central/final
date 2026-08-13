import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/features/network/data/network_service_provider.dart';
import 'package:thix_id/models/network_post.dart';

final userProfileProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  final service = ref.read(networkServiceProvider);
  return await service.getUserProfile(userId);
});

final pinnedPostsProvider = FutureProvider.family<List<NetworkPost>, String>((ref, userId) async {
  final service = ref.read(networkServiceProvider);
  return await service.getPinnedPosts(userId);
});

final userPostsProvider = AsyncNotifierProviderFamily<UserPostsNotifier, List<NetworkPost>, String>(UserPostsNotifier.new);

class UserPostsNotifier extends FamilyAsyncNotifier<List<NetworkPost>, String> {
  int _offset = 0;
  static const _limit = 15;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool get hasMore => _hasMore;

  @override
  Future<List<NetworkPost>> build(String userId) async {
    _offset = 0;
    final service = ref.read(networkServiceProvider);
    final posts = await service.getUserPosts(userId, offset: 0, limit: _limit);
    _offset = posts.length;
    _hasMore = posts.length == _limit;
    return posts;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    try {
      final service = ref.read(networkServiceProvider);
      final more = await service.getUserPosts(arg, offset: _offset, limit: _limit);
      _hasMore = more.length == _limit;
      _offset += more.length;
      state = AsyncData([...state.valueOrNull?? [], ...more]);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(networkServiceProvider);
      final posts = await service.getUserPosts(arg, offset: 0, limit: _limit);
      _offset = posts.length;
      _hasMore = posts.length == _limit;
      return posts;
    });
  }
}

final followStatusProvider =
    FutureProvider.family<bool, String>((ref, targetId) async {
  final supabase = Supabase.instance.client;
  final me = supabase.auth.currentUser?.id;
  if (me == null || me.isEmpty || targetId.isEmpty || me == targetId) {
    return false;
  }

  try {
    // Source de vérité = table follows (comme followUser)
    final res = await supabase
        .from('follows')
        .select('follower_id')
        .eq('follower_id', me)
        .eq('following_id', targetId)
        .maybeSingle();
    return res != null;
  } catch (e) {
    debugPrint('followStatusProvider error: $e');
    return false;
  }
});
