import 'package:flutter/material.dart';

class DigitalLegalChamberScreen extends StatefulWidget {
  const DigitalLegalChamberScreen({Key? key}) : super(key: key);

  @override
  State<DigitalLegalChamberScreen> createState() => _DigitalLegalChamberScreenState();
}

class _DigitalLegalChamberScreenState extends State<DigitalLegalChamberScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Legal Chamber'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
            child: const Text('IN SESSION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ListTile(
              title: Text('Client: John Doe'),
              subtitle: Text('Case: Property Dispute'),
              trailing: Text('00:15:23'),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.videocam, size: 32, color: Colors.blue)),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.call, size: 32, color: Colors.green)),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.message, size: 32, color: Colors.orange)),
                ],
              ),
            ),
            const Divider(),
            const ListTile(title: Text('Document Workspace', style: TextStyle(fontWeight: FontWeight.bold))),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 2,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: Text('Document_${index + 1}.pdf'),
                  trailing: const Icon(Icons.download),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Document'),
              ),
            ),
            const Divider(),
            const ListTile(title: Text('Private Notes', style: TextStyle(fontWeight: FontWeight.bold))),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: TextField(
                maxLines: 5,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Type your session notes here...',
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {},
            child: const Text('End Session & Generate Report', style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
