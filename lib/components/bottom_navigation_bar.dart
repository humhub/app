import 'package:flutter/material.dart';
import 'animated_padding_component.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BottomNavigation extends StatefulWidget {
  final int pageCount;
  final Function(int) onPageChange;
  const BottomNavigation({super.key, required this.onPageChange, required this.pageCount});

  @override
  State<BottomNavigation> createState() => BottomNavigationState();
}

class BottomNavigationState extends State<BottomNavigation> with TickerProviderStateMixin {
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        setState(() {
          selectedIndex--;
          widget.onPageChange(selectedIndex);
        });
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.transparent.withValues(alpha: 0.0),
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
                    onPressed: () => navigateBack(),
                    child: Text(
                      AppLocalizations.of(context)!.back,
                      style: const TextStyle(color: Colors.grey),
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: AnimatedPaddingComponent(
                padding: _getPadding(selectedIndex),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.pageCount,
                    (index) {
                      return index < widget.pageCount - 1
                          ? Row(
                              children: [
                                _buildPageIndicator(index),
                                const SizedBox(width: 8),
                              ],
                            )
                          : _buildPageIndicator(index);
                    },
                  ),
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
                    onPressed: () => navigateForth(),
                    child: Text(
                      selectedIndex != widget.pageCount - 1
                          ? AppLocalizations.of(context)!.next
                          : AppLocalizations.of(context)!.connect_now,
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

  _getPadding(int selectedIndex) {
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
    bool isActive = index == selectedIndex;
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

  navigateBack() {
    if (selectedIndex == 0) {
      Navigator.pop(context);
    } else {
      setState(() {
        selectedIndex--;
        widget.onPageChange(selectedIndex);
      });
    }
  }

  navigateForth() {
    if (selectedIndex == widget.pageCount - 1) {
      Navigator.pop(context);
    } else {
      setState(() {
        selectedIndex++;
        widget.onPageChange(selectedIndex);
      });
    }
  }

  bool get canPop {
    if (selectedIndex == 0) {
      return true;
    }
    setState(() {
      selectedIndex--;
      widget.onPageChange(selectedIndex);
    });
    return false;
  }
}
