import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ChallanVerificationScreen extends StatefulWidget {
  const ChallanVerificationScreen({super.key});

  @override
  State<ChallanVerificationScreen> createState() => _ChallanVerificationScreenState();
}

class _ChallanVerificationScreenState extends State<ChallanVerificationScreen> {
  final _plateController = TextEditingController();
  final _cnicController = TextEditingController();
  String _selectedProvince = 'Punjab';
  String _selectedVerificationType = 'Vehicle MTMIS'; // Vehicle MTMIS or Traffic Challan

  @override
  void dispose() {
    _plateController.dispose();
    _cnicController.dispose();
    super.dispose();
  }

  Future<void> _launchVerificationPortal() async {
    final plate = _plateController.text.trim();
    final cnic = _cnicController.text.trim();

    String urlString = '';

    if (_selectedVerificationType == 'Vehicle MTMIS') {
      switch (_selectedProvince) {
        case 'Punjab':
          // Punjab MTMIS Excise Portal
          urlString = 'https://mtmis.excise.punjab.gov.pk/';
          break;
        case 'Sindh':
          // Sindh Excise Online Verification
          urlString = 'https://excise.gos.pk/vehicle/vehicle_search';
          break;
        case 'KPK':
          // KPK Excise Portal
          urlString = 'https://www.kpexcise.gov.pk/app/';
          break;
        case 'Islamabad':
          // Islamabad MTMIS Excise Portal
          urlString = 'http://islamabadexcise.gov.pk/';
          break;
      }
    } else {
      // Traffic Challan Verification
      switch (_selectedProvince) {
        case 'Punjab':
          // Punjab Traffic Police E-Challan Portal
          urlString = 'https://echallan.psca.gop.pk/';
          break;
        case 'Sindh':
          urlString = 'https://tracs.sindhpolice.gov.pk/check-challan/';
          break;
        case 'Islamabad':
          urlString = 'https://islamabadpolice.gov.pk/echallan/';
          break;
        default:
          urlString = 'https://echallan.psca.gop.pk/';
      }
    }

    final Uri uri = Uri.parse(urlString);
    try {
      final bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch verification portal: $urlString'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Excise & Challan Portal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            
            // Selector for Verification Type
            Row(
              children: [
                Expanded(
                  child: _buildSelectorCard(
                    title: 'Vehicle MTMIS',
                    icon: Icons.directions_car_rounded,
                    isSelected: _selectedVerificationType == 'Vehicle MTMIS',
                    onTap: () => setState(() => _selectedVerificationType = 'Vehicle MTMIS'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSelectorCard(
                    title: 'Traffic Challan',
                    icon: Icons.receipt_long_rounded,
                    isSelected: _selectedVerificationType == 'Traffic Challan',
                    onTap: () => setState(() => _selectedVerificationType = 'Traffic Challan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Region / Province', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textGrey)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedProvince,
                        isExpanded: true,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        items: ['Punjab', 'Sindh', 'KPK', 'Islamabad'].map((prov) {
                          return DropdownMenuItem<String>(value: prov, child: Text(prov));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedProvince = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_selectedVerificationType == 'Vehicle MTMIS') ...[
                    const Text('Vehicle License Plate Number', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textGrey)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _plateController,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      decoration: InputDecoration(
                        hintText: 'e.g. LEV-15-4320 or LEA-1234',
                        prefixIcon: const Icon(Icons.tag_rounded, color: AppTheme.goldPremium),
                        filled: true,
                        fillColor: AppTheme.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ] else ...[
                    const Text('Bike Number Plate / Challan ID (Required)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textGrey)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _cnicController,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        hintText: 'e.g. KHS-7098 or 12345',
                        prefixIcon: const Icon(Icons.motorcycle_rounded, color: AppTheme.goldPremium),
                        filled: true,
                        fillColor: AppTheme.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  if (_selectedVerificationType == 'Vehicle MTMIS') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _launchVerificationPortal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.navyDeep,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.open_in_new_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Verify Registration Online',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Double buttons for E-Challan (Real vs Simulator)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _launchVerificationPortal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.goldPremium,
                          foregroundColor: AppTheme.textDark,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.open_in_new_rounded, size: 18, color: AppTheme.textDark),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Launch Official Police Portal',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.textDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Instructions / Guidelines Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.navyDeep.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppTheme.goldPremium, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'VERIFICATION GUIDELINES',
                        style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.navyDeep.withOpacity(0.9), fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildGuidelineRow('1', 'Enter license plate format exactly as stamped on your physical sheet.'),
                  _buildGuidelineRow('2', 'Online records depend on provincial Excise & Taxation database sync schedules.'),
                  _buildGuidelineRow('3', 'E-Challan portal uses safe SSL-encrypted redirection for public peace of mind.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.navyDeep,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REGISTRATION & CHALLAN HUB',
            style: TextStyle(color: AppTheme.goldPremium, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Access official Excise & Taxation and Traffic Police databases securely. No account credentials required to search public directory listings.',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, height: 1.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ).animate().fade().slideY(begin: 0.05);
  }

  Widget _buildSelectorCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.navyDeep : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.navyDeep : AppTheme.border),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.navyDeep.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.goldPremium : AppTheme.navyDeep,
              size: 28,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppTheme.textDark,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineRow(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.navyDeep,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: AppTheme.textGrey, height: 1.4, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
