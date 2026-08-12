// lib/presentation/education/screens/book_details_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookDetailsPage extends ConsumerStatefulWidget {
  final String bookId;

  const BookDetailsPage({super.key, required this.bookId});

  @override
  ConsumerState<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends ConsumerState<BookDetailsPage> {
  final _db = Supabase.instance.client;
  bool _loading = true;
  Map<String, dynamic>? _book;
  bool _isPurchased = false;
  bool _isFree = false;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    try {
      final userId = _db.auth.currentUser?.id;

      final bookRes = await _db
          .from('books')
          .select()
          .eq('id', widget.bookId)
          .maybeSingle();

      if (bookRes == null) {
        setState(() => _loading = false);
        return;
      }

      final book = Map<String, dynamic>.from(bookRes);
      final price = (book['price'] as num?)?.toDouble() ?? 0;
      final isFree = price <= 0 || book['is_free'] == true;

      bool purchased = false;
      if (!isFree && userId != null) {
        final purchase = await _db
            .from('book_purchases')
            .select()
            .eq('book_id', widget.bookId)
            .eq('user_id', userId)
            .maybeSingle();
        purchased = purchase != null;
      }

      setState(() {
        _book = book;
        _isFree = isFree;
        _isPurchased = purchased || isFree;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _goToChapters() {
    final title = _book?['title'] ?? 'Livre';
    context.push(
      '/education/book/${widget.bookId}/chapters',
      extra: {'title': title},
    );
  }

  void _goToPayment() {
    context.push('/payment', extra: {
      'type': 'book',
      'id': widget.bookId,
      'title': _book?['title'] ?? 'Livre',
      'price': _book?['price'] ?? 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Livre')),
        body: const Center(child: Text('Livre introuvable')),
      );
    }

    final title = _book!['title'] ?? 'Sans titre';
    final author = _book!['author'] ?? '';
    final description = _book!['description'] ?? '';
    final coverUrl = _book!['cover_url'] ?? _book!['image_url'];
    final price = (_book!['price'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0A1F44),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: coverUrl != null && coverUrl.toString().isNotEmpty
                    ? Image.network(
                        coverUrl,
                        height: 220,
                        width: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderCover(),
                      )
                    : _placeholderCover(),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0A1F44),
              ),
            ),
            if (author.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                author,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isFree ? Colors.green.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isFree ? 'Gratuit' : '${price.toStringAsFixed(0)} FC',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _isFree ? Colors.green.shade700 : Colors.blue.shade800,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0A1F44),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description.isNotEmpty ? description : 'Aucune description.',
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A1F44),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isPurchased ? _goToChapters : _goToPayment,
              child: Text(
                _isPurchased ? 'Lire maintenant' : 'Payer pour lire',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
Widget _buildDeletionAlert(Map<String, dynamic> book) {
  final scheduled = book['scheduled_deletion_at'];
  if (scheduled == null) return const SizedBox.shrink();

  final deletionDate = DateTime.parse(scheduled);
  final remaining = deletionDate.difference(DateTime.now());

  if (remaining.isNegative) return const SizedBox.shrink();

  final days = remaining.inDays;
  final hours = remaining.inHours % 24;

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF3C7),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFF59E0B)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.warning_amber_rounded,
            color: Color(0xFFD97706), size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Alerte',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF92400E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ce livre ne sera plus accessible dans : '
                '${days}j ${hours}h',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF92400E),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
  Widget _placeholderCover() {
    return Container(
      height: 220,
      width: 160,
      color: Colors.grey.shade300,
      child: const Icon(Icons.menu_book, size: 60, color: Colors.grey),
    );
  }
}
