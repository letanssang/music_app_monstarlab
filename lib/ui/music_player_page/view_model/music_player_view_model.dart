import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/services/audio_player_manager.dart';
import 'package:music_app/services/songs_provider.dart';
import '../../../data/models/song.dart';
import 'music_player_state.dart';

final musicPlayerViewModelProvider =
    StateNotifierProvider.autoDispose<MusicPlayerViewModel, MusicPlayerState>(
  (ref) => MusicPlayerViewModel(ref, AudioPlayerSingleton().audioPlayer!),
);

class MusicPlayerViewModel extends StateNotifier<MusicPlayerState> {
  final Ref _ref;
  final AudioPlayer audioPlayer;

  MusicPlayerViewModel(this._ref, this.audioPlayer)
      : super(MusicPlayerState(
          song: Song(
            id: 0,
            data: '',
            title: '',
            artist: '',
            duration: Duration.zero,
            path: '',
            image: Container(),
          ),
        )) {
    state = state.copyWith(
        song: getSongFromList(),
        isFavorite: getSongFromList().isFavorite,
        isPlaying: true);
    play();
  }

  void play() async {
    audioPlayer.setSourceUrl(getSongFromList().data);
    state = state.copyWith(isPlaying: true);
    await audioPlayer.stop();
    Future.delayed(const Duration(milliseconds: 100), () async {
      await audioPlayer.resume();
    });

    moveToNextSong();
  }

  void moveToNextSong() {
    audioPlayer.onPlayerComplete.listen((event) async {
      _ref.watch(currentPostionProvider.notifier).state = Duration.zero;
      if (state.isRepeat) {
        // If repeat mode is enabled, play the same song again
        play();
      } else {
        // Play the next song in the list
        skipForward();
      }
    });
  }

  void skipForward() {
    final songs = getListSong();
    final song = getSongFromList();
    int index = getIndex(song);
    if (index == songs.length - 1) {
      index = 0;
    } else {
      index++;
    }
    state = state.copyWith(song: songs[index]);
    _ref.read(songPlayingIndexProvider.notifier).state = index;
    play();
  }

  void skipBackward() {
    final songs = getListSong();
    final song = getSongFromList();
    int index = getIndex(song);
    if (index == 0) {
      index = songs.length - 1;
    } else {
      index--;
    }
    state = state.copyWith(song: songs[index]);
    _ref.read(songPlayingIndexProvider.notifier).state = index;
    play();
  }

  void pause() async {
    state = state.copyWith(isPlaying: false);
    await audioPlayer.pause();
  }

  void stop() async {
    state = state.copyWith(isPlaying: false);
    await audioPlayer.stop();
  }

  void onTapShuffle() {
    state = state.copyWith(isShuffle: !state.isShuffle);
  }

  void onTapRepeat() {
    state = state.copyWith(isRepeat: !state.isRepeat);
  }

  void onTapFavorite() {
    state = state.copyWith(isFavorite: !state.isFavorite);
    final songs = getListSong();
    final song = getSongFromList();
    int index = getIndex(song);
    songs[index] = songs[index].copyWith(isFavorite: state.isFavorite);
  }

  Future<void> seek(Duration position) async {
    if (position > state.song.duration) {
      position = state.song.duration;
    }
    await audioPlayer.seek(position);
  }

  int getIndex(Song song) {
    return _ref.read(songPlayingIndexProvider) ?? 0;
  }

  Song getSongFromList() {
    final songs = _ref.read(songsProvider) as List<Song>;
    final index = _ref.read(songPlayingIndexProvider);
    return songs[index ?? 0];
  }

  List<Song> getListSong() {
    return _ref.read(songsProvider) as List<Song>;
  }
}
