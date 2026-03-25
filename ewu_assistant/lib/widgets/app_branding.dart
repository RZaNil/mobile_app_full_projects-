import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppBrandAssets {
  const AppBrandAssets._();

  static const String logo = 'assets/images/logo.png';
  static const String logoMark = 'assets/images/logo_mark.png';
}

class AppLogoMark extends StatelessWidget {
  const AppLogoMark({
    super.key,
    this.size = 56,
    this.dark = false,
    this.framed = true,
    this.backgroundColor,
  });

  final double size;
  final bool dark;
  final bool framed;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final double iconSize = size * 0.42;
    final Color resolvedBackground =
        backgroundColor ??
        (dark ? Colors.white.withValues(alpha: 0.14) : AppTheme.primaryDark);
    final Color resolvedForeground = dark ? Colors.white : Colors.white;

    final Widget mark = Padding(
      padding: EdgeInsets.all(size * 0.16),
      child: Image.asset(
        AppBrandAssets.logoMark,
        fit: BoxFit.contain,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
              return Icon(
                Icons.auto_awesome_rounded,
                color: resolvedForeground,
                size: iconSize,
              );
            },
      ),
    );

    if (!framed) {
      return SizedBox(height: size, width: size, child: mark);
    }

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: dark
            ? const <BoxShadow>[]
            : <BoxShadow>[
                BoxShadow(
                  color: AppTheme.primaryDark.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: mark,
    );
  }
}

class AppWordmark extends StatelessWidget {
  const AppWordmark({
    super.key,
    this.dark = false,
    this.height = 32,
    this.textAlign = TextAlign.left,
  });

  final bool dark;
  final double height;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Image.asset(
        AppBrandAssets.logo,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
              return Align(
                alignment: textAlign == TextAlign.center
                    ? Alignment.center
                    : Alignment.centerLeft,
                child: Text(
                  'EWU Assistant',
                  textAlign: textAlign,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: dark ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              );
            },
      ),
    );
  }
}

class AppBrandLockup extends StatelessWidget {
  const AppBrandLockup({
    super.key,
    this.dark = false,
    this.centered = false,
    this.markSize = 64,
    this.wordmarkHeight = 34,
    this.subtitle,
    this.subtitleStyle,
  });

  final bool dark;
  final bool centered;
  final double markSize;
  final double wordmarkHeight;
  final String? subtitle;
  final TextStyle? subtitleStyle;

  @override
  Widget build(BuildContext context) {
    final CrossAxisAlignment alignment = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: <Widget>[
        Row(
          mainAxisSize: centered ? MainAxisSize.min : MainAxisSize.max,
          children: <Widget>[
            AppLogoMark(size: markSize, dark: dark),
            const SizedBox(width: 14),
            Flexible(
              child: AppWordmark(
                dark: dark,
                height: wordmarkHeight,
                textAlign: centered ? TextAlign.center : TextAlign.left,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 14),
          Text(
            subtitle!,
            textAlign: centered ? TextAlign.center : TextAlign.left,
            style:
                subtitleStyle ??
                Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.78)
                      : AppTheme.textSecondary,
                  height: 1.45,
                ),
          ),
        ],
      ],
    );
  }
}
