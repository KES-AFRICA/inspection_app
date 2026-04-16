// lib/widgets/app_bottom_sheet.dart
import 'package:flutter/material.dart';

class AppBottomSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? bottomButton;
  final double? maxHeight;

  const AppBottomSheet({
    super.key,
    required this.title,
    required this.children,
    this.bottomButton,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? screenHeight * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: isSmallScreen ? 8 : 12),
            width: isSmallScreen ? 30 : 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(height: 0),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: children,
              ),
            ),
          ),
          if (bottomButton != null) ...[
            const Divider(height: 0),
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: bottomButton,
            ),
          ],
          SizedBox(height: isSmallScreen ? 8 : 12),
        ],
      ),
    );
  }
}