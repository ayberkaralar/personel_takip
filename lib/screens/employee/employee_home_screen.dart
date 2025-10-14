import 'package:flutter/material.dart';
import 'package:personel_takip/screens/employee/employee_attandance_history_screen.dart';
import 'package:personel_takip/services/location_services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../services/attendance_service.dart';
import '../../models/attendance_model.dart';
import '../../widgets/location_map_widget.dart';
import 'leave_request_screen.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  final LocationService _locationService = LocationService();
  final AttendanceService _attendanceService = AttendanceService();
  bool _isCheckingIn = false;
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleCheckIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;

    if (user == null) return;

    setState(() {
      _isCheckingIn = true;
    });

    try {
      // Konumu al
      Position? position = await _locationService.getCurrentLocation();
      
      if (position == null) {
        throw 'Konum alınamadı';
      }

      // Check-in yap
      await _attendanceService.checkIn(
        userId: user.uid,
        userName: user.name,
        position: position,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giriş yapıldı! ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingIn = false;
        });
      }
    }
  }

  Future<void> _handleCheckOut(AttendanceModel attendance) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;

    if (user == null) return;

    // Onay diyalogu
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isCheckingOut = true;
    });

    try {
      // Konumu al
      Position? position = await _locationService.getCurrentLocation();
      
      if (position == null) {
        throw 'Konum alınamadı';
      }

      // Check-out yap
      await _attendanceService.checkOut(
        attendanceId: attendance.id,
        userId: user.uid,
        position: position,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Çıkış yapıldı! 👋'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hoşgeldin, ${user?.name ?? 'Kullanıcı'}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
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
                    child: Text(
                      user?.name.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'Kullanıcı',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profil'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Profil sayfasına git
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('İzin Talebi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LeaveRequestScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Mesai Geçmişi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AttendanceHistoryScreen(),
                  ),
                );
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

                if (confirm == true && mounted) {
                  await authProvider.signOut();
                }
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              
              // Bugünkü Durum Kartı
              StreamBuilder<AttendanceModel?>(
                stream: user != null 
                    ? _attendanceService.todayAttendanceStream(user.uid)
                    : null,
                builder: (context, snapshot) {
                  final attendance = snapshot.data;
                  final hasCheckedIn = attendance != null;
                  final hasCheckedOut = attendance?.isCheckedOut ?? false;

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bugünkü Durum',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          if (!hasCheckedIn) ...[
                            Row(
                              children: [
                                const Icon(Icons.info_outline, color: Colors.orange),
                                const SizedBox(width: 12),
                                Text(
                                  'Henüz giriş yapmadınız',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'İşe Giriş',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('HH:mm').format(attendance!.checkInTime),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (hasCheckedOut) ...[
                                  const Icon(Icons.arrow_forward, color: Colors.grey),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'İşten Çıkış',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('HH:mm').format(attendance.checkOutTime!),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
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
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, color: Colors.blue),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _LiveWorkDuration(
                                      checkInTime: attendance.checkInTime,
                                      checkOutTime: attendance.checkOutTime,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Giriş/Çıkış Butonları
              StreamBuilder<AttendanceModel?>(
                stream: user != null 
                    ? _attendanceService.todayAttendanceStream(user.uid)
                    : null,
                builder: (context, snapshot) {
                  final attendance = snapshot.data;
                  final hasCheckedIn = attendance != null;
                  final hasCheckedOut = attendance?.isCheckedOut ?? false;

                  return Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: hasCheckedIn || _isCheckingIn 
                              ? null 
                              : _handleCheckIn,
                          icon: _isCheckingIn
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.login),
                          label: Text(_isCheckingIn ? 'Giriş Yapılıyor...' : 'Giriş Yap'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasCheckedIn ? Colors.grey : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: !hasCheckedIn || hasCheckedOut || _isCheckingOut
                              ? null
                              : () => _handleCheckOut(attendance!),
                          icon: _isCheckingOut
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.logout),
                          label: Text(_isCheckingOut ? 'Çıkış Yapılıyor...' : 'Çıkış Yap'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !hasCheckedIn || hasCheckedOut 
                                ? Colors.grey 
                                : Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Konum Haritası
              const Text(
                'Konumum',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),
              
              const LocationMapWidget(),
              
              const SizedBox(height: 24),
              
              // Son Hareketler
              const Text(
                'Son Hareketler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Henüz hareket kaydı yok',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Canlı çalışma süresi widget'ı
class _LiveWorkDuration extends StatefulWidget {
  final DateTime checkInTime;
  final DateTime? checkOutTime;

  const _LiveWorkDuration({
    required this.checkInTime,
    this.checkOutTime,
  });

  @override
  State<_LiveWorkDuration> createState() => _LiveWorkDurationState();
}

class _LiveWorkDurationState extends State<_LiveWorkDuration> {
  String _duration = '';

  @override
  void initState() {
    super.initState();
    _updateDuration();
  }

  void _updateDuration() {
    if (!mounted) return;

    setState(() {
      final endTime = widget.checkOutTime ?? DateTime.now();
      final diff = endTime.difference(widget.checkInTime);
      
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      final seconds = diff.inSeconds.remainder(60);
      
      if (widget.checkOutTime != null) {
        // Çıkış yapılmış
        if (hours > 0) {
          _duration = 'Toplam: ${hours}s ${minutes}dk';
        } else {
          _duration = 'Toplam: ${minutes}dk';
        }
      } else {
        // Hala çalışıyor
        if (hours > 0) {
          _duration = 'Çalışma: ${hours}s ${minutes}dk ${seconds}sn';
        } else if (minutes > 0) {
          _duration = 'Çalışma: ${minutes}dk ${seconds}sn';
        } else {
          _duration = 'Çalışma: ${seconds}sn';
        }
      }
    });

    // Eğer çıkış yapılmadıysa her saniye güncelle
    if (widget.checkOutTime == null) {
      Future.delayed(const Duration(seconds: 1), _updateDuration);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _duration,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }
}