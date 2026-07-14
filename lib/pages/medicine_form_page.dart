import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../services/medicine_service.dart';

class _Brand {
  static const Color start = Color(0xFF3B82C4);
  static const Color end = Color(0xFF0F6E56);
}

class MedicineFormPage extends StatefulWidget {
  final Medicine? medicine; // null means Add mode, non-null means Edit mode

  const MedicineFormPage({super.key, required this.medicine});

  @override
  State<MedicineFormPage> createState() => _MedicineFormPageState();
}

class _MedicineFormPageState extends State<MedicineFormPage> {
  final _formKey = GlobalKey<FormState>();
  final MedicineService _service = MedicineService();
  bool _saving = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _nameBanglaCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _descriptionBanglaCtrl;
  late final TextEditingController _dosageCtrl;
  late final TextEditingController _dosageBanglaCtrl;
  late final TextEditingController _usesCtrl; // comma-separated
  late final TextEditingController _usesBanglaCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _sideEffectsCtrl; // comma-separated
  late final TextEditingController _sideEffectsBanglaCtrl;
  late final TextEditingController _usageBanglaCtrl;
  late final TextEditingController _stockCtrl;

  bool get isEdit => widget.medicine != null;

  @override
  void initState() {
    super.initState();
    final m = widget.medicine;
    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _nameBanglaCtrl = TextEditingController(text: m?.nameBangla ?? '');
    _companyCtrl = TextEditingController(text: m?.company ?? '');
    _categoryCtrl = TextEditingController(text: m?.category ?? '');
    _descriptionCtrl = TextEditingController(text: m?.description ?? '');
    _descriptionBanglaCtrl = TextEditingController(text: m?.descriptionBangla ?? '');
    _dosageCtrl = TextEditingController(text: m?.dosage ?? '');
    _dosageBanglaCtrl = TextEditingController(text: m?.dosageBangla ?? '');
    _usesCtrl = TextEditingController(text: m?.uses.join(', ') ?? '');
    _usesBanglaCtrl = TextEditingController(text: m?.usesBangla.join(', ') ?? '');
    _priceCtrl = TextEditingController(text: m?.unitPrice.toString() ?? '');
    _sideEffectsCtrl = TextEditingController(text: m?.sideEffects.join(', ') ?? '');
    _sideEffectsBanglaCtrl = TextEditingController(text: m?.sideEffectsBangla.join(', ') ?? '');
    _usageBanglaCtrl = TextEditingController(text: m?.usageBangla ?? '');
    _stockCtrl = TextEditingController(text: m?.stockQuantity?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameBanglaCtrl.dispose();
    _companyCtrl.dispose();
    _categoryCtrl.dispose();
    _descriptionCtrl.dispose();
    _descriptionBanglaCtrl.dispose();
    _dosageCtrl.dispose();
    _dosageBanglaCtrl.dispose();
    _usesCtrl.dispose();
    _usesBanglaCtrl.dispose();
    _priceCtrl.dispose();
    _sideEffectsCtrl.dispose();
    _sideEffectsBanglaCtrl.dispose();
    _usageBanglaCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  List<String> _splitCsv(String value) {
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final medicine = Medicine(
        id: widget.medicine?.id ?? '',
        name: _nameCtrl.text.trim(),
        nameBangla: _nameBanglaCtrl.text.trim(),
        company: _companyCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        descriptionBangla: _descriptionBanglaCtrl.text.trim(),
        dosage: _dosageCtrl.text.trim(),
        dosageBangla: _dosageBanglaCtrl.text.trim(),
        uses: _splitCsv(_usesCtrl.text),
        usesBangla: _splitCsv(_usesBanglaCtrl.text),
        unitPrice: double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
        sideEffects: _splitCsv(_sideEffectsCtrl.text),
        sideEffectsBangla: _splitCsv(_sideEffectsBanglaCtrl.text),
        usageBangla: _usageBanglaCtrl.text.trim(),
        stockQuantity: _stockCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_stockCtrl.text.trim()),
      );

      if (isEdit) {
        await _service.updateMedicine(medicine);
      } else {
        await _service.addMedicine(medicine);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Medicine updated successfully' : 'Medicine added successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Something went wrong: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Medicine' : 'Add New Medicine'),
        backgroundColor: _Brand.start,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_nameCtrl, 'Name (English)', required: true),
            _field(_nameBanglaCtrl, 'Name (Bangla)', required: true),
            _field(_companyCtrl, 'Company'),
            _field(_categoryCtrl, 'Category', required: true),
            _field(_priceCtrl, 'Unit Price (৳)', required: true, keyboardType: TextInputType.number),
            _field(
              _stockCtrl,
              'Stock Quantity (leave blank if not tracked yet)',
              keyboardType: TextInputType.number,
            ),
            _field(_descriptionCtrl, 'Description (English)', maxLines: 3),
            _field(_descriptionBanglaCtrl, 'Description (Bangla)', maxLines: 3),
            _field(_dosageCtrl, 'Dosage (English)'),
            _field(_dosageBanglaCtrl, 'Dosage (Bangla)'),
            _field(_usesCtrl, 'Uses (comma-separated)', maxLines: 2),
            _field(_usesBanglaCtrl, 'Uses Bangla (comma-separated)', maxLines: 2),
            _field(_sideEffectsCtrl, 'Side Effects (comma-separated)', maxLines: 2),
            _field(_sideEffectsBanglaCtrl, 'Side Effects Bangla (comma-separated)', maxLines: 2),
            _field(_usageBanglaCtrl, 'Usage Bangla'),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Brand.start,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(isEdit ? 'Update' : 'Add'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: required
            ? (value) =>
                (value == null || value.trim().isEmpty) ? '$label is required' : null
            : null,
      ),
    );
  }
}