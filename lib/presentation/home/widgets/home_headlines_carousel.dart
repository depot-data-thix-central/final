// lib/presentation/home/widgets/home_headlines_carousel.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/core/theme/thix_design_policy.dart';

class HomeHeadlinesCarousel extends StatefulWidget {
  final PageController controller;
  final String? uid;
  final VoidCallback onThixInfoTap;
  final VoidCallback onOpportunityTap;

  const HomeHeadlinesCarousel({
    super.key,
    required this.controller,
    this.uid,
    required this.onThixInfoTap,
    required this.onOpportunityTap,
  });

  @override
  State<HomeHeadlinesCarousel> createState() => _HomeHeadlinesCarouselState();
}

class _HomeHeadlinesCarouselState extends State<HomeHeadlinesCarousel> {
  int _currentIndex = 0;
  bool _isAdmin = false;
  late final Stream<List<Map<String, dynamic>>> _bannersStream;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
    // Écoute en temps réel de la table "banners" (uniquement les actives)
    _bannersStream = Supabase.instance.client
        .from('banners')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('created_at', ascending: false);
  }

  // Vérifie si l'utilisateur est admin pour afficher le bouton "Supprimer"
  Future<void> _checkAdminRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('role, account_type')
          .eq('id', user.id)
          .maybeSingle();
          
      if (data != null && mounted) {
        final role = (data['role'] ?? data['account_type'] ?? '').toString().toLowerCase();
        if (role == 'admin' || role == 'entreprise' || role == 'support') {
          setState(() => _isAdmin = true);
        }
      }
    } catch (_) {}
  }

  // Fonction pour supprimer une bannière de la base de données ET du Storage
  Future<void> _deleteBanner(String id, String imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThixPolicy.surface,
        title: const Text('Supprimer l\'annonce ?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Cette action est irréversible. L\'annonce sera retirée pour tout le monde.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text('Annuler', style: TextStyle(color: ThixPolicy.textSecondary))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ThixPolicy.danger),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Supprimer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          ),
        ],
      )
    );

    if (confirm != true) return;

    try {
      // 1. Supprimer de la table
      await Supabase.instance.client.from('banners').delete().eq('id', id);

      // 2. Extraire le chemin du fichier pour le supprimer du Storage
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf('banners');
      
      if (bucketIndex != -1 && bucketIndex < segments.length - 1) {
        final path = segments.sublist(bucketIndex + 1).join('/');
        await Supabase.instance.client.storage.from('banners').remove([path]);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Annonce supprimée'), backgroundColor: ThixPolicy.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: ThixPolicy.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _bannersStream,
      builder: (context, snapshot) {
        // En cas de chargement ou d'erreur
        if (!snapshot.hasData && !snapshot.hasError) {
          return const SizedBox(
            height: 180, 
            child: Center(child: CircularProgressIndicator(color: ThixPolicy.primary))
          );
        }

        final banners = snapshot.data ?? [];

        // Si aucune annonce n'est chargée dans la base de données
        if (banners.isEmpty) {
          return Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: ThixPolicy.tint,
              borderRadius: BorderRadius.circular(ThixPolicy.rLg),
              border: Border.all(color: ThixPolicy.border),
            ),
            child: const Center(
              child: Text(
                'Aucune annonce pour le moment', 
                style: TextStyle(color: ThixPolicy.textSecondary, fontWeight: FontWeight.w600)
              )
            ),
          );
        }

        return Column(
          children: [
            // Le Carrousel
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: widget.controller,
                itemCount: banners.length,
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  final imageUrl = banner['image_url'] as String;
                  final title = banner['title'] as String? ?? 'Annonce';
                  final tag = banner['tag'] as String? ?? 'À la une';
                  final id = banner['id'].toString();

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(ThixPolicy.rLg),
                      color: ThixPolicy.tint,
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // L'image de fond depuis Supabase Storage
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, color: ThixPolicy.textSecondary)),
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: ThixPolicy.primary)),
                        ),
                        
                        // Le filtre noir dégradé (pour que le texte blanc soit toujours lisible)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.8),
                                Colors.black.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                        // Le Tag et le Titre de la bannière (en bas)
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: ThixPolicy.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  tag.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // BOUTON SUPPRIMER (Visible que pour les Admins, en haut à GAUCHE)
                        if (_isAdmin)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: GestureDetector(
                              onTap: () => _deleteBanner(id, imageUrl),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: ThixPolicy.danger,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Les petits points d'indication
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                banners.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentIndex == index ? ThixPolicy.gold : ThixPolicy.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
