// lib/presentation/education/screens/author_library_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/book.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              author,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            Text(
              'Étagère $shelfCode · \( {books.length} livre \){books.length > 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: books.isEmpty
          ? const Center(child: Text('Aucun livre'))
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
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
                                    top: Radius.circular(12)),
                                child: book.imageUrl != null &&
                                        book.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        book.imageUrl!,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: const Color(0xFF0F172A),
                                        child: const Icon(
                                          Icons.menu_book,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                      ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isFree
                                        ? Colors.green.shade600
                                        : const Color(0xFF0284C7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isFree
                                        ? 'Gratuit'
                                        : '${book.price.toStringAsFixed(0)} ${book.currency}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              if (isDeleting)
                                Positioned(
                                  left: 6,
                                  right: 6,
                                  bottom: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Suppression programmée',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
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
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: Color(0xFF0F172A),
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  book.author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
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
