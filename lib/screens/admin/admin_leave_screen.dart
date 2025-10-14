import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/leave_service.dart';
import '../../models/leave_model.dart';

class AdminLeaveScreen extends StatefulWidget {
  const AdminLeaveScreen({super.key});

  @override
  State<AdminLeaveScreen> createState() => _AdminLeaveScreenState();
}

class _AdminLeaveScreenState extends State<AdminLeaveScreen> {
  final LeaveService _leaveService = LeaveService();
  String _selectedFilter = 'pending'; // pending, approved, rejected, all

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İzin Talepleri'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filtre butonları
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Bekleyenler',
                    isSelected: _selectedFilter == 'pending',
                    color: Colors.orange,
                    onTap: () => setState(() => _selectedFilter = 'pending'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Onaylananlar',
                    isSelected: _selectedFilter == 'approved',
                    color: Colors.green,
                    onTap: () => setState(() => _selectedFilter = 'approved'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Reddedilenler',
                    isSelected: _selectedFilter == 'rejected',
                    color: Colors.red,
                    onTap: () => setState(() => _selectedFilter = 'rejected'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Tümü',
                    isSelected: _selectedFilter == 'all',
                    color: Colors.blue,
                    onTap: () => setState(() => _selectedFilter = 'all'),
                  ),
                ],
              ),
            ),
          ),

          // İzin talepleri listesi
          Expanded(
            child: FutureBuilder<List<LeaveModel>>(
              future: _getLeaves(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Hata: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getEmptyMessage(),
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final leaves = snapshot.data!;

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: leaves.length,
                    itemBuilder: (context, index) {
                      final leave = leaves[index];
                      
                      Color statusColor;
                      IconData statusIcon;
                      
                      switch (leave.status) {
                        case 'approved':
                          statusColor = Colors.green;
                          statusIcon = Icons.check_circle;
                          break;
                        case 'rejected':
                          statusColor = Colors.red;
                          statusIcon = Icons.cancel;
                          break;
                        default:
                          statusColor = Colors.orange;
                          statusIcon = Icons.pending;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showLeaveDetails(context, leave, statusColor),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.blue.shade100,
                                      child: Text(
                                        leave.userName.substring(0, 1).toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            leave.userName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            leave.typeText,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(statusIcon, size: 14, color: statusColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            leave.statusText,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: statusColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 12),
                                
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${DateFormat('dd MMM yyyy').format(leave.startDate)} - ${DateFormat('dd MMM yyyy').format(leave.endDate)}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${leave.totalDays} gün',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                if (leave.reason != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    leave.reason!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<LeaveModel>> _getLeaves() async {
  try {
    switch (_selectedFilter) {
      case 'pending':
        return await _leaveService.getPendingLeaves();
      case 'approved':
        // Onaylananları getir
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('leaves')
            .where('status', isEqualTo: 'approved')
            .orderBy('createdAt', descending: true)
            .get();
        return snapshot.docs.map((doc) => LeaveModel.fromFirestore(doc)).toList();
      case 'rejected':
        // Reddedilenleri getir
        QuerySnapshot snapshot2 = await FirebaseFirestore.instance
            .collection('leaves')
            .where('status', isEqualTo: 'rejected')
            .orderBy('createdAt', descending: true)
            .get();
        return snapshot2.docs.map((doc) => LeaveModel.fromFirestore(doc)).toList();
      case 'all':
        // Tümünü getir
        QuerySnapshot snapshot3 = await FirebaseFirestore.instance
            .collection('leaves')
            .orderBy('createdAt', descending: true)
            .get();
        return snapshot3.docs.map((doc) => LeaveModel.fromFirestore(doc)).toList();
      default:
        return await _leaveService.getPendingLeaves();
    }
  } catch (e) {
    print('Hata: $e'); // Debug için
    return [];
  }
}

  String _getEmptyMessage() {
    switch (_selectedFilter) {
      case 'pending':
        return 'Bekleyen izin talebi yok';
      case 'approved':
        return 'Onaylanmış izin yok';
      case 'rejected':
        return 'Reddedilmiş izin yok';
      default:
        return 'İzin talebi yok';
    }
  }

  void _showLeaveDetails(BuildContext context, LeaveModel leave, Color statusColor) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'İzin Detayları',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              _DetailRow(
                icon: Icons.person,
                label: 'Personel',
                value: leave.userName,
              ),
              
              _DetailRow(
                icon: Icons.category,
                label: 'İzin Tipi',
                value: leave.typeText,
              ),
              
              _DetailRow(
                icon: Icons.calendar_today,
                label: 'Başlangıç',
                value: DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(leave.startDate),
              ),
              
              _DetailRow(
                icon: Icons.event,
                label: 'Bitiş',
                value: DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(leave.endDate),
              ),
              
              _DetailRow(
                icon: Icons.access_time,
                label: 'Toplam',
                value: '${leave.totalDays} gün',
              ),
              
              _DetailRow(
                icon: Icons.info_outline,
                label: 'Durum',
                value: leave.statusText,
                valueColor: statusColor,
              ),
              
              if (leave.reason != null) ...[
                const Divider(height: 24),
                const Text(
                  'Açıklama:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  leave.reason!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
              
              if (leave.status == 'pending') ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _handleLeaveAction(
                            context,
                            leave.id,
                            'rejected',
                            authProvider.userModel!.uid,
                          );
                        },
                        icon: const Icon(Icons.cancel),
                        label: const Text('Reddet'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _handleLeaveAction(
                            context,
                            leave.id,
                            'approved',
                            authProvider.userModel!.uid,
                          );
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Onayla'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleLeaveAction(
    BuildContext context,
    String leaveId,
    String status,
    String approvedBy,
  ) async {
    try {
      await _leaveService.updateLeaveStatus(
        leaveId: leaveId,
        status: status,
        approvedBy: approvedBy,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved' 
                ? 'İzin talebi onaylandı ✅' 
                : 'İzin talebi reddedildi ❌',
          ),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ),
      );

      setState(() {}); // Listeyi yenile
    } catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? Colors.grey.shade700,
                fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}