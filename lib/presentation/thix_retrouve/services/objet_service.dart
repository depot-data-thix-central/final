import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/supabase/supabase_config.dart';
import '../models/objet_model.dart';

class ObjetService {
  final SupabaseClient _client;

  ObjetService({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  static const String _table = 'thix_objets';
  static const String _bucket = 'objets'; // crée ce bucket dans Supabase Storage

  // ── Upload photo ──────────────────────────────────────────────
  Future<String?> uploadPhoto(File file) async {
    try {
      final userId = SupabaseConfig.currentUser?.id ?? 'anonymous';
      final ext = file.path.split('.').last.toLowerCase();
      final fileName = '\( {userId}_ \){DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = 'photos/$fileName';

      await _client.storage.from(_bucket).upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final publicUrl = _client.storage.from(_bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print('Erreur uploadPhoto: $e');
      rethrow;
    }
  }

  // ── Déclarer un objet ─────────────────────────────────────────
  Future<ObjetModel?> declarerObjet({
    required String titre,
    required String description,
    required StatutObjet statut,
    required String lieu,
    String? recompense,
    String? categorie,
    String? contactInfo,
    double? latitude,
    double? longitude,
    File? photo,
  }) async {
    try {
      String? imageUrl;

      // Upload photo si présente
      if (photo != null) {
        imageUrl = await uploadPhoto(photo);
      }

      final userId = SupabaseConfig.currentUser?.id;

      final data = {
        'titre': titre.trim(),
        'description': description.trim(),
        'statut': statut.name,
        'lieu': lieu.trim(),
        'date_signalement': DateTime.now().toIso8601String(),
        'recompense': recompense?.trim(),
        'categorie': categorie,
        'contact_info': contactInfo?.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'image_url': imageUrl,
        'user_id': userId,
      };

      final res = await _client.from(_table).insert(data).select().single();
      return ObjetModel.fromJson(Map<String, dynamic>.from(res));
    } catch (e) {
      print('Erreur declarerObjet: $e');
      rethrow;
    }
  }

  // ── Liste objets récents ──────────────────────────────────────
  Future<List<ObjetModel>> getObjetsRecents({int limit = 30}) async {
    try {
      final res = await _client
          .from(_table)
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return (res as List)
          .map((e) => ObjetModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('Erreur getObjetsRecents: $e');
      return [];
    }
  }

  // ── Mes objets ────────────────────────────────────────────────
  Future<List<ObjetModel>> getMesObjets() async {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) return [];

    try {
      final res = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (res as List)
          .map((e) => ObjetModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('Erreur getMesObjets: $e');
      return [];
    }
  }

  // ── Matching simple ───────────────────────────────────────────
  Future<List<ObjetModel>> rechercherCorrespondances(ObjetModel perdu) async {
    try {
      final keyword = perdu.titre.split(' ').first;
      final res = await _client
          .from(_table)
          .select()
          .eq('statut', 'trouve')
          .ilike('titre', '%$keyword%')
          .order('created_at', ascending: false)
          .limit(10);

      return (res as List)
          .map((e) => ObjetModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> marquerRecupere(String objetId) async {
    await _client.from(_table).update({
      'statut': 'recupere',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', objetId);
  }
}
