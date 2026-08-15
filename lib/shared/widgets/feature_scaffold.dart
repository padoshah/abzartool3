import 'package:flutter/material.dart';

class FeatureScaffold extends StatelessWidget {
  const FeatureScaffold({required this.title, required this.child, this.actions = const <Widget>[], super.key});
  final String title;
  final Widget child;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(title), actions: actions), body: SafeArea(child: child));
}
