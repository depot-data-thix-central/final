// lib/presentation/education/services/book_content_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book_chapter.dart';
import '../models/book_section.dart';

class BookContentService {
  final _db = Supabase.instance.client;

  // ---------- CHAPITRES ----------
  Future<List<BookChapter>> getChapters(String bookId) async {
    final res = await _db
        .from('book_chapters')
        .select()
        .eq('book_id', bookId)
        .order('sort_order')
        .order('chapter_number');
    return res.map((e) => BookChapter.fromJson(e)).toList();
  }

  Future<BookChapter> createChapter(BookChapter chapter) async {
    final data = chapter.toJson()..remove('id');
    final res = await _db.from('book_chapters').insert(data).select().single();
    return BookChapter.fromJson(res);
  }

  // ---------- SECTIONS ----------
  Future<List<BookSection>> getSectionsByChapter(String chapterId) async {
    final res = await _db
        .from('book_sections')
        .select()
        .eq('chapter_id', chapterId)
        .eq('is_published', true)
        .order('sort_order')
        .order('section_number');
    return res.map((e) => BookSection.fromJson(e)).toList();
  }

  Future<List<BookSection>> getSectionsByBook(String bookId) async {
    final res = await _db
        .from('book_sections')
        .select()
        .eq('book_id', bookId)
        .eq('is_published', true)
        .order('sort_order');
    return res.map((e) => BookSection.fromJson(e)).toList();
  }

  Future<BookSection> getSectionById(String sectionId) async {
    final res = await _db
        .from('book_sections')
        .select()
        .eq('id', sectionId)
        .single();
    return BookSection.fromJson(res);
  }

  Future<BookSection> createSection(BookSection section) async {
    final data = section.toJson()..remove('id');
    final res = await _db.from('book_sections').insert(data).select().single();
    return BookSection.fromJson(res);
  }
}
