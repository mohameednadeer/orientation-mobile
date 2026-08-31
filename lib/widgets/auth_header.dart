import 'package:flutter/material.dart';
import 'orientation_logo.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image replacing geometric shapes
          Image.asset(
            'assets/images/login_bg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to black if image is missing
              return Container(color: Colors.black);
            },
          ),
          // Dark gradient overlay to blend into the black screen below
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                  Colors.black,
                ],
                stops: const [0.4, 0.8, 1.0],
              ),
            ),
          ),
          // Logo centered at the bottom
          const Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Center(
              child: OrientationLogo(),
            ),
          ),
        ],
      ),
    );
  }
}
