import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/theme.dart';

class MochiCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool enableAnimation;

  const MochiCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.elevation,
    this.padding,
    this.borderRadius,
    this.onTap,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget card = Card(
      color: backgroundColor ?? theme.cardColor,
      elevation: elevation ?? 8,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(MochiSizes.radiusL),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(MochiSizes.radiusL),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(MochiSizes.paddingM),
          child: child,
        ),
      ),
    );

    if (enableAnimation) {
      card = card
          .animate()
          .fadeIn(duration: MochiAnimations.medium)
          .slideY(begin: 0.3, end: 0, duration: MochiAnimations.medium)
          .then()
          .shimmer(duration: const Duration(seconds: 2), color: Colors.white.withValues(alpha: 0.3));
    }

    return card;
  }
}

class MochiButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool isLoading;
  final IconData? icon;
  final bool isSecondary;

  const MochiButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.padding,
    this.borderRadius,
    this.isLoading = false,
    this.icon,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = MochiTheme.getThemeColors('default');

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSecondary 
            ? colors['secondary'] 
            : backgroundColor ?? theme.primaryColor,
        foregroundColor: textColor ?? Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(MochiSizes.radiusL),
        ),
        padding: padding ?? const EdgeInsets.symmetric(
          horizontal: MochiSizes.paddingL,
          vertical: MochiSizes.paddingM,
        ),
        elevation: 8,
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  textColor ?? Colors.white,
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: MochiSizes.iconM),
                  const SizedBox(width: MochiSizes.paddingS),
                ],
                Text(
                  text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor ?? Colors.white,
                  ),
                ),
              ],
            ),
    ).animate()
     .scale(duration: MochiAnimations.fast, curve: Curves.elasticOut);
  }
}

class MochiFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool isListening;
  final double size;

  const MochiFloatingActionButton({
    super.key,
    this.onPressed,
    required this.icon,
    this.backgroundColor,
    this.iconColor,
    this.isListening = false,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MochiTheme.getThemeColors('default');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            backgroundColor ?? colors['secondary']!,
            (backgroundColor ?? colors['secondary']!).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? colors['secondary']!).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: Center(
            child: Icon(
              icon,
              size: size * 0.4,
              color: iconColor ?? Colors.white,
            ),
          ),
        ),
      ),
    ).animate(
      target: isListening ? 1 : 0,
    ).scale(
      end: const Offset(1.2, 1.2),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
    ).then().shimmer(
      duration: const Duration(seconds: 1),
      color: Colors.white.withValues(alpha: 0.5),
    );
  }
}

class MochiAvatar extends StatelessWidget {
  final String expression;
  final double size;
  final String? mood;
  final bool isAnimated;

  const MochiAvatar({
    super.key,
    this.expression = 'happy',
    this.size = 100,
    this.mood,
    this.isAnimated = true,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = MochiTheme.mochiExpressions[expression] ?? '😄';
    
    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFE0E6),
            Color(0xFFF0F8FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(
            fontSize: size * 0.6,
          ),
        ),
      ),
    );

    if (isAnimated) {
      avatar = avatar
          .animate(
            onPlay: (controller) => controller.repeat(reverse: true),
          )
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
          );
    }

    return avatar;
  }
}

class MochiTextField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final String? Function(String?)? validator;

  const MochiTextField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: Colors.grey,
        ),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MochiSizes.radiusM),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MochiSizes.radiusM),
          borderSide: BorderSide(
            color: theme.primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MochiSizes.radiusM),
          borderSide: BorderSide(
            color: theme.primaryColor,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MochiSizes.paddingM,
          vertical: MochiSizes.paddingM,
        ),
      ),
    ).animate()
     .fadeIn(duration: MochiAnimations.medium)
     .slideX(begin: -0.3, end: 0, duration: MochiAnimations.medium);
  }
}

class MochiConnectionStatus extends StatelessWidget {
  final bool isConnected;
  final String deviceName;
  final int? batteryLevel;

  const MochiConnectionStatus({
    super.key,
    required this.isConnected,
    this.deviceName = 'Mochi Device',
    this.batteryLevel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MochiCard(
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? Colors.green : Colors.red,
            ),
          ).animate(
            target: isConnected ? 1 : 0,
          ).scale(
            duration: MochiAnimations.fast,
          ),
          const SizedBox(width: MochiSizes.paddingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isConnected ? 'Connected ✅' : 'Disconnected ❌',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          if (batteryLevel != null)
            Row(
              children: [
                Icon(
                  Icons.battery_full,
                  color: batteryLevel! > 20 ? Colors.green : Colors.orange,
                ),
                Text('$batteryLevel%'),
              ],
            ),
        ],
      ),
    );
  }
}