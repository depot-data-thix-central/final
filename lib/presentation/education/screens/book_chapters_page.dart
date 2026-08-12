// lib/presentation/education/screens/book_chapters_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/book_chapter.dart';
import '../models/book_section.dart';
import '../services/book_content_service.dart';

final bookChaptersProvider =
    FutureProvider.family<List<BookChapter>, String>((ref, bookId) async {
  return BookContentService().getChapters(bookId);
});

final bookSectionsByChapterProvider =
    FutureProvider.family<List<BookSection>, String>((ref, chapterId) async {
  return BookContentService().getSectionsByChapter(chapterId);
});

class BookChaptersPage extends ConsumerWidget {
  final String bookId;
  final String? bookTitle;

  const BookChaptersPage({
    required this.bookId,
    this.bookTitle,
    super.key,
  });

  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color ivory = Color(0xFFF6F7FB);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10182B);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color hairline = Color(0xFFE7EAF3);
  static const Color gold = Color(0xFFE3B23C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(bookChaptersProvider(bookId));

    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        backgroundColor: navyDeep,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          bookTitle ?? 'Chapitres',
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: chaptersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (chapters) {
          if (chapters.isEmpty) {
            return const Center(
              child: Text(
                'Aucun chapitre disponible pour ce livre.',
                style: TextStyle(color: mutedText),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              return _ChapterCard(
                chapter: chapter,
                bookId: bookId,
              );
            },
          );
        },
      ),
    );
  }
}

class _ChapterCard extends ConsumerWidget {
  final BookChapter chapter;
  final String bookId;

  const _ChapterCard({required this.chapter, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync =
        ref.watch(bookSectionsByChapterProvider(chapter.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: BookChaptersPage.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BookChaptersPage.hairline),
        boxShadow: [
          BoxShadow(
            color: BookChaptersPage.navyDeep.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BookChaptersPage.navyDeep.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${chapter.chapterNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: BookChaptersPage.navyDeep,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          title: Text(
            chapter.title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: BookChaptersPage.darkText,
            ),
          ),
          subtitle: Text(
            'Chapitre ${chapter.chapterNumber}',
            style: const TextStyle(
              fontSize: 12,
              color: BookChaptersPage.mutedText,
            ),
          ),
          children: [
            sectionsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, _) => Text('Erreur : $e'),
              data: (sections) {
                if (sections.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Aucune section dans ce chapitre.',
                      style: TextStyle(color: BookChaptersPage.mutedText),
                    ),
                  );
                }

                return Column(
                  children: sections.map((section) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      leading: const Icon(
                        Icons.article_outlined,
                        size: 20,
                        color: BookChaptersPage.primaryBlue,
                      ),
                      title: Text(
                        section.title ??
                            'Section ${section.sectionNumber ?? ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: section.sectionNumber != null
                          ? Text('§ ${section.sectionNumber}')
                          : null,
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () {
                        context.push(
                          '/education/section/${section.id}',
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
