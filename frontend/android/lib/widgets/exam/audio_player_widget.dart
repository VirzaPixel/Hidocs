import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioSource;
  final bool compact;

  const AudioPlayerWidget({
    required this.audioSource,
    this.compact = false,
    super.key,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;

  @override
  void initState() {
    super.initState();
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _state = s);
    });
    _posSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _durSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_state == PlayerState.playing) {
      await _player.pause();
    } else {
      final src = widget.audioSource;
      if (src.startsWith('http://') || src.startsWith('https://')) {
        await _player.play(UrlSource(src));
      } else {
        await _player.play(DeviceFileSource(src));
      }
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPlaying = _state == PlayerState.playing;
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final bg = isDark
        ? AppTheme.darkCard
        : context.primaryWith(0.06);
    final border = isDark ? AppTheme.darkBorder : context.primaryWith(0.18);

    if (widget.compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor:
                    isDark ? AppTheme.darkBorder : AppTheme.border,
                valueColor: AlwaysStoppedAnimation<Color>(context.primary),
                minHeight: 3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _fmt(_duration.inMilliseconds > 0 ? _position : _duration),
style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.primary,
                ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.music_note_rounded,
                  size: 16, color: context.primary),
              const SizedBox(width: 6),
              Text(
                'Audio Soal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.primary,
                ),
              ),
              const Spacer(),
              Text(
                '${_fmt(_position)} / ${_fmt(_duration)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: context.primary,
              inactiveTrackColor: isDark ? AppTheme.darkBorder : AppTheme.border,
              thumbColor: context.primary,
              overlayColor: context.primaryWith(0.15),
            ),
            child: Slider(
              value: progress,
              onChanged: _duration.inMilliseconds > 0
                  ? (v) {
                      final target = Duration(
                        milliseconds:
                            (v * _duration.inMilliseconds).round(),
                      );
                      _player.seek(target);
                    }
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10_rounded),
                iconSize: 22,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                onPressed: () {
                  final newPos = _position - const Duration(seconds: 10);
                  _player.seek(newPos < Duration.zero ? Duration.zero : newPos);
                },
              ),
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [context.primary, context.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: context.primaryWith(0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.forward_10_rounded),
                iconSize: 22,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                onPressed: () {
                  final newPos = _position + const Duration(seconds: 10);
                  _player.seek(
                    newPos > _duration ? _duration : newPos,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
