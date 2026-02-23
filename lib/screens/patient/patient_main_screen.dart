import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctoroncall/screens/shared/profile_screen.dart';
import 'package:doctoroncall/screens/patient/appointment_list_screen.dart';
import 'package:doctoroncall/screens/shared/doctor_profile_screen.dart';
import 'package:doctoroncall/screens/shared/message_list_screen.dart';
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
import 'package:doctoroncall/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:doctoroncall/features/notifications/presentation/bloc/notification_state.dart';
import 'package:doctoroncall/features/notifications/presentation/bloc/notification_event.dart';
import 'package:intl/intl.dart';

class PatientMainScreen extends StatefulWidget {
  const PatientMainScreen({super.key});

  @override
  State<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends State<PatientMainScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DoctorBloc>().add(LoadDoctorsRequested());
    final box = Hive.box(HiveBoxes.users);
    final userId = box.get('userId');
    if (userId != null) {
      context.read<AppointmentBloc>().add(LoadAppointmentsRequested(userId: userId));
    }
  }
  int _selectedIndex = 0;

  List<Widget> get _pages => [
        _HomeDashboardContent(),
        AppointmentListScreen(),
        const MessageListScreen(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6AA9D8),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Appointments',
          ),
           BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            activeIcon: Icon(Icons.message),
            label: 'Messages',
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
    final filteredDoctors = _query.isEmpty
        ? allDoctors
        : allDoctors.where((d) {
            final name = '${d.firstName} ${d.lastName}'.toLowerCase();
            final spec = (d.specialization ?? '').toLowerCase();
            return name.contains(_query) || spec.contains(_query);
          }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    valueListenable: Hive.box(HiveBoxes.users).listenable(keys: ['profileImage']),
                    builder: (context, Box box, _) {
                      final imageUrl = box.get('profileImage');
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
                    valueListenable: Hive.box(HiveBoxes.users).listenable(keys: ['firstName', 'lastName']),
                    builder: (context, Box box, _) {
                      final firstName = box.get('firstName', defaultValue: 'User');
                      final lastName = box.get('lastName', defaultValue: '');
                      
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
                            ),
                          ),
                          Text(
                            greeting,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
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
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.notifications_none, color: Color(0xFF6AA9D8)),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF6AA9D8),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
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

          // --- SEARCH BAR SECTION ---
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: _query.isNotEmpty
                      ? const Color(0xFF6AA9D8).withOpacity(0.15)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: _query.isNotEmpty
                    ? const Color(0xFF6AA9D8).withOpacity(0.4)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF6AA9D8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.search, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search doctors by name or specialty…',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ),
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: () => _searchController.clear(),
                    child: const Icon(Icons.close, color: Colors.grey, size: 20),
                  )
                else
                  const Icon(Icons.tune, color: Colors.grey, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // --- SECTION: TOP DOCTORS ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Top Doctors',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                'See All',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TopDoctorBanner(),
          const SizedBox(height: 32),

          // --- SECTION: UPCOMING APPOINTMENTS ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Upcoming Appointments',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'See All',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const [
                _FilterChip(label: 'All', isSelected: true),
                _FilterChip(label: 'General'),
                _FilterChip(label: 'Specialist'),
                _FilterChip(label: 'Pediatrics'),
                _FilterChip(label: 'Nutritionist'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          BlocBuilder<AppointmentBloc, AppointmentState>(
            builder: (context, state) {
              if (state is AppointmentLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is AppointmentError) {
                return Center(child: Text(state.message));
              } else if (state is AppointmentsLoaded) {
                final upcoming = state.appointments.where((a) => a.dateTime.isAfter(DateTime.now())).toList();
                if (upcoming.isEmpty) {
                  return const Center(child: Text('No upcoming appointments.'));
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: upcoming.length > 3 ? 3 : upcoming.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final ap = upcoming[index];
                    return _UpcomingAppointmentCard(appointment: ap);
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 32),

          // --- SECTION: AVAILABLE DOCTORS (filtered by search) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _query.isEmpty ? 'Available Doctors' : 'Search Results',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (_query.isNotEmpty)
                Text(
                  '${filteredDoctors.length} found',
                  style: const TextStyle(color: Color(0xFF6AA9D8), fontSize: 14, fontWeight: FontWeight.w600),
                )
              else
                const Text('See All', style: TextStyle(color: Colors.grey, fontSize: 14)),
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
                    const Icon(Icons.search_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      _query.isEmpty
                          ? 'No doctors available right now.'
                          : 'No doctors found for "$_query"',
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
                return _DoctorCard(doctor: doctor);
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}



class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterChip({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6AA9D8) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _TopDoctorBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6AA9D8), Color(0xFF4A8ABC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/doctor-image3.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _BannerTag(label: 'Urologist'),
                              const SizedBox(width: 8),
                              _BannerTag(label: '\$60/Session'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tatiana Bergson',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: const [
                              Icon(Icons.star, color: Colors.orange, size: 18),
                              SizedBox(width: 4),
                              Text('4.9', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.favorite_border, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 20),
                // DATE SELECTOR
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _DateItem(day: 'M', date: '12'),
                    _DateItem(day: 'T', date: '13'),
                    _DateItem(day: 'W', date: '14'),
                    _DateItem(day: 'T', date: '15'),
                    _DateItem(day: 'F', date: '16', isSelected: true),
                    _DateItem(day: 'S', date: '17'),
                    _DateItem(day: 'S', date: '18'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerTag extends StatelessWidget {
  final String label;
  _BannerTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
    );
  }
}

class _DateItem extends StatelessWidget {
  final String day;
  final String date;
  final bool isSelected;

  const _DateItem({required this.day, required this.date, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(day, style: TextStyle(color: isSelected ? const Color(0xFF6AA9D8) : Colors.white, fontSize: 12)),
          const SizedBox(height: 4),
          Text(date, style: TextStyle(color: isSelected ? const Color(0xFF6AA9D8) : Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;

  const _DoctorCard({
    required this.doctor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: doctor.image != null
                  ? DecorationImage(image: NetworkImage(doctor.image!), fit: BoxFit.cover)
                  : null,
            ),
            child: doctor.image == null ? const Icon(Icons.person, size: 40) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. ${doctor.firstName} ${doctor.lastName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${doctor.specialization} Specialist',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.star, color: Colors.orange, size: 16),
                    SizedBox(width: 4),
                    Text('4.9', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Text('(73 Reviews)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DoctorProfileScreen(doctor: doctor),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6AA9D8).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.north_east, color: Color(0xFF6AA9D8), size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  const _UpcomingAppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6AA9D8).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.access_time_filled, color: Color(0xFF6AA9D8), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Appointment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  DateFormat('MMM d, h:mm a').format(appointment.dateTime),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }
}

