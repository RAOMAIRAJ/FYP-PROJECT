import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api_service.dart';

class LegalMarketplaceScreen extends StatefulWidget {
  const LegalMarketplaceScreen({Key? key}) : super(key: key);

  @override
  State<LegalMarketplaceScreen> createState() => _LegalMarketplaceScreenState();
}

class _LegalMarketplaceScreenState extends State<LegalMarketplaceScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _myServices = [];
  List<dynamic> _myOrders = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw Exception("Unauthorized");

      final services = await _apiService.getMyServices(token);
      final orders = await _apiService.getMyOrders(token);

      setState(() {
        _myServices = services;
        _myOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load marketplace data: $e')),
        );
      }
    }
  }

  Future<void> _toggleService(String serviceId, bool newValue) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw Exception("Unauthorized");
      await _apiService.toggleService(serviceId, token);
      _fetchData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw Exception("Unauthorized");
      await _apiService.updateOrderStatus(orderId, "accepted", token);
      _fetchData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _showCreateServiceDialog() async {
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _descController = TextEditingController();
    final TextEditingController _priceController = TextEditingController();
    final TextEditingController _daysController = TextEditingController();
    String _category = "consultation";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New Service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 12),
                TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                const SizedBox(height: 12),
                TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price (Rs.)'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: _daysController, decoration: const InputDecoration(labelText: 'Delivery Days'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _category,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: "consultation", child: Text("Consultation")),
                    DropdownMenuItem(value: "drafting", child: Text("Drafting")),
                    DropdownMenuItem(value: "review", child: Text("Review")),
                    DropdownMenuItem(value: "representation", child: Text("Representation")),
                  ],
                  onChanged: (v) => setDialogState(() => _category = v!),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isEmpty || _priceController.text.isEmpty) return;
                Navigator.pop(context);
                try {
                  const storage = FlutterSecureStorage();
                  final token = await storage.read(key: 'auth_token');
                  if (token == null) throw Exception("Unauthorized");
                  await _apiService.createService(
                    title: _titleController.text,
                    description: _descController.text,
                    category: _category,
                    price: double.parse(_priceController.text),
                    deliveryDays: int.parse(_daysController.text),
                    token: token,
                  );
                  _fetchData();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service created successfully')));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Legal Marketplace'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'My Services'),
              Tab(text: 'Orders'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _myServices.isEmpty
                      ? const Center(child: Text("No services found."))
                      : ListView.builder(
                          itemCount: _myServices.length,
                          itemBuilder: (context, index) {
                            final service = _myServices[index];
                            return Card(
                              margin: const EdgeInsets.all(8),
                              child: ListTile(
                                title: Text(service['title'] ?? 'Service'),
                                subtitle: Text('Rs. ${service['price']} • ${service['delivery_days']} Days Delivery'),
                                trailing: Switch(
                                  value: service['is_active'] ?? false,
                                  onChanged: (v) => _toggleService(service['id'], v),
                                ),
                              ),
                            );
                          },
                        ),
                  _myOrders.isEmpty
                      ? const Center(child: Text("No orders found."))
                      : ListView.builder(
                          itemCount: _myOrders.length,
                          itemBuilder: (context, index) {
                            final order = _myOrders[index];
                            return Card(
                              margin: const EdgeInsets.all(8),
                              child: ListTile(
                                title: Text('Order #${order['order']['id'].toString().length > 8 ? order['order']['id'].toString().substring(0, 8) : order['order']['id'].toString()}'),
                                subtitle: Text('Status: ${order['order']['status']}'),
                                trailing: order['order']['status'] == 'pending'
                                    ? ElevatedButton(
                                        onPressed: () => _acceptOrder(order['order']['id']),
                                        child: const Text('Accept'),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateServiceDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
