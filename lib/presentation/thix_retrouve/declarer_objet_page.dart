import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/objet_model.dart';

class DeclarerObjetPage extends StatefulWidget {
  final StatutObjet type; // perdu ou trouve

  const DeclarerObjetPage({super.key, required this.type});

  @override
  State<DeclarerObjetPage> createState() => _DeclarerObjetPageState();
}

class _DeclarerObjetPageState extends State<DeclarerObjetPage> {
  final _formKey = GlobalKey<FormState>();
  final _titreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _lieuCtrl = TextEditingController();
  final _recompenseCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();

  String? _categorie;
  bool _isLoading = false;

  final List<String> _categories = [
    'Téléphone',
    'Portefeuille / Sac',
    'Clés',
    'Documents',
    'Bijoux / Montre',
    'Sac à dos',
    'Écouteurs / Accessoires',
    'Autre',
  ];

  bool get isPerdu => widget.type == StatutObjet.perdu;

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descCtrl.dispose();
    _lieuCtrl.dispose();
    _recompenseCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // TODO: Appel service Supabase / API
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPerdu
                ? 'Objet perdu déclaré avec succès ! THIX IA recherche des correspondances...'
                : 'Objet trouvé déclaré. Merci de contribuer à la communauté !',
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isPerdu ? "J'ai perdu un objet" : "J'ai trouvé un objet",
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header coloré
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isPerdu ? const Color(0xFFF59E0B) : const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    isPerdu ? Icons.search : Icons.inventory_2_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isPerdu
                          ? 'Déclarez l\'objet que vous avez perdu. La communauté et THIX IA vont vous aider à le retrouver.'
                          : 'Déclarez l\'objet que vous avez trouvé. Aidez quelqu\'un à le récupérer.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Photo placeholder
            GestureDetector(
              onTap: () {
                // TODO: Image picker
              },
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 36, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Ajouter une photo',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel('Titre de l\'objet *'),
            TextFormField(
              controller: _titreCtrl,
              decoration: _inputDecoration('Ex: Téléphone Samsung Galaxy A54'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Titre obligatoire' : null,
            ),
            const SizedBox(height: 16),

            _buildLabel('Catégorie'),
            DropdownButtonFormField<String>(
              value: _categorie,
              decoration: _inputDecoration('Choisir une catégorie'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _categorie = v),
            ),
            const SizedBox(height: 16),

            _buildLabel('Description détaillée *'),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: _inputDecoration(
                isPerdu
                    ? 'Couleur, marque, particularités, contenu...'
                    : 'Décrivez précisément l\'objet trouvé...',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Description obligatoire' : null,
            ),
            const SizedBox(height: 16),

            _buildLabel(isPerdu ? 'Lieu de perte *' : 'Lieu de trouvaille *'),
            TextFormField(
              controller: _lieuCtrl,
              decoration: _inputDecoration('Ex: THIX Center, Kiswahili / Parking visiteurs'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Lieu obligatoire' : null,
            ),
            const SizedBox(height: 16),

            if (isPerdu) ...[
              _buildLabel('Récompense (optionnel)'),
              TextFormField(
                controller: _recompenseCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Ex: 20 000 FC'),
              ),
              const SizedBox(height: 16),
            ],

            _buildLabel('Contact (téléphone ou email)'),
            TextFormField(
              controller: _contactCtrl,
              decoration: _inputDecoration('+243 ... ou email@example.com'),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPerdu ? const Color(0xFFF59E0B) : const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        isPerdu ? 'Déclarer comme perdu' : 'Déclarer comme trouvé',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }
}
