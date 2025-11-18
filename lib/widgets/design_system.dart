import 'package:flutter/material.dart';
import 'dart:async';

class AppColors {
  static const Color primary = Color(0xFF7B68EE);
  static const Color primaryLight = Color(0xFF9B8CF5);
  static const Color primaryDark = Color(0xFF5B48CE);
  static const Color accent = Color(0xFFB4F34D);
  static const Color accentLight = Color(0xFFC8F76D);
  static const Color accentDark = Color(0xFF9FE02D);
  static const Color secondary = Color(0xFFFF6B9D);
  static const Color secondaryLight = Color(0xFFFF8BB0);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);
}

class AppGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7B68EE), Color(0xFFA294F9)],
  );
  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB4F34D), Color(0xFF9FE02D)],
  );
  static const LinearGradient secondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B9D), Color(0xFFFF8BB0)],
  );
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final bool fullWidth;
  final EdgeInsetsGeometry padding;
  const GradientButton({super.key, required this.text, this.onPressed, this.loading = false, this.fullWidth = false, this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12)});
  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !loading;
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
          ),
        if (loading) const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      ],
    );
    final content = Container(
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x4D7B68EE), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onPressed : null,
          child: Padding(padding: padding, child: Center(child: child)),
        ),
      ),
    );
    return SizedBox(width: fullWidth ? double.infinity : null, height: 50, child: content);
  }
}

class AccentButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final EdgeInsetsGeometry padding;
  const AccentButton({super.key, required this.text, this.onPressed, this.fullWidth = false, this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12)});
  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        gradient: AppGradients.accent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x4DB4F34D), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: padding,
            child: Center(child: Text(text, style: const TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w600))),
          ),
        ),
      ),
    );
    return SizedBox(width: fullWidth ? double.infinity : null, height: 50, child: content);
  }
}

class OutlineButtonX extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool fullWidth;
  const OutlineButtonX({super.key, required this.text, this.onPressed, this.fullWidth = false});
  @override
  Widget build(BuildContext context) {
    final btn = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(0, 50),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      child: Text(text),
    );
    return SizedBox(width: fullWidth ? double.infinity : null, child: btn);
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final int? maxLength;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  const AppTextField({super.key, required this.controller, required this.labelText, this.maxLength, this.keyboardType, this.onChanged});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        counterText: '',
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }
}

class AppFormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  const AppFormTextField({super.key, required this.controller, required this.labelText, this.validator, this.keyboardType, this.onChanged});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }
}

class AppSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final void Function(String)? onChanged;
  final Duration debounce;
  const AppSearchField({super.key, this.controller, required this.hintText, this.onChanged, this.debounce = const Duration(milliseconds: 300)});
  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  Timer? _debounce;
  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () {
      widget.onChanged?.call(v);
    });
  }
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onChanged: _onChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }
}

class SelectableChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const SelectableChip({super.key, required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final bg = selected ? null : AppColors.surface;
    final textColor = selected ? Colors.white : AppColors.textSecondary;
    final deco = selected
        ? BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(20))
        : BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.textSecondary.withOpacity(0.3)));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: deco,
        child: Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class GradientBorderCard extends StatefulWidget {
  final Widget child;
  final bool hoverable;
  const GradientBorderCard({super.key, required this.child, this.hoverable = true});
  @override
  State<GradientBorderCard> createState() => _GradientBorderCardState();
}

class _GradientBorderCardState extends State<GradientBorderCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final inner = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0x14000000), blurRadius: _hover ? 14 : 10, offset: Offset(0, _hover ? 6 : 4)),
        ],
      ),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        child: widget.child,
      ),
    );
    final content = Container(
      decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(16)),
      child: inner,
    );
    if (!widget.hoverable) return content;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(scale: _hover ? 1.01 : 1.0, duration: const Duration(milliseconds: 150), child: content),
    );
  }
}

class ResponsiveContainer extends StatelessWidget {
  final double maxWidth;
  final Widget child;
  const ResponsiveContainer({super.key, required this.maxWidth, required this.child});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
    );
  }
}

class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final Duration duration;
  const FadeSlideIn({super.key, required this.child, this.duration = const Duration(milliseconds: 600)});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, (1 - v) * 24), child: child),
        );
      },
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  const StatusBadge({super.key, required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  final String imageUrl;
  final String initials;
  final double size;
  const ProfileAvatar({super.key, required this.imageUrl, required this.initials, this.size = 40});
  @override
  Widget build(BuildContext context) {
    if (imageUrl.isNotEmpty) {
      return CircleAvatar(radius: size / 2, foregroundImage: NetworkImage(imageUrl));
    }
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(initials.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}