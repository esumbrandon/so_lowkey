import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

final ambientAudioProvider =
    StateNotifierProvider<AmbientAudioNotifier, AsyncValue<bool>>((ref) {
      final notifier = AmbientAudioNotifier();
      ref.onDispose(notifier.dispose);
      return notifier;
    });

class AmbientAudioNotifier extends StateNotifier<AsyncValue<bool>> {
  final AudioPlayer _player = AudioPlayer();
  String? _currentUrl;

  AmbientAudioNotifier() : super(const AsyncValue.data(false));

  Future<void> playLoungeTrack(String url) async {
    if (_currentUrl == url && _player.playing) return;

    try {
      state = const AsyncValue.loading();
      _currentUrl = url;
      await _player.setUrl(url);
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(0.4);
      _player.play();
      state = const AsyncValue.data(true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
      state = const AsyncValue.data(false);
    } else {
      await _player.play();
      state = const AsyncValue.data(true);
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _currentUrl = null;
    state = const AsyncValue.data(false);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
