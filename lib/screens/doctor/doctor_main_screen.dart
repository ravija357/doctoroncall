import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctoroncall/screens/doctor/doctor_dashboard_screen.dart';
import 'package:doctoroncall/screens/patient/appointment_list_screen.dart';
import 'package:doctoroncall/screens/shared/message_list_screen.dart';
import 'package:doctoroncall/features/messages/presentation/bloc/chat_bloc.dart';
import 'package:doctoroncall/features/messages/presentation/bloc/chat_state.dart';
import 'package:doctoroncall/features/messages/presentation/bloc/chat_event.dart';

class DoctorMainScreen extends StatefulWidget {
  const DoctorMainScreen({super.key});

  @override
  State<DoctorMainScreen> createState() => _DoctorMainScreenState();
}

class _DoctorMainScreenState extends State<DoctorMainScreen> {
  int _selectedIndex = 0;
  int _unreadMessageCount = 0;

  @override
  void initState() {
    super.initState();
    // Connect socket & load contacts to populate unread badges
    context.read<ChatBloc>().add(ConnectSocketRequested());
    context.read<ChatBloc>().add(const LoadContactsRequested());
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      setState(() => _unreadMessageCount = 0);
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ContactsLoaded && _selectedIndex != 2) {
          final totalUnread = state.contacts.fold<int>(0, (sum, c) => sum + c.unread);
          if (totalUnread != _unreadMessageCount) {
            setState(() => _unreadMessageCount = totalUnread);
          }
        }
      },
      child: Scaffold(
        extendBody: true,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF4889A8),
                Color(0xFFF8FAFC),
              ],
              stops: [0.0, 0.4],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                IndexedStack(
                  index: _selectedIndex,
                  children: const [
                    DoctorDashboardScreen(),
                    AppointmentListScreen(isFromBottomNav: true),
                    MessageListScreen(),
                  ],
                ),
                // Floating Premium Bottom Navigation Bar
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 25,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _NavItem(
                                icon: Icons.dashboard_rounded,
                                activeIcon: Icons.dashboard_rounded,
                                index: 0,
                                selectedIndex: _selectedIndex,
                                onTap: () => _onItemTapped(0),
                              ),
                              _NavItem(
                                icon: Icons.event_note_rounded,
                                activeIcon: Icons.event_note_rounded,
                                index: 1,
                                selectedIndex: _selectedIndex,
                                onTap: () => _onItemTapped(1),
                              ),
                              _NavItem(
                                icon: Icons.forum_outlined,
                                activeIcon: Icons.forum_rounded,
                                index: 2,
                                selectedIndex: _selectedIndex,
                                badgeCount: _unreadMessageCount,
                                onTap: () => _onItemTapped(2),
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
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int index;
  final int selectedIndex;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = selectedIndex == index;
    final primaryColor = const Color(0xFF4889A8);
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? primaryColor.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? primaryColor : Colors.grey.shade500,
                  size: 26,
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: 6,
                  top: 4,
                  child: AnimatedScale(
                    scale: badgeCount > 0 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.elasticOut,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Center(
                        child: Text(
                          badgeCount > 99 ? '99+' : badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isActive ? 4 : 0,
            height: 4,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
