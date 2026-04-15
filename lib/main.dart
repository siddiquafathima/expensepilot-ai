import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
      ],
      child: const ExpensePilotApp(),
    ),
  );
}

final NumberFormat indianCurrency = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

class AppColors {
  static const Color primary = Color(0xFF9B7BFF);
  static const Color primaryDark = Color(0xFF5F2BFF);
  static const Color darkBg = Color(0xFF060312);
  static const Color darkCard = Color(0xFF130A24);
  static const Color darkCard2 = Color(0xFF1B1033);
  static const Color lightBg = Color(0xFFF5F2FB);
  static const Color lightCard = Colors.white;
  static const Color lightBorder = Color(0xFFE6DFFF);
}

class AppThemes {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.lightBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightCard,
      labelStyle: const TextStyle(color: Colors.black87),
      hintStyle: const TextStyle(color: Colors.black45),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primary.withOpacity(0.18),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.darkBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.darkCard,
      indicatorColor: AppColors.primary.withOpacity(0.18),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class ExpensePilotApp extends StatelessWidget {
  const ExpensePilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ExpensePilot AI',
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      home: const SplashScreen(),
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    loadTheme();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    notifyListeners();
  }
}

class TimezoneOption {
  final String id;
  final String label;
  final Duration offset;

  const TimezoneOption({
    required this.id,
    required this.label,
    required this.offset,
  });
}

const List<TimezoneOption> commonTimezones = [
  TimezoneOption(
    id: 'asia_kolkata',
    label: 'India (IST, UTC+5:30)',
    offset: Duration(hours: 5, minutes: 30),
  ),
  TimezoneOption(
    id: 'asia_dubai',
    label: 'Dubai/UAE (GST, UTC+4)',
    offset: Duration(hours: 4),
  ),
  TimezoneOption(
    id: 'utc',
    label: 'UTC (UTC+0)',
    offset: Duration(),
  ),
  TimezoneOption(
    id: 'europe_london',
    label: 'London (UTC+0)',
    offset: Duration(),
  ),
  TimezoneOption(
    id: 'america_new_york',
    label: 'New York (UTC-5)',
    offset: Duration(hours: -5),
  ),
  TimezoneOption(
    id: 'america_los_angeles',
    label: 'Los Angeles (UTC-8)',
    offset: Duration(hours: -8),
  ),
  TimezoneOption(
    id: 'asia_singapore',
    label: 'Singapore (UTC+8)',
    offset: Duration(hours: 8),
  ),
];

class UserProvider extends ChangeNotifier {
  String _userName = '';
  double _monthlyBudget = 25000;
  String _timezoneId = 'asia_kolkata';
  bool _loaded = false;

  String get userName => _userName;
  double get monthlyBudget => _monthlyBudget;
  String get timezoneId => _timezoneId;
  bool get loaded => _loaded;
  bool get isOnboarded => _userName.trim().isNotEmpty;

  UserProvider() {
    loadUser();
  }

  TimezoneOption get selectedTimezone {
    return commonTimezones.firstWhere(
      (tz) => tz.id == _timezoneId,
      orElse: () => commonTimezones.first,
    );
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('userName') ?? '';
    _monthlyBudget = prefs.getDouble('monthlyBudget') ?? 25000;
    _timezoneId = prefs.getString('timezoneId') ?? 'asia_kolkata';
    _loaded = true;
    notifyListeners();
  }

  Future<void> saveOnboarding({
    required String userName,
    required double monthlyBudget,
    required String timezoneId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _userName = toTitleCase(userName.trim());
    _monthlyBudget = monthlyBudget;
    _timezoneId = timezoneId;

    await prefs.setString('userName', _userName);
    await prefs.setDouble('monthlyBudget', _monthlyBudget);
    await prefs.setString('timezoneId', _timezoneId);
    notifyListeners();
  }

  DateTime getCurrentSelectedTime() {
    final utcNow = DateTime.now().toUtc();
    return utcNow.add(selectedTimezone.offset);
  }

  String getGreeting() {
  DateTime now = DateTime.now().toUtc();

  switch (timezoneId) {
    case 'asia_kolkata':
      now = now.add(const Duration(hours: 5, minutes: 30));
      break;
    case 'asia_dubai':
      now = now.add(const Duration(hours: 4));
      break;
    case 'utc':
      break;
    case 'europe_london':
      break;
    case 'america_new_york':
      now = now.add(const Duration(hours: -5));
      break;
    case 'america_los_angeles':
      now = now.add(const Duration(hours: -8));
      break;
    case 'asia_singapore':
      now = now.add(const Duration(hours: 8));
      break;
    default:
      now = now.add(const Duration(hours: 5, minutes: 30));
  }

  final hour = now.hour;

  if (hour >= 5 && hour < 12) {
    return 'Good Morning';
  } else if (hour >= 12 && hour < 17) {
    return 'Good Afternoon';
  } else if (hour >= 17 && hour < 21) {
    return 'Good Evening';
  } else {
    return 'Good Night';
  }
}
  String toTitleCase(String text) {
    if (text.trim().isEmpty) return '';
    return text
        .trim()
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

class Expense {
  String id;
  String title;
  String category;
  double amount;
  String date;
  String note;
  String approvalStatus; // Approved / Pending
  String aiRecommendation; // Approve / Review / Flag
  String aiReason;

  Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.note,
    required this.approvalStatus,
    required this.aiRecommendation,
    required this.aiReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date,
      'note': note,
      'approvalStatus': approvalStatus,
      'aiRecommendation': aiRecommendation,
      'aiReason': aiReason,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      amount: (json['amount'] as num).toDouble(),
      date: json['date'],
      note: json['note'] ?? '',
      approvalStatus: json['approvalStatus'] ?? 'Pending',
      aiRecommendation: json['aiRecommendation'] ?? 'Review',
      aiReason: json['aiReason'] ?? 'Needs manual review',
    );
  }
}

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];

  List<Expense> get expenses => _expenses;

  ExpenseProvider() {
    loadExpenses();
  }

  double totalExpense() {
    return _expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double remainingBudget(double budget) {
    return budget - totalExpense();
  }

  double budgetUsedPercent(double budget) {
    if (budget <= 0) return 0;
    final value = totalExpense() / budget;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  int pendingCount() =>
      _expenses.where((e) => e.approvalStatus == 'Pending').length;

  int approvedCount() =>
      _expenses.where((e) => e.approvalStatus == 'Approved').length;

  Future<void> addExpense(Expense expense) async {
    _expenses.add(expense);
    await saveExpenses();
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((expense) => expense.id == id);
    await saveExpenses();
    notifyListeners();
  }

  Future<void> updateExpense(String id, Expense updatedExpense) async {
    final index = _expenses.indexWhere((expense) => expense.id == id);
    if (index != -1) {
      _expenses[index] = updatedExpense;
      await saveExpenses();
      notifyListeners();
    }
  }

  Future<void> saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expenseList =
        _expenses.map((expense) => jsonEncode(expense.toJson())).toList();
    await prefs.setStringList('expenses', expenseList);
  }

  Future<void> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expenseList = prefs.getStringList('expenses');
    if (expenseList != null) {
      _expenses = expenseList
          .map((expense) => Expense.fromJson(jsonDecode(expense)))
          .toList();
      notifyListeners();
    }
  }

  double categoryTotal(String category) {
    return _expenses
        .where((e) => e.category == category)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  List<String> fakeAiAlerts(double budget) {
    final List<String> alerts = [];

    if (_expenses.isEmpty) {
      alerts.add('AI Tip: Add your first expense to unlock smart insights 🤖');
      return alerts;
    }

    if (totalExpense() > budget) {
      alerts.add('AI Alert: You have crossed your monthly budget ⚠️');
    } else if (budgetUsedPercent(budget) >= 0.8) {
      alerts.add('AI Alert: You are close to your monthly budget limit 📊');
    }

    if (categoryTotal('Bills') >= 5000) {
      alerts.add('AI Insight: Bills are unusually high this month 💡');
    }

    if (categoryTotal('Shopping') >= 5000) {
      alerts.add('AI Insight: Shopping expenses are rising fast 🛍️');
    }

    if (alerts.isEmpty) {
      alerts.add('AI Insight: Your spending pattern looks healthy ✅');
    }

    return alerts;
  }

  String heroInsight(double budget) {
    if (_expenses.isEmpty) {
      return 'No expenses yet. Start tracking with smart finance insights ✨';
    }

    if (totalExpense() > budget) {
      return 'You have exceeded your budget. Spend carefully ⚠️';
    }

    if (budgetUsedPercent(budget) >= 0.8) {
      return 'You have used more than 80% of your budget this month 📉';
    }

    final food = categoryTotal('Food');
    final shopping = categoryTotal('Shopping');
    final bills = categoryTotal('Bills');
    final transport = categoryTotal('Transport');

    if (bills >= food && bills >= shopping && bills >= transport && bills > 0) {
      return 'Bills are taking most of your monthly budget 💡';
    }
    if (food >= shopping && food >= bills && food >= transport && food > 0) {
      return 'Food is your top spending category this month 🍔';
    }
    if (shopping >= food && shopping >= bills && shopping >= transport && shopping > 0) {
      return 'Shopping spend is leading this month 🛍️';
    }
    if (transport > 0) {
      return 'Transport expenses are steadily increasing 🚕';
    }

    return 'Your spending pattern looks balanced right now ✅';
  }

  String suggestCategory(String title, String note) {
    final text = '${title.toLowerCase()} ${note.toLowerCase()}';

    if (text.contains('uber') ||
        text.contains('ola') ||
        text.contains('metro') ||
        text.contains('bus') ||
        text.contains('fuel')) {
      return 'Transport';
    }
    if (text.contains('starbucks') ||
        text.contains('restaurant') ||
        text.contains('food') ||
        text.contains('cafe') ||
        text.contains('lunch') ||
        text.contains('dinner') ||
        text.contains('grocery') ||
        text.contains('groceries')) {
      return 'Food';
    }
    if (text.contains('amazon') ||
        text.contains('shopping') ||
        text.contains('clothes') ||
        text.contains('mall') ||
        text.contains('salon')) {
      return 'Shopping';
    }
    if (text.contains('electricity') ||
        text.contains('rent') ||
        text.contains('bill') ||
        text.contains('internet') ||
        text.contains('fee') ||
        text.contains('medical')) {
      return 'Bills';
    }
    if (text.contains('movie') ||
        text.contains('netflix') ||
        text.contains('game')) {
      return 'Entertainment';
    }

    return 'Other';
  }

  Map<String, String> generateAiDecision({
    required String title,
    required String category,
    required double amount,
    required String note,
  }) {
    final lowerTitle = title.toLowerCase();
    final lowerNote = note.toLowerCase();

    String recommendation = 'Approve';
    String reason = 'Expense looks normal and within expected range';

    if (amount >= 10000) {
      recommendation = 'Flag';
      reason = 'High-value expense detected';
    } else if (amount >= 5000 && category == 'Shopping') {
      recommendation = 'Review';
      reason = 'Shopping expense is higher than usual';
    } else if (note.trim().isEmpty) {
      recommendation = 'Review';
      reason = 'Missing note or justification';
    } else if (lowerTitle.contains('uber') || lowerTitle.contains('ola')) {
      recommendation = 'Approve';
      reason = 'Travel-related business expense pattern detected';
    } else if (lowerTitle.contains('restaurant') ||
        lowerTitle.contains('cafe') ||
        lowerTitle.contains('starbucks') ||
        lowerTitle.contains('grocery') ||
        category == 'Food') {
      recommendation = amount > 3000 ? 'Review' : 'Approve';
      reason = amount > 3000
          ? 'Meal cost is above normal threshold'
          : 'Meal expense looks acceptable';
    } else if (lowerTitle.contains('flight') || lowerNote.contains('trip')) {
      recommendation = 'Approve';
      reason = 'Travel expense detected';
    }

    return {
      'recommendation': recommendation,
      'reason': reason,
    };
  }

  String approvalStatusFromAi(String aiRecommendation) {
    if (aiRecommendation == 'Approve') {
      return 'Approved';
    }
    return 'Pending';
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<void> goNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final userProvider = context.read<UserProvider>();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => userProvider.isOnboarded
            ? const MainNavigationScreen()
            : const OnboardingScreen(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    goNext();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [
                    Color(0xFF05020E),
                    Color(0xFF120626),
                    Color(0xFF220D44),
                  ]
                : const [
                    Color(0xFFF8F4FF),
                    Color(0xFFEFE8FF),
                    Color(0xFFE2D4FF),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  color: Colors.black.withOpacity(0.14),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: AppColors.primary,
                  child: Icon(
                    Icons.auto_graph_rounded,
                    size: 40,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  'ExpensePilot AI',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Corporate spend, smarter approvals ✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final budgetController = TextEditingController();
  String selectedTimezoneId = commonTimezones.first.id;

  final budgetFormatter = CurrencyTextInputFormatter.currency(
    locale: 'en_IN',
    symbol: '',
    decimalDigits: 0,
  );

  double parseAmount(String value) {
    return double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
  }

  @override
  void dispose() {
    nameController.dispose();
    budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [
                    Color(0xFF05020E),
                    Color(0xFF120626),
                    Color(0xFF220D44),
                  ]
                : const [
                    Color(0xFFF8F4FF),
                    Color(0xFFEFE8FF),
                    Color(0xFFE2D4FF),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.white.withOpacity(0.94),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 34,
                      backgroundColor: AppColors.primary,
                      child: Icon(
                        Icons.wallet_outlined,
                        color: Colors.black,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Welcome to ExpensePilot AI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Set up your profile to personalize your dashboard',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Your Name',
                        hintText: 'Enter your name',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: budgetController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        budgetFormatter,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Monthly Budget',
                        prefixText: '₹ ',
                        hintText: 'Enter monthly budget',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter budget';
                        }
                        if (parseAmount(value) <= 0) {
                          return 'Budget must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedTimezoneId,
                      decoration: const InputDecoration(
                        labelText: 'Timezone',
                      ),
                      items: commonTimezones
                          .map(
                            (tz) => DropdownMenuItem(
                              value: tz.id,
                              child: Text(tz.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedTimezoneId =
                              value ?? commonTimezones.first.id;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            await userProvider.saveOnboarding(
                              userName: nameController.text,
                              monthlyBudget: parseAmount(budgetController.text),
                              timezoneId: selectedTimezoneId,
                            );

                            if (!mounted) return;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const MainNavigationScreen(),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentIndex = 0;

  final screens = const [
    DashboardScreen(),
    CardsScreen(),
    ApprovalsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: screens[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.18),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined),
            selectedIcon: Icon(Icons.credit_card),
            label: 'Cards',
          ),
          NavigationDestination(
            icon: Icon(Icons.approval_outlined),
            selectedIcon: Icon(Icons.approval),
            label: 'Approvals',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddExpenseScreen(),
            ),
          );
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final userProvider = context.watch<UserProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredExpenses = expenseProvider.expenses.where((expense) {
      final q = searchQuery.toLowerCase();
      return expense.title.toLowerCase().contains(q) ||
          expense.category.toLowerCase().contains(q) ||
          expense.note.toLowerCase().contains(q);
    }).toList().reversed.toList();

    final budget = userProvider.monthlyBudget;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 92,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${userProvider.getGreeting()}, ${userProvider.userName} 👋',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'ExpensePilot AI',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Switch(
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.toggleTheme(value),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit_profile') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileSettingsScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit_profile',
                child: Text('Edit Profile'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              _buildHeroCard(context, expenseProvider, budget),
              const SizedBox(height: 12),
              _buildAlertStrip(
                expenseProvider.fakeAiAlerts(budget),
                isDark,
              ),
              const SizedBox(height: 12),
              TextField(
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'Search expenses...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 14),
              if (filteredExpenses.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'No expenses found',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              else
                ...filteredExpenses.map(
                  (expense) => ExpenseCard(expense: expense),
                ),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    ExpenseProvider provider,
    double budget,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFAA8CFF), Color(0xFF5B2EFF)],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.18),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Total Spend',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            indianCurrency.format(provider.totalExpense()),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: provider.budgetUsedPercent(budget),
              backgroundColor: Colors.white24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Budget: ${indianCurrency.format(budget)} • Remaining: ${indianCurrency.format(provider.remainingBudget(budget))}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            provider.heroInsight(budget),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertStrip(List<String> alerts, bool isDark) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.35),
              ),
            ),
            child: Center(
              child: Text(
                alerts[index],
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final userProvider = context.watch<UserProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tileColor = isDark ? AppColors.darkCard : Colors.white;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;

    final cardLimit = userProvider.monthlyBudget;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Corporate Cards',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                colors: [Color(0xFF1D103C), Color(0xFF5B2EFF)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ExpensePilot Virtual Card',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  '****  ****  ****  2048',
                  style: TextStyle(
                    fontSize: 26,
                    letterSpacing: 2,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Status: Active',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Limit: ${indianCurrency.format(cardLimit)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _infoTile(
            title: 'Used this month',
            value: indianCurrency.format(provider.totalExpense()),
            tileColor: tileColor,
            textSecondary: textSecondary,
          ),
          _infoTile(
            title: 'Remaining card limit',
            value: indianCurrency.format(cardLimit - provider.totalExpense()),
            tileColor: tileColor,
            textSecondary: textSecondary,
          ),
          _infoTile(
            title: 'Pending approvals',
            value: provider.pendingCount().toString(),
            tileColor: tileColor,
            textSecondary: textSecondary,
          ),
          _infoTile(
            title: 'Approved expenses',
            value: provider.approvedCount().toString(),
            tileColor: tileColor,
            textSecondary: textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required String title,
    required String value,
    required Color tileColor,
    required Color textSecondary,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: tileColor,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: textSecondary)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class ApprovalsScreen extends StatelessWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final items = provider.expenses.reversed.toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Approvals Center',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: items.isEmpty
          ? const Center(child: Text('No approvals yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final expense = items[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: cardColor,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              expense.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          _statusChip(expense.approvalStatus),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${expense.category} • ${indianCurrency.format(expense.amount)}'),
                      const SizedBox(height: 6),
                      Text(
                        'AI: ${expense.aiRecommendation} • ${expense.aiReason}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _statusChip(String status) {
    Color color = Colors.orange;
    if (status == 'Approved') color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ExpenseCard extends StatelessWidget {
  final Expense expense;

  const ExpenseCard({
    super.key,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ExpenseProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: cardColor,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  expense.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                indianCurrency.format(expense.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${expense.category} • ${expense.date}',
            style: TextStyle(color: subtitleColor),
          ),
          const SizedBox(height: 6),
          Text(
            expense.note.isEmpty ? 'No note added' : expense.note,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _miniChip(expense.approvalStatus),
              const Spacer(),
              IconButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddExpenseScreen(expense: expense),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
              ),
              IconButton(
                onPressed: () {
                  provider.deleteExpense(expense.id);
                },
                icon: const Icon(Icons.delete),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String text) {
    Color color = Colors.orange;
    if (text == 'Approved') color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddExpenseScreen({
    super.key,
    this.expense,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  final amountFormatter = CurrencyTextInputFormatter.currency(
    locale: 'en_IN',
    decimalDigits: 0,
    symbol: '',
  );

  String? selectedCategory;
  String aiSuggestion = '';
  String aiRecommendation = '';
  String aiReason = '';
  String approvalStatus = 'Pending';

  DateTime selectedDate = DateTime.now();

  final categories = const [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.expense != null) {
      final e = widget.expense!;
      titleController.text = e.title;
      amountController.text = amountFormatter.formatString(
        e.amount.toInt().toString(),
      );
      noteController.text = e.note;
      selectedCategory = e.category;
      aiRecommendation = e.aiRecommendation;
      aiReason = e.aiReason;
      approvalStatus = e.approvalStatus;
      selectedDate = DateFormat('dd-MM-yyyy').parse(e.date);
      aiSuggestion = e.category;
    }
  }

  double parseAmount(String value) {
    return double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
  }

  String toTitleCase(String text) {
    if (text.trim().isEmpty) return '';
    return text
        .trim()
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  String capitalizeFirst(String text) {
    if (text.trim().isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }

  void runAiPreview() {
    final provider = context.read<ExpenseProvider>();
    final title = titleController.text.trim();
    final note = noteController.text.trim();
    final amount = parseAmount(amountController.text);

    final suggestion = provider.suggestCategory(title, note);
    final finalCategory = selectedCategory ?? suggestion;

    final decision = provider.generateAiDecision(
      title: title,
      category: finalCategory,
      amount: amount,
      note: note,
    );

    final finalStatus =
        provider.approvalStatusFromAi(decision['recommendation']!);

    setState(() {
      aiSuggestion = suggestion;
      aiRecommendation = decision['recommendation']!;
      aiReason = decision['reason']!;
      approvalStatus = finalStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ExpenseProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Add Expense' : 'Edit Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: cardColor,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.08),
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Expense Title',
                  ),
                  onChanged: (_) => runAiPreview(),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter title' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    amountFormatter,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹ ',
                  ),
                  onChanged: (_) => runAiPreview(),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter amount' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  hint: const Text('Select Category'),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                    runAiPreview();
                  },
                  validator: (value) =>
                      value == null ? 'Select category' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: noteController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                  ),
                  onChanged: (_) => runAiPreview(),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Date: ${DateFormat('dd-MM-yyyy').format(selectedDate)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2030),
                    );

                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),
                if (aiSuggestion.isNotEmpty) _aiCard(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final title = toTitleCase(titleController.text.trim());
                        final note = capitalizeFirst(noteController.text.trim());
                        final amount = parseAmount(amountController.text);
                        final finalCategory = selectedCategory ?? aiSuggestion;

                        final decision = provider.generateAiDecision(
                          title: title,
                          category: finalCategory,
                          amount: amount,
                          note: note,
                        );

                        final finalStatus = provider.approvalStatusFromAi(
                          decision['recommendation']!,
                        );

                        final expense = Expense(
                          id: widget.expense?.id ??
                              DateTime.now().millisecondsSinceEpoch.toString(),
                          title: title,
                          category: finalCategory,
                          amount: amount,
                          date: DateFormat('dd-MM-yyyy').format(selectedDate),
                          note: note,
                          approvalStatus: finalStatus,
                          aiRecommendation: decision['recommendation']!,
                          aiReason: decision['reason']!,
                        );

                        if (widget.expense == null) {
                          await provider.addExpense(expense);
                        } else {
                          await provider.updateExpense(widget.expense!.id, expense);
                        }

                        if (!mounted) return;
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      widget.expense == null ? 'Save Expense' : 'Update Expense',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _aiCard() {
    Color color = Colors.orange;
    if (aiRecommendation == 'Approve') color = Colors.green;
    if (aiRecommendation == 'Flag') color = Colors.redAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: color.withOpacity(0.10),
        border: Border.all(
          color: color.withOpacity(0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Suggested Category: $aiSuggestion',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text('AI Recommendation: $aiRecommendation'),
          const SizedBox(height: 4),
          Text(
            aiReason,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Final workflow status: $approvalStatus',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final nameController = TextEditingController();
  final budgetController = TextEditingController();
  String selectedTimezoneId = commonTimezones.first.id;

  final budgetFormatter = CurrencyTextInputFormatter.currency(
    locale: 'en_IN',
    symbol: '',
    decimalDigits: 0,
  );

  double parseAmount(String value) {
    return double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = context.read<UserProvider>();

    if (nameController.text.isEmpty) {
      nameController.text = userProvider.userName;
      budgetController.text = budgetFormatter.formatString(
        userProvider.monthlyBudget.toInt().toString(),
      );
      selectedTimezoneId = userProvider.timezoneId;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.read<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Your Name'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: budgetController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                budgetFormatter,
              ],
              decoration: const InputDecoration(
                labelText: 'Monthly Budget',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: selectedTimezoneId,
              decoration: const InputDecoration(labelText: 'Timezone'),
              items: commonTimezones
                  .map(
                    (tz) => DropdownMenuItem(
                      value: tz.id,
                      child: Text(tz.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedTimezoneId = value ?? selectedTimezoneId;
                });
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  await userProvider.saveOnboarding(
                    userName: nameController.text,
                    monthlyBudget: parseAmount(budgetController.text),
                    timezoneId: selectedTimezoneId,
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}