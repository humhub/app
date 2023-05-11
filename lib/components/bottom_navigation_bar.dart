import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import 'animated_padding_component.dart';

class BottomNavigation extends StatefulWidget {
  final int pageCount;
  final Function(int) onPageChange;
  const BottomNavigation({super.key, required this.onPageChange, required this.pageCount});

  @override
  State<BottomNavigation> createState() => BottomNavigationState();
}

class BottomNavigationState extends State<BottomNavigation> with TickerProviderStateMixin {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex == 0) {
          return true;
        }
        setState(() {
          _selectedIndex--;
          widget.onPageChange(_selectedIndex);
        });
        return false;
      },
      child: Container(
        height: 50,
        padding: Platform.isIOS ? const EdgeInsets.only(bottom: 20) : null,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.transparent.withOpacity(0.0),
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 3,
              child: TextButton(
                onPressed: _selectedIndex == 0
                    ? () {
                        Navigator.pop(context);
                      }
                    : () {
                        setState(() {
                          _selectedIndex--;
                          widget.onPageChange(_selectedIndex);
                        });
                      },
                child: const Text(
                  "Back",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            Expanded(
              flex: 7,
              child: AnimatedPaddingComponent(
                padding: getPadding(_selectedIndex),
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
              flex: 3,
              child: TextButton(
                onPressed: _selectedIndex == widget.pageCount - 1
                    ? () {
                        Navigator.pop(context);
                      }
                    : () {
                        setState(() {
                          _selectedIndex++;
                          widget.onPageChange(_selectedIndex);
                        });
                      },
                child: AutoSizeText(
                  _selectedIndex != 2 ? "Next" : "Connect now",
                  style: const TextStyle(color: Colors.grey),
                  maxLines: 1,
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
    bool isActive = index == _selectedIndex;
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
