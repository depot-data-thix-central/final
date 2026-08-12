// lib/presentation/education/instructor/add_book_content_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/book_chapter.dart';
import '../models/book_section.dart';
import '../services/book_content_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class AddBookContentPage extends ConsumerStatefulWidget {
  final String bookId;

  const AddBookContentPage({super.key, required this.bookId});

  @override
  ConsumerState<AddBookContentPage> createState() => _AddBookContentPageState();
}

class _AddBookContentPageState extends ConsumerState<AddBookContentPage> {
  final _service = BookContentService();

  final _chapterTitleCtrl = TextEditingController();
  final _chapterNumberCtrl = TextEditingController();
  final _sectionTitleCtrl = TextEditingController();
  final _sectionNumberCtrl = TextEditingController();
  final _contentFrCtrl = TextEditingController();
  final _contentLnCtrl = TextEditingController();
  final _contentSwCtrl = TextEditingController();
  final _contentEnCtrl = TextEditingController();

  List<BookChapter> _chapters = [];
  String? _selectedChapterId;
  String? _editingChapterId; // null = création, sinon = édition
  bool _loading = true;
  bool _saving = false;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    setState(() => _loading = true);
    try {
      final list = await _service.getChapters(widget.bookId);
      setState(() {
        _chapters = list;
        if (list.isNotEmpty && _selectedChapterId == null) {
          _selectedChapterId = list.first.id;
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startEditChapter(BookChapter chapter) {
    setState(() {
      _editingChapterId = chapter.id;
      _chapterNumberCtrl.text = chapter.chapterNumber.toString();
      _chapterTitleCtrl.text = chapter.title;
      _tabIndex = 0;
    });
  }

  void _cancelEditChapter() {
    setState(() {
      _editingChapterId = null;
      _chapterNumberCtrl.clear();
      _chapterTitleCtrl.clear();
    });
  }

  Future<void> _saveChapter() async {
    if (_chapterTitleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      if (_editingChapterId != null) {
        // UPDATE
        await SupabaseUpdateChapter(
          id: _editingChapterId!,
          title: _chapterTitleCtrl.text.trim(),
          chapterNumber:
              int.tryParse(_chapterNumberCtrl.text) ?? 1,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chapitre modifié !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // CREATE
        final chapter = BookChapter(
          id: '',
          bookId: widget.bookId,
          title: _chapterTitleCtrl.text.trim(),
          chapterNumber:
              int.tryParse(_chapterNumberCtrl.text) ?? (_chapters.length + 1),
          sortOrder: _chapters.length,
        );
        await _service.createChapter(chapter);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chapitre ajouté !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      _cancelEditChapter();
      await _loadChapters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteChapter(BookChapter chapter) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce chapitre ?'),
        content: Text(
          '« ${chapter.title} » et toutes ses sections seront supprimés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await SupabaseDeleteChapter(chapter.id);
      if (_selectedChapterId == chapter.id) {
        _selectedChapterId = null;
      }
      if (_editingChapterId == chapter.id) {
        _cancelEditChapter();
      }
      await _loadChapters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chapitre supprimé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveSection() async {
    if (_selectedChapterId == null || _contentFrCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisis un chapitre et remplis le contenu FR'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final section = BookSection(
        id: '',
        chapterId: _selectedChapterId!,
        bookId: widget.bookId,
        title: _sectionTitleCtrl.text.trim().isEmpty
            ? null
            : _sectionTitleCtrl.text.trim(),
        sectionNumber: _sectionNumberCtrl.text.trim().isEmpty
            ? null
            : _sectionNumberCtrl.text.trim(),
        contentFr: _contentFrCtrl.text.trim(),
        contentLn: _contentLnCtrl.text.trim().isEmpty
            ? null
            : _contentLnCtrl.text.trim(),
        contentSw: _contentSwCtrl.text.trim().isEmpty
            ? null
            : _contentSwCtrl.text.trim(),
        contentEn: _contentEnCtrl.text.trim().isEmpty
            ? null
            : _contentEnCtrl.text.trim(),
      );
      await _service.createSection(section);
      _sectionTitleCtrl.clear();
      _sectionNumberCtrl.clear();
      _contentFrCtrl.clear();
      _contentLnCtrl.clear();
      _contentSwCtrl.clear();
      _contentEnCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Section ajoutée !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _chapterTitleCtrl.dispose();
    _chapterNumberCtrl.dispose();
    _sectionTitleCtrl.dispose();
    _sectionNumberCtrl.dispose();
    _contentFrCtrl.dispose();
    _contentLnCtrl.dispose();
    _contentSwCtrl.dispose();
    _contentEnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Contenu du livre',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0A1F44),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => setState(() => _tabIndex = 0),
                          child: Text(
                            'Chapitre',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _tabIndex == 0
                                  ? const Color(0xFF2D6CDF)
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () => setState(() => _tabIndex = 1),
                          child: Text(
                            'Section',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _tabIndex == 1
                                  ? const Color(0xFF2D6CDF)
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _tabIndex == 0
                        ? _buildChapterForm()
                        : _buildSectionForm(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildChapterForm() {
    final isEditing = _editingChapterId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEditing ? 'Modifier le chapitre' : 'Nouveau chapitre',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _chapterNumberCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Numéro du chapitre',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _chapterTitleCtrl,
          decoration: const InputDecoration(
            labelText: 'Titre du chapitre *',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            if (isEditing) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelEditChapter,
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: isEditing ? 2 : 1,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveChapter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A1F44),
                    foregroundColor: Colors.white,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isEditing
                          ? 'Enregistrer'
                          : 'Ajouter le chapitre'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_chapters.isNotEmpty) ...[
          const Text('Chapitres existants',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ..._chapters.map((c) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2D6CDF),
                    child: Text(
                      '${c.chapterNumber}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(c.title),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        color: const Color(0xFF2D6CDF),
                        onPressed: () => _startEditChapter(c),
                        tooltip: 'Modifier',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_rounded, size: 20),
                        color: Colors.red,
                        onPressed: () => _deleteChapter(c),
                        tooltip: 'Supprimer',
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildSectionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nouvelle section',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedChapterId,
          decoration: const InputDecoration(
            labelText: 'Chapitre *',
            border: OutlineInputBorder(),
          ),
          items: _chapters
              .map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.chapterNumber}. ${c.title}'),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedChapterId = v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _sectionNumberCtrl,
          decoration: const InputDecoration(
            labelText: 'Numéro de section (ex: 1.1)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _sectionTitleCtrl,
          decoration: const InputDecoration(
            labelText: 'Titre de la section',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contentFrCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Contenu FR *',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contentLnCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Contenu Lingala (optionnel)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contentSwCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Contenu Swahili (optionnel)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contentEnCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Contenu English (optionnel)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _saving ? null : _saveSection,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A1F44),
              foregroundColor: Colors.white,
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Ajouter la section'),
          ),
        ),
      ],
    );
  }
}

// Helpers temporaires (à déplacer dans BookContentService si tu veux)
Future<void> SupabaseUpdateChapter({
  required String id,
  required String title,
  required int chapterNumber,
}) async {
  await Supabase.instance.client.from('book_chapters').update({
    'title': title,
    'chapter_number': chapterNumber,
  }).eq('id', id);
}

Future<void> SupabaseDeleteChapter(String id) async {
  // Les sections sont supprimées automatiquement grâce à ON DELETE CASCADE
  await Supabase.instance.client.from('book_chapters').delete().eq('id', id);
}
