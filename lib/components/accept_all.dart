import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:humhub/util/const.dart';

class AcceptAllButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const AcceptAllButton({
    super.key,
    required this.onPressed,
    this.label = "Accept all",
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: onPressed,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.90,
          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 14.0),
          decoration: BoxDecoration(
            color: Color(0xFF78A808),
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
