import '../models/objet_model.dart';

/// Service pour gérer les objets perdus / trouvés.
/// À brancher sur Supabase (ou ton backend) plus tard.
class ObjetService {
  // Simulation locale pour le moment
  static final List<ObjetModel> _localCache = [];

  Future<List<ObjetModel>> getObjetsRecents({int limit = 10}) async {
    // TODO: await supabase.from('objets').select().order('created_at').limit(limit)
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_localCache.reversed.take(limit));
  }

  Future<List<ObjetModel>> getMesObjets({required String userId}) async {
    // TODO: filter by user_id
    await Future.delayed(const Duration(milliseconds: 200));
    return _localCache.where((o) => o.userId == userId).toList();
  }

  Future<ObjetModel> declarerObjet(ObjetModel objet) async {
    // TODO: insert into supabase
    await Future.delayed(const Duration(milliseconds: 600));
    _localCache.add(objet);
    return objet;
  }

  Future<List<ObjetModel>> rechercherCorrespondances(ObjetModel perdu) async {
    // Placeholder pour THIX IA matching
    await Future.delayed(const Duration(milliseconds: 400));
    return _localCache
        .where((o) =>
            o.statut == StatutObjet.trouve &&
            o.titre.toLowerCase().contains(perdu.titre.toLowerCase().split(' ').first))
        .toList();
  }

  Future<List<ObjetModel>> getObjetsAutour({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) async {
    // TODO: PostGIS ou calcul distance
    await Future.delayed(const Duration(milliseconds: 300));
    return _localCache;
  }
}
