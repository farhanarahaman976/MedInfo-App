import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class _Brand {
  static const Color start = Color(0xFF3B82C4);
  static const Color end = Color(0xFF0F6E56);
}

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUserDetails(BuildContext context, Map<String, dynamic> data, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1C1E26) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final name = (data['name'] as String?) ?? 'No name';
        final email = (data['email'] as String?) ?? '';
        final phone = (data['phone'] as String?) ?? '';
        final address = (data['address'] as String?) ?? '';
        final bloodGroup = (data['bloodGroup'] as String?) ?? '';
        final weight = data['weight'];
        final height = data['height'];
        final hasDiabetes = (data['hasDiabetes'] as bool?) ?? false;
        final hasHypertension = (data['hasHypertension'] as bool?) ?? false;
        final hasThyroid = (data['hasThyroid'] as bool?) ?? false;
        final hasHeartDisease = (data['hasHeartDisease'] as bool?) ?? false;
        final hasAsthma = (data['hasAsthma'] as bool?) ?? false;
        final emergencyName = (data['emergencyContactName'] as String?) ?? '';
        final emergencyPhone = (data['emergencyContactPhone'] as String?) ?? '';

        final conditions = <String>[
          if (hasDiabetes) 'Diabetes',
          if (hasHypertension) 'Hypertension',
          if (hasThyroid) 'Thyroid',
          if (hasHeartDisease) 'Heart Disease',
          if (hasAsthma) 'Asthma',
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: _Brand.start,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F1117),
                              ),
                            ),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _detailRow(Icons.phone_outlined, 'Phone', phone.isEmpty ? 'Not provided' : phone, isDark),
                  _detailRow(Icons.location_on_outlined, 'Address', address.isEmpty ? 'Not provided' : address, isDark),
                  _detailRow(Icons.bloodtype_outlined, 'Blood Group', bloodGroup.isEmpty ? 'Not provided' : bloodGroup, isDark),
                  if (weight != null)
                    _detailRow(Icons.monitor_weight_outlined, 'Weight', '$weight kg', isDark),
                  if (height != null)
                    _detailRow(Icons.height_rounded, 'Height', '$height cm', isDark),
                  const SizedBox(height: 12),
                  Text(
                    'Medical Conditions',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  conditions.isEmpty
                      ? Text(
                          'None reported',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: conditions
                              .map(
                                (c) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    c,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red[700],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                  if (emergencyName.isNotEmpty || emergencyPhone.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Emergency Contact',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _detailRow(Icons.contact_emergency_outlined, 'Name', emergencyName.isEmpty ? 'Not provided' : emergencyName, isDark),
                    _detailRow(Icons.call_outlined, 'Phone', emergencyPhone.isEmpty ? 'Not provided' : emergencyPhone, isDark),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _Brand.start),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF0F1117),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // ── Search bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
            decoration: InputDecoration(
              hintText: 'Search users by name or email...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: isDark ? const Color(0xFF1C1E26) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // ── User list ──
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              var docs = snapshot.data?.docs ?? [];

              if (_query.isNotEmpty) {
                docs = docs.where((doc) {
                  final data = doc.data();
                  final name = (data['name'] as String? ?? '').toLowerCase();
                  final email = (data['email'] as String? ?? '').toLowerCase();
                  return name.contains(_query) || email.contains(_query);
                }).toList();
              }

              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    'No users found.',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final name = (data['name'] as String?) ?? 'No name';
                  final email = (data['email'] as String?) ?? '';
                  final phone = (data['phone'] as String?) ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1E26) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.grey.withValues(alpha: 0.1),
                        width: 0.8,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showUserDetails(context, data, isDark),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: _Brand.start,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F1117),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                                if (phone.isNotEmpty)
                                  Text(
                                    phone,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}