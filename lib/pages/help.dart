import 'package:flutter/material.dart';
import 'package:humhub/util/const.dart';

import '../components/ease_out_image.dart';

class Help extends StatefulWidget {
  static const String path = '/help';
  const Help({Key? key}) : super(key: key);

  @override
  HelpState createState() => HelpState();
}

class HelpState extends State<Help> {
  int _selectedIndex = 0;
  final _pageController = PageController(initialPage: 0);

  Widget _buildPageIndicator(int index) {
    bool isActive = index == _selectedIndex;
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: isActive ? 16.0 : 8.0,
      height: 8.0,
      decoration: BoxDecoration(
        color: isActive ? Colors.blue : Colors.grey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      /*bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        selectedItemColor: Colors.grey,
        selectedIconTheme: IconThemeData(size: 22),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(left: 100),
                child: Icon(Icons.circle, size: _selectedIndex == 0 ? 18 : 14,),
              ), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.circle, size: _selectedIndex == 1 ? 18 : 14,), label: ""),
          BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(right: 100),
                child: Icon(Icons.circle, size: _selectedIndex == 2 ? 18 : 14,),
              ), label: "")
        ],
        onTap: _onTappedBar,
        currentIndex: _selectedIndex,
      ),*/
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: _selectedIndex == 0
                  ? null
                  : () {
                      setState(() {
                        _selectedIndex--;
                      });
                    },
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPageIndicator(0),
                  SizedBox(width: 8.0),
                  _buildPageIndicator(1),
                  SizedBox(width: 8.0),
                  _buildPageIndicator(2),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios),
              onPressed: _selectedIndex == 3 - 1
                  ? null
                  : () {
                      setState(() {
                        _selectedIndex++;
                      });
                    },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const EaseOutImage(
              imagePath: 'assets/images/logo.png',
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _selectedIndex = page;
                  });
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              Locales.helpTitle,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            Locales.helpFirstPar,
                            style: const TextStyle(letterSpacing: 0.5),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            Locales.helpSecPar,
                            style: const TextStyle(letterSpacing: 0.5),
                          ),
                        ),
                        /*HatchImage()*/
                      ],
                    ),
                  ),
                  Container(color: Colors.blue),
                  Container(color: Colors.green),
                  Container(color: Colors.yellow),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
    });
    _pageController.jumpToPage(value);
  }
}
