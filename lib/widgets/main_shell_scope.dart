import 'package:flutter/widgets.dart';

enum MainShellTab { home, patients, activity, settings }

class MainShellScope extends InheritedWidget {
  const MainShellScope({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
    required super.child,
  });

  final MainShellTab currentTab;
  final ValueChanged<MainShellTab> onTabSelected;

  static MainShellScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'MainShellScope is not available in this context.');
    return scope!;
  }

  static MainShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainShellScope>();
  }

  void selectTab(MainShellTab tab) => onTabSelected(tab);

  @override
  bool updateShouldNotify(MainShellScope oldWidget) {
    return currentTab != oldWidget.currentTab;
  }
}
