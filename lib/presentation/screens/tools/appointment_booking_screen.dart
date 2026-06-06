import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qanoon_buddy/core/theme.dart';

class AppointmentBookingScreen extends StatefulWidget {
  final String? initialLawyerName;
  const AppointmentBookingScreen({super.key, this.initialLawyerName});

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  late String _selectedLawyer;
  final List<String> _lawyers = [
    'Adv. Sarah Mansoor (Family & Civil Law)',
    'Adv. Zain-ul-Abideen (Corporate & Property)',
    'Adv. Muhammad Hamza (Criminal & Bail)',
    'Adv. Ayesha Siddiqua (Labor & Employment)',
  ];

  final _userNameController = TextEditingController();
  final _userPhoneController = TextEditingController();
  final _issueController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '10:00 AM';

  final List<String> _timeSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:30 AM',
    '02:00 PM',
    '03:30 PM',
    '05:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-populate if lawyer arguments are passed
    if (widget.initialLawyerName != null && _lawyers.contains(widget.initialLawyerName)) {
      _selectedLawyer = widget.initialLawyerName!;
    } else {
      _selectedLawyer = _lawyers.first;
    }
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _userPhoneController.dispose();
    _issueController.dispose();
    super.dispose();
  }

  Future<void> _launchWhatsAppBooking() async {
    final name = _userNameController.text.trim();
    final phone = _userPhoneController.text.trim();
    final issue = _issueController.text.trim();

    if (name.isEmpty || phone.isEmpty || issue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all form inputs first.')),
      );
      return;
    }

    final formattedDate = DateFormat('EEEE, MMMM dd').format(_selectedDate);

    // Beautifully formatted pre-filled WhatsApp message
    final rawMessage = 'Assalam-o-Alaikum,\n\n'
        'I would like to book a legal consultation session with $_selectedLawyer.\n\n'
        '🗓 *Requested Date:* $formattedDate\n'
        '⏰ *Preferred Slot:* $_selectedTimeSlot\n'
        '👤 *Client Name:* $name\n'
        '📞 *Client Contact:* $phone\n'
        '⚖️ *Legal Issue Details:* $issue\n\n'
        'Please confirm if this slot is available or suggest an alternative. Thank you!';

    final encodedMessage = Uri.encodeComponent(rawMessage);
    // Standard mock WhatsApp dispatch redirecting directly to lawyer support desk
    final whatsappUrl = 'https://wa.me/923001234567?text=$encodedMessage';
    final uri = Uri.parse(whatsappUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not trigger WhatsApp application.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Book Appointment', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selection info
              const Text(
                'Select Legal Advisor',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textGrey),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLawyer,
                    isExpanded: true,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 14),
                    items: _lawyers.map((String val) {
                      return DropdownMenuItem<String>(value: val, child: Text(val));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLawyer = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Calendar Horizontal Slider
              const Text(
                'Choose Consult Date',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textGrey),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 85,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 14, // Next 2 weeks
                  itemBuilder: (context, index) {
                    final day = DateTime.now().add(Duration(days: index + 1));
                    final isSelected = day.day == _selectedDate.day && day.month == _selectedDate.month;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: InkWell(
                        onTap: () => setState(() => _selectedDate = day),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 65,
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.navyDeep : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? AppTheme.navyDeep : AppTheme.border),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('E').format(day).toUpperCase(),
                                style: TextStyle(
                                  color: isSelected ? Colors.white.withOpacity(0.6) : AppTheme.textGrey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                day.day.toString(),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppTheme.textDark,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
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
              const SizedBox(height: 20),

              // Time slot grids
              const Text(
                'Select Time Slot',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textGrey),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.2,
                ),
                itemCount: _timeSlots.length,
                itemBuilder: (context, index) {
                  final slot = _timeSlots[index];
                  final isSelected = _selectedTimeSlot == slot;
                  return InkWell(
                    onTap: () => setState(() => _selectedTimeSlot = slot),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.goldPremium : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppTheme.goldPremium : AppTheme.border),
                      ),
                      child: Text(
                        slot,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Personal info inputs
              const Text(
                'Your Details',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.navyDeep),
              ),
              const SizedBox(height: 16),
              _buildField(_userNameController, 'Your Full Name', 'Enter your name', Icons.person),
              const SizedBox(height: 14),
              _buildField(_userPhoneController, 'Contact Number', 'e.g. +92 300 1234567', Icons.phone),
              const SizedBox(height: 14),
              _buildField(_issueController, 'Consultation Statement', 'Briefly describe your legal dispute or agreement request...', Icons.notes, maxLines: 4),

              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _launchWhatsAppBooking,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Book via WhatsApp', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.navyDeep,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, String hint, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textGrey),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppTheme.textGrey.withOpacity(0.5)),
            prefixIcon: Icon(icon, color: AppTheme.goldPremium, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
