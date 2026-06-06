import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/core/tflite_service.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';

class SignatureVerificationPage extends StatefulWidget {
  const SignatureVerificationPage({super.key});

  @override
  State<SignatureVerificationPage> createState() => _SignatureVerificationPageState();
}

class _SignatureVerificationPageState extends State<SignatureVerificationPage> {
  Uint8List? _image1Bytes;
  Uint8List? _image2Bytes;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _results;

  Future<void> _pickImage(int index) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, // Forces byte loading for web
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        if (index == 1) _image1Bytes = result.files.single.bytes!;
        else _image2Bytes = result.files.single.bytes!;
      });
    }
  }

  Future<void> _startAnalysis() async {
    if (_image1Bytes == null || _image2Bytes == null) return;
    
    setState(() {
      _isAnalyzing = true;
      _results = null;
    });

    // Simulate forensic scan latency
    await Future.delayed(const Duration(seconds: 2));
    
    final results = await tfliteService.compareSignatures(_image1Bytes!, _image2Bytes!);
    
    setState(() {
      _results = results;
      _isAnalyzing = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forensic Signature Matcher"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text(
                "Upload two signatures to calculate the structural similarity score.",
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 500.ms),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded, color: Colors.blueAccent, size: 14),
                    SizedBox(width: 6),
                    Text(
                      "On-Device Forensic Analysis (100% Private)",
                      style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 30),
              
              Row(
                children: [
                  Expanded(child: _buildPicker(1, "Original Scan", _image1Bytes)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildPicker(2, "Test Specimen", _image2Bytes)),
                ],
              ),
              
              const SizedBox(height: 40),
              
              if (_isAnalyzing) ...[
                const CircularProgressIndicator(color: Colors.blueAccent),
                const SizedBox(height: 15),
                const Text("Performing Local Forensic Scan...", style: TextStyle(color: Colors.blueAccent)),
              ] else if (_results != null) ...[
                _buildResultsCard(),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: (_image1Bytes != null && _image2Bytes != null) ? _startAnalysis : null,
                  icon: const Icon(Icons.security),
                  label: const Text("RUN FORENSIC ANALYSIS"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ).animate().scale(),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPicker(int index, String label, Uint8List? image) {
    return HoverButton(
      onTap: () => _pickImage(index),
      child: Column(
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white24),
              image: image != null ? DecorationImage(image: MemoryImage(image), fit: BoxFit.cover) : null,
            ),
            child: image == null ? const Icon(Icons.add_a_photo, color: Colors.white54, size: 40) : null,
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildResultsCard() {
    final similarity = double.tryParse(_results!['similarity'] ?? "0") ?? 0;
    final color = similarity > 80 ? Colors.greenAccent : (similarity > 60 ? Colors.orangeAccent : Colors.redAccent);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            "${_results!['similarity']}%",
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: color),
          ),
          const Text("SIMILARITY SCORE", style: TextStyle(color: Colors.white54, fontSize: 12)),
          const Divider(color: Colors.white12, height: 30),
          Text(
            _results!['verdict'],
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user, color: color, size: 16),
              const SizedBox(width: 5),
              Text(_results!['status'], style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.1, duration: 500.ms).fadeIn();
  }
}
