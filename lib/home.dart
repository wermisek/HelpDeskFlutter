import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Home")),
      body: Center(child: Text("Welcome to the User Home Page!")),
    );
  }
}
