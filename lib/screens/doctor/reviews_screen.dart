import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctoroncall/core/network/api_client.dart';
import 'package:doctoroncall/core/di/injection_container.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

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
  }

  Future<void> _fetchReviews() async {
    try {
      final apiClient = sl<ApiClient>();
      
      // Attempt to hit the reviews endpoint. If it doesn't exist, we will fallback to empty state.
      // Usually it's /reviews or /reviews/doctor/xyz
      final response = await apiClient.dio.get('/reviews');
      
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Patient Reviews',
          style: TextStyle(
            color: Color(0xFF1A1D26),
            fontWeight: FontWeight.w700,
            fontSize: 18,
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
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6AA9D8)));
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
                          _buildRatingHeader(rating, totalReviews),
                          const SizedBox(height: 32),
                          const Text(
                            'Recent Feedback',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1D26),
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
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
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

  Widget _buildRatingHeader(double rating, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
        border: Border.all(color: const Color(0xFFF0F4F8)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rating > 0 ? rating.toStringAsFixed(1) : 'New',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1D26),
                  height: 0.9,
                  letterSpacing: -1,
                ),
              ),
              if (rating > 0)
                const Padding(
                  padding: EdgeInsets.only(bottom: 6, left: 4),
                  child: Text('/ 5.0', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
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
              color: const Color(0xFFF8FAFB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Based on $total review${total == 1 ? '' : 's'}',
              style: TextStyle(
                color: Colors.grey.shade600,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.shade100),
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
                    backgroundColor: const Color(0xFF6AA9D8).withOpacity(0.1),
                    child: Text(
                      pName.isNotEmpty ? pName[0].toUpperCase() : 'P',
                      style: const TextStyle(color: Color(0xFF6AA9D8), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pName.isEmpty ? 'Anonymous' : pName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A1D26)),
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
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold, fontSize: 12),
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
              color: Colors.grey.shade700,
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
