import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctoroncall/screens/shared/profile_screen.dart';
import 'package:doctoroncall/screens/patient/appointment_list_screen.dart';
import 'package:doctoroncall/screens/shared/doctor_profile_screen.dart';
import 'package:doctoroncall/screens/shared/message_list_screen.dart';
import 'package:doctoroncall/screens/patient/medical_records_screen.dart';
import 'package:doctoroncall/screens/patient/prescriptions_screen.dart';
import 'package:doctoroncall/core/utils/image_utils.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:doctoroncall/features/doctors/domain/entities/doctor.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_bloc.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_event.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_state.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_bloc.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_event.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_state.dart';
import 'package:doctoroncall/features/appointments/domain/entities/appointment.dart';
import 'package:doctoroncall/screens/shared/notification_screen.dart';
import 'package:doctoroncall/screens/shared/chat_screen.dart';
import 'package:doctoroncall/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:doctoroncall/features/notifications/presentation/bloc/notification_state.dart';
import 'package:doctoroncall/features/notifications/presentation/bloc/notification_event.dart';
import 'package:doctoroncall/features/messages/presentation/bloc/chat_bloc.dart';
import 'package:doctoroncall/features/messages/presentation/bloc/chat_state.dart';
import 'package:doctoroncall/features/messages/presentation/bloc/chat_event.dart';
import 'package:intl/intl.dart';
import 'package:doctoroncall/screens/patient/top_doctors_screen.dart';
import 'package:doctoroncall/screens/patient/book_appointment_screen.dart';
import 'package:doctoroncall/core/di/injection_container.dart' as di;

class PatientMainScreen extends StatefulWidget {
  const PatientMainScreen({super.key});

  @override
  State<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends State<PatientMainScreen> {
  int _unreadMessageCount = 0;

  @override
  void initState() {
    super.initState();
    context.read<DoctorBloc>().add(LoadDoctorsRequested());
    // Connect socket & load contacts so we can get unread counts
    context.read<ChatBloc>().add(ConnectSocketRequested());
    context.read<ChatBloc>().add(const LoadContactsRequested());
    final box = Hive.box(HiveBoxes.users);
    final userData = box.get('currentUser');
    final String? userId;
    if (userData is Map) {
      userId = userData['id'] as String?;
    } else {
      userId = box.get('userId');
    }
    if (userId != null) {
      context.read<AppointmentBloc>().add(LoadAppointmentsRequested(userId: userId));
    }
  }

  int _selectedIndex = 0;

  List<Widget> get _pages => [
        _HomeDashboardContent(),
        const AppointmentListScreen(isFromBottomNav: true),
        const MessageListScreen(),
      ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // Clear unread count when navigating to messages
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
        // Count total unread from all contacts when NOT in messages tab
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
                Color(0xFFCDE2EC),
              ],
              stops: [0.0, 0.5],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                _pages[_selectedIndex],

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
                                icon: Icons.home_rounded,
                                activeIcon: Icons.home_rounded,
                                index: 0,
                                selectedIndex: _selectedIndex,
                                onTap: () => _onItemTapped(0),
                              ),
                              _NavItem(
                                icon: Icons.calendar_today_rounded,
                                activeIcon: Icons.calendar_month_rounded,
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
                  color: isActive ? const Color(0xFF4889A8).withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? const Color(0xFF4889A8) : Colors.grey.shade500,
                  size: 26,
                ),
              ),
              // Red badge
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
            decoration: const BoxDecoration(
              color: Color(0xFF4889A8),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}



class _HomeDashboardContent extends StatefulWidget {
  const _HomeDashboardContent();

  @override
  State<_HomeDashboardContent> createState() => _HomeDashboardContentState();
}

class _HomeDashboardContentState extends State<_HomeDashboardContent> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedCategory = 'All';

  static const _categories = [
    {'label': 'All', 'icon': Icons.grid_view_rounded},
    {'label': 'General', 'icon': Icons.local_hospital_outlined},
    {'label': 'Cardiologist', 'icon': Icons.favorite_border},
    {'label': 'Neurologist', 'icon': Icons.psychology_outlined},
    {'label': 'Dermatologist', 'icon': Icons.face_retouching_natural},
    {'label': 'Pediatrician', 'icon': Icons.child_care},
    {'label': 'Orthopedic', 'icon': Icons.accessibility_new},
    {'label': 'Gynecologist', 'icon': Icons.pregnant_woman},
    {'label': 'Psychiatrist', 'icon': Icons.self_improvement},
    {'label': 'Nutritionist', 'icon': Icons.restaurant_menu},
    {'label': 'ENT', 'icon': Icons.hearing},
    {'label': 'Urologist', 'icon': Icons.medical_services_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorState = context.watch<DoctorBloc>().state;
    final allDoctors = doctorState is DoctorsLoaded ? doctorState.doctors : <Doctor>[];

    // Filter by search query
    var filteredDoctors = _query.isEmpty
        ? allDoctors
        : allDoctors.where((d) {
            final name = '${d.firstName} ${d.lastName}'.toLowerCase();
            final spec = (d.specialization).toLowerCase();
            return name.contains(_query) || spec.contains(_query);
          }).toList();

    // Filter by category
    if (_selectedCategory != 'All') {
      filteredDoctors = filteredDoctors.where((d) {
        final spec = d.specialization.toLowerCase();
        final cat = _selectedCategory.toLowerCase();
        return spec.contains(cat) || cat.contains(spec);
      }).toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120), // Bottom padding for floating nav bar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER SECTION ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ValueListenableBuilder(
                    valueListenable: Hive.box(HiveBoxes.users).listenable(),
                    builder: (context, Box box, _) {
                      final userData = box.get('currentUser');
                      final String? imageUrl;
                      if (userData is Map) {
                        imageUrl = userData['profileImage'];
                      } else {
                        imageUrl = box.get('profileImage');
                      }
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileScreen()),
                          );
                        },
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: ImageUtils.getImageProvider(imageUrl),
                          child: imageUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  ValueListenableBuilder(
                    valueListenable: Hive.box(HiveBoxes.users).listenable(),
                    builder: (context, Box box, _) {
                      final userData = box.get('currentUser');
                      final String firstName;
                      final String lastName;
                      if (userData is Map) {
                        firstName = userData['firstName'] ?? 'User';
                        lastName = userData['lastName'] ?? '';
                      } else {
                        firstName = box.get('firstName', defaultValue: 'User');
                        lastName = box.get('lastName', defaultValue: '');
                      }
                      
                      final hour = DateTime.now().hour;
                      String greeting = 'Good Morning!';
                      if (hour >= 12 && hour < 17) greeting = 'Good Afternoon!';
                      else if (hour >= 17 || hour < 4) greeting = 'Good Evening!';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$firstName $lastName'.trim(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      );
                    },
                  ),
                ],
              ),
              BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  int unreadCount = 0;
                  if (state is NotificationsLoaded) {
                    unreadCount = state.unreadCount;
                  }
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationScreen()),
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(Icons.notifications_rounded, color: Colors.grey.shade800, size: 26),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3B30), // iOS red color
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),

          // --- UPCOMING APPOINTMENT SECTION ---
          BlocBuilder<AppointmentBloc, AppointmentState>(
            builder: (context, state) {
              if (state is AppointmentsLoaded && state.appointments.isNotEmpty) {
                final upcoming = state.appointments
                    .where((a) => a.dateTime.isAfter(DateTime.now().subtract(const Duration(days: 1))) && ['scheduled', 'confirmed'].contains(a.status))
                    .toList();
                
                if (upcoming.isNotEmpty) {
                  upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));
                  return Column(
                    children: [
                      const Center(
                        child: Text(
                          'Upcoming Appointments',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _UpcomingAppointmentCard(appointment: upcoming.first),
                      const SizedBox(height: 32),
                    ],
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
          // --- SECTION: MEDICAL SERVICES ---
          const Text(
            'Medical Services',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _QuickActionCard(
                icon: Icons.history_edu_rounded,
                label: 'E-Records',
                color: Colors.orange.shade50,
                iconColor: Colors.orange.shade600,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicalRecordsScreen())),
              ),
              const SizedBox(width: 12),
              _QuickActionCard(
                icon: Icons.medication,
                label: 'Prescriptions',
                color: Colors.teal.shade50,
                iconColor: Colors.teal.shade600,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrescriptionsScreen())),
              ),
              const SizedBox(width: 12),
              _QuickActionCard(
                icon: Icons.calendar_today_rounded,
                label: 'Schedules',
                color: Colors.blue.shade50,
                iconColor: Colors.blue.shade600,
                onTap: () {
                   setState(() {
                      // Accessing parent state index
                      final parent = context.findAncestorStateOfType<_PatientMainScreenState>();
                      parent?._onItemTapped(1); 
                   });
                },
              ),
            ],
          ),
          const SizedBox(height: 32),

          // --- SECTION: SPECIALTIES ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Doctor Specialty',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TopDoctorsScreen()),
                  );
                },
                child: const Text(
                  'View Details',
                  style: TextStyle(color: Color(0xFF32789D), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['label'];
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat['label'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 20 : 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF32789D) : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: const Color(0xFF32789D).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        else
                           BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.transparent : Colors.grey.shade200,
                            ),
                          ),
                          child: Icon(
                            cat['icon'] as IconData,
                            color: const Color(0xFF32789D),
                            size: 18,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Text(
                            cat['label'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          // --- SECTION: POPULAR DOCTOR ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Popular Doctor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TopDoctorsScreen()),
                  );
                },
                child: const Text(
                  'View Details',
                  style: TextStyle(color: Color(0xFF32789D), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (doctorState is DoctorLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF6AA9D8)))
          else if (doctorState is DoctorError)
            Center(child: Text((doctorState as DoctorError).message))
          else if (filteredDoctors.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      _selectedCategory != 'All'
                          ? (_categories.firstWhere((c) => c['label'] == _selectedCategory)['icon'] as IconData)
                          : Icons.search_off,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedCategory != 'All'
                          ? 'No $_selectedCategory doctors available'
                          : (_query.isEmpty
                              ? 'No doctors available right now.'
                              : 'No doctors found for "$_query"'),
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredDoctors.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final doctor = filteredDoctors[index];
                return TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(milliseconds: 300 + (index * 150).clamp(0, 900)),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: _DoctorCard(doctor: doctor),
                );
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}



class _DoctorCard extends StatelessWidget {
  final Doctor doctor;

  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorProfileScreen(doctor: doctor),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9), // Frosted glass back
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Left Content: Text & Ratings
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 24, bottom: 20, right: 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text(
                    'Dr. ${doctor.firstName}\n${doctor.lastName}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -0.5,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    doctor.specialization,
                    style: TextStyle(
                      color: Colors.grey.shade700, 
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFFB300), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          doctor.averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Right Content: Doctor Cutout Image Background shape
            Positioned(
              right: 0,
              bottom: 0,
              top: 0,
              width: 130, // Background shape behind doctor
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                child: Container(
                   decoration: const BoxDecoration(
                      color: Colors.transparent, 
                   ),
                ),
              ),
            ),

            Positioned(
              right: 15,
              bottom: 0,
              child: doctor.image != null && doctor.image!.isNotEmpty && ImageUtils.getImageProvider(doctor.image) != null
                  ? Image(
                      image: ImageUtils.getImageProvider(doctor.image)!,
                      height: 140, // Needs to be slightly taller than container or sit perfectly
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomRight,
                    )
                  : Image.asset(
                      'assets/images/doctor-image3.png',
                      height: 140,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomRight,
                    ),
            ),

            // Top Right: Favorite Action Icon
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6AA9D8).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite, color: Color(0xFF32789D), size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  const _UpcomingAppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    // Read populated fields from the appointment model
    final doctorName = appointment.doctorName != null ? 'Doctor ${appointment.doctorName}' : 'Doctor';
    final doctorImage = appointment.doctorImage;
    final doctorSpecialty = appointment.specialization ?? 'Specialist';
    
    // Formatting date matching the screenshot
    final formattedDate = DateFormat('d MMMM EEEE').format(appointment.dateTime);
    final formattedTime = DateFormat('h:mm a').format(appointment.dateTime).toLowerCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9), // Frosted glass look
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row: Doctor Info
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                  image: doctorImage != null && doctorImage.isNotEmpty && ImageUtils.getImageProvider(doctorImage) != null
                      ? DecorationImage(
                          image: ImageUtils.getImageProvider(doctorImage)!,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (doctorImage == null || doctorImage.isEmpty || ImageUtils.getImageProvider(doctorImage) == null) 
                    ? const Icon(Icons.person, color: Colors.grey) 
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctorSpecialty,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (appointment.doctorId.isNotEmpty) {
                    final doctorState = context.read<DoctorBloc>().state;
                    if (doctorState is DoctorsLoaded) {
                      try {
                        final doctor = doctorState.doctors.firstWhere((d) => d.id == appointment.doctorId);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorProfileScreen(doctor: doctor)));
                      } catch (e) {
                         // Doctor not found in bloc
                      }
                    }
                  }
                },
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    color: Color(0xFF32789D),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Middle Row: Date & Time
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                formattedDate,
                style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 24),
              const Icon(Icons.access_time_outlined, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                formattedTime,
                style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bottom Row: Action Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final doctorState = context.read<DoctorBloc>().state;
                    if (doctorState is DoctorsLoaded) {
                      try {
                        final doctor = doctorState.doctors.firstWhere((d) => d.id == appointment.doctorId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => di.sl<AppointmentBloc>(),
                              child: BookAppointmentScreen(doctor: doctor),
                            ),
                          ),
                        ).then((_) {
                          final box = Hive.box(HiveBoxes.users);
                          final userData = box.get('currentUser');
                          final String? userId;
                          if (userData is Map) {
                            userId = userData['id'] as String?;
                          } else {
                            userId = box.get('userId');
                          }
                          if (userId != null) {
                            context.read<AppointmentBloc>().add(LoadAppointmentsRequested(userId: userId));
                          }
                        });
                      } catch (_) {}
                    }
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Reschedule',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                     if (appointment.status.toLowerCase() == 'pending') {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Waiting for doctor confirmation.')),
                       );
                       return;
                     }
                     Navigator.push(
                       context,
                       MaterialPageRoute(
                         builder: (_) => ChatScreen(
                           otherUserId: appointment.doctorId,
                           otherUserName: doctorName,
                         ),
                       ),
                     );
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: appointment.status.toLowerCase() == 'pending' ? Colors.orange.shade400 : const Color(0xFF246C92), // Solid dark blue
                      borderRadius: BorderRadius.circular(25),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(appointment.status.toLowerCase() == 'pending' ? Icons.hourglass_empty : Icons.videocam, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          appointment.status.toLowerCase() == 'pending' ? 'Pending' : 'Join Now',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

