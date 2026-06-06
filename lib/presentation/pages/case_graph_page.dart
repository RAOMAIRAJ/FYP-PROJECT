import 'dart:math';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';

class CaseGraphPage extends ConsumerStatefulWidget {
  const CaseGraphPage({super.key});

  @override
  ConsumerState<CaseGraphPage> createState() => _CaseGraphPageState();
}

class _CaseGraphPageState extends ConsumerState<CaseGraphPage> {
  final Graph graph = Graph()..isTree = false;
  final FruchtermanReingoldAlgorithm algorithm = FruchtermanReingoldAlgorithm(FruchtermanReingoldConfiguration());

  @override
  void initState() {
    super.initState();
    _setupGraph();
  }

  void _setupGraph() {
    final user = ref.read(authProvider).user;
    final userName = user?['full_name'] ?? 'Guest User';

    // ── Nodes ─────────────────────────────────────────────────
    final nodeCase = Node.Id('Property Dispute #821 (Template)');
    final nodeUser = Node.Id('$userName (Client)');
    final nodeEvidence1Header = Node.Id('Sale Deed (2022) [SAMPLE]');
    final nodeEvidence2Header = Node.Id('Fard Identity [SAMPLE]');
    final nodeLawyer = Node.Id('Lead Forensic Consultant (Expert)');
    final nodeRisk = Node.Id('RISK: Adverse Possession (Warning)');

    // ── Edges ─────────────────────────────────────────────────
    graph.addEdge(nodeUser, nodeCase);
    graph.addEdge(nodeCase, nodeLawyer);
    graph.addEdge(nodeCase, nodeEvidence1Header);
    graph.addEdge(nodeCase, nodeEvidence2Header);
    graph.addEdge(nodeCase, nodeRisk);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Digital Legal Relationship Map"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(100),
        minScale: 0.1,
        maxScale: 2.0,
        child: GraphView(
          graph: graph,
          algorithm: algorithm,
          paint: Paint()
            ..color = Colors.blueAccent.withOpacity(0.5)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
          builder: (Node node) {
            var value = node.key!.value as String;
            return _buildNodeWidget(value);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text("EXPORT AS EVIDENCE MAP"),
        icon: const Icon(Icons.share),
        backgroundColor: Colors.blueAccent,
      ).animate().slideY(begin: 1.0, end: 0.0),
    );
  }

  Widget _buildNodeWidget(String value) {
    bool isRisk = value.contains("RISK");
    bool isCase = value.contains("Dispute");
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isRisk ? Colors.redAccent.withOpacity(0.2) : (isCase ? Colors.blueAccent.withOpacity(0.2) : Colors.white10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRisk ? Colors.redAccent : (isCase ? Colors.blueAccent : Colors.white24),
          width: 2,
        ),
        boxShadow: [
          if (isCase || isRisk)
            BoxShadow(
              color: (isCase ? Colors.blueAccent : Colors.redAccent).withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRisk ? Icons.warning : (isCase ? Icons.gavel : Icons.person),
            color: isRisk ? Colors.redAccent : (isCase ? Colors.blueAccent : Colors.white70),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: (isCase || isRisk) ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
