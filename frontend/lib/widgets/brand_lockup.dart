import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BrandLockup extends StatelessWidget {
  final double logoHeight;
  final bool compact;

  const BrandLockup({
    super.key,
    this.logoHeight = 42,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final blue = Theme.of(context).colorScheme.secondary;
    final red = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'Assets/Images/HDFC_Life_Logo.svg',
          height: logoHeight,
          semanticsLabel: 'HDFC Life logo',
        ),
        const SizedBox(width: 10),
        if (!compact)
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.6,
              ),
              children: [
                TextSpan(text: 'Insta', style: TextStyle(color: red)),
                TextSpan(text: 'response', style: TextStyle(color: blue)),
              ],
            ),
          ),
      ],
    );
  }
}
