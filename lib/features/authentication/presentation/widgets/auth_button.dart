import 'package:flutter/material.dart';

enum AuthButtonType {
  primary,
  secondary,
  outline,
  text,
}

enum AuthButtonSize {
  small,
  medium,
  large,
}

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AuthButtonType type;
  final AuthButtonSize size;
  final bool isLoading;
  final Widget? icon;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  const AuthButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AuthButtonType.primary,
    this.size = AuthButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine colors based on button type
    Color getBackgroundColor() {
      if (backgroundColor != null) return backgroundColor!;

      switch (type) {
        case AuthButtonType.primary:
          return colorScheme.primary;
        case AuthButtonType.secondary:
          return colorScheme.secondary;
        case AuthButtonType.outline:
          return Colors.transparent;
        case AuthButtonType.text:
          return Colors.transparent;
      }
    }

    Color getTextColor() {
      if (textColor != null) return textColor!;

      switch (type) {
        case AuthButtonType.primary:
          return colorScheme.onPrimary;
        case AuthButtonType.secondary:
          return colorScheme.onSecondary;
        case AuthButtonType.outline:
          return colorScheme.primary;
        case AuthButtonType.text:
          return colorScheme.primary;
      }
    }

    Color? getBorderColor() {
      if (borderColor != null) return borderColor;

      switch (type) {
        case AuthButtonType.outline:
          return colorScheme.primary;
        default:
          return null;
      }
    }

    // Determine size properties
    double getHeight() {
      switch (size) {
        case AuthButtonSize.small:
          return 40;
        case AuthButtonSize.medium:
          return 48;
        case AuthButtonSize.large:
          return 56;
      }
    }

    EdgeInsets getPadding() {
      switch (size) {
        case AuthButtonSize.small:
          return const EdgeInsets.symmetric(horizontal: 16);
        case AuthButtonSize.medium:
          return const EdgeInsets.symmetric(horizontal: 20);
        case AuthButtonSize.large:
          return const EdgeInsets.symmetric(horizontal: 24);
      }
    }

    TextStyle? getTextStyle() {
      final baseStyle = switch (size) {
        AuthButtonSize.small => theme.textTheme.labelMedium,
        AuthButtonSize.medium => theme.textTheme.labelLarge,
        AuthButtonSize.large => theme.textTheme.titleSmall,
      };

      return baseStyle?.copyWith(
        color: getTextColor(),
        fontWeight: FontWeight.w600,
      );
    }

    Widget buildButtonContent() {
      if (isLoading) {
        return SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(getTextColor()),
          ),
        );
      }

      if (icon != null) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon!,
            const SizedBox(width: 8),
            Text(
              text,
              style: getTextStyle(),
              semanticsLabel: text,
            ),
          ],
        );
      }

      return Text(
        text,
        style: getTextStyle(),
        semanticsLabel: text,
      );
    }

    final button = SizedBox(
      height: getHeight(),
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: getBackgroundColor(),
          foregroundColor: getTextColor(),
          elevation: type == AuthButtonType.primary ? 2 : 0,
          shadowColor: colorScheme.shadow.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: getBorderColor() != null
                ? BorderSide(color: getBorderColor()!, width: 1.5)
                : BorderSide.none,
          ),
          padding: getPadding(),
          splashFactory: InkRipple.splashFactory,
        ),
        child: buildButtonContent(),
      ),
    );

    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      child: button,
    );
  }
}

// Specialized buttons for common auth actions
class LoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const LoginButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AuthButton(
      text: 'Giriş Yap',
      onPressed: onPressed,
      isLoading: isLoading,
      type: AuthButtonType.primary,
      size: AuthButtonSize.large,
    );
  }
}

class RegisterButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const RegisterButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AuthButton(
      text: 'Kayıt Ol',
      onPressed: onPressed,
      isLoading: isLoading,
      type: AuthButtonType.primary,
      size: AuthButtonSize.large,
    );
  }
}

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AuthButton(
      text: 'Google ile Giriş Yap',
      onPressed: onPressed,
      isLoading: isLoading,
      type: AuthButtonType.outline,
      size: AuthButtonSize.large,
      icon: const Icon(Icons.g_mobiledata, size: 20),
    );
  }
}