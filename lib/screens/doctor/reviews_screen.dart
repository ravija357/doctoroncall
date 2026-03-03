import 'dart:async';
import 'package:flutter/material.dart';
import 'package:doctoroncall/core/network/api_client.dart';
import 'package:doctoroncall/core/di/injection_container.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:doctoroncall/features/messages/domain/repositories/chat_repository.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  List<dynamic> _reviews = [];
  bool _isLoading = true;
  StreamSubscription? _reviewSyncSubscription;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();

    _fetchReviews();
    _setupSyncListener();
  }

  void _setupSyncListener() {
    _reviewSyncSubscription = sl<ChatRepository>().reviewSyncStream().listen((data) {
      final box = Hive.box(HiveBoxes.users);
      final userData = box.get('currentUser');
      String? currentDoctorId;
      
      if (userData is Map) {
        currentDoctorId = userData['id'] as String?;
      } else {
        currentDoctorId = box.get('userId') as String?;
      }

      final incomingDoctorId = data is Map ? data['doctorId']?.toString() : null;

      if (incomingDoctorId == null || incomingDoctorId == currentDoctorId) {
        print('[REVIEWS] Real-time sync event received for this doctor, refreshing...');
        _fetchReviews();
      }
    });
  }

  Future<void> _fetchReviews() async {
    try {
      final box = Hive.box(HiveBoxes.users);
      final userData = box.get('currentUser');
      String? doctorId;
      
      if (userData is Map) {
        doctorId = userData['id'] as String?;
      } else {
        doctorId = box.get('userId') as String?;
      }

      if (doctorId == null) {
         setState(() => _isLoading = false);
         return;
      }

      final apiClient = sl<ApiClient>();
      final response = await apiClient.dio.get('/reviews/$doctorId');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _reviews = response.data['data'] as List<dynamic>;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load reviews');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _reviewSyncSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        centerTitle: true,
        title: Text(
          'Patient Reviews',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: isDark ? Border.all(color: theme.dividerColor.withOpacity(0.1)) : null,
            ),
            child: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : const Color(0xFF344955), size: 18),
          ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box(HiveBoxes.users).listenable(),
        builder: (context, Box box, _) {
          final userData = box.get('currentUser');
          double rating = 0.0;
          int totalReviews = 0;
          
          if (userData is Map) {
            rating = (userData['averageRating'] as num?)?.toDouble() ?? 0.0;
            totalReviews = (userData['totalReviews'] as num?)?.toInt() ?? 0;
          }

          if (_isLoading) {
            return Center(child: CircularProgressIndicator(color: theme.primaryColor));
          }

          return FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRatingHeader(rating, totalReviews, theme, isDark),
                          const SizedBox(height: 32),
                          Text(
                            'Recent Feedback',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  if (_reviews.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.star_rounded, size: 60, color: Colors.amber.shade200),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No reviews yet',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Patient feedback will appear here.',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final review = _reviews[index];
                            return _ReviewCard(review: review);
                          },
                          childCount: _reviews.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingHeader(double rating, int total, ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
        border: isDark ? Border.all(color: theme.dividerColor.withOpacity(0.1)) : Border.all(color: const Color(0xFFF0F4F8)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rating > 0 ? rating.toStringAsFixed(1) : 'New',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 0.9,
                  letterSpacing: -1,
                ),
              ),
              if (rating > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 4),
                  child: Text('/ 5.0', style: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                index < rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber,
                size: 28,
              );
            }),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8FAFB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Based on $total review${total == 1 ? '' : 's'}',
              style: TextStyle(
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final comment = review['comment'] as String? ?? 'No comment provided.';
    final dateStr = review['createdAt'] != null 
        ? DateFormat('MMM d, y').format(DateTime.parse(review['createdAt']))
        : 'Recent';
        
    final patient = review['patient'] as Map<String, dynamic>?;
    final String pName = patient != null 
        ? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim()
        : 'Patient';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.04 : 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: isDark ? theme.dividerColor.withOpacity(0.1) : Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    child: Text(
                      pName.isNotEmpty ? pName[0].toUpperCase() : 'P',
                      style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pName.isEmpty ? 'Anonymous' : pName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: TextStyle(color: Colors.amber.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            comment,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
