import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/ticket_service.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  List<dynamic> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  void _fetchTickets() async {
    final response = await TicketService.getMyTickets();
    if (mounted) {
      setState(() {
        if (response['success'] == true) {
          _tickets = response['tickets'] ?? [];
        }
        _isLoading = false;
      });
    }
  }

  // ✨ Ticket Card Design
  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    String gameType = ticket['gameType'] ?? 'Unknown';
    List<dynamic> chosenNumbers = ticket['chosenNumbers'] ?? [];
    String receiptCode = ticket['receiptCode'] ?? '#000000';
    double price = (ticket['price'] ?? 0.0).toDouble();
    bool isWon = ticket['isWon'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.amberAccent.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
              ],
            ),
            child: Row(
              children: [
                // Game Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.amberAccent.withOpacity(0.5),
                    ),
                  ),
                  child: const Icon(
                    Icons.confirmation_number,
                    color: Colors.amberAccent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 15),
                // Ticket Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Game: $gameType',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Numbers: ${chosenNumbers.join(", ")}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Receipt: $receiptCode',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Price & Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // ✨ FIX: Rs. formatting applied
                    Text(
                      'Rs. ${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blueAccent),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0014),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.amberAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'MY TICKETS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned(
            top: 100,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amberAccent.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amberAccent.withOpacity(0.3),
                    blurRadius: 100,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.amberAccent),
                  )
                : _tickets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Opacity(
                          opacity: 0.6,
                          child: Lottie.network(
                            'https://assets5.lottiefiles.com/packages/lf20_1p0x2x9b.json',
                            height: 200,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Vault is Empty!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "You haven't bought any tickets yet.",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _tickets.length,
                    itemBuilder: (context, index) {
                      return _buildTicketCard(_tickets[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
