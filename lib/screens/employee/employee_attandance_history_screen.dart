import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/attendance_service.dart';
import '../../models/attendance_model.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final attendanceService = AttendanceService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesai Geçmişi'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<AttendanceModel>>(
              future: attendanceService.getUserAttendances(user.uid),
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
                        Text(
                          'Hata: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
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
                          Icons.history,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz mesai kaydınız yok',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final attendances = snapshot.data!;

                return RefreshIndicator(
                  onRefresh: () async {
                    // Sayfayı yenile
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: attendances.length,
                    itemBuilder: (context, index) {
                      final attendance = attendances[index];
                      final isToday = attendance.isToday;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: isToday
                              ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                              : BorderSide.none,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showAttendanceDetails(context, attendance),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Tarih başlığı
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isToday
                                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.calendar_today,
                                        color: isToday
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey.shade600,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            DateFormat('dd MMMM yyyy, EEEE', 'tr_TR')
                                                .format(attendance.checkInTime),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isToday
                                                  ? Theme.of(context).primaryColor
                                                  : Colors.black,
                                            ),
                                          ),
                                          if (isToday)
                                            Text(
                                              'Bugün',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context).primaryColor,
                                                fontWeight: FontWeight.w500,
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
                                        color: attendance.isCheckedOut
                                            ? Colors.green.shade50
                                            : Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        attendance.isCheckedOut ? 'Tamamlandı' : 'Devam ediyor',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: attendance.isCheckedOut
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Giriş/Çıkış bilgileri
                                Row(
                                  children: [
                                    Expanded(
                                      child: _TimeInfo(
                                        icon: Icons.login,
                                        label: 'Giriş',
                                        time: DateFormat('HH:mm').format(attendance.checkInTime),
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: attendance.isCheckedOut
                                          ? _TimeInfo(
                                              icon: Icons.logout,
                                              label: 'Çıkış',
                                              time: DateFormat('HH:mm')
                                                  .format(attendance.checkOutTime!),
                                              color: Colors.orange,
                                            )
                                          : Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Column(
                                                children: [
                                                  Icon(
                                                    Icons.access_time,
                                                    color: Colors.grey.shade400,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Çıkış',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '--:--',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey.shade400,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Çalışma süresi
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.timer, color: Colors.blue, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Çalışma Süresi: ${attendance.formattedWorkDuration}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
    );
  }

  void _showAttendanceDetails(BuildContext context, AttendanceModel attendance) {
    showModalBottomSheet(
      context: context,
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
                      'Mesai Detayları',
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
                icon: Icons.calendar_today,
                label: 'Tarih',
                value: DateFormat('dd MMMM yyyy, EEEE', 'tr_TR')
                    .format(attendance.checkInTime),
              ),

              _DetailRow(
                icon: Icons.login,
                label: 'Giriş Saati',
                value: DateFormat('HH:mm:ss').format(attendance.checkInTime),
              ),

              if (attendance.isCheckedOut)
                _DetailRow(
                  icon: Icons.logout,
                  label: 'Çıkış Saati',
                  value: DateFormat('HH:mm:ss').format(attendance.checkOutTime!),
                ),

              _DetailRow(
                icon: Icons.timer,
                label: 'Çalışma Süresi',
                value: attendance.formattedWorkDuration,
              ),

              _DetailRow(
                icon: Icons.location_on,
                label: 'Giriş Konumu',
                value:
                    '${attendance.checkInLocation.latitude.toStringAsFixed(6)}, ${attendance.checkInLocation.longitude.toStringAsFixed(6)}',
              ),

              if (attendance.checkOutLocation != null)
                _DetailRow(
                  icon: Icons.location_on,
                  label: 'Çıkış Konumu',
                  value:
                      '${attendance.checkOutLocation!.latitude.toStringAsFixed(6)}, ${attendance.checkOutLocation!.longitude.toStringAsFixed(6)}',
                ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _TimeInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final Color color;

  const _TimeInfo({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
