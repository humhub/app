import 'package:flutter/material.dart';

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
              flex: 1,
              child: Align(
                alignment: Alignment.bottomLeft,
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
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPageIndicator(0),
                      const SizedBox(width: 8.0),
                      _buildPageIndicator(1),
                      const SizedBox(width: 8.0),
                      _buildPageIndicator(2),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.bottomRight,
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
                  child: Text(_selectedIndex != 2 ? "Next" : "Connect now", style: const TextStyle(color: Colors.grey)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
