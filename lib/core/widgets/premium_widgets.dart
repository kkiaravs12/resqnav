import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/premium_theme.dart';

/// ═══════════════════════════════════════════════════════════
/// PREMIUM CUSTOM WIDGETS FOR RESQNAV
/// ═══════════════════════════════════════════════════════════

/// Premium Gradient Button with Hover Effects
class PremiumButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;
  final double? width;

  const PremiumButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
    this.width,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: PremiumTheme.animFast,
        decoration: BoxDecoration(
          gradient: widget.isSecondary
              ? null
              : _hovered
                  ? PremiumTheme.premiumGradient
                  : LinearGradient(
                      colors: [
                        PremiumTheme.primary,
                        PremiumTheme.primary.withValues(alpha: 0.9),
                      ],
                    ),
          borderRadius:
              BorderRadius.circular(PremiumTheme.radiusMD),
          boxShadow: _hovered
              ? PremiumTheme.primaryGlow
              : [
                  BoxShadow(
                    color: PremiumTheme.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            borderRadius:
                BorderRadius.circular(PremiumTheme.radiusMD),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 16,
              ),
              child: widget.isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.isSecondary
                              ? PremiumTheme.primary
                              : Colors.white,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium Card with Glass Effect
class PremiumCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool isGlassy;
  final LinearGradient? gradient;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.isGlassy = false,
    this.gradient,
  });

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: PremiumTheme.animFast,
        decoration: BoxDecoration(
          color: widget.isGlassy
              ? Colors.white.withValues(alpha: 0.1)
              : PremiumTheme.surface,
          gradient: widget.gradient,
          borderRadius:
              BorderRadius.circular(PremiumTheme.radiusLG),
          border: Border.all(
            color: widget.isGlassy
                ? Colors.white.withValues(alpha: 0.2)
                : _hovered
                    ? PremiumTheme.primary.withValues(alpha: 0.3)
                    : PremiumTheme.border,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: _hovered
              ? PremiumTheme.cardShadow +
                  [
                    BoxShadow(
                      color: PremiumTheme.primary
                          .withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ]
              : PremiumTheme.cardShadow,
        ),
        child: widget.isGlassy
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius:
                        BorderRadius.circular(PremiumTheme.radiusLG),
                    child: Padding(
                      padding: widget.padding,
                      child: widget.child,
                    ),
                  ),
                ),
              )
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius:
                      BorderRadius.circular(PremiumTheme.radiusLG),
                  child: Padding(
                    padding: widget.padding,
                    child: widget.child,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Premium Animated Header with Gradient
class PremiumHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const PremiumHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: PremiumTheme.premiumGradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(PremiumTheme.radiusXXL),
        ),
        boxShadow: PremiumTheme.primaryGlow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (showBackButton)
                  GestureDetector(
                    onTap: onBackPressed ?? () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          PremiumTheme.radiusSM,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                if (showBackButton) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (action != null) ...[ action! ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium Input Field with Icons
class PremiumInput extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final int maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const PremiumInput({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
  });

  @override
  State<PremiumInput> createState() => _PremiumInputState();
}

class _PremiumInputState extends State<PremiumInput> {
  late bool _obscured;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: PremiumTheme.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (focused) {
            setState(() => _isFocused = focused);
          },
          child: AnimatedContainer(
            duration: PremiumTheme.animFast,
            decoration: BoxDecoration(
              color: _isFocused
                  ? PremiumTheme.primarySuper
                  : PremiumTheme.surfaceAlt,
              borderRadius:
                  BorderRadius.circular(PremiumTheme.radiusMD),
              border: Border.all(
                color: _isFocused
                    ? PremiumTheme.primary
                    : PremiumTheme.border,
                width: _isFocused ? 2.5 : 1.5,
              ),
            ),
            child: TextField(
              controller: widget.controller,
              obscureText: _obscured,
              maxLines: _obscured ? 1 : widget.maxLines,
              onChanged: widget.onChanged,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: PremiumTheme.textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: PremiumTheme.textTertiary,
                ),
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        color: _isFocused
                            ? PremiumTheme.primary
                            : PremiumTheme.textTertiary,
                        size: 20,
                      )
                    : null,
                suffixIcon: widget.suffixIcon != null ||
                        widget.obscureText
                    ? GestureDetector(
                        onTap: widget.obscureText
                            ? () =>
                                setState(() => _obscured = !_obscured)
                            : null,
                        child: Icon(
                          widget.obscureText
                              ? (_obscured
                                  ? Icons.visibility_off
                                  : Icons.visibility)
                              : widget.suffixIcon,
                          color: _isFocused
                              ? PremiumTheme.primary
                              : PremiumTheme.textTertiary,
                          size: 20,
                        ),
                      )
                    : null,
                contentPadding: const EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Premium Alert/Info Box
class PremiumAlert extends StatelessWidget {
  final String title;
  final String message;
  final AlertType type;
  final VoidCallback? onDismiss;

  const PremiumAlert({
    super.key,
    required this.title,
    required this.message,
    this.type = AlertType.info,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors['bg'] as Color,
        borderRadius:
            BorderRadius.circular(PremiumTheme.radiusMD),
        border: Border.all(
          color: colors['border'] as Color,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (colors['accent'] as Color)
                .withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (colors['accent'] as Color)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(
                PremiumTheme.radiusSM,
              ),
            ),
            child: Icon(
              colors['icon'] as IconData,
              color: colors['accent'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors['title'] as Color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors['text'] as Color,
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                color: colors['accent'] as Color,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _getColors() {
    switch (type) {
      case AlertType.success:
        return {
          'bg': const Color(0xFFF0FDF4),
          'border': const Color(0xFFBBF7D0),
          'accent': PremiumTheme.success,
          'icon': Icons.check_circle,
          'title': PremiumTheme.success,
          'text': const Color(0xFF166534),
        };
      case AlertType.warning:
        return {
          'bg': const Color(0xFFFEFCE8),
          'border': const Color(0xFFFCD34D),
          'accent': PremiumTheme.warning,
          'icon': Icons.warning,
          'title': const Color(0xFF92400E),
          'text': const Color(0xFF7C2D12),
        };
      case AlertType.danger:
        return {
          'bg': const Color(0xFFFEF2F2),
          'border': const Color(0xFFFECA5B),
          'accent': PremiumTheme.danger,
          'icon': Icons.error,
          'title': PremiumTheme.danger,
          'text': const Color(0xFF7F1D1D),
        };
      default:
        return {
          'bg': const Color(0xFFF0F9FF),
          'border': const Color(0xFFBAE6FD),
          'accent': PremiumTheme.info,
          'icon': Icons.info,
          'title': PremiumTheme.info,
          'text': const Color(0xFF082F49),
        };
    }
  }
}

enum AlertType { success, warning, danger, info }

/// Premium Loading Indicator
class PremiumLoader extends StatelessWidget {
  final String? message;

  const PremiumLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: PremiumTheme.premiumGradient,
              borderRadius:
                  BorderRadius.circular(PremiumTheme.radiusXL),
              boxShadow: PremiumTheme.primaryGlow,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: PremiumTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Premium Chip/Tag
class PremiumChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onDelete;
  final bool isSelected;
  final VoidCallback? onTap;

  const PremiumChip({
    super.key,
    required this.label,
    this.icon,
    this.onDelete,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? PremiumTheme.primary
              : PremiumTheme.surfaceAlt,
          borderRadius:
              BorderRadius.circular(PremiumTheme.radiusMD),
          border: Border.all(
            color: isSelected
                ? PremiumTheme.primary
                : PremiumTheme.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : PremiumTheme.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : PremiumTheme.textPrimary,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.7)
                      : PremiumTheme.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
