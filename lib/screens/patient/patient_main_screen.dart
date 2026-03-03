import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:doctoroncall/features/doctors/domain/entities/doctor.dart';
import 'package:doctoroncall/features/appointments/domain/entities/appointment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctoroncall/features/doctors/presentation/providers/doctor_provider.dart';
import 'package:doctoroncall/features/appointments/presentation/providers/appointment_provider.dart';
import 'package:doctoroncall/features/messages/presentation/providers/chat_provider.dart';
import 'package:doctoroncall/features/messages/presentation/bloc/chat_state.dart';
import 'package:doctoroncall/features/notifications/presentation/providers/notification_provider.dart';
import 'package:doctoroncall/features/notifications/presentation/bloc/notification_state.dart';
import 'package:doctoroncall/screens/patient/top_doctors_screen.dart';
import 'package:doctoroncall/screens/shared/notification_screen.dart';
import 'package:doctoroncall/screens/patient/book_appointment_screen.dart';
import 'package:doctoroncall/screens/shared/chat_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:doctoroncall/screens/patient/appointment_list_screen.dart';
import 'package:doctoroncall/screens/shared/message_list_screen.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_state.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_state.dart';
import 'package:doctoroncall/screens/patient/medical_records_screen.dart';
import 'package:doctoroncall/screens/patient/prescriptions_screen.dart';
import 'package:doctoroncall/screens/shared/profile_screen.dart';
import 'package:doctoroncall/core/utils/image_utils.dart';
import 'package:doctoroncall/screens/shared/doctor_profile_screen.dart';

class PatientMainScreen extends ConsumerStatefulWidget {
  const PatientMainScreen({super.key});

  @override
  ConsumerState<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends ConsumerState<PatientMainScreen> {
  int _unreadMessageCount = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(doctorNotifierProvider.notifier).loadDoctors();
      ref.read(chatNotifierProvider.notifier).connectSocket();
      ref.read(chatNotifierProvider.notifier).loadContacts();

      final box = Hive.box(HiveBoxes.users);
      final userData = box.get('currentUser');
      final String? userId;
      if (userData is Map) {
        userId = userData['id'] as String?;
      } else {
        userId = box.get('userId');
      }
      if (userId != null) {
        ref.read(appointmentNotifierProvider.notifier).loadAppointments(userId);
      }
    });
  }

  int _selectedIndex = 0;

  List<Widget> get _pages => [
    _HomeDashboardContent(),
    AppointmentListScreen(
      isFromBottomNav: true,
      onBackPressed: () => _onItemTapped(0),
    ),
    MessageListScreen(onBackPressed: () => _onItemTapped(0)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<ChatState>(chatNotifierProvider, (previous, next) {
      // Count total unread from all contacts when NOT in messages tab
      if (next is ContactsLoaded && _selectedIndex != 2) {
        final totalUnread = next.contacts.fold<int>(
          0,
          (sum, c) => sum + c.unread,
        );
        if (totalUnread != _unreadMessageCount) {
          setState(() => _unreadMessageCount = totalUnread);
        }
      }
    });

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(isDark ? 0.3 : 0.8),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.4],
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
                        color: isDark
                            ? Theme.of(context).cardColor.withOpacity(0.9)
                            : Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.3 : 0.08,
                            ),
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
    final Color primaryColor = Theme.of(context).primaryColor;
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: isActive
                      ? primaryColor
                      : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade600
                            : Colors.grey.shade400),
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
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
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
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeDashboardContent extends ConsumerStatefulWidget {
  const _HomeDashboardContent();

  @override
  ConsumerState<_HomeDashboardContent> createState() =>
      _HomeDashboardContentState();
}

class _HomeDashboardContentState extends ConsumerState<_HomeDashboardContent> {
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final doctorState = ref.watch(doctorNotifierProvider);
    final allDoctors = doctorState is DoctorsLoaded
        ? doctorState.doctors
        : <Doctor>[];

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
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 120,
      ), // Bottom padding for floating nav bar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER SECTION ---
          _buildHeader(context, ref, theme, isDark),
          const SizedBox(height: 32),
          _buildSearchBar(theme, isDark),
          const SizedBox(height: 32),

          // --- UPCOMING APPOINTMENT SECTION ---
          () {
            final state = ref.watch(appointmentNotifierProvider);
            if (state is AppointmentsLoaded && state.appointments.isNotEmpty) {
              final upcoming = state.appointments
                  .where(
                    (a) =>
                        a.dateTime.isAfter(
                          DateTime.now().subtract(const Duration(days: 1)),
                        ) &&
                        ['scheduled', 'confirmed'].contains(a.status),
                  )
                  .toList();

              if (upcoming.isNotEmpty) {
                upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Upcoming Schedule',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        GestureDetector(
                          onTap: () {
                            final parent = context
                                .findAncestorStateOfType<
                                  _PatientMainScreenState
                                >();
                            parent?._onItemTapped(1);
                          },
                          child: Text(
                            'See All',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _UpcomingAppointmentCard(appointment: upcoming.first),
                    const SizedBox(height: 32),
                  ],
                );
              }
            }
            return const SizedBox.shrink();
          }(),

          // ... rest of the original Column children

          // --- SECTION: MEDICAL SERVICES ---
          Text(
            'Medical Services',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _QuickActionCard(
                icon: Icons.history_edu_rounded,
                label: 'Records',
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                iconColor: Theme.of(context).primaryColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MedicalRecordsScreen(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _QuickActionCard(
                icon: Icons.medication_liquid_rounded,
                label: 'Prescript',
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                iconColor: Theme.of(context).primaryColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrescriptionsScreen(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _QuickActionCard(
                icon: Icons.calendar_month_rounded,
                label: 'Schedules',
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                iconColor: Theme.of(context).primaryColor,
                onTap: () {
                  setState(() {
                    final parent = context
                        .findAncestorStateOfType<_PatientMainScreenState>();
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
              Text(
                'Doctor Specialty',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TopDoctorsScreen()),
                  );
                },
                child: Text(
                  'Explore',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 54,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['label'];

                return GestureDetector(
                  onTap: () => setState(
                    () => _selectedCategory = cat['label'] as String,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 24 : 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        else if (!isDark)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                      ],
                      border: isDark && !isSelected
                          ? Border.all(
                              color: theme.dividerColor.withOpacity(0.1),
                            )
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? theme.scaffoldBackgroundColor
                                : (isSelected
                                      ? Colors.white.withOpacity(0.2)
                                      : theme.primaryColor.withOpacity(0.1)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            cat['icon'] as IconData,
                            color: isSelected
                                ? Colors.white
                                : theme.primaryColor,
                            size: 18,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 10),
                          Text(
                            cat['label'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: 0.3,
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
              Text(
                'Top Doctors',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TopDoctorsScreen()),
                  );
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // --- SECTION: DOCTOR LIST ---
          if (filteredDoctors.isEmpty && _query.isNotEmpty)
            _buildNoResults(theme, isDark)
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
                  duration: Duration(
                    milliseconds: 300 + (index * 150).clamp(0, 900),
                  ),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: _DoctorCard(doctor: doctor),
                );
              },
            ),
          const SizedBox(
            height: 80,
          ), // Ensure content is not hidden by the floating nav bar
        ],
      ),
    );
  }

  // Helper methods for cleaner build
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isDark,
  ) {
    return Row(
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
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: isDark
                          ? theme.cardColor
                          : Colors.grey.shade200,
                      backgroundImage: ImageUtils.getImageProvider(imageUrl),
                      child: imageUrl == null
                          ? Icon(
                              Icons.person,
                              color: isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey,
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
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
                String greeting = 'Good Morning,';
                if (hour >= 12 && hour < 17)
                  greeting = 'Good Afternoon,';
                else if (hour >= 17 || hour < 4)
                  greeting = 'Good Evening,';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$firstName $lastName'.trim(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        () {
          final state = ref.watch(notificationNotifierProvider);
          int unreadCount = 0;
          if (state is NotificationsLoaded) {
            unreadCount = state.unreadCount;
          }
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30),
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.primaryColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 22,
                        minHeight: 22,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }(),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? theme.cardColor.withOpacity(0.8)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          fontSize: 16,
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search doctors, specialties...',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Icon(
              Icons.search_rounded,
              color: theme.primaryColor,
              size: 24,
            ),
          ),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildNoResults(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _selectedCategory != 'All'
                    ? (_categories.firstWhere(
                            (c) => c['label'] == _selectedCategory,
                          )['icon']
                          as IconData)
                    : Icons.search_off_rounded,
                size: 48,
                color: theme.primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedCategory != 'All'
                  ? 'No $_selectedCategory doctors found'
                  : 'No doctors found for "$_query"',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorCard extends ConsumerWidget {
  final Doctor doctor;
  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DoctorProfileScreen(doctor: doctor)),
      ),
      child: Container(
        width: 280,
        height: 140,
        margin: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: isDark
              ? Border.all(color: theme.dividerColor.withOpacity(0.1))
              : null,
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Stack(
          children: [
            // Left Content: Text Details
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                top: 16.0,
                bottom: 16.0,
                right: 120.0,
              ), // Give room for image
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      doctor.specialization,
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dr. ${doctor.firstName} ${doctor.lastName}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${doctor.experience} Exp',
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.scaffoldBackgroundColor
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? theme.dividerColor.withOpacity(0.1)
                            : Colors.grey.shade100,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amber, size: 16),
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

            // Right Content: Doctor Image
            Positioned(
              right: 12,
              bottom: 0,
              child: Hero(
                tag: 'doctor-${doctor.id}',
                child:
                    doctor.image != null &&
                        doctor.image!.isNotEmpty &&
                        ImageUtils.getImageProvider(doctor.image) != null
                    ? Image(
                        image: ImageUtils.getImageProvider(doctor.image)!,
                        height: 140,
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
            ),

            // Top Right: Favorite Action Icon
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.scaffoldBackgroundColor.withOpacity(0.5)
                      : Colors.grey.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_border_rounded,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingAppointmentCard extends ConsumerWidget {
  final Appointment appointment;
  const _UpcomingAppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final doctorName = appointment.doctorName != null
        ? 'Dr. ${appointment.doctorName}'
        : 'Doctor';
    final doctorImage = appointment.doctorImage;
    final doctorSpecialty = appointment.specialization ?? 'Specialist';

    final formattedDate = DateFormat(
      'd MMMM, EEEE',
    ).format(appointment.dateTime);
    final formattedTime = DateFormat('h:mm a').format(appointment.dateTime);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: isDark
            ? Border.all(color: theme.dividerColor.withOpacity(0.1))
            : null,
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
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
                  color: isDark
                      ? theme.scaffoldBackgroundColor
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.primaryColor.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child:
                      doctorImage != null &&
                          doctorImage.isNotEmpty &&
                          ImageUtils.getImageProvider(doctorImage) != null
                      ? Image(
                          image: ImageUtils.getImageProvider(doctorImage)!,
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.person_rounded,
                          color: Colors.grey.shade400,
                          size: 28,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctorSpecialty,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  if (appointment.doctorId.isNotEmpty) {
                    final doctorState = ref.read(doctorNotifierProvider);
                    if (doctorState is DoctorsLoaded) {
                      try {
                        final doctor = doctorState.doctors.firstWhere(
                          (d) => d.id == appointment.doctorId,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DoctorProfileScreen(doctor: doctor),
                          ),
                        );
                      } catch (_) {}
                    }
                  }
                },
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Middle Info Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.scaffoldBackgroundColor.withOpacity(0.5)
                  : theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? theme.dividerColor.withOpacity(0.1)
                    : theme.dividerColor.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Container(width: 1, height: 16, color: theme.dividerColor),
                const Spacer(),
                Icon(
                  Icons.access_time_rounded,
                  size: 18,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  formattedTime,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bottom Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    var doctorState = ref.read(doctorNotifierProvider);
                    if (doctorState is! DoctorsLoaded) {
                      // Show loading snackbar first
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Loading doctor information...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      // Force load the doctors if not loaded yet
                      ref
                          .read(doctorNotifierProvider.notifier)
                          .loadDoctors()
                          .then((_) {
                            if (!context.mounted) return;
                            doctorState = ref.read(doctorNotifierProvider);
                            _proceedToReschedule(
                              context,
                              ref,
                              doctorState,
                              appointment,
                            );
                          });
                    } else {
                      _proceedToReschedule(
                        context,
                        ref,
                        doctorState,
                        appointment,
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(
                      color: isDark
                          ? theme.dividerColor.withOpacity(0.3)
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'Reschedule',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (appointment.status.toLowerCase() == 'pending') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Waiting for doctor confirmation.'),
                        ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        appointment.status.toLowerCase() == 'pending'
                        ? Colors.orange
                        : theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        appointment.status.toLowerCase() == 'pending'
                            ? Icons.hourglass_top_rounded
                            : Icons.videocam_rounded,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        appointment.status.toLowerCase() == 'pending'
                            ? 'Pending'
                            : 'Join Call',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _proceedToReschedule(
    BuildContext context,
    WidgetRef ref,
    DoctorState doctorState,
    Appointment appointment,
  ) {
    if (doctorState is DoctorsLoaded) {
      try {
        final doctor = doctorState.doctors.firstWhere(
          (d) => d.id == appointment.doctorId,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookAppointmentScreen(doctor: doctor),
          ),
        ).then((_) {
          if (!context.mounted) return;
          final box = Hive.box(HiveBoxes.users);
          final userData = box.get('currentUser');
          final String? userId = userData is Map
              ? userData['id']
              : box.get('userId');
          if (userId != null) {
            ref
                .read(appointmentNotifierProvider.notifier)
                .loadAppointments(userId);
          }
        });
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor information not available.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to load doctor information. Please try again later.',
          ),
        ),
      );
    }
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: isDark
                ? Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                  )
                : null,
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? color.withOpacity(0.1) : color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
