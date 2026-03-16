import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ticket_receipt_screen.dart';
import 'deposit_screen.dart'; // ✨ Deposit Screen import ki
import '../services/ticket_service.dart';
import '../services/auth_service.dart'; // ✨ Live Balance lene ke liye

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  String? _selectedGame;
  List<List<TextEditingController>> _rowsControllers = [];
  List<List<FocusNode>> _rowsFocusNodes = [];
  List<Map<String, bool>> _rowsTypes = [];

  int _ticketQuantity = 1;
  bool _isLoading = false;

  // ✨ WALLET SYSTEM VARIABLES
  Map<String, dynamic>? _wallets;
  bool _isFetchingWallets = true;
  String _selectedWallet = 'deposit'; // Default: Play Balance

  @override
  void initState() {
    super.initState();
    _fetchWallets(); // Screen khulte hi wallet balance le aao
  }

  // Live balance fetch karne ka function
  void _fetchWallets() async {
    final data = await AuthService.getUserData();
    if (mounted) {
      setState(() {
        if (data['success'] == true) {
          _wallets = data['user']['wallets'];
        }
        _isFetchingWallets = false;
      });
    }
  }

  @override
  void dispose() {
    for (var row in _rowsControllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    for (var row in _rowsFocusNodes) {
      for (var node in row) {
        node.dispose();
      }
    }
    super.dispose();
  }

  void _addRow() {
    setState(() {
      var newControllers = List.generate(4, (_) => TextEditingController());
      var newNodes = List.generate(4, (_) => FocusNode());

      for (var controller in newControllers) {
        controller.addListener(() {
          setState(() {});
        });
      }

      _rowsControllers.add(newControllers);
      _rowsFocusNodes.add(newNodes);
      _rowsTypes.add({'straight': false, 'mixFix': false});
    });
  }

  void _clearAll() {
    setState(() {
      _selectedGame = null;
      _rowsControllers.clear();
      _rowsFocusNodes.clear();
      _rowsTypes.clear();
      _ticketQuantity = 1;
    });
  }

  double get _currentPrice {
    if (_selectedGame == null) return 0.00;
    double price = 0.0;

    for (int i = 0; i < _rowsControllers.length; i++) {
      if (_rowsControllers[i].any((c) => c.text.isNotEmpty)) {
        int multiplier = 1;
        if (_selectedGame == '4tune') {
          int c = 0;
          if (_rowsTypes[i]['straight'] == true) c++;
          if (_rowsTypes[i]['mixFix'] == true) c++;
          multiplier = c > 0 ? c : 0;
        }
        price += 0.035 * multiplier * _ticketQuantity;
      }
    }
    return price;
  }

  Future<void> _buyTicket() async {
    if (_selectedGame == null) return;

    // ✨ WALLET BALANCE CHECK
    double availableBalance = (_wallets?[_selectedWallet] ?? 0.0).toDouble();
    if (availableBalance < _currentPrice) {
      _showInsufficientBalanceDialog();
      return;
    }

    int maxAllowed = _selectedGame == '4tune'
        ? 4
        : (_selectedGame == '3luck' ? 3 : (_selectedGame == '2win' ? 2 : 1));

    List<String> receiptDisplayStrings = [];
    List<Map<String, dynamic>> backendLinesData = [];

    for (int r = 0; r < _rowsControllers.length; r++) {
      int filledCount = _rowsControllers[r]
          .where((c) => c.text.isNotEmpty)
          .length;
      if (filledCount == 0) continue;

      if (filledCount < maxAllowed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Line ${r + 1} is incomplete!'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      if (_selectedGame == '4tune' &&
          _rowsTypes[r]['straight'] == false &&
          _rowsTypes[r]['mixFix'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select Straight or Mix Fix for Line ${r + 1}!',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      String displayNumber = "";
      String dbNumber = "";
      List<int> positions = [];

      for (int i = 0; i < 4; i++) {
        if (_rowsControllers[r][i].text.isNotEmpty) {
          displayNumber += _rowsControllers[r][i].text;
          dbNumber += _rowsControllers[r][i].text;
          positions.add(i);
        } else {
          displayNumber += "-";
        }
      }

      String typeStr = "";
      if (_selectedGame == '4tune') {
        List<String> t = [];
        if (_rowsTypes[r]['straight'] == true) t.add("Str");
        if (_rowsTypes[r]['mixFix'] == true) t.add("Mix");
        typeStr = " (${t.join('+')})";
      }
      receiptDisplayStrings.add("$displayNumber$typeStr");

      backendLinesData.add({
        "chosenNumbers": [dbNumber],
        "positions": positions,
        "isStraight": _rowsTypes[r]['straight'],
        "isMixFix": _rowsTypes[r]['mixFix'],
      });
    }

    if (backendLinesData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill at least one number line!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // ✨ API CALL WITH SELECTED WALLET
    final response = await TicketService.buyTicket(
      gameType: _selectedGame!,
      quantity: _ticketQuantity,
      lines: backendLinesData,
      walletType: _selectedWallet, // Backend ko wallet type bhej diya
    );

    setState(() => _isLoading = false);

    if (response['success'] == true) {
      final data = response['receiptData'];
      String combinedTickets = receiptDisplayStrings.join('\n');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TicketReceiptScreen(
            ticketNumber: combinedTickets,
            gameType: _selectedGame!,
            matchType: _selectedGame == '4tune'
                ? 'Custom per line'
                : 'Positional',
            amount: (data['amountPaid'] as num).toDouble(),
            username: data['username'],
            email: data['email'],
            winAmount: (data['winAmount'] as num).toDouble(),
            sponsorUsername: data['sponsorUsername'],
            grandSponsorUsername: data['grandSponsorUsername'],
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Purchase Failed!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ✨ VIP INSUFFICIENT BALANCE DIALOG
  void _showInsufficientBalanceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E003E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.amberAccent.withOpacity(0.5)),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
                size: 30,
              ),
              SizedBox(width: 10),
              Text(
                'Insufficient Funds',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            'Your selected wallet does not have enough balance to purchase this ticket (\$${_currentPrice.toStringAsFixed(3)} required).',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DepositScreen()),
                ); // ✨ Go to Deposit Screen
              },
              child: const Text(
                'TOP UP NOW',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // ✨ WALLET SELECTOR WIDGET
  Widget _buildWalletSelector(
    String type,
    String title,
    Color color,
    IconData icon,
  ) {
    bool isSelected = _selectedWallet == type;
    double balance = (_wallets?[type] ?? 0.0).toDouble();

    return GestureDetector(
      onTap: () => setState(() => _selectedWallet = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? color : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.amber),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'PLAY JACKPOT',
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
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F001F), Color(0xFF2A004F)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['4tune', '3luck', '2win', '1won'].map((game) {
                      bool isSelected = _selectedGame == game;
                      bool isDisabled =
                          _selectedGame != null && _selectedGame != game;
                      return GestureDetector(
                        onTap: isDisabled
                            ? null
                            : () {
                                if (_selectedGame == null) {
                                  setState(() {
                                    _selectedGame = game;
                                    _addRow();
                                  });
                                }
                              },
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isDisabled ? 0.3 : 1.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.amber
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.amberAccent
                                    : Colors.white24,
                              ),
                            ),
                            child: Text(
                              game,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.white70,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 50),

                  if (_selectedGame == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'Select a game category to unlock numbers.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        ...List.generate(_rowsControllers.length, (rowIndex) {
                          int maxAllowed = _selectedGame == '4tune'
                              ? 4
                              : (_selectedGame == '3luck'
                                    ? 3
                                    : (_selectedGame == '2win' ? 2 : 1));
                          bool limitReached =
                              _rowsControllers[rowIndex]
                                  .where((c) => c.text.isNotEmpty)
                                  .length >=
                              maxAllowed;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 25.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(4, (colIndex) {
                                    bool isFilled =
                                        _rowsControllers[rowIndex][colIndex]
                                            .text
                                            .isNotEmpty;
                                    bool isDisabled = limitReached && !isFilled;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                      ),
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isFilled
                                              ? Colors.white.withOpacity(0.1)
                                              : Colors.black26,
                                          border: Border.all(
                                            color: isFilled
                                                ? Colors.amber
                                                : (isDisabled
                                                      ? Colors.redAccent
                                                            .withOpacity(0.5)
                                                      : Colors.white24),
                                            width: isFilled ? 2 : 1,
                                          ),
                                          boxShadow: isFilled
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.amber
                                                        .withOpacity(0.3),
                                                    blurRadius: 10,
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: Center(
                                          child: isDisabled
                                              ? const Icon(
                                                  Icons.close,
                                                  color: Colors.redAccent,
                                                  size: 25,
                                                )
                                              : TextField(
                                                  controller:
                                                      _rowsControllers[rowIndex][colIndex],
                                                  focusNode:
                                                      _rowsFocusNodes[rowIndex][colIndex],
                                                  textAlign: TextAlign.center,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                    LengthLimitingTextInputFormatter(
                                                      1,
                                                    ),
                                                  ],
                                                  style: const TextStyle(
                                                    fontSize: 26,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                  decoration:
                                                      const InputDecoration(
                                                        border:
                                                            InputBorder.none,
                                                        counterText: "",
                                                      ),
                                                  onChanged: (val) {
                                                    if (val.isNotEmpty &&
                                                        colIndex < 3 &&
                                                        !limitReached)
                                                      FocusScope.of(
                                                        context,
                                                      ).requestFocus(
                                                        _rowsFocusNodes[rowIndex][colIndex +
                                                            1],
                                                      );
                                                  },
                                                ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                if (_selectedGame == '4tune')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Theme(
                                          data: Theme.of(context).copyWith(
                                            unselectedWidgetColor:
                                                Colors.white54,
                                          ),
                                          child: Checkbox(
                                            value:
                                                _rowsTypes[rowIndex]['straight'],
                                            activeColor: Colors.amber,
                                            checkColor: Colors.black,
                                            onChanged: (val) => setState(
                                              () =>
                                                  _rowsTypes[rowIndex]['straight'] =
                                                      val!,
                                            ),
                                          ),
                                        ),
                                        const Text(
                                          'Straight',
                                          style: TextStyle(
                                            color: Colors.amberAccent,
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Theme(
                                          data: Theme.of(context).copyWith(
                                            unselectedWidgetColor:
                                                Colors.white54,
                                          ),
                                          child: Checkbox(
                                            value:
                                                _rowsTypes[rowIndex]['mixFix'],
                                            activeColor: Colors.amber,
                                            checkColor: Colors.black,
                                            onChanged: (val) => setState(
                                              () =>
                                                  _rowsTypes[rowIndex]['mixFix'] =
                                                      val!,
                                            ),
                                          ),
                                        ),
                                        const Text(
                                          'Mix Fix',
                                          style: TextStyle(
                                            color: Colors.amberAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                                color: Colors.greenAccent,
                                size: 35,
                              ),
                              onPressed: _addRow,
                            ),
                            const SizedBox(width: 5),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_sweep,
                                color: Colors.redAccent,
                                size: 35,
                              ),
                              onPressed: _clearAll,
                            ),
                          ],
                        ),
                      ],
                    ),

                  const SizedBox(height: 30),

                  // ✨ CHECKOUT BOX WITH WALLET SELECTOR
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          children: [
                            // Quantity Controls
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Ticket Quantity:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.amber,
                                      ),
                                      onPressed: () {
                                        if (_ticketQuantity > 1)
                                          setState(() => _ticketQuantity--);
                                      },
                                    ),
                                    Text(
                                      '$_ticketQuantity',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.amber,
                                      ),
                                      onPressed: () =>
                                          setState(() => _ticketQuantity++),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white24, height: 25),

                            // ✨ WALLET SELECTION ROW
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Pay via:',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _isFetchingWallets
                                ? const SizedBox(
                                    height: 40,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.amberAccent,
                                      ),
                                    ),
                                  )
                                : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        _buildWalletSelector(
                                          'deposit',
                                          'PLAY',
                                          Colors.greenAccent,
                                          Icons.account_balance_wallet,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildWalletSelector(
                                          'win',
                                          'WIN',
                                          Colors.pinkAccent,
                                          Icons.emoji_events,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildWalletSelector(
                                          'bonus',
                                          'BONUS',
                                          Colors.cyanAccent,
                                          Icons.card_giftcard,
                                        ),
                                      ],
                                    ),
                                  ),

                            const SizedBox(height: 20),

                            // Buy Button
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                onPressed: _isLoading || _currentPrice == 0.0
                                    ? null
                                    : _buyTicket,
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.black,
                                      )
                                    : Text(
                                        'GET NOW (\$${_currentPrice.toStringAsFixed(3)})',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
