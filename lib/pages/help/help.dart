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
  final ValueNotifier<bool> fadeInFirst = ValueNotifier<bool>(false);
  final ValueNotifier<bool> fadeInSecond = ValueNotifier<bool>(false);
  final ValueNotifier<int> currentPage = ValueNotifier<int>(0);
  @override
  Widget build(BuildContext context) {
    GlobalKey<PageAnimationContainerState> statePagesKey = GlobalKey<PageAnimationContainerState>();
    GlobalKey<BottomNavigationState> bottomNavigationStateKey = GlobalKey<BottomNavigationState>();

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      bottomNavigationBar: BottomNavigation(
        key: bottomNavigationStateKey,
        pageCount: 3,
        onPageChange: (index) {
          currentPage.value = index;
          statePagesKey.currentState?.navigateTo(index);
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
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
                const ThirdPage(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
