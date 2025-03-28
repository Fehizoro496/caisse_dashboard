import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      // clipBehavior: Clip.hardEdge,
      child: ListView(
        children: [
          Container(
            color: Colors.purple,
            height: kToolbarHeight,
          ),
          const ListTile(
            title: Text('Accueil'),
          )
        ],
      ),
    );
  }
}
