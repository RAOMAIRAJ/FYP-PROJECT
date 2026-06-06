import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:qanoon_buddy/core/theme.dart';

class StampDutyCalculatorScreen extends StatefulWidget {
  const StampDutyCalculatorScreen({super.key});

  @override
  State<StampDutyCalculatorScreen> createState() => _StampDutyCalculatorScreenState();
}

class _StampDutyCalculatorScreenState extends State<StampDutyCalculatorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1: Stamp Duty State
  String _stampDeedType = 'Sale Deed';
  final _stampPropertyValueController = TextEditingController();
  double _calculatedStampDuty = 0;
  double _calculatedLocalTax = 0;
  double _calculatedFbrTax = 0;
  double _calculatedTotalStampDues = 0;
  bool _showStampResults = false;

  // Tab 2: Property Tax State
  String _propertyType = 'Residential';
  String _propertyCity = 'Lahore';
  final _propertyAreaController = TextEditingController();
  final _propertyRentalController = TextEditingController();
  double _calculatedPropertyTax = 0;
  bool _showPropertyResults = false;

  // Tab 3: Court Fee State
  final _courtSuitValueController = TextEditingController();
  double _calculatedCourtFee = 0;
  bool _showCourtResults = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _stampPropertyValueController.dispose();
    _propertyAreaController.dispose();
    _propertyRentalController.dispose();
    _courtSuitValueController.dispose();
    super.dispose();
  }

  void _calculateStampDutyFee() {
    final value = double.tryParse(_stampPropertyValueController.text.trim()) ?? 0;
    if (value <= 0) return;

    // Formulas representing Pakistani provincial legal rates
    double dutyRate = 0.03; // Default 3%
    double localRate = 0.01; // 1% local council tax
    double fbrRate = 0.02; // 2% for active taxpayers, simulated base rate

    if (_stampDeedType == 'Gift Deed') {
      dutyRate = 0.02;
    } else if (_stampDeedType == 'Power of Attorney') {
      dutyRate = 0.005; // fixed low rates generally, but simulated as percentage for simplicity
    } else if (_stampDeedType == 'Lease Agreement') {
      dutyRate = 0.015;
    }

    setState(() {
      _calculatedStampDuty = value * dutyRate;
      _calculatedLocalTax = value * localRate;
      _calculatedFbrTax = value * fbrRate;
      _calculatedTotalStampDues = _calculatedStampDuty + _calculatedLocalTax + _calculatedFbrTax;
      _showStampResults = true;
    });
  }

  void _calculatePropertyTaxFee() {
    final area = double.tryParse(_propertyAreaController.text.trim()) ?? 0;
    final rental = double.tryParse(_propertyRentalController.text.trim()) ?? 0;

    if (area <= 0 && rental <= 0) return;

    // Simulated regional tax calculation formulas
    double baseRate = _propertyType == 'Commercial' ? 150 : 50; // PKR per Marla/SqFt
    double cityMultiplier = 1.0;
    if (_propertyCity == 'Lahore') cityMultiplier = 1.2;
    if (_propertyCity == 'Islamabad') cityMultiplier = 1.3;
    if (_propertyCity == 'Karachi') cityMultiplier = 1.1;

    double tax = 0;
    if (rental > 0) {
      // Annual Rental Value (ARV) method
      tax = rental * 12 * 0.10 * cityMultiplier; // 10% of annual value
    } else {
      // Size base method
      tax = area * baseRate * cityMultiplier;
    }

    setState(() {
      _calculatedPropertyTax = tax;
      _showPropertyResults = true;
    });
  }

  void _calculateCourtFeeAmount() {
    final value = double.tryParse(_courtSuitValueController.text.trim()) ?? 0;
    if (value <= 0) return;

    // Court Fee Act: 7.5% of value up to a maximum cap of PKR 15,000
    double fee = value * 0.075;
    if (fee > 15000) {
      fee = 15000;
    }

    setState(() {
      _calculatedCourtFee = fee;
      _showCourtResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Stamp & Fee Calculator', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.navyDeep, AppTheme.navyLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.goldPremium,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          indicatorColor: AppTheme.goldPremium,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Stamp Duty'),
            Tab(text: 'Property Tax'),
            Tab(text: 'Court Fee'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStampDutyTab(),
          _buildPropertyTaxTab(),
          _buildCourtFeeTab(),
        ],
      ),
    );
  }

  Widget _buildStampDutyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Stamp Duty Calculator', 'Estimate official provincial stamp values, registration fees, and local council taxes for real estate deeds & legal agreements.'),
          const SizedBox(height: 24),

          // Inputs
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Deed Category', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textGrey)),
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
                      value: _stampDeedType,
                      isExpanded: true,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      items: ['Sale Deed', 'Gift Deed', 'Power of Attorney', 'Lease Agreement'].map((type) {
                        return DropdownMenuItem<String>(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _stampDeedType = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text('Property/Deed Declared Value (PKR)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textGrey)),
                const SizedBox(height: 8),
                TextField(
                  controller: _stampPropertyValueController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  decoration: InputDecoration(
                    hintText: 'e.g. 5,000,000',
                    prefixIcon: const Icon(Icons.monetization_on_rounded, color: AppTheme.goldPremium),
                    filled: true,
                    fillColor: AppTheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _calculateStampDutyFee,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.navyDeep,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Calculate Taxes & Dues', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),

          if (_showStampResults) ...[
            const SizedBox(height: 24),
            _buildResultCard([
              _buildResultRow('Stamp Duty Base Rate', 'PKR ${_formatDouble(_calculatedStampDuty)}'),
              _buildResultRow('Local Council Tax', 'PKR ${_formatDouble(_calculatedLocalTax)}'),
              _buildResultRow('Regulatory/FBR Tax', 'PKR ${_formatDouble(_calculatedFbrTax)}'),
              const Divider(color: AppTheme.border, height: 24),
              _buildResultRow('TOTAL ESTIMATED DUES', 'PKR ${_formatDouble(_calculatedTotalStampDues)}', isTotal: true),
            ]).animate().fade().slideY(begin: 0.05),
          ]
        ],
      ),
    );
  }

  Widget _buildPropertyTaxTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Property Tax Estimator', 'Calculate property taxes based on square footage, municipal valuation categories, commercialization multipliers, or rental values.'),
          const SizedBox(height: 24),

          // Inputs
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Property Type', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textGrey)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _propertyType,
                                isExpanded: true,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                items: ['Residential', 'Commercial'].map((type) {
                                  return DropdownMenuItem<String>(value: type, child: Text(type));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _propertyType = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('District/City', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textGrey)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _propertyCity,
                                isExpanded: true,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                items: ['Lahore', 'Islamabad', 'Karachi', 'Peshawar'].map((city) {
                                  return DropdownMenuItem<String>(value: city, child: Text(city));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _propertyCity = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text('Property Area (in Marlas)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textGrey)),
                const SizedBox(height: 8),
                TextField(
                  controller: _propertyAreaController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  decoration: InputDecoration(
                    hintText: 'e.g. 5, 10, 20 Marla',
                    prefixIcon: const Icon(Icons.zoom_out_map_rounded, color: AppTheme.goldPremium),
                    filled: true,
                    fillColor: AppTheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),

                const Text('OR: Expected Monthly Rent (If Rented, PKR)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textGrey)),
                const SizedBox(height: 8),
                TextField(
                  controller: _propertyRentalController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  decoration: InputDecoration(
                    hintText: 'e.g. 50,000 / month',
                    prefixIcon: const Icon(Icons.house_rounded, color: AppTheme.goldPremium),
                    filled: true,
                    fillColor: AppTheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _calculatePropertyTaxFee,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.navyDeep,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Calculate Property Tax', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),

          if (_showPropertyResults) ...[
            const SizedBox(height: 24),
            _buildResultCard([
              _buildResultRow('Calculation System', _propertyRentalController.text.trim().isNotEmpty ? 'Annual Rental Value (ARV) Method' : 'Property Size Valuation'),
              _buildResultRow('Tax District Factor', _propertyCity),
              _buildResultRow('Property Class Factor', _propertyType),
              const Divider(color: AppTheme.border, height: 24),
              _buildResultRow('ANNUAL ESTIMATED PROPERTY TAX', 'PKR ${_formatDouble(_calculatedPropertyTax)}', isTotal: true),
            ]).animate().fade().slideY(begin: 0.05),
          ]
        ],
      ),
    );
  }

  Widget _buildCourtFeeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Court Fee Calculator', 'Compute mandatory legal fees required for civil suits, recovery procedures, and general plaints in corporate or civil courts.'),
          const SizedBox(height: 24),

          // Inputs
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Declared Suit/Claim Valuation (PKR)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textGrey)),
                const SizedBox(height: 8),
                TextField(
                  controller: _courtSuitValueController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  decoration: InputDecoration(
                    hintText: 'e.g. 100,000',
                    prefixIcon: const Icon(Icons.gavel_rounded, color: AppTheme.goldPremium),
                    filled: true,
                    fillColor: AppTheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _calculateCourtFeeAmount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.navyDeep,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Calculate Court Fees', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),

          if (_showCourtResults) ...[
            const SizedBox(height: 24),
            _buildResultCard([
              _buildResultRow('Valuation Method', 'Court Fees Act Schedule (7.5% Base)'),
              _buildResultRow('Subscribed Suit Value', 'PKR ${_formatDouble(double.parse(_courtSuitValueController.text))}'),
              _buildResultRow('Statutory Limit Cap', 'PKR 15,000 (Maximum Cap)'),
              const Divider(color: AppTheme.border, height: 24),
              _buildResultRow('REQUIRED LEGAL COURT FEE', 'PKR ${_formatDouble(_calculatedCourtFee)}', isTotal: true),
            ]).animate().fade().slideY(begin: 0.05),
          ]
        ],
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
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
          Text(
            title.toUpperCase(),
            style: const TextStyle(color: AppTheme.goldPremium, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.border, fontSize: 12, height: 1.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: AppTheme.goldPremium, size: 22),
              const SizedBox(width: 10),
              Text(
                'ESTIMATED CALCULATION SHEET',
                style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.navyDeep.withOpacity(0.9), fontSize: 12, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildResultRow(String title, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold,
              color: isTotal ? AppTheme.navyDeep : AppTheme.textGrey,
              fontSize: isTotal ? 14 : 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w800,
              color: isTotal ? AppTheme.navyDeep : AppTheme.textDark,
              fontSize: isTotal ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDouble(double val) {
    final formatter = NumberFormat('#,###.##');
    return formatter.format(val);
  }
}
