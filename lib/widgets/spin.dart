import 'package:flutter/material.dart';

class Spinner extends StatelessWidget {
  const Spinner();

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.lime),
        ),
      ),
      color: Colors.white.withOpacity(0.8),
    );
  }
}
