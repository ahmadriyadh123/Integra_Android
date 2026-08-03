import 'package:flutter/material.dart';

class VideoPlayerSection extends StatelessWidget {
  final bool isPlaying;
  final double currentSliderValue;
  final double totalDuration;
  final VoidCallback onPlayPauseTap;
  final ValueChanged<double> onSliderChanged;
  final void Function(String) onActionTap;

  const VideoPlayerSection({
    super.key,
    required this.isPlaying,
    required this.currentSliderValue,
    required this.totalDuration,
    required this.onPlayPauseTap,
    required this.onSliderChanged,
    required this.onActionTap,
  });

  String _formatDuration(double minutes) {
    int mins = minutes.toInt();
    int secs = ((minutes - mins) * 60).toInt();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF059669);

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF064E3B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(Icons.functions_rounded, color: Colors.white24, size: 80),
              ),
            ),
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => onActionTap('Mundur 10 Detik'),
                        icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 24),
                      InkWell(
                        onTap: onPlayPauseTap,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10),
                            ],
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        onPressed: () => onActionTap('Maju 10 Detik'),
                        icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(currentSliderValue),
                              style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace'),
                            ),
                            Text(
                              _formatDuration(totalDuration),
                              style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          activeTrackColor: primaryColor,
                          inactiveTrackColor: Colors.white30,
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: currentSliderValue,
                          min: 0.0,
                          max: totalDuration,
                          onChanged: onSliderChanged,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                onPressed: () => onActionTap('Subtitle Bahasa Indonesia'),
                                icon: const Icon(Icons.closed_caption_rounded, color: Colors.white, size: 18),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '1.0x',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            onPressed: () => onActionTap('Layar Penuh'),
                            icon: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}