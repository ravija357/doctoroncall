import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_bloc.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_event.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_state.dart';
import 'package:doctoroncall/screens/shared/doctor_profile_screen.dart';
import 'package:doctoroncall/core/utils/image_utils.dart';

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'General',
    'Cardiologist',
    'Dentist',
    'Neurologist',
    'Pediatrician',
    'Orthopedist',
  ];

  @override
  void initState() {
    super.initState();
    // Fetch doctors if not already loaded
    final doctorState = context.read<DoctorBloc>().state;
    if (doctorState is! DoctorsLoaded) {
      context.read<DoctorBloc>().add(const LoadDoctorsRequested());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Find a Doctor',
          style: TextStyle(
            color: Color(0xFF1A1D26),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF344955), size: 18),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search doctors, specialties...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6AA9D8)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Categories
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = category),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF6AA9D8) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF6AA9D8) : Colors.grey.shade300,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: const Color(0xFF6AA9D8).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: BlocBuilder<DoctorBloc, DoctorState>(
              builder: (context, state) {
                if (state is DoctorLoading) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF6AA9D8)));
                } else if (state is DoctorError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 60, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load doctors',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => context.read<DoctorBloc>().add(const LoadDoctorsRequested()),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6AA9D8)),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (state is DoctorsLoaded) {
                  var filtered = state.doctors.where((d) {
                    final isNameMatch = '${d.firstName} ${d.lastName}'.toLowerCase().contains(_searchQuery);
                    final isSpecMatch = d.specialization.toLowerCase().contains(_searchQuery);
                    final isSearchMatch = isNameMatch || isSpecMatch;
                    
                    final isCatMatch = _selectedCategory == 'All' || 
                        d.specialization.toLowerCase().contains(_selectedCategory.toLowerCase());
                        
                    return isSearchMatch && isCatMatch;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_rounded, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No doctors found',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or filters',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final doctor = filtered[index];
                      final name = '${doctor.firstName} ${doctor.lastName}'.trim();
                      
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DoctorProfileScreen(doctor: doctor),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF6AA9D8).withOpacity(0.3), width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.grey.shade100,
                                  backgroundImage: ImageUtils.getImageProvider(doctor.image),
                                  child: doctor.image == null
                                      ? const Icon(Icons.person, color: Colors.grey, size: 30)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.isEmpty ? 'Doctor' : 'Dr. $name',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Color(0xFF1A1D26)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      doctor.specialization,
                                      style: const TextStyle(color: Color(0xFF6AA9D8), fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          doctor.averageRating > 0 ? doctor.averageRating.toStringAsFixed(1) : 'New',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '|  ${doctor.experience} Yrs Exp',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
