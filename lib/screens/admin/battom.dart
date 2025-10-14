import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Floating NavBar Örneği',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Sayfalarımızı tutan liste
  static const List<Widget> _widgetOptions = <Widget>[
    PlaceholderWidget(color: Colors.lightBlue, text: 'Ana Sayfa'),
    PlaceholderWidget(color: Colors.lightGreen, text: 'Arama'),
    PlaceholderWidget(color: Colors.orangeAccent, text: 'Profil'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sayfa içeriğinin, alttaki bar'ın arkasına uzanmasını sağlar.
      // Bu, floating efekti için önemlidir.
      extendBody: true,
      appBar: AppBar(
        title: const Text('Floating BottomNavBar'),
      ),
      // Seçilen indekse göre ilgili sayfayı gösterir.
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: _buildFloatingBottomNavBar(),
    );
  }

  // Floating Bottom Navigation Bar'ı oluşturan metot
  Widget _buildFloatingBottomNavBar() {
    return Padding(
      // Kenarlardan boşluk vererek "floating" efekti oluşturuyoruz.
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: ClipRRect(
        // Kenarları yuvarlaklaştırmak için ClipRRect kullanıyoruz.
        borderRadius: const BorderRadius.all(Radius.circular(30.0)),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Ana Sayfa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Arama',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          // Arka plan rengini buradan ayarlayabilirsiniz.
          backgroundColor: Colors.white,
          // Seçili olmayan etiketleri de göstermek için.
          showUnselectedLabels: true,
          // Yükseltiyi (gölgeyi) kaldırıyoruz, çünkü kendi padding'imiz var.
          elevation: 0,
        ),
      ),
    );
  }
}

// Sayfa içeriğini temsil eden basit bir widget.
// Kaydırma efektini görebilmek için uzun bir liste içerir.
class PlaceholderWidget extends StatelessWidget {
  final Color color;
  final String text;

  const PlaceholderWidget({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 50,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color,
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text('$text - Öğe ${index + 1}'),
          ),
        );
      },
    );
  }
}