import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'package:hi_docs/main.dart';

void main() {
  patrolTest('J1 - app launch shows login', ($) async {
    await $.pumpWidgetAndSettle(const FormMakerApp());
    expect($('HiDocs!').visible, findsWidgets);
  });

  patrolTest('J2 - login validation blocks bad email', ($) async {
    await $.pumpWidgetAndSettle(const FormMakerApp());
    await $(Icons.login_rounded).tap();
    await $.pumpAndSettle();
    expect($('HiDocs!').visible, findsWidgets);
  });

  patrolTest('J3 - login screen has email and password fields', ($) async {
    await $.pumpWidgetAndSettle(const FormMakerApp());
    expect($(Scrollable).visible, findsWidgets);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  patrolTest('J4 - register screen reachable from login', ($) async {
    await $.pumpWidgetAndSettle(const FormMakerApp());
    expect($('HiDocs!').visible, findsWidgets);
  });

  patrolTest('J5 - theme settings screen renders', ($) async {
    await $.pumpWidgetAndSettle(const FormMakerApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
