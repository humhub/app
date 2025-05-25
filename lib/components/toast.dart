import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:flutter_svg/svg.dart';
import 'package:humhub/util/const.dart';

class Toast {
  Toast._();

  static void show(BuildContext context, String title) {
    showToastWidget(
      _buildToastContent(context, title),
      context: context,
      position: StyledToastPosition(
        align: Alignment.bottomCenter,
        offset: 40.0,
      ),
      animDuration: Duration(milliseconds: 400),
      duration: Duration(seconds: 3),
      animationBuilder: (context, controller, duration, child) {
        // Slide in from right
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(3.0, 0.0),
            end: Offset(0.0, 0.0),
          ).animate(CurvedAnimation(
            parent: controller,
            curve: Curves.easeOut,
          )),
          child: child,
        );
      },
      reverseAnimBuilder: (context, controller, duration, child) {
        // Slide out to left
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0.0, 0.0),
            end: Offset(-3.0, 0.0),
          ).animate(CurvedAnimation(
            parent: controller,
            curve: Curves.easeIn,
          )),
          child: child,
        );
      },
    );
  }

  static Widget _buildToastContent(BuildContext context, String title) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 22.0, vertical: 12.0),
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
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.77,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(3.0),
                child: SvgPicture.asset(
                  Assets.circleCheck,
                  width: 22,
                  height: 22,
                ),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
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
