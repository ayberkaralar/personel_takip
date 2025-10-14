import 'package:flutter/material.dart';
import 'package:personel_takip/screens/admin/battom.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/attendance_service.dart';
import '../../services/leave_service.dart';
import '../../models/attendance_model.dart';
import '../../models/leave_model.dart';
import 'attendance_list_screen.dart';
import 'admin_leave_screen.dart';


class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final attendanceService = AttendanceService();
    final leaveService = LeaveService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 32,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'Admin',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Yönetici',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Personel Listesi'),
              onTap: () {
                Navigator.pop(context);
                
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Çıkış Yap'),
                    content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await authProvider.signOut();
                }
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Sayfayı yenile
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hoşgeldin mesajı
              Text(
                'Hoşgeldin, ${user?.name ?? 'Admin'}!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(DateTime.now()),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 24),

              // İstatistik kartları
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Bugün İşe Gelenler',
                      icon: Icons.people,
                      color: Colors.green,
                      stream: attendanceService.getTodayAllAttendances(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AttendanceListScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Bekleyen İzinler',
                      icon: Icons.pending_actions,
                      color: Colors.orange,
                      stream: leaveService.getPendingLeaves(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminLeaveScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Bugün işe gelenler
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bugün İşe Gelenler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AttendanceListScreen(),
                        ),
                      );
                    },
                    child: const Text('Tümünü Gör'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              FutureBuilder<List<AttendanceModel>>(
                future: attendanceService.getTodayAllAttendances(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Bugün henüz kimse giriş yapmadı',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      ),
                    );
                  }

                  final attendances = snapshot.data!.take(5).toList();

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: attendances.length,
                    itemBuilder: (context, index) {
                      final attendance = attendances[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              attendance.userName.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            attendance.userName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Giriş: ${DateFormat('HH:mm').format(attendance.checkInTime)}',
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: attendance.isCheckedOut
                                  ? Colors.grey.shade100
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              attendance.isCheckedOut
                                  ? attendance.formattedWorkDuration
                                  : 'Devam ediyor',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: attendance.isCheckedOut
                                    ? Colors.grey.shade700
                                    : Colors.green,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),

              // Bekleyen izin talepleri
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bekleyen İzin Talepleri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminLeaveScreen(),
                        ),
                      );
                    },
                    child: const Text('Tümünü Gör'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              FutureBuilder<List<LeaveModel>>(
                future: leaveService.getPendingLeaves(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Bekleyen izin talebi yok',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      ),
                    );
                  }

                  final leaves = snapshot.data!.take(5).toList();

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: leaves.length,
                    itemBuilder: (context, index) {
                      final leave = leaves[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: const Icon(
                              Icons.pending_actions,
                              color: Colors.orange,
                            ),
                          ),
                          title: Text(
                            leave.userName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${leave.typeText} - ${leave.totalDays} gün',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminLeaveScreen(),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Future<List> stream;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.stream,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List>(
      future: stream,
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.length : 0;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    snapshot.connectionState == ConnectionState.waiting
                        ? '...'
                        : count.toString(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}