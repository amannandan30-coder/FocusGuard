import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/content_blocker_service.dart';

final contentBlockerServiceProvider = Provider<ContentBlockerService>((Ref ref) {
  return const ContentBlockerService();
});

class ContentBlockerNotifier extends StateNotifier<AsyncValue<ContentBlockerConfig>> {
  ContentBlockerNotifier(this._service) : super(const AsyncValue.loading()) {
    loadConfig();
  }

  final ContentBlockerService _service;

  Future<void> loadConfig() async {
    state = const AsyncValue.loading();
    try {
      final config = await _service.getBlockerConfig();
      state = AsyncValue.data(config);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleYouTubeShorts(bool value) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = current.copyWith(blockYouTubeShorts: value);
    state = AsyncValue.data(updated);

    await _service.saveBlockerConfig(
      blockYouTubeShorts: updated.blockYouTubeShorts,
      blockInstagramReels: updated.blockInstagramReels,
      blockingAction: updated.blockingAction,
    );
  }

  Future<void> toggleInstagramReels(bool value) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = current.copyWith(blockInstagramReels: value);
    state = AsyncValue.data(updated);

    await _service.saveBlockerConfig(
      blockYouTubeShorts: updated.blockYouTubeShorts,
      blockInstagramReels: updated.blockInstagramReels,
      blockingAction: updated.blockingAction,
    );
  }

  Future<void> updateBlockingAction(String action) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = current.copyWith(blockingAction: action);
    state = AsyncValue.data(updated);

    await _service.saveBlockerConfig(
      blockYouTubeShorts: updated.blockYouTubeShorts,
      blockInstagramReels: updated.blockInstagramReels,
      blockingAction: updated.blockingAction,
    );
  }

  Future<void> openSettings() async {
    await _service.openAccessibilitySettings();
  }
}

final contentBlockerProvider =
    StateNotifierProvider<ContentBlockerNotifier, AsyncValue<ContentBlockerConfig>>((ref) {
  return ContentBlockerNotifier(ref.watch(contentBlockerServiceProvider));
});
