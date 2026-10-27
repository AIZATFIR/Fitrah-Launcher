import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Niagara Launcher signature curved wave alphabet scrubber.
/// Bends horizontally in a smooth tactile Gaussian wave toward the thumb.
class NiagaraWaveScrubber extends StatefulWidget {
  const NiagaraWaveScrubber({
    super.key,
    required this.alphabet,
    required this.selectedLetter,
    required this.onLetterSelected,
    this.onScrubStart,
    this.onScrubEnd,
    this.topPadding = 60,
    this.bottomPadding = 40,
    this.waveBulgeWidth = 42.0,
  });

  final List<String> alphabet;
  final String selectedLetter;
  final ValueChanged<String> onLetterSelected;
  final VoidCallback? onScrubStart;
  final VoidCallback? onScrubEnd;
  final double topPadding;
  final double bottomPadding;
  final double waveBulgeWidth;

  @override
  State<NiagaraWaveScrubber> createState() => _NiagaraWaveScrubberState();
}

class _NiagaraWaveScrubberState extends State<NiagaraWaveScrubber>
    with SingleTickerProviderStateMixin {
  double? _touchY;
  bool _isDragging = false;
  String _activeLetter = '';

  late final AnimationController _animCtrl;
  late Animation<double> _waveIntensityAnim;

  @override
  void initState() {
    super.initState();
    _activeLetter = widget.selectedLetter;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _waveIntensityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _handleTouch(Offset localPos, double totalHeight, double totalWidth) {
    final availableHeight = totalHeight - widget.topPadding - widget.bottomPadding;
    if (availableHeight <= 0) return;

    final clampedY = (localPos.dy - widget.topPadding).clamp(0.0, availableHeight);
    final ratio = clampedY / availableHeight;
    final index = (ratio * (widget.alphabet.length - 1)).round().clamp(0, widget.alphabet.length - 1);
    final letter = widget.alphabet[index];

    if (_activeLetter != letter) {
      _activeLetter = letter;
      HapticFeedback.selectionClick();
      widget.onLetterSelected(letter);
    }

    setState(() {
      _touchY = localPos.dy;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final totalWidth = constraints.maxWidth;
        final availableHeight = totalHeight - widget.topPadding - widget.bottomPadding;
        final count = widget.alphabet.length;
        final itemHeight = count > 0 ? availableHeight / count : 12.0;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (details) {
            _isDragging = true;
            widget.onScrubStart?.call();
            _animCtrl.forward();
            _handleTouch(details.localPosition, totalHeight, totalWidth);
          },
          onPanUpdate: (details) {
            _handleTouch(details.localPosition, totalHeight, totalWidth);
          },
          onPanEnd: (_) {
            _finishScrub();
          },
          onPanCancel: () {
            _finishScrub();
          },
          child: AnimatedBuilder(
            animation: _waveIntensityAnim,
            builder: (context, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Alphabet items column with dynamic wave offset
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: widget.topPadding,
                        bottom: widget.bottomPadding,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(count, (i) {
                          final letter = widget.alphabet[i];
                          final itemCenterY = widget.topPadding + (i + 0.5) * itemHeight;

                          // Compute Gaussian curve factor
                          double waveFactor = 0.0;
                          if (_touchY != null && _waveIntensityAnim.value > 0) {
                            final dist = (itemCenterY - _touchY!).abs();
                            const sigma = 55.0; // Influence radius in pixels
                            waveFactor = math.exp(-(dist * dist) / (2 * sigma * sigma));
                          }

                          final xOffset = -waveFactor * widget.waveBulgeWidth * _waveIntensityAnim.value;
                          final scale = 1.0 + waveFactor * 0.9 * _waveIntensityAnim.value;
                          final isExact = _activeLetter == letter && _isDragging;

                          return Transform.translate(
                            offset: Offset(xOffset, 0),
                            child: Transform.scale(
                              scale: scale,
                              child: Text(
                                letter,
                                style: TextStyle(
                                  fontSize: letter == '★' ? 10.0 : 9.5,
                                  fontWeight: isExact
                                      ? FontWeight.w900
                                      : (waveFactor > 0.4 ? FontWeight.w700 : FontWeight.w500),
                                  color: isExact
                                      ? Colors.white
                                      : (waveFactor > 0.2
                                          ? Colors.white.withOpacity(0.6 + waveFactor * 0.4)
                                          : Colors.white.withOpacity(0.35)),
                                  shadows: isExact
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.6),
                                            blurRadius: 4,
                                            offset: const Offset(-2, 0),
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),

                  // Floating Magnifying Indicator Bubble follows thumb horizontally
                  if (_isDragging && _touchY != null)
                    Positioned(
                      right: 56.0,
                      top: (_touchY! - 24).clamp(widget.topPadding, totalHeight - widget.bottomPadding - 48),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D64A8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.45),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _activeLetter,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _finishScrub() {
    _isDragging = false;
    _animCtrl.reverse().then((_) {
      if (mounted) {
        setState(() {
          _touchY = null;
        });
      }
    });
    widget.onScrubEnd?.call();
  }
}
