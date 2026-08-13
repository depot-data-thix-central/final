import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FollowersListPage extends StatefulWidget {
  final String userId;
  const FollowersListPage({super.key, required this.userId});
  
  @override 
  State<FollowersListPage> createState() => _FollowersListPageState();
}

class _FollowersListPageState extends State<FollowersListPage> {
  List<Map<String, dynamic>> all = [];
  bool loading = true;
  
  // 1. Variable pour stocker le texte de recherche
  String _searchQuery = '';

  @override 
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() { loading = true; });
    try {
      // Ta requête Supabase (inchangée, elle est parfaite)
      final res = await Supabase.instance.client
          .from('follows')
          .select('follower_id, profiles!follows_follower_id_fkey(id, display_name, photo_url, avatar_url)')
          .eq('following_id', widget.userId);
          
      if (mounted) {
        setState(() {
          all = (res as List).cast<Map<String, dynamic>>();
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { loading = false; });
    }
  }

  @override 
  Widget build(BuildContext context) {
    // 2. Filtrer la liste en fonction de la barre de recherche
    final filteredList = all.where((item) {
      final profile = item['profiles'] as Map<String, dynamic>?;
      final name = profile != null ? (profile['display_name'] ?? 'User') as String : 'User';
      
      // On compare le nom et la recherche en minuscules pour ne pas rater de majuscules
      return name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          'Abonnés (${all.length})',
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          // ─── BARRE DE RECHERCHE ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Rechercher un abonné...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF1F5F9), // Fond gris très clair
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // ─── LISTE FILTRÉE ───
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: load,
                    child: filteredList.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isEmpty 
                                  ? 'Aucun abonné.' 
                                  : 'Aucun résultat trouvé.',
                              style: const TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: filteredList.length,
                            separatorBuilder: (context, i) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            itemBuilder: (context, i) {
                              final item = filteredList[i];
                              final profile = item['profiles'] as Map<String, dynamic>?;
                              final fid = item['follower_id'] as String;
                              final name = profile != null ? (profile['display_name'] ?? 'User') as String : 'User';
                              final photo = profile != null ? (profile['photo_url'] ?? profile['avatar_url']) as String? : null;

                              Widget avatarWidget;
                              if (photo != null && photo.isNotEmpty) {
                                avatarWidget = CircleAvatar(backgroundImage: NetworkImage(photo));
                              } else {
                                avatarWidget = const CircleAvatar(
                                  backgroundColor: Color(0xFFF1F5F9),
                                  child: Icon(Icons.person, color: Colors.grey),
                                );
                              }

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                leading: avatarWidget,
                                title: Text(
                                  name, 
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))
                                ),
                                onTap: () => context.push('/network/member/$fid'),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
