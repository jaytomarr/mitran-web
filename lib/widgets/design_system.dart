import 'package:flutter/material.dart';
import 'dart:async';

class AppColors {
  static const Color primary = Color(0xFF5B4D9D); // Ruang Edit Purple
  static const Color primaryLight = Color(0xFF8B7FCD);
  static const Color primaryDark = Color(0xFF2D264B);
  
  static const Color accent = Color(0xFFFFB067); // Ruang Edit Orange/Yellow
  static const Color accentLight = Color(0xFFFFD18D);
  static const Color accentDark = Color(0xFFFF9545);
  
  static const Color secondary = Color(0xFFFF8BB0); // Pinkish accent
  static const Color secondaryLight = Color(0xFFFFB5CD);
  
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  
  static const Color text = Color(0xFF2D264B); // Dark Purple Text
  static const Color textSecondary = Color(0xFF7A7495); // Muted Purple Text
  
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);
  
  static const Color border = Color(0xFFE8E6F0); // Light purple border
}

class AppGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B4D9D), Color(0xFF8B7FCD)],
  );
  static const LinearGradient accent = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFFB067), Color(0xFFFF9545)],
  );
  static const LinearGradient secondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8BB0), Color(0xFFFF6B9D)],
  );
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final bool fullWidth;
  final EdgeInsetsGeometry padding;
  final IconData? icon;
  
  const GradientButton({
    super.key, 
    required this.text, 
    this.onPressed, 
    this.loading = false, 
    this.fullWidth = false, 
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    this.icon,
  });

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
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
        if (icon != null) ...[
          const SizedBox(width: 8),
          Icon(icon, color: Colors.white, size: 20),
        ],
      ],
    );

    final content = Container(
      decoration: BoxDecoration(
        color: AppColors.primaryDark, // Ruang Edit "Join Us" button style is often solid dark or gradient
        gradient: null, 
        borderRadius: BorderRadius.circular(50), // Pill shape
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: enabled ? onPressed : null,
          child: Padding(padding: padding, child: Center(child: child)),
        ),
      ),
    );

    return SizedBox(width: fullWidth ? double.infinity : null, height: 56, child: content);
  }
}

class AccentButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final EdgeInsetsGeometry padding;
  final IconData? icon;

  const AccentButton({
    super.key, 
    required this.text, 
    this.onPressed, 
    this.fullWidth = false, 
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(50), // Pill shape
        boxShadow: const [BoxShadow(color: Color(0x4DFFB067), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: onPressed,
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, color: Colors.white, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return SizedBox(width: fullWidth ? double.infinity : null, height: 56, child: content);
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
        foregroundColor: AppColors.primaryDark,
        side: const BorderSide(color: AppColors.primaryDark, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)), // Pill shape
        minimumSize: const Size(0, 56),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
  
  const AppTextField({
    super.key, 
    required this.controller, 
    required this.labelText, 
    this.maxLength, 
    this.keyboardType, 
    this.onChanged
  });
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        counterText: '',
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
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
  
  const AppFormTextField({
    super.key, 
    required this.controller, 
    required this.labelText, 
    this.validator, 
    this.keyboardType, 
    this.onChanged
  });
  
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }
}

class AppSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final void Function(String)? onChanged;
  final Duration debounce;
  
  const AppSearchField({
    super.key, 
    this.controller, 
    required this.hintText, 
    this.onChanged, 
    this.debounce = const Duration(milliseconds: 300)
  });
  
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
      style: const TextStyle(color: AppColors.text),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: const Color(0xFFF5F5FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
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
    final bg = selected ? null : const Color(0xFFF5F5FA);
    final textColor = selected ? Colors.white : AppColors.textSecondary;
    final deco = selected
        ? BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(50))
        : BoxDecoration(color: bg, borderRadius: BorderRadius.circular(50));
        
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: deco,
        child: Text(label, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class GradientBorderCard extends StatefulWidget {
  final Widget child;
  final bool hoverable;
  final VoidCallback? onTap;
  
  const GradientBorderCard({super.key, required this.child, this.hoverable = true, this.onTap});
  
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _hover ? AppColors.primaryLight : const Color(0xFFE0E0E0), width: 1.5),
        boxShadow: [
          if (_hover)
            BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))
          else
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: widget.child,
      ),
    );

    if (!widget.hoverable) return inner;
    
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hover ? 1.02 : 1.0, 
          duration: const Duration(milliseconds: 200), 
          child: inner
        ),
      ),
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
  final double delay;
  
  const FadeSlideIn({super.key, required this.child, this.duration = const Duration(milliseconds: 600), this.delay = 0});
  
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, (1 - v) * 30), child: child),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(50)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
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
      return Container(
        width: size, 
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
          border: Border.all(color: Colors.white, width: 2),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(initials.toUpperCase(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * 0.4)),
    );
  }
}