import 'package:flutter/material.dart';
import 'models/medicine.dart';

class SymptomBaseMedicinePage extends StatefulWidget {
  final List<Medicine> cartItems;
  final ValueChanged<Medicine> onAddToCart;
  final bool Function(Medicine) isInCart;
  final VoidCallback onViewOrder;

  const SymptomBaseMedicinePage({
    super.key,
    required this.cartItems,
    required this.onAddToCart,
    required this.isInCart,
    required this.onViewOrder,
  });

  @override
  State<SymptomBaseMedicinePage> createState() =>
      _SymptomBaseMedicinePageState();
}

class _SymptomBaseMedicinePageState extends State<SymptomBaseMedicinePage> {
  final List<Medicine> _medicines = const [
    Medicine(
      name: 'Paracetamol',
      nameBangla: 'প্যারাসিটামল',
      category: 'Analgesic',
      description: 'Relieves mild to moderate pain and reduces fever.',
      descriptionBangla: 'হালকা থেকে মধ্যম ব্যথা উপশম করে এবং জ্বর কমায়।',
      dosage: '500 mg every 4-6 hours as needed.',
      dosageBangla: 'প্রয়োজন অনুযায়ী প্রতি 4-6 ঘণ্টায় 500 মিগ্রা।',
      uses: ['Headache', 'Fever', 'Muscle pain'],
      usesBangla: ['মাথাব্যথা', 'জ্বর', 'পেশীর ব্যথা'],
      price: 15.0,
      sideEffects: ['Nausea', 'Allergic reaction'],
      sideEffectsBangla: ['বমি ভাব', 'অ্যালার্জিক প্রতিক্রিয়া'],
      usageBangla: 'ব্যবহার',
    ),
    Medicine(
      name: 'Amoxicillin',
      nameBangla: 'অ্যামোক্সিসিলিন',
      category: 'Antibiotic',
      description:
          'Treats bacterial infections such as ear and sinus infections.',
      descriptionBangla:
          'কান এবং সাইনাস সংক্রমণের মতো ব্যাকটেরিয়াল সংক্রমণ চিকিৎসা করে।',
      dosage: '250-500 mg every 8 hours depending on severity.',
      dosageBangla: 'তীব্রতার উপর নির্ভর করে প্রতি 8 ঘণ্টায় 250-500 মিগ্রা।',
      uses: ['Ear infection', 'Sinus infection', 'Respiratory infection'],
      usesBangla: ['কান সংক্রমণ', 'সাইনাস সংক্রমণ', 'শ্বাসযন্ত্রের সংক্রমণ'],
      price: 35.0,
      sideEffects: ['Diarrhea', 'Nausea', 'Allergic reaction'],
      sideEffectsBangla: ['ডায়রিয়া', 'বমি ভাব', 'অ্যালার্জিক প্রতিক্রিয়া'],
      usageBangla: 'ব্যবহার',
    ),
    Medicine(
      name: 'Cetirizine',
      nameBangla: 'সেটিরিজাইন',
      category: 'Antihistamine',
      description: 'Reduces allergy symptoms like sneezing and itching.',
      descriptionBangla: 'হাঁচি এবং চুলকানির মতো অ্যালার্জির লক্ষণ কমায়।',
      dosage: '10 mg once daily.',
      dosageBangla: 'দিনে একবার 10 মিগ্রা।',
      uses: ['Hay fever', 'Allergic rhinitis', 'Skin rash'],
      usesBangla: ['খড় জ্বর', 'অ্যালার্জিক রাইনাইটিস', 'ত্বকের ফুসকুড়ি'],
      price: 20.0,
      sideEffects: ['Drowsiness', 'Headache'],
      sideEffectsBangla: ['তন্দ্রা', 'মাথাব্যথা'],
      usageBangla: 'ব্যবহার',
    ),
    Medicine(
      name: 'Aspirin',
      nameBangla: 'অ্যাসপিরিন',
      category: 'Analgesic',
      description: 'Reduces pain, fever, and inflammation.',
      descriptionBangla: 'ব্যথা, জ্বর এবং প্রদাহ কমায়।',
      dosage: '300-600 mg every 4-6 hours as needed.',
      dosageBangla: 'প্রয়োজন অনুযায়ী প্রতি 4-6 ঘণ্টায় 300-600 মিগ্রা।',
      uses: ['Headache', 'Inflammation', 'Heart attack prevention'],
      usesBangla: ['মাথাব্যথা', 'প্রদাহ', 'হৃদরোগ প্রতিরোধ'],
      price: 20.0,
      sideEffects: ['Stomach upset', 'Heartburn'],
      sideEffectsBangla: ['পেটের গোলমাল', 'বুকজ্বালা'],
      usageBangla: 'ব্যবহার',
    ),
    Medicine(
      name: 'Ibuprofen',
      nameBangla: 'আইবুপ্রোফেন',
      category: 'NSAID',
      description: 'Reduces pain, fever, and inflammation.',
      descriptionBangla: 'ব্যথা, জ্বর এবং প্রদাহ কমায়।',
      dosage: '200-400 mg every 4-6 hours as needed.',
      dosageBangla: 'প্রয়োজন অনুযায়ী প্রতি 4-6 ঘণ্টায় 200-400 মিগ্রা।',
      uses: ['Fever', 'Pain', 'Inflammation'],
      usesBangla: ['জ্বর', 'ব্যথা', 'প্রদাহ'],
      price: 25.0,
      sideEffects: ['Stomach upset', 'Nausea'],
      sideEffectsBangla: ['পেটের গোলমাল', 'বমি ভাব'],
      usageBangla: 'ব্যবহার',
    ),
    Medicine(
      name: 'Loratadine',
      nameBangla: 'লোরাটাডিন',
      category: 'Antihistamine',
      description: 'Treats allergy symptoms.',
      descriptionBangla: 'অ্যালার্জির লক্ষণ চিকিৎসা করে।',
      dosage: '10 mg once daily.',
      dosageBangla: 'দিনে একবার 10 মিগ্রা।',
      uses: ['Allergy', 'Hay fever', 'Itching'],
      usesBangla: ['অ্যালার্জি', 'খড় জ্বর', 'চুলকানি'],
      price: 18.0,
      sideEffects: ['Drowsiness'],
      sideEffectsBangla: ['তন্দ্রা'],
      usageBangla: 'ব্যবহার',
    ),
    Medicine(
      name: 'Diphenhydramine',
      nameBangla: 'ডিফেনহাইড্রামাইন',
      category: 'Antihistamine',
      description: 'Relieves cold and allergy symptoms.',
      descriptionBangla: 'সর্দি এবং অ্যালার্জির লক্ষণ উপশম করে।',
      dosage: '25-50 mg every 4-6 hours.',
      dosageBangla: 'প্রতি 4-6 ঘণ্টায় 25-50 মিগ্রা।',
      uses: ['Cold', 'Allergy', 'Runny nose'],
      usesBangla: ['সর্দি', 'অ্যালার্জি', 'নাক বন্ধ'],
      price: 22.0,
      sideEffects: ['Drowsiness', 'Dizziness'],
      sideEffectsBangla: ['তন্দ্রা', 'মাথা ঘোরানো'],
      usageBangla: 'ব্যবহার',
    ),
  ];

  String _searchTerm = '';

  List<Medicine> get _filteredMedicines {
    if (_searchTerm.isEmpty) return [];
    final query = _searchTerm.toLowerCase();
    return _medicines.where((medicine) {
      return medicine.uses.any((use) => use.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Base Medicine'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            tooltip: 'Order',
            onPressed: widget.onViewOrder,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Search for Symptoms',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter a symptom like fever, cold, allergy to find suggested medicines.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search symptoms',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => setState(() => _searchTerm = value),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _filteredMedicines.isEmpty && _searchTerm.isNotEmpty
                    ? const Center(
                        child: Text(
                          'No medicines found for this symptom. Try another.',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : _searchTerm.isEmpty
                    ? const Center(
                        child: Text(
                          'Enter a symptom to see suggestions.',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredMedicines.length,
                        itemBuilder: (context, index) {
                          final medicine = _filteredMedicines[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          medicine.name,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Chip(
                                          label: Text(medicine.category),
                                          backgroundColor: Theme.of(
                                            context,
                                          ).colorScheme.primary.withAlpha(38),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(medicine.description),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Dosage: ${medicine.dosage}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: medicine.uses
                                          .map(
                                            (use) => Chip(
                                              label: Text(use),
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withAlpha(31),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        icon: Icon(
                                          widget.isInCart(medicine)
                                              ? Icons.check
                                              : Icons.add_shopping_cart,
                                        ),
                                        label: Text(
                                          widget.isInCart(medicine)
                                              ? 'Added'
                                              : 'Add to Cart',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        onPressed: widget.isInCart(medicine)
                                            ? null
                                            : () =>
                                                  widget.onAddToCart(medicine),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
