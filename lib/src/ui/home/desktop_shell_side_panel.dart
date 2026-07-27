import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/widgets/staff_chat_list_content.dart';
import '../../chat/widgets/staff_chat_thread_content.dart';
import '../../help/widgets/help_tickets_list_content.dart';
import '../../help/widgets/support_ticket_detail_content.dart';
import 'shell_side_panel_provider.dart';

/// Fixed right-hand glass panel for chat + help (desktop / wide layout only).
class DesktopShellSidePanel extends ConsumerStatefulWidget {
  const DesktopShellSidePanel({super.key});

  @override
  ConsumerState<DesktopShellSidePanel> createState() =>
      _DesktopShellSidePanelState();
}

class _DesktopShellSidePanelState extends ConsumerState<DesktopShellSidePanel> {
  String? _chatConversationId;
  String? _chatPeerTitle;
  String? _chatPeerStaffId;
  String? _ticketId;

  static const _panelWidth = 400.0;

  @override
  Widget build(BuildContext context) {
    final panel = ref.watch(shellSidePanelProvider);
    final isOpen = panel.isOpen;
    final tab = panel.activeTab;

    ref.listen(shellSidePanelProvider, (prev, next) {
      if (!next.isOpen) {
        setState(() {
          _chatConversationId = null;
          _chatPeerTitle = null;
          _chatPeerStaffId = null;
          _ticketId = null;
        });
        return;
      }
      if (prev?.isOpen == true && prev?.activeTab != next.activeTab) {
        setState(() {
          if (next.activeTab != ShellSidePanelTab.chat) {
            _chatConversationId = null;
            _chatPeerTitle = null;
            _chatPeerStaffId = null;
          }
          if (next.activeTab != ShellSidePanelTab.help) {
            _ticketId = null;
          }
        });
      }
    });

    final scheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !isOpen,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              opacity: isOpen ? 1 : 0,
              child: GestureDetector(
                onTap: () =>
                    ref.read(shellSidePanelProvider.notifier).close(),
                child: Container(
                  color: scheme.scrim.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          top: 0,
          bottom: 0,
          right: isOpen ? 0 : -_panelWidth - 24,
          width: _panelWidth,
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(28),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          scheme.surface.withValues(alpha: 0.92),
                          scheme.surfaceContainerLowest.withValues(alpha: 0.88),
                        ],
                      ),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.45),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.shadow.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(-4, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PanelChrome(
                          tab: tab ?? ShellSidePanelTab.chat,
                          showBack: _showBack(tab),
                          onClose: () => ref
                              .read(shellSidePanelProvider.notifier)
                              .close(),
                          onBack: _popSubView,
                          onSelectTab: (t) => ref
                              .read(shellSidePanelProvider.notifier)
                              .open(t),
                        ),
                        Expanded(
                          child: tab == null
                              ? const SizedBox.shrink()
                              : Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      12, 0, 12, 12),
                                  child: _buildTabBody(tab),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _showBack(ShellSidePanelTab? tab) {
    if (tab == ShellSidePanelTab.chat && _chatConversationId != null) {
      return true;
    }
    if (tab == ShellSidePanelTab.help && _ticketId != null) return true;
    return false;
  }

  void _popSubView() {
    setState(() {
      if (_chatConversationId != null) {
        _chatConversationId = null;
        _chatPeerTitle = null;
        _chatPeerStaffId = null;
      } else if (_ticketId != null) {
        _ticketId = null;
      }
    });
  }

  Widget _buildTabBody(ShellSidePanelTab tab) {
    switch (tab) {
      case ShellSidePanelTab.chat:
        if (_chatConversationId != null) {
          return StaffChatThreadContent(
            key: ValueKey(_chatConversationId),
            conversationId: _chatConversationId!,
            embedded: true,
            compactChrome: true,
            conversationTitle: _chatPeerTitle,
            peerStaffId: _chatPeerStaffId,
            maxBubbleWidthFraction: 0.92,
          );
        }
        return StaffChatListContent(
          dense: true,
          onOpenConversation: (id, {String? title, String? peerStaffId}) {
            setState(() {
              _chatConversationId = id;
              _chatPeerTitle = title;
              _chatPeerStaffId = peerStaffId;
            });
          },
        );
      case ShellSidePanelTab.help:
        if (_ticketId != null) {
          return SupportTicketDetailContent(
            key: ValueKey(_ticketId),
            ticketId: _ticketId!,
            embedded: true,
            compactChrome: true,
            maxBubbleWidthFraction: 0.92,
          );
        }
        return HelpTicketsListContent(
          dense: true,
          onOpenTicket: (id) {
            setState(() => _ticketId = id);
          },
        );
    }
  }
}

class _PanelChrome extends StatelessWidget {
  const _PanelChrome({
    required this.tab,
    required this.showBack,
    required this.onClose,
    required this.onBack,
    required this.onSelectTab,
  });

  final ShellSidePanelTab tab;
  final bool showBack;
  final VoidCallback onClose;
  final VoidCallback onBack;
  final void Function(ShellSidePanelTab) onSelectTab;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 6, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'Close',
                onPressed: onClose,
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
              if (showBack) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ],
              const Spacer(),
            ],
          ),
          const SizedBox(height: 6),
          SegmentedButton<ShellSidePanelTab>(
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              backgroundColor: WidgetStateProperty.resolveWith((s) {
                if (s.contains(WidgetState.selected)) {
                  return scheme.primaryContainer;
                }
                return scheme.surfaceContainerHighest.withValues(alpha: 0.5);
              }),
            ),
            segments: const [
              ButtonSegment<ShellSidePanelTab>(
                value: ShellSidePanelTab.chat,
                label: Text('Chat'),
                icon: Icon(Icons.chat_bubble_outline_rounded, size: 18),
              ),
              ButtonSegment<ShellSidePanelTab>(
                value: ShellSidePanelTab.help,
                label: Text('Help'),
                icon: Icon(Icons.support_agent_rounded, size: 18),
              ),
            ],
            selected: {tab},
            onSelectionChanged: (s) {
              if (s.isNotEmpty) onSelectTab(s.first);
            },
          ),
        ],
      ),
    );
  }
}
