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
      await _apiService.toggleService(serviceId, token!);
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      await _apiService.updateOrderStatus(orderId, "accepted", token!);
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Legal Marketplace'),
          bottom: const TabBar(
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
                                title: Text('Order #${order['id'].toString().substring(0, 8)}'),
                                subtitle: Text('Status: ${order['status']}'),
                                trailing: order['status'] == 'pending'
                                    ? ElevatedButton(
                                        onPressed: () => _acceptOrder(order['id']),
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
          onPressed: () {
            // TODO: Implement Create Service dialog
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Coming Soon: Create Service")));
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
