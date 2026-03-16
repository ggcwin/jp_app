import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TicketReceiptScreen extends StatelessWidget {
  final String ticketNumber;
  final String gameType;
  final String matchType;
  final double amount;
  final String username;
  final String email;

  final double winAmount;
  final String sponsorUsername;
  final String grandSponsorUsername;

  const TicketReceiptScreen({
    super.key,
    required this.ticketNumber,
    required this.gameType,
    required this.matchType,
    required this.amount,
    required this.username,
    required this.email,
    required this.winAmount,
    required this.sponsorUsername,
    required this.grandSponsorUsername,
  });

  Widget _buildInvoiceRow(
    String label,
    String value, {
    bool isHighlight = false,
    bool isSubText = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSubText ? 4.0 : 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSubText ? Colors.white38 : Colors.white54,
              fontSize: isSubText ? 12 : 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isHighlight
                    ? Colors.greenAccent
                    : (isSubText ? Colors.white54 : Colors.white),
                fontSize: isHighlight ? 18 : (isSubText ? 12 : 14),
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 5% Commission Calculations
    final double sponsorCut = winAmount * 0.05;
    final double grandSponsorCut = winAmount * 0.05;

    // QR Code mein data
    final String qrData =
        "https://jackpot.verify/?ticket=${Uri.encodeComponent(ticketNumber)}&type=$gameType&match=${Uri.encodeComponent(matchType)}&user=$username";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'E-RECEIPT',
          style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F001F), Color(0xFF2A004F)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.receipt_long,
                                  color: Colors.amber,
                                  size: 28,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'OFFICIAL INVOICE',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    letterSpacing: 3,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const _DashedDivider(),
                            const SizedBox(height: 20),

                            _buildInvoiceRow('Username:', username),
                            _buildInvoiceRow('Email:', email),
                            const SizedBox(height: 10),

                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.greenAccent.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildInvoiceRow(
                                    'Est. Win Amount:',
                                    '\$${winAmount.toStringAsFixed(2)}',
                                    isHighlight: true,
                                  ),
                                  const Divider(color: Colors.white12),
                                  _buildInvoiceRow(
                                    'Sponsor ($sponsorUsername):',
                                    '+ \$${sponsorCut.toStringAsFixed(2)}',
                                    isSubText: true,
                                  ),
                                  _buildInvoiceRow(
                                    'G. Sponsor ($grandSponsorUsername):',
                                    '+ \$${grandSponsorCut.toStringAsFixed(2)}',
                                    isSubText: true,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),
                            _buildInvoiceRow(
                              'Date:',
                              DateTime.now().toString().split(' ')[0],
                            ),

                            const SizedBox(height: 20),
                            const _DashedDivider(),
                            const SizedBox(height: 20),

                            const Text(
                              'TICKET NUMBERS',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // ✨ MULTI-LINE FONT SIZE FIX
                            Text(
                              ticketNumber,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: ticketNumber.contains('\n') ? 32 : 45,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: ticketNumber.contains('\n')
                                    ? 8
                                    : 15,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 20),

                            _buildInvoiceRow('Game:', gameType),
                            _buildInvoiceRow('Type:', matchType),

                            const SizedBox(height: 20),
                            const _DashedDivider(),
                            const SizedBox(height: 20),

                            _buildInvoiceRow(
                              'Total Paid:',
                              '\$${amount.toStringAsFixed(3)}',
                              isHighlight: true,
                            ),
                            _buildInvoiceRow('Status:', 'PAID SUCCESS'),

                            const SizedBox(height: 30),

                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.2),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                data: qrData,
                                version: QrVersions.auto,
                                size: 160.0,
                                backgroundColor: Colors.white,
                                errorCorrectionLevel: QrErrorCorrectLevel.M,
                              ),
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              'SCAN TO VERIFY TICKET',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invoice saved to gallery! ✅'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: const Text(
                        'SAVE TO GALLERY',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Return to Dashboard',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.white24),
              ),
            );
          }),
        );
      },
    );
  }
}
