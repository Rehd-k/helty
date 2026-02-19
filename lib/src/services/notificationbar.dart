import 'package:flutter/material.dart';

class SlidingNotificationDropdown extends StatefulWidget {
  const SlidingNotificationDropdown({super.key});

  @override
  State<SlidingNotificationDropdown> createState() =>
      _SlidingNotificationDropdownState();
}

class _SlidingNotificationDropdownState
    extends State<SlidingNotificationDropdown>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  // final jwtService = JwtService();
  // final apiService = ApiService();
  var notifications = [];

  @override
  void initState() {
    super.initState();
    getNotification();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  Future<void> getNotification() async {
    // var res = await apiService.get(
    //   'notifications/${jwtService.decodedToken?['username']}',
    // );
    // setState(() {
    //   notifications = res.data;
    // });
  }

  void _toggleDropdown() {
    if (_overlayEntry != null) {
      _closeDropdown();
    } else {
      getNotification();
      _showDropdown();
    }
  }

  void _showDropdown() {
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(
            -250,
            40,
          ), // Adjust for position relative to bell
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                // Dismiss area
                GestureDetector(
                  onTap: _closeDropdown,
                  behavior: HitTestBehavior.translucent,
                  child: Container(
                    color: Colors.transparent,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _controller,
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).cardColor,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 350),
                          child: notifications.isEmpty
                              ? SizedBox(
                                  child: Center(
                                    child: Text('No Notifications'),
                                  ),
                                )
                              : ListView(
                                  padding: const EdgeInsets.all(2),
                                  shrinkWrap: true,
                                  children: [
                                    ...notifications.map(
                                      (res) => ListTile(
                                        leading: const Icon(
                                          Icons.horizontal_distribute_outlined,
                                          size: 12,
                                        ),
                                        title: Text(
                                          res['title'],
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        subtitle: Text(
                                          (() {
                                            final date = DateTime.parse(
                                              res['createdAt'],
                                            );
                                            final now = DateTime.now();
                                            final difference = now.difference(
                                              date,
                                            );

                                            if (difference.inSeconds < 60) {
                                              return '${res['message']} - ${difference.inSeconds} seconds ago';
                                            } else if (difference.inMinutes <
                                                60) {
                                              return '${res['message']} - ${difference.inMinutes} minutes ago';
                                            } else if (difference.inHours <
                                                24) {
                                              return '${res['message']} - ${difference.inHours} hours ago';
                                            } else if (difference.inDays == 1) {
                                              return '${res['message']} - yesterday';
                                            } else {
                                              return '${res['message']} - ${date.toString().substring(0, 16)}';
                                            }
                                          })(),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
    _controller.forward();
  }

  void _closeDropdown() async {
    await _controller.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Tooltip(
        message: 'Notifications',
        child: InkWell(
          onTap: _toggleDropdown,

          child: const Icon(Icons.notifications, size: 12),
        ),
      ),
    );
  }
}
