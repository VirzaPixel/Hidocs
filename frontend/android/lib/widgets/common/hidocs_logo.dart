import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HiDocsLogo extends StatelessWidget {
  final double size;
  final bool showShadow;

  const HiDocsLogo({
    this.size = 88,
    this.showShadow = true,
    super.key,
  });

  static const String _svgString = '''
<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">
<rect width="32" height="32" rx="4" fill="white"/>
<path d="M16.4727 7.39236C16.1708 7.26293 15.829 7.26293 15.5271 7.39236L7.12712 10.9924C6.67852 11.178 6.38599 11.6157 6.38599 12.1012C6.38599 12.5866 6.67852 13.0243 7.12712 13.21L7.25672 13.2652C6.91512 15.2767 7.44283 17.3386 8.70872 18.9388L7.86032 23.1808C7.77946 23.5822 7.90889 23.9971 8.20361 24.2814C8.49833 24.5657 8.91767 24.68 9.31592 24.5848L13.5423 23.74C15.4874 24.6618 17.7436 24.6618 19.6887 23.74L23.9151 24.5848C24.3134 24.68 24.7327 24.5657 25.0274 24.2814C25.3221 23.9971 25.4516 23.5822 25.3707 23.1808L24.5223 18.9388C25.7882 17.3386 26.3159 15.2767 25.9743 13.2652L26.1039 13.21C26.5525 13.0243 26.845 12.5866 26.845 12.1012C26.845 11.6157 26.5525 11.178 26.1039 10.9924L17.7039 7.39236H16.4727ZM15.9999 22C13.3507 22 11.1999 19.8491 11.1999 17.2C11.1999 14.5508 13.3507 12.4 15.9999 12.4C18.6491 12.4 20.7999 14.5508 20.7999 17.2C20.7999 19.8491 18.6491 22 15.9999 22Z" fill="#0A3D7F"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: showShadow
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFDEDDB).withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            )
          : null,
      child: SvgPicture.string(
        _svgString,
        width: size,
        height: size,
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
      ),
    );
  }
}   
