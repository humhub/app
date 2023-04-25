import 'package:flutter/material.dart';
import 'package:humhub/pages/help/components/first_page.dart';
import 'package:humhub/pages/help/components/third_page.dart';
import '../../components/page_animation_container.dart';
import '../../components/bottom_navigation_bar.dart';
import '../../components/ease_out_image.dart';
import 'components/second_page.dart';

class Help extends StatefulWidget {
  static const String path = '/help';
  const Help({Key? key}) : super(key: key);

  @override
  HelpState createState() => HelpState();
}

class HelpState extends State<Help> {
  @override
  Widget build(BuildContext context) {
    GlobalKey<PageAnimationContainerState> statePagesKey = GlobalKey<PageAnimationContainerState>();

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigation(
        pageCount: 3,
        onPageChange: (index) {
          // print(index);
          statePagesKey.currentState?.navigateTo(index);
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            const EaseOutImage(
              imagePath: 'assets/images/logo.png',
            ),
            PageAnimationContainer(
              key: statePagesKey,
              fadeDuration: const Duration(milliseconds: 500),
              fadeCurve: Curves.easeInOut,
              navigationCallback: (currentIndex, previousIndex){
                if(currentIndex == 0){

                }
              },
              children: const [
                FirstPage(),
                SecondPage(),
                ThirdPage(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
