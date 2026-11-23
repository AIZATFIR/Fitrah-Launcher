import 'package:fitrah_launcher/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Compact Bookpaper alphabet index for the installed-app list.
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
  });

  final List<String> alphabet;
  final String selectedLetter;
  final ValueChanged<String> onLetterSelected;
  final VoidCallback? onScrubStart;
  final VoidCallback? onScrubEnd;
  final double topPadding;
  final double bottomPadding;

  @override
  State<NiagaraWaveScrubber> createState() => _NiagaraWaveScrubberState();
}

class _NiagaraWaveScrubberState extends State<NiagaraWaveScrubber> {
  double? _touchY;
  bool _isDragging = false;
  String _activeLetter = '';

  @override
  void initState() {
    super.initState();
    _activeLetter = widget.alphabet.contains(widget.selectedLetter)
        ? widget.selectedLetter
        : widget.alphabet.firstOrNull ?? '';
  }

  @override
  void didUpdateWidget(covariant NiagaraWaveScrubber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLetter != widget.selectedLetter &&
        widget.alphabet.contains(widget.selectedLetter)) {
      _activeLetter = widget.selectedLetter;
    }
  }

  void _handleTouch(
    Offset localPosition,
    double height, {
    bool forceSelection = false,
  }) {
    if (widget.alphabet.isEmpty) return;
    final availableHeight = height - widget.topPadding - widget.bottomPadding;
    if (availableHeight <= 0) return;

    final y = (localPosition.dy - widget.topPadding).clamp(
      0.0,
      availableHeight,
    );
    final index = (y / availableHeight * (widget.alphabet.length - 1))
        .round()
        .clamp(0, widget.alphabet.length - 1);
    _selectLetter(widget.alphabet[index], haptic: true, force: forceSelection);
    setState(() => _touchY = localPosition.dy);
  }

  void _selectLetter(String letter, {bool haptic = false, bool force = false}) {
    if (_activeLetter == letter) {
      if (force) widget.onLetterSelected(letter);
      return;
    }
    _activeLetter = letter;
    if (haptic) HapticFeedback.selectionClick();
    widget.onLetterSelected(letter);
    if (mounted) setState(() {});
  }

  void _adjustLetter(int offset) {
    final index = widget.alphabet.indexOf(_activeLetter);
    final next = (index + offset).clamp(0, widget.alphabet.length - 1);
    if (index >= 0 && next != index) {
      _selectLetter(widget.alphabet[next]);
    }
  }

  bool _canAdjust(int offset) {
    final index = widget.alphabet.indexOf(_activeLetter);
    return index >= 0 &&
        index + offset >= 0 &&
        index + offset < widget.alphabet.length;
  }

  String _nextLetter(int offset) {
    if (widget.alphabet.isEmpty) return '';
    final index = widget.alphabet.indexOf(_activeLetter);
    final current = index < 0 ? 0 : index;
    return _accessibleLabel(
      widget.alphabet[(current + offset).clamp(0, widget.alphabet.length - 1)],
    );
  }

  String _accessibleLabel(String letter) => switch (letter) {
    '☆' || '★' => 'Favorit',
    '○' => 'Akhir daftar',
    _ => letter,
  };

  IconData? _markerIcon(String letter) => switch (letter) {
    '☆' || '★' => Icons.star_rounded,
    '○' => Icons.vertical_align_bottom_rounded,
    _ => null,
  };

  Widget _buildLetter(String letter) {
    final color = _activeLetter == letter
        ? AppPalette.accent
        : AppPalette.textDim;
    final icon = _markerIcon(letter);
    if (icon != null) return Icon(icon, size: 13, color: color);
    return Text(
      letter,
      style: TextStyle(
        fontSize: 12,
        fontWeight: _activeLetter == letter ? FontWeight.w700 : FontWeight.w500,
        color: color,
      ),
    );
  }

  Widget _buildSelectionMarker() {
    final icon = _markerIcon(_activeLetter);
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppPalette.accent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppPalette.blackBg.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: icon == null
          ? Text(
              _activeLetter,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppPalette.bg,
              ),
            )
          : Icon(icon, size: 18, color: AppPalette.bg),
    );
  }

  void _finishScrub() {
    setState(() {
      _isDragging = false;
      _touchY = null;
    });
    widget.onScrubEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final availableHeight =
            height - widget.topPadding - widget.bottomPadding;

        return Semantics(
          container: true,
          excludeSemantics: true,
          label: 'Pilih bagian daftar aplikasi',
          value: _accessibleLabel(_activeLetter),
          increasedValue: _nextLetter(1),
          decreasedValue: _nextLetter(-1),
          onIncrease: _canAdjust(1) ? () => _adjustLetter(1) : null,
          onDecrease: _canAdjust(-1) ? () => _adjustLetter(-1) : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              _isDragging = true;
              widget.onScrubStart?.call();
              _handleTouch(details.localPosition, height, forceSelection: true);
            },
            onPanUpdate: (details) =>
                _handleTouch(details.localPosition, height),
            onPanEnd: (_) => _finishScrub(),
            onPanCancel: _finishScrub,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: widget.topPadding,
                      bottom: widget.bottomPadding,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: widget.alphabet.map(_buildLetter).toList(),
                      ),
                    ),
                  ),
                ),
                if (_isDragging && _touchY != null && availableHeight >= 36)
                  Positioned(
                    right: 48,
                    top: (_touchY! - 18).clamp(
                      widget.topPadding,
                      height - widget.bottomPadding - 36,
                    ),
                    child: _buildSelectionMarker(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
