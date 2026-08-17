// lib/presentation/mon_pays/providers/news_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/news_article.dart';

// Service qui gère les requêtes vers Supabase
class NewsService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<NewsArticle>> fetchNews() async {
    final response = await _client
        .from('news_articles')
        .select()
        .order('published_at', ascending: false); // Les plus récents en premier

    return (response as List<dynamic>)
        .map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// Provider du service
final newsServiceProvider = Provider<NewsService>((ref) => NewsService());

// Provider qui expose la liste des articles à l'interface (UI)
final newsProvider = FutureProvider<List<NewsArticle>>((ref) async {
  final service = ref.read(newsServiceProvider);
  return await service.fetchNews();
});
