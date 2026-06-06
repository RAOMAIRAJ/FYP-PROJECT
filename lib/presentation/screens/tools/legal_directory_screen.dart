import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qanoon_buddy/core/theme.dart';

class LegalDirectoryScreen extends StatefulWidget {
  const LegalDirectoryScreen({super.key});

  @override
  State<LegalDirectoryScreen> createState() => _LegalDirectoryScreenState();
}

class _LegalDirectoryScreenState extends State<LegalDirectoryScreen> {
  String _selectedCity = 'Karachi';
  String _selectedCategory = 'All';
  String _searchQuery = '';

  // Cities list
  final List<String> _cities = ['Karachi', 'Lahore', 'Islamabad'];

  // Categories list
  final List<String> _categories = ['All', 'Lawyers', 'Notary Publics', 'Legal Aid'];

  // Realistic high-fidelity Pakistani legal listings
  final List<Map<String, dynamic>> _directoryListings = [
    // Karachi
    {
      'name': 'Adv. Rao M. Mairaj',
      'category': 'Lawyers',
      'city': 'Karachi',
      'specialization': 'Criminal & Corporate Law',
      'experience': '14 Years',
      'rating': 4.9,
      'reviews': 124,
      'office': 'Suite 402, Landmark Plaza, I.I. Chundrigar Road, Karachi',
      'phone': '+92-21-32630123',
      'email': 'mairaj.advocate@qanoonbuddy.pk',
      'verified': true,
      'price': 'PKR 3,500 / Consult',
    },
    {
      'name': 'Barrister Ayesha Khan',
      'category': 'Lawyers',
      'city': 'Karachi',
      'specialization': 'Constitutional & Family Disputes',
      'experience': '9 Years',
      'rating': 4.8,
      'reviews': 82,
      'office': '5th Floor, Executive Tower, Dolmen City, Clifton, Karachi',
      'phone': '+92-21-35290987',
      'email': 'ayesha.khan@qanoonbuddy.pk',
      'verified': true,
      'price': 'PKR 5,000 / Consult',
    },
    {
      'name': 'Siddiqui Notary & Attestation Center',
      'category': 'Notary Publics',
      'city': 'Karachi',
      'specialization': 'Affidavits, Power of Attorney & Document Verification',
      'experience': '22 Years',
      'rating': 4.7,
      'reviews': 210,
      'office': 'Shop 14, Civic Center, Gulshan-e-Iqbal, Karachi',
      'phone': '+92-21-34987654',
      'email': 'siddiqui.notary@gmail.com',
      'verified': true,
      'price': 'PKR 500 / Document',
    },
    {
      'name': 'Karachi Legal Aid Clinic (KLAC)',
      'category': 'Legal Aid',
      'city': 'Karachi',
      'specialization': 'Pro-Bono Services & Human Rights Advocacy',
      'experience': '15 Years',
      'rating': 4.9,
      'reviews': 345,
      'office': 'House 43/B, Block 6, PECHS, Karachi',
      'phone': '+92-21-34538910',
      'email': 'info@klac.org.pk',
      'verified': true,
      'price': 'Free / Pro-Bono',
    },

    // Lahore
    {
      'name': 'Adv. Umer Ali Khan Lodhi',
      'category': 'Lawyers',
      'city': 'Lahore',
      'specialization': 'Taxation, Real Estate & Property Disputes',
      'experience': '12 Years',
      'rating': 4.9,
      'reviews': 96,
      'office': 'Office 9, High Court Arcade, Dev Samaj Road, Lahore',
      'phone': '+92-42-37210987',
      'email': 'umer.lodhi@qanoonbuddy.pk',
      'verified': true,
      'price': 'PKR 4,000 / Consult',
    },
    {
      'name': 'Barrister Mustafa Rehman',
      'category': 'Lawyers',
      'city': 'Lahore',
      'specialization': 'Civil Litigation & Intellectual Property',
      'experience': '8 Years',
      'rating': 4.7,
      'reviews': 54,
      'office': 'Suite 104, Landmark Tower, Jail Road, Gulberg, Lahore',
      'phone': '+92-42-35789123',
      'email': 'mustafa.rehman@qanoonbuddy.pk',
      'verified': false,
      'price': 'PKR 4,500 / Consult',
    },
    {
      'name': 'Lahore Notary Registry & Oath Commissioner',
      'category': 'Notary Publics',
      'city': 'Lahore',
      'specialization': 'Registry Attestations & Rent Agreements',
      'experience': '18 Years',
      'rating': 4.6,
      'reviews': 143,
      'office': 'District Courts complex, Lower Mall, Lahore',
      'phone': '+92-300-8456721',
      'email': 'lhr.notary@gmail.com',
      'verified': true,
      'price': 'PKR 600 / Document',
    },
    {
      'name': 'Punjab Women Legal Helpdesk',
      'category': 'Legal Aid',
      'city': 'Lahore',
      'specialization': 'Free Legal Aid for Domestic & Custody Cases',
      'experience': '10 Years',
      'rating': 4.8,
      'reviews': 189,
      'office': 'LDA Plaza, Egerton Road, Lahore',
      'phone': '+92-42-99201234',
      'email': 'pwlh@punjab.gov.pk',
      'verified': true,
      'price': 'Free / Pro-Bono',
    },

    // Islamabad
    {
      'name': 'Adv. Zainab Chaudhry',
      'category': 'Lawyers',
      'city': 'Islamabad',
      'specialization': 'Supreme Court Litigation & Banking Laws',
      'experience': '20 Years',
      'rating': 5.0,
      'reviews': 167,
      'office': 'Chamber 12, Supreme Court Chambers Building, G-5, Islamabad',
      'phone': '+92-51-2276543',
      'email': 'zainab.c@qanoonbuddy.pk',
      'verified': true,
      'price': 'PKR 8,000 / Consult',
    },
    {
      'name': 'Barrister Saad Murtaza',
      'category': 'Lawyers',
      'city': 'Islamabad',
      'specialization': 'International Law & Arbitration',
      'experience': '10 Years',
      'rating': 4.8,
      'reviews': 63,
      'office': 'Block 4, G-8 Markaz, Islamabad',
      'phone': '+92-51-2287654',
      'email': 'saad.murtaza@qanoonbuddy.pk',
      'verified': true,
      'price': 'PKR 6,000 / Consult',
    },
    {
      'name': 'Capital Oath Commissioner & Notary public',
      'category': 'Notary Publics',
      'city': 'Islamabad',
      'specialization': 'Affidavits & Visa Document Attestations',
      'experience': '15 Years',
      'rating': 4.8,
      'reviews': 112,
      'office': 'F-8 Markaz Court Premises, Islamabad',
      'phone': '+92-51-2259876',
      'email': 'capital.attestation@outlook.com',
      'verified': true,
      'price': 'PKR 800 / Document',
    },
    {
      'name': 'Islamabad Legal Aid & Advice Center',
      'category': 'Legal Aid',
      'city': 'Islamabad',
      'specialization': 'Civil Rights & Pro-Bono Counsel Service',
      'experience': '11 Years',
      'rating': 4.9,
      'reviews': 156,
      'office': 'Sector I-10/2, Islamabad',
      'phone': '+92-51-4432109',
      'email': 'ilaac@isb.org.pk',
      'verified': true,
      'price': 'Free / Pro-Bono',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Filter listings based on selected City, Category, and Search query
    final filteredListings = _directoryListings.where((item) {
      final matchesCity = item['city'] == _selectedCity;
      final matchesCategory = _selectedCategory == 'All' || item['category'] == _selectedCategory;
      final matchesSearch = item['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['specialization'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['office'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCity && matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.folder_shared_rounded, color: AppTheme.goldPremium, size: 24),
            SizedBox(width: 10),
            Text(
              'Legal Directory',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.navyDeep, AppTheme.navyLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 🌆 City Selector Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: AppTheme.navyDeep,
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: AppTheme.goldPremium, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Select City:',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _cities.map((city) {
                        final active = _selectedCity == city;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setState(() => _selectedCity = city),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: active ? AppTheme.goldPremium : Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: active ? AppTheme.goldPremium : Colors.white24,
                                ),
                              ),
                              child: Text(
                                city,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🔍 Search Bar & Category Filters
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Column(
              children: [
                // Search Input Field
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search by name, specialization, or office...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.goldPremium),
                    filled: true,
                    fillColor: AppTheme.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final active = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedCategory = cat),
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: active ? AppTheme.navyDeep : AppTheme.surface,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: active ? AppTheme.navyDeep : AppTheme.border,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: active ? Colors.white : AppTheme.textGrey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // 📄 Listings List View
          Expanded(
            child: filteredListings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: AppTheme.textGrey.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text(
                          'No listings found',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try searching for something else in $_selectedCity',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredListings.length,
                    itemBuilder: (context, index) {
                      final item = filteredListings[index];
                      final categoryColor = item['category'] == 'Lawyers'
                          ? AppTheme.navyDeep
                          : item['category'] == 'Notary Publics'
                              ? AppTheme.goldMuted
                              : Colors.teal;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Category tag, verified badge, rating
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: categoryColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      item['category'].toString().toUpperCase(),
                                      style: TextStyle(
                                        color: categoryColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (item['verified'])
                                    const Row(
                                      children: [
                                        Icon(Icons.verified_rounded, color: Colors.blueAccent, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          'Verified Office',
                                          style: TextStyle(
                                            color: Colors.blueAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  const Spacer(),
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    item['rating'].toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  Text(
                                    ' (${item['reviews']})',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textGrey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Name & Specialty
                              Text(
                                item['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: AppTheme.textDark,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['specialization'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.navyDeep,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Experience & Office Address
                              Row(
                                children: [
                                  const Icon(Icons.business_center_rounded, color: AppTheme.textGrey, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Exp: ${item['experience']}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textGrey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.payments_rounded, color: AppTheme.textGrey, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    item['price'],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.goldMuted,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.pin_drop_rounded, color: AppTheme.textGrey, size: 14),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item['office'],
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textGrey,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(height: 1, color: AppTheme.border),
                              const SizedBox(height: 16),

                              // Actions Row: Call, Secure Email, Book Appointment
                              Row(
                                children: [
                                  if (item['category'] == 'Lawyers') ...[
                                    // Compact Call Button
                                    SizedBox(
                                      width: 46,
                                      height: 42,
                                      child: OutlinedButton(
                                        onPressed: () => _makePhoneCall(item['phone']),
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          side: const BorderSide(color: AppTheme.border),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Icon(Icons.phone_rounded, size: 18, color: AppTheme.navyDeep),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Compact Email/Mail Button
                                    SizedBox(
                                      width: 46,
                                      height: 42,
                                      child: OutlinedButton(
                                        onPressed: () => _sendEmail(item['email'], item['name']),
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          side: const BorderSide(color: AppTheme.border),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Icon(Icons.email_outlined, size: 18, color: AppTheme.navyDeep),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Primary Booking CTA
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          context.push('/form-booking', extra: item['name']);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(0, 42),
                                          backgroundColor: AppTheme.goldPremium,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 0,
                                        ),
                                        icon: const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.white),
                                        label: const Text(
                                          'Book Office',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    // 2 columns: Call Office & Secure Mail
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _makePhoneCall(item['phone']),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(0, 42),
                                          side: const BorderSide(color: AppTheme.border),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        icon: const Icon(Icons.phone_rounded, size: 16, color: AppTheme.navyDeep),
                                        label: const Text(
                                          'Call Office',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.navyDeep,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _sendEmail(item['email'], item['name']),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(0, 42),
                                          side: const BorderSide(color: AppTheme.border),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        icon: const Icon(Icons.email_outlined, size: 16, color: AppTheme.navyDeep),
                                        label: const Text(
                                          'Secure Mail',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.navyDeep,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ).animate().fade(delay: (index * 50).ms).slideY(begin: 0.05);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Helper method to make phone call
  void _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll('-', '').replaceAll(' ', '');
    final Uri callUri = Uri(scheme: 'tel', path: cleanPhone);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not trigger call dialer for $phoneNumber')),
        );
      }
    }
  }

  // Helper method to send email
  void _sendEmail(String email, String name) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Legal Inquiry via Qanoon Buddy',
        'body': 'Dear $name,\n\nI am contacting you through the Qanoon Buddy app to request a legal consultation regarding...',
      },
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not trigger mail client for $email')),
        );
      }
    }
  }
}
