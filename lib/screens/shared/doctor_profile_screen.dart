import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctoroncall/screens/patient/book_appointment_screen.dart';
import 'package:doctoroncall/screens/shared/chat_screen.dart';
import 'package:doctoroncall/features/doctors/domain/entities/doctor.dart';
import 'package:doctoroncall/features/appointments/presentation/providers/appointment_provider.dart';
import 'package:doctoroncall/core/network/api_client.dart';
import 'package:doctoroncall/core/di/injection_container.dart';
import 'package:doctoroncall/core/utils/image_utils.dart';
import 'package:doctoroncall/features/doctors/presentation/providers/doctor_provider.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DoctorProfileScreen extends ConsumerStatefulWidget {
  final Doctor doctor;
  const DoctorProfileScreen({super.key, required this.doctor});

  @override
  ConsumerState<DoctorProfileScreen> createState() =>
      _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Rating state
  int _userRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _submittingReview = false;
  bool _reviewSubmitted = false;

  // Mutable display values that update after review
  late double _displayRating;
  late int _displayReviews;

  @override
  void initState() {
    super.initState();
    _displayRating = widget.doctor.averageRating;
    _displayReviews = widget.doctor.totalReviews;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String get _doctorName {
    final first = widget.doctor.firstName.trim();
    final last = widget.doctor.lastName.trim();
    if (first.isEmpty && last.isEmpty) return 'Doctor';
    return 'Dr. $first $last'.trim();
  }

  Future<void> _submitReview() async {
    if (_userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submittingReview = true);

    try {
      final apiClient = sl<ApiClient>();
      final body = <String, dynamic>{
        'doctorId': widget.doctor.id,
        'rating': _userRating,
      };
      if (_commentController.text.trim().isNotEmpty) {
        body['comment'] = _commentController.text.trim();
      }

      await apiClient.dio.post('/reviews', data: body);

      if (!mounted) return;

      // Compute new average rating in real-time
      final oldTotal = _displayReviews;
      final oldAvg = _displayRating;
      final newTotal = oldTotal + 1;
      final newAvg = ((oldAvg * oldTotal) + _userRating) / newTotal;

      setState(() {
        _submittingReview = false;
        _reviewSubmitted = true;
        _displayRating = newAvg;
        _displayReviews = newTotal;
      });

      // Refresh doctor list so dashboard & top doctors also update
      if (mounted) {
        ref.read(doctorNotifierProvider.notifier).loadDoctors();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Thank you for your review! ⭐',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF6AA9D8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submittingReview = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: isDark
                        ? Border.all(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.1),
                          )
                        : null,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: isDark ? Colors.white : const Color(0xFF344955),
                    size: 18,
                  ),
                ),
              ),
              centerTitle: true,
              title: Text(
                'Doctor Profile',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Doctor avatar & name
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.04,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: isDark
                            ? Border.all(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withValues(alpha: 0.1),
                              )
                            : null,
                      ),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.2),
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: isDark
                                  ? Theme.of(context).scaffoldBackgroundColor
                                  : Colors.grey.shade100,
                              backgroundImage: ImageUtils.getImageProvider(
                                doctor.image,
                              ),
                              child: doctor.image == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _doctorName,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${doctor.specialization} • ${doctor.experience} Yrs Experience',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Rating display
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ...List.generate(5, (i) {
                                return Icon(
                                  i < _displayRating.round()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 22,
                                );
                              }),
                              const SizedBox(width: 8),
                              Text(
                                _displayRating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.color,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '($_displayReviews)',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats row
                    Row(
                      children: [
                        _statCard(
                          'Experience',
                          '${doctor.experience} yrs',
                          Icons.work_outline,
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          'Fees',
                          'NPR ${doctor.fees.toStringAsFixed(0)}',
                          Icons.payments_outlined,
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          'Reviews',
                          '$_displayReviews',
                          Icons.rate_review_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Bio
                    if (doctor.bio.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.2 : 0.03,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: isDark
                              ? Border.all(
                                  color: Theme.of(
                                    context,
                                  ).dividerColor.withValues(alpha: 0.1),
                                )
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'About',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              doctor.bio,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ⭐ Premium Star Rating Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.04,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: _reviewSubmitted
                          ? _buildReviewSuccess(context)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Rate this Doctor',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Your feedback helps other patients',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Star row
                                Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(5, (i) {
                                      final starIndex = i + 1;
                                      return GestureDetector(
                                        onTap: () => setState(
                                          () => _userRating = starIndex,
                                        ),
                                        child: TweenAnimationBuilder<double>(
                                          tween: Tween(
                                            begin: 1.0,
                                            end: _userRating >= starIndex
                                                ? 1.2
                                                : 1.0,
                                          ),
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          curve: Curves.elasticOut,
                                          builder: (context, scale, child) {
                                            return Transform.scale(
                                              scale: scale,
                                              child: child,
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                            ),
                                            child: Icon(
                                              _userRating >= starIndex
                                                  ? Icons.star_rounded
                                                  : Icons.star_outline_rounded,
                                              color: _userRating >= starIndex
                                                  ? Colors.amber
                                                  : isDark
                                                  ? Colors.white12
                                                  : Colors.grey.shade300,
                                              size: 44,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                if (_userRating > 0) ...[
                                  const SizedBox(height: 4),
                                  Center(
                                    child: Text(
                                      _ratingLabel(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.amber.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),

                                // Comment field
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Theme.of(
                                            context,
                                          ).scaffoldBackgroundColor
                                        : Theme.of(
                                            context,
                                          ).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).dividerColor.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _commentController,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Share your experience (optional)',
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(14),
                                    ),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Submit button
                                SizedBox(
                                  width: double.infinity,
                                  child: GestureDetector(
                                    onTap: _submittingReview
                                        ? null
                                        : _submitReview,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: _userRating > 0
                                              ? [
                                                  const Color(0xFFFFC107),
                                                  const Color(0xFFFFB300),
                                                ]
                                              : [
                                                  Colors.grey.shade300,
                                                  Colors.grey.shade300,
                                                ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: _userRating > 0
                                            ? [
                                                BoxShadow(
                                                  color: Colors.amber
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Center(
                                        child: _submittingReview
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.5,
                                                    ),
                                              )
                                            : const Text(
                                                'Submit Review',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    otherUserId: doctor.userId,
                                    otherUserName: _doctorName,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    color: Theme.of(context).primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Chat',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BookAppointmentScreen(doctor: doctor),
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
                                  ref
                                      .read(
                                        appointmentNotifierProvider.notifier,
                                      )
                                      .loadAppointments(userId);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).primaryColor,
                                    Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Book Appointment',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
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
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewSuccess(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            color: Colors.green.shade400,
            size: 40,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Review Submitted!',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Thank you for rating $_doctorName',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            return Icon(
              i < _userRating ? Icons.star_rounded : Icons.star_outline_rounded,
              color: Colors.amber,
              size: 28,
            );
          }),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: isDark
              ? Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                )
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel() {
    switch (_userRating) {
      case 1:
        return '😞 Poor';
      case 2:
        return '😕 Fair';
      case 3:
        return '😊 Good';
      case 4:
        return '😄 Very Good';
      case 5:
        return '🤩 Excellent!';
      default:
        return '';
    }
  }
}
