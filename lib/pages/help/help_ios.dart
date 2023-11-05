import 'dart:io';
import 'package:flutter/material.dart';
import 'package:humhub/components/bottom_navigation_bar.dart';
import 'package:humhub/components/ease_out_container.dart';
import 'package:humhub/components/help_safe_area.dart';
import 'package:humhub/components/page_animation_container.dart';
import 'package:humhub/pages/help/components/first_page.dart';
import 'package:swipe_to/swipe_to.dart';
import 'components/second_page.dart';

class HelpIos extends StatefulWidget {
  static const String path = '/help';
  const HelpIos({Key? key}) : super(key: key);

  @override
  HelpIosState createState() => HelpIosState();
}

class HelpIosState extends State<HelpIos> {
  final ValueNotifier<bool> fadeInFirst = ValueNotifier<bool>(false);
  final ValueNotifier<bool> fadeInSecond = ValueNotifier<bool>(false);
  final ValueNotifier<bool> fadeInThird = ValueNotifier<bool>(false);
  final ValueNotifier<int> currentPage = ValueNotifier<int>(0);
  GlobalKey<PageAnimationContainerState> statePagesKey = GlobalKey<PageAnimationContainerState>();
  GlobalKey<BottomNavigationState> bottomNavigationStateKey = GlobalKey<BottomNavigationState>();

  @override
  Widget build(BuildContext context) {
    return SwipeTo(
      offsetDx: 0,
      animationDuration: const Duration(milliseconds: 100),
      onRightSwipe: () => bottomNavigationStateKey.currentState?.navigateBack(),
      onLeftSwipe: () => bottomNavigationStateKey.currentState?.navigateForth(),
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBody: true,
        bottomNavigationBar: Container(
          padding: Platform.isIOS ? const EdgeInsets.only(bottom: 20) : const EdgeInsets.only(bottom: 5),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: BottomNavigation(
            key: bottomNavigationStateKey,
            pageCount: 2,
            onPageChange: (index) {
              currentPage.value = index;
              statePagesKey.currentState?.navigateTo(index);
            },
          ),
        ),
        body: HelpSafeArea(
          child: Column(
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.only(top: 60, bottom: 40),
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: EaseOutContainer(
                    child: Image.asset('assets/images/logo.png'),
                  ),
                ),
              ),
              PageAnimationContainer(
                key: statePagesKey,
                fadeDuration: const Duration(milliseconds: 500),
                fadeCurve: Curves.easeInOut,
                navigationCallback: (currentIndex, nextIndex) {
                  if (currentIndex == 0) {
                    fadeInFirst.value = true;
                  } else {
                    fadeInFirst.value = false;
                  }
                  if (currentIndex == 1) {
                    fadeInSecond.value = true;
                  } else {
                    fadeInSecond.value = false;
                  }
                },
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: fadeInFirst,
                    builder: (BuildContext context, value, Widget? child) {
                      return FirstPage(fadeIn: fadeInFirst.value);
                    },
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: fadeInSecond,
                    builder: (BuildContext context, value, Widget? child) {
                      return SecondPage(fadeIn: fadeInSecond.value);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
