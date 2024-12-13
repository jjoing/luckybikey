import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../utils/providers/page_provider.dart';

class BottomNavigation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pageProvider = Provider.of<PageProvider>(context);

    return BottomNavigationBar(
      currentIndex: pageProvider.currentPage,
      onTap: (index) {
        pageProvider.setPage(index);
      },
      backgroundColor: Colors.white,
      selectedItemColor: Colors.lightGreenAccent,
      unselectedItemColor: Colors.lightGreen,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}