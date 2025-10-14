import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/attendance_service.dart';
import '../../models/attendance_model.dart';

class AttendanceListScreen extends StatelessWidget {
  const AttendanceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final attendanceService = AttendanceService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bugün İşe Gelenler'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<AttendanceModel>>(
        future: attendanceService.getTodayAllAttendances(),
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
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bugün henüz kimse giriş yapmadı',
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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: attendances.length,
            itemBuilder: (context, index) {
              final attendance = attendances[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showAttendanceDetails(context, attendance),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                attendance.userName.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 20,
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
                                    attendance.userName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: attendance.isCheckedOut
                                          ? Colors.grey.shade100
                                          : Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      attendance.isCheckedOut
                                          ? 'Çıkış Yapıldı'
                                          : 'Çalışıyor',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: attendance.isCheckedOut
                                            ? Colors.grey.shade700
                                            : Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
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
                            if (attendance.isCheckedOut) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: _TimeInfo(
                                  icon: Icons.logout,
                                  label: 'Çıkış',
                                  time: DateFormat('HH:mm').format(attendance.checkOutTime!),
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 18,
                                color: Colors.blue,
                              ),
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
                icon: Icons.person,
                label: 'Personel',
                value: attendance.userName,
              ),
              
              _DetailRow(
                icon: Icons.calendar_today,
                label: 'Tarih',
                value: DateFormat('dd MMMM yyyy', 'tr_TR').format(attendance.checkInTime),
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
                icon: Icons.access_time,
                label: 'Çalışma Süresi',
                value: attendance.formattedWorkDuration,
              ),
              
              _DetailRow(
                icon: Icons.location_on,
                label: 'Giriş Konumu',
                value: '${attendance.checkInLocation.latitude.toStringAsFixed(6)}, ${attendance.checkInLocation.longitude.toStringAsFixed(6)}',
              ),
              
              if (attendance.checkOutLocation != null)
                _DetailRow(
                  icon: Icons.location_on,
                  label: 'Çıkış Konumu',
                  value: '${attendance.checkOutLocation!.latitude.toStringAsFixed(6)}, ${attendance.checkOutLocation!.longitude.toStringAsFixed(6)}',
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