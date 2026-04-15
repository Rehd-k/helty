import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ShellSidePanelTab { chat, help }

class ShellSidePanelState {
  const ShellSidePanelState({this.activeTab});

  /// `null` when the desktop side panel is closed.
  final ShellSidePanelTab? activeTab;

  bool get isOpen => activeTab != null;
}

class ShellSidePanelNotifier extends StateNotifier<ShellSidePanelState> {
  ShellSidePanelNotifier() : super(const ShellSidePanelState());

  void open(ShellSidePanelTab tab) {
    state = ShellSidePanelState(activeTab: tab);
  }

  void close() => state = const ShellSidePanelState();

  /// Opens [tab], or closes if it is already the active tab.
  void toggle(ShellSidePanelTab tab) {
    if (state.activeTab == tab) {
      close();
    } else {
      open(tab);
    }
  }
}

final shellSidePanelProvider =
    StateNotifierProvider<ShellSidePanelNotifier, ShellSidePanelState>((ref) {
  return ShellSidePanelNotifier();
});
