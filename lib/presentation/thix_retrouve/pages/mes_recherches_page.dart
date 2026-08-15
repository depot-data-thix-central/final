import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MesRecherchesPage extends StatefulWidget {
  const MesRecherchesPage({super.key});

  @override
  State<MesRecherchesPage> createState() => _MesRecherchesPageState();
}

class _MesRecherchesPageState extends State<MesRecherchesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _perdus = [
    {
      'title': 'Téléphone Samsung',
      'status': 'Perdu',
      'time': "Aujourd'hui, 15h",
      'state': 'En recherche',
      'icon': Icons.phone_android,
    },
    {
      'title': 'Montre noire',
      'status': 'Perdu',
      'time': '20 Mai, 10h',
      'state': 'En recherche',
      'icon': Icons.watch,
    },
  ];

  final List<Map<String, dynamic>> _trouves = [];

  final List<Map<String, dynamic>> _recuperes = [
    {
      'title': 'Portefeuille marron',
      'status': 'Perdu',
      'time': '18 Mai, 18h',
      'state': 'Récupéré',
      'icon': Icons.account_balance_wallet,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mes recherches',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1E3A8A),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1E3A8A),
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Objets perdus'),
            Tab(text: 'Objets trouvés'),
            Tab(text: 'Récupérés'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_perdus),
          _buildList(_trouves, emptyMessage: 'Aucun objet trouvé déclaré'),
          _buildList(_recuperes),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, {String emptyMessage = 'Aucun objet'}) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: GoogleFonts.inter(color: Colors.grey[500]),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final obj = items[index];
        final isRecovered = obj['state'] == 'Récupéré';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(obj['icon'] as IconData, size: 26, color: Colors.grey[700]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      obj['title'] as String,
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${obj['status']} • ${obj['time']}',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isRecovered ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  obj['state'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isRecovered ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
