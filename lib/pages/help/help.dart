import 'package:flutter/material.dart';
import 'package:humhub/pages/help/components/first_page.dart';
import 'package:humhub/pages/help/components/third_page.dart';
import '../../components/page_animation_container.dart';
import '../../components/bottom_navigation_bar.dart';
import '../../components/ease_out_container.dart';
import 'components/second_page.dart';

class Help extends StatefulWidget {
  static const String path = '/help';
  const Help({Key? key}) : super(key: key);

  @override
  HelpState createState() => HelpState();
}

class HelpState extends State<Help> {
  final ValueNotifier<bool> fadeIn = ValueNotifier<bool>(false);
  final ValueNotifier<int> currentPage = ValueNotifier<int>(0);
  @override
  Widget build(BuildContext context) {
    GlobalKey<PageAnimationContainerState> statePagesKey = GlobalKey<PageAnimationContainerState>();

    return WillPopScope(
      onWillPop: () async {
        if (currentPage.value != 0) {
          statePagesKey.currentState?.navigateTo(currentPage.value - 1);
        } else {
          return true;
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBody: true,
        bottomNavigationBar: BottomNavigation(
          pageCount: 3,
          onPageChange: (index) {
            currentPage.value = index;
            statePagesKey.currentState?.navigateTo(index);
          },
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              EaseOutContainer(
                child: Image.asset('assets/images/logo.png'),
              ),
              PageAnimationContainer(
                key: statePagesKey,
                fadeDuration: const Duration(milliseconds: 500),
                fadeCurve: Curves.easeInOut,
                navigationCallback: (currentIndex, nextIndex) {
                  if (currentIndex == 0) {
                    fadeIn.value = true;
                  } else {
                    fadeIn.value = false;
                  }
                },
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: fadeIn,
                    builder: (BuildContext context, value, Widget? child) {
                      return FirstPage(fadeIn: fadeIn.value);
                    },
                  ),
                  const SecondPage(),
                  const ThirdPage(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
