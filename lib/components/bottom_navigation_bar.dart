import 'package:flutter/material.dart';

class BottomNavigation extends StatefulWidget {
  final int pageCount;
  final Function(int) onPageChange;
  const BottomNavigation({super.key, required this.onPageChange, required this.pageCount});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> with TickerProviderStateMixin {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          TextButton(
            onPressed: _selectedIndex == 0
                ? null
                : () {
                    setState(() {
                      _selectedIndex--;
                      widget.onPageChange(_selectedIndex);
                    });
                  },
            child: const Text("Back", style: TextStyle(color: Colors.grey),),
          ),
          Expanded(
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
          TextButton(
            onPressed: _selectedIndex == widget.pageCount - 1
                ? null
                : () {
                    setState(() {
                      _selectedIndex++;
                      widget.onPageChange(_selectedIndex);
                    });
                  },
            child: const Text("Next", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    bool isActive = index == _selectedIndex;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 16.0 : 8.0,
      height: isActive ? 16.0 : 8.0,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }
}
