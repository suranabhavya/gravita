import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/permission_provider.dart';
import '../../services/api_service.dart';
import 'dart:convert';

class PendingApprovalsScreen extends StatefulWidget {
  const PendingApprovalsScreen({Key? key}) : super(key: key);

  @override
  State<PendingApprovalsScreen> createState() => _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState extends State<PendingApprovalsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingListings = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingApprovals();
  }

  Future<void> _loadPendingApprovals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.get(
        '/materials/approvals/pending',
        includeAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _pendingListings = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load pending approvals');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _approveListing(String listingId, double amount) async {
    try {
      final response = await ApiService.post(
        '/materials/listings/$listingId/approve',
        {},
        includeAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPendingApprovals(); // Refresh list
      } else {
        throw Exception('Failed to approve listing');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectListing(String listingId) async {
    final reason = await _showRejectDialog();
    if (reason == null) return;

    try {
      final response = await ApiService.post(
        '/materials/listings/$listingId/reject',
        {'reason': reason},
        includeAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadPendingApprovals(); // Refresh list
      } else {
        throw Exception('Failed to reject listing');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Listing'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Enter reason...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Color _getAmountColor(double amount, double userLimit) {
    if (amount > userLimit) {
      return Colors.red; // Exceeds limit
    } else if (amount > userLimit * 0.8) {
      return Colors.orange; // Close to limit
    } else {
      return Colors.green; // Within limit
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '\$${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final permissionProvider = Provider.of<PermissionProvider>(context);
    final canApprove = permissionProvider.canApproveListings;
    final userLimit = permissionProvider.context?.maxApprovalAmount ?? 0;

    if (!canApprove) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pending Approvals'),
        ),
        body: const Center(
          child: Text('You don\'t have permission to approve listings'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0d2818),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pending Approvals',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadPendingApprovals,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading approvals',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadPendingApprovals,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _pendingListings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: Colors.green, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'All caught up!',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No pending approvals',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Info Banner
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your Approval Limit: ${_formatCurrency(userLimit)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    Text(
                                      'Listings above your limit will be escalated',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.blue.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Listings List
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _pendingListings.length,
                            itemBuilder: (context, index) {
                              final listing = _pendingListings[index];
                              final amount = (listing['estimatedValue'] as num?)?.toDouble() ?? 0;
                              final canApproveAmount = amount <= userLimit;
                              final amountColor = _getAmountColor(amount, userLimit);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  listing['materialType'] ?? 'Unknown Material',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${listing['quantity']} ${listing['unit']}',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    color: Colors.white.withOpacity(0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Amount Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: amountColor.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: amountColor.withOpacity(0.5),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              _formatCurrency(amount),
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: amountColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Details
                                    if (listing['pickupLocation'] != null)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 16,
                                              color: Colors.white.withOpacity(0.6),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              listing['pickupLocation'],
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                color: Colors.white.withOpacity(0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Warning if exceeds limit
                                    if (!canApproveAmount)
                                      Container(
                                        margin: const EdgeInsets.all(16),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.warning, color: Colors.red, size: 20),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Amount exceeds your approval limit (${_formatCurrency(userLimit)})',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Action Buttons
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () => _rejectListing(listing['id']),
                                              icon: const Icon(Icons.close, size: 18),
                                              label: const Text('Reject'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red,
                                                side: const BorderSide(color: Colors.red),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: canApproveAmount
                                                  ? () => _approveListing(listing['id'], amount)
                                                  : null,
                                              icon: const Icon(Icons.check, size: 18),
                                              label: const Text('Approve'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                disabledBackgroundColor: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}


