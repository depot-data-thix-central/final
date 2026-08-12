// lib/presentation/education/screens/author_library_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/book.dart';
import '../../theme/thix_policy.dart'; // Ajuste le chemin selon ton arborescence

class AuthorLibraryPage extends StatelessWidget {
  final String author;
  final String shelfCode;
  final List<Book> books;

  const AuthorLibraryPage({
    super.key,
    required this.author,
    required this.shelfCode,
    required this.books,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Logique basique de pluriel (si tu n'utilises pas la vraie syntaxe intl plural)
    final bookLabel = books.length > 1 ? l10n.books : l10n.book;

    return Scaffold(
      backgroundColor: ThixPolicy.surfaceSoft,
      appBar: AppBar(
        backgroundColor: ThixPolicy.inkDeep,
        foregroundColor: ThixPolicy.onBrand,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              author,
              style: ThixPolicy.titleStyle.copyWith(
                fontWeight: ThixPolicy.bold,
                color: ThixPolicy.onBrand,
              ),
            ),
            Text(
              '${l10n.shelf} $shelfCode · ${books.length} $bookLabel',
              style: ThixPolicy.captionStyle.copyWith(
                color: ThixPolicy.onBrand.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
      body: books.isEmpty
          ? Center(
              child: Text(
                l10n.noBooksAvailable,
                style: ThixPolicy.bodyStyle.copyWith(
                  color: ThixPolicy.textSecondary,
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                ThixPolicy.s16, 
                ThixPolicy.s16, 
                ThixPolicy.s16, 
                100,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: ThixPolicy.s14,
                mainAxisSpacing: ThixPolicy.s14,
              ),
              itemCount: books.length,
              itemBuilder: (context, i) {
                final book = books[i];
                final isFree = book.price == 0;
                final isDeleting = book.scheduledDeletionAt != null &&
                    book.scheduledDeletionAt!.isAfter(DateTime.now());

                return GestureDetector(
                  onTap: () => context.push('/education/book/${book.id}'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: ThixPolicy.card,
                      borderRadius: BorderRadius.circular(ThixPolicy.rSm),
                      boxShadow: ThixPolicy.shadowSoft(),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(ThixPolicy.rSm),
                                ),
                                child: book.imageUrl != null &&
                                        book.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        book.imageUrl!,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: ThixPolicy.inkDeep,
                                        child: const Icon(
                                          Icons.menu_book,
                                          color: ThixPolicy.onBrand,
                                          size: ThixPolicy.s40,
                                        ),
                                      ),
                              ),
                              Positioned(
                                top: ThixPolicy.s8,
                                right: ThixPolicy.s8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: ThixPolicy.s6, 
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isFree
                                        ? ThixPolicy.success
                                        : ThixPolicy.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isFree
                                        ? l10n.free
                                        : '${book.price.toStringAsFixed(0)} ${book.currency}',
                                    style: ThixPolicy.microStyle.copyWith(
                                      color: ThixPolicy.onBrand,
                                      fontWeight: ThixPolicy.bold,
                                    ),
                                  ),
                                ),
                              ),
                              if (isDeleting)
                                Positioned(
                                  left: ThixPolicy.s6,
                                  right: ThixPolicy.s6,
                                  bottom: ThixPolicy.s6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: ThixPolicy.s4, 
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ThixPolicy.danger,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      l10n.scheduledDeletion,
                                      textAlign: TextAlign.center,
                                      style: ThixPolicy.microStyle.copyWith(
                                        color: ThixPolicy.onBrand,
                                        fontWeight: ThixPolicy.bold,
                                        fontSize: 9, // Forcé petit pour ce badge critique
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(ThixPolicy.s10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: ThixPolicy.bodyMediumStyle.copyWith(
                                    fontWeight: ThixPolicy.bold,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: ThixPolicy.s4),
                                Text(
                                  book.author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ThixPolicy.captionStyle,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
