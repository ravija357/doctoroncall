import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:doctoroncall/features/appointments/domain/entities/appointment.dart';

class PatientDetailScreen extends StatelessWidget {
  final String patientId;
  final String patientName;
  final int totalVisits;
  final List<Appointment> history;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.totalVisits,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    // Sort history by date descending
    final sortedHistory = List<Appointment>.from(history)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: _buildPatientHeader(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Medical Timeline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1D26),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4889A8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalVisits Records',
                      style: const TextStyle(
                        color: Color(0xFF4889A8),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (sortedHistory.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_rounded, size: 60, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text('No medical history found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                    final isFirst = index == 0;
                    final isLast = index == sortedHistory.length - 1;
                    return _TimelineItem(
                      appointment: sortedHistory[index],
                      isFirst: isFirst,
                      isLast: isLast,
                    );
                  },
                  childCount: sortedHistory.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
      bottomNavigationBar: _buildQuickActionsMenu(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: const Color(0xFF4889A8),
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
      ),
      flexibleSpace: const FlexibleSpaceBar(
        title: Text('Patient Record', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
    );
  }

  Widget _buildPatientHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
          CircleAvatar(
            radius: 45,
            backgroundColor: const Color(0xFF6AA9D8).withOpacity(0.1),
            child: Text(
              patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF4889A8)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            patientName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1D26)),
          ),
          const SizedBox(height: 8),
          Text(
            'Patient ID: #${patientId.substring(0, 8).toUpperCase()}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13, letterSpacing: 0.5),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatIcon(Icons.calendar_month_rounded, 'First Visit', 
                history.isEmpty ? 'N/A' : DateFormat('MMM yyyy').format(history.last.dateTime)),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              _buildStatIcon(Icons.check_circle_rounded, 'Status', 'Active'),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              _buildStatIcon(Icons.star_rounded, 'Loyalty', totalVisits > 3 ? 'High' : 'New'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatIcon(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6AA9D8), size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
      ],
    );
  }

  Widget _buildQuickActionsMenu(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Opening chat with $patientName...')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.chat_bubble_rounded, color: Color(0xFF344955), size: 20),
                      SizedBox(width: 8),
                      Text('Message', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF344955))),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening clinical notes editor...')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4889A8),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF4889A8).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.edit_document, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Add Note', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final Appointment appointment;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({required this.appointment, this.isFirst = false, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Line & Dot
          SizedBox(
            width: 30,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: isFirst ? 30 : 0,
                  bottom: isLast ? null : 0,
                  height: isLast ? 30 : null,
                  child: Container(width: 2, color: Colors.grey.shade200),
                ),
                Positioned(
                  top: 30,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: appointment.status == 'completed' ? Colors.green : const Color(0xFF6AA9D8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMM d, yyyy').format(appointment.dateTime),
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1D26), fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: appointment.status == 'completed' ? Colors.green.shade50 : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            appointment.status.toUpperCase(),
                            style: TextStyle(
                              color: appointment.status == 'completed' ? Colors.green.shade700 : Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appointment.reason ?? 'Consultation',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                    if (appointment.notes != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.notes_rounded, size: 16, color: Colors.orange.shade400),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                appointment.notes!,
                                style: TextStyle(color: Colors.orange.shade900, fontSize: 12, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
