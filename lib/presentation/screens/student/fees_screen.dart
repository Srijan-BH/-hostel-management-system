import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_management_system/services/auth_service.dart';
import 'package:hostel_management_system/services/data_service.dart';
import 'package:hostel_management_system/models/fee_model.dart';
import 'package:intl/intl.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  late Future<List<FeeModel>> _feesFuture;

  @override
  void initState() {
    super.initState();
    _loadFees();
  }

  void _loadFees() {
    final studentId = context.read<AuthService>().currentUser!.id;
    _feesFuture = context.read<DataService>().fetchStudentFees(studentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fee Details'), automaticallyImplyLeading: false),
      body: FutureBuilder<List<FeeModel>>(
        future: _feesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final fees = snapshot.data ?? [];
          
          if (fees.isEmpty) {
            return const Center(child: Text('No fee records found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: fees.length,
            itemBuilder: (context, index) {
              final fee = fees[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(fee.description, style: Theme.of(context).textTheme.titleLarge),
                          _buildStatusChip(fee.status),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount:'),
                          Text('₹${fee.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Paid Amount:'),
                          Text('₹${fee.paidAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Remaining:'),
                          Text('₹${fee.remainingAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Due Date: ${DateFormat('MMM dd, yyyy').format(fee.dueDate)}', style: const TextStyle(fontStyle: FontStyle.italic)),
                      if (fee.remainingAmount > 0)
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: () => _showPaymentBottomSheet(context, fee),
                            child: const Text('Pay Now'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(FeeStatus status) {
    Color color;
    switch (status) {
      case FeeStatus.paid: color = Colors.green; break;
      case FeeStatus.partiallyPaid: color = Colors.blue; break;
      case FeeStatus.pending: color = Colors.orange; break;
      case FeeStatus.overdue: color = Colors.red; break;
    }
    return Chip(
      label: Text(status.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
    );
  }

  void _showPaymentBottomSheet(BuildContext context, FeeModel fee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _PaymentBottomSheet(
          fee: fee, 
          onPaymentComplete: () {
            _loadFees();
            setState(() {});
          }
        );
      },
    );
  }
}

class _PaymentBottomSheet extends StatefulWidget {
  final FeeModel fee;
  final VoidCallback onPaymentComplete;

  const _PaymentBottomSheet({required this.fee, required this.onPaymentComplete});

  @override
  State<_PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<_PaymentBottomSheet> {
  String? _selectedMethod;
  bool _isProcessing = false;
  bool _isSuccess = false;

  void _processPayment() async {
    if (_selectedMethod == null) return;
    
    setState(() {
      _isProcessing = true;
    });

    final success = await context.read<DataService>().processFeePayment(widget.fee.id, widget.fee.remainingAmount);

    if (mounted && success) {
      setState(() {
        _isProcessing = false;
        _isSuccess = true;
      });
      
      // Wait to show success animation then close
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
        widget.onPaymentComplete();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Successful!')));
      }
    } else if (mounted) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Failed. Try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 80),
              SizedBox(height: 16),
              Text('Payment Successful', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    if (_isProcessing) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text('Processing $_selectedMethod Payment...', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              const Text('Please do not close this window.', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Checkout', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Pay ₹${widget.fee.remainingAmount.toStringAsFixed(2)} for ${widget.fee.description}'),
          const SizedBox(height: 24),
          const Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildMethodTile('UPI', Icons.qr_code),
          _buildMethodTile('Credit/Debit Card', Icons.credit_card),
          _buildMethodTile('Net Banking', Icons.account_balance),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _selectedMethod == null ? null : _processPayment,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text('Proceed to Pay', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMethodTile(String method, IconData icon) {
    final isSelected = _selectedMethod == method;
    return Card(
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey),
        title: Text(method, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
        onTap: () {
          setState(() {
            _selectedMethod = method;
          });
        },
      ),
    );
  }
}
