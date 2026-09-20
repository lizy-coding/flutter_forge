import 'package:flutter/material.dart';

import '../state/video_player_adapter.dart';

class VideoPlayerControls extends StatelessWidget {
  const VideoPlayerControls({super.key, required this.adapter});

  final VideoPlayerAdapter adapter;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        return Column(
          children: [
            Row(
              children: [
                ValueListenableBuilder<PlayerUiState>(
                  valueListenable: adapter.uiState,
                  builder: (context, state, child) {
                    if (state == PlayerUiState.loading) {
                      return const SizedBox.square(
                        dimension: 48,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final isPlaying = state == PlayerUiState.playing;
                    return IconButton(
                      key: const Key('video-play-pause'),
                      tooltip: isPlaying ? '暂停' : '播放',
                      onPressed: state == PlayerUiState.error
                          ? null
                          : adapter.togglePlayPause,
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    );
                  },
                ),
                Expanded(
                  child: _Timeline(adapter: adapter, compact: compact),
                ),
                ValueListenableBuilder<double>(
                  valueListenable: adapter.rate,
                  builder: (context, rate, child) {
                    return DropdownButton<double>(
                      key: const Key('video-rate'),
                      value: rate,
                      onChanged: (value) {
                        if (value != null) adapter.setRate(value);
                      },
                      items: const [0.5, 1.0, 1.5, 2.0]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('${value.toStringAsFixed(1)}x'),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
            if (compact) _SeekBar(adapter: adapter),
            Row(
              children: [
                const Icon(Icons.volume_up),
                Expanded(
                  child: ValueListenableBuilder<double>(
                    valueListenable: adapter.volume,
                    builder: (context, volume, child) {
                      return Slider(
                        key: const Key('video-volume'),
                        value: volume,
                        onChanged: adapter.setVolume,
                      );
                    },
                  ),
                ),
                ValueListenableBuilder<double>(
                  valueListenable: adapter.volume,
                  builder: (context, volume, child) {
                    return SizedBox(
                      width: 48,
                      child: Text('${(volume * 100).round()}%'),
                    );
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static String _formatDuration(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.adapter, required this.compact});

  final VideoPlayerAdapter adapter;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: adapter.duration,
      builder: (context, total, child) {
        return ValueListenableBuilder<Duration>(
          valueListenable: adapter.position,
          builder: (context, current, child) {
            final label = Text(
              '${VideoPlayerControls._formatDuration(current)} / '
              '${VideoPlayerControls._formatDuration(total)}',
            );
            if (compact) return Center(child: label);
            return Row(
              children: [
                label,
                Expanded(child: _SeekBar(adapter: adapter)),
              ],
            );
          },
        );
      },
    );
  }
}

class _SeekBar extends StatelessWidget {
  const _SeekBar({required this.adapter});

  final VideoPlayerAdapter adapter;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: adapter.duration,
      builder: (context, total, child) {
        return ValueListenableBuilder<Duration>(
          valueListenable: adapter.position,
          builder: (context, current, child) {
            final maxMilliseconds = total.inMilliseconds.toDouble();
            final currentMilliseconds = current.inMilliseconds.toDouble().clamp(
              0.0,
              maxMilliseconds == 0 ? 0.0 : maxMilliseconds,
            );
            return Slider(
              key: const Key('video-seek'),
              value: currentMilliseconds,
              max: maxMilliseconds == 0 ? 1 : maxMilliseconds,
              onChanged: maxMilliseconds == 0
                  ? null
                  : (value) =>
                        adapter.seek(Duration(milliseconds: value.round())),
            );
          },
        );
      },
    );
  }
}
