import 'package:flutter/material.dart';

import 'animated_padding_component.dart';

class BottomNavigation extends StatefulWidget {
  final int pageCount;
  ValueNotifier<int> selectedPage;
  final Function(int) onPageChange;
  BottomNavigation({super.key, required this.onPageChange, required this.selectedPage, required this.pageCount});

  @override
  State<BottomNavigation> createState() => BottomNavigationState();
}

class BottomNavigationState extends State<BottomNavigation> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.selectedPage.value == 0) {
          return true;
        }
        setState(() {
          widget.selectedPage.value--;
          widget.onPageChange(widget.selectedPage.value);
        });
        return false;
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.transparent.withOpacity(0.0),
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              flex: 5,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: TextButton(
                    onPressed: widget.selectedPage.value == 0
                        ? () {
                            Navigator.pop(context);
                          }
                        : () {
                            setState(() {
                              widget.selectedPage.value--;
                              widget.onPageChange(widget.selectedPage.value);
                            });
                          },
                    child: const Text(
                      "Back",
                      style: TextStyle(color: Colors.grey),
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: AnimatedPaddingComponent(
                padding: getPadding(widget.selectedPage.value),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPageIndicator(0),
                    const SizedBox(width: 8),
                    _buildPageIndicator(1),
                    const SizedBox(width: 8),
                    _buildPageIndicator(2),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: TextButton(
                    onPressed: widget.selectedPage.value == widget.pageCount - 1
                        ? () {
                            Navigator.pop(context);
                          }
                        : () {
                            setState(() {
                              widget.selectedPage.value++;
                              widget.onPageChange(widget.selectedPage.value);
                            });
                          },
                    child: Text(
                      widget.selectedPage.value != 2 ? "Next" : "Connect now",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  getPadding(int selectedIndex) {
    if (selectedIndex == 0) {
      return const EdgeInsets.only(left: 34);
    }
    if (selectedIndex == 2) {
      return const EdgeInsets.only(right: 34);
    } else {
      return const EdgeInsets.only();
    }
  }

  Widget _buildPageIndicator(int index) {
    bool isActive = index == widget.selectedPage.value;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 13.0 : 8.0,
      height: isActive ? 13.0 : 8.0,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }
}
