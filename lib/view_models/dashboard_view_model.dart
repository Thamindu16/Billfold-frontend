// lib/view_models/dashboard_view_model.dart
import 'package:flutter/material.dart';
import '../core/utils/user_helper.dart';
import '../data/repositories/doc_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final DocRepository _repo = DocRepository();

  bool isLoading = false;
  String? error;

  Map<String, dynamic> summary = {};
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> transactions = [];
  Map<String, dynamic> budget = {};
  Map<String, dynamic> savings = {};
  Map<String, dynamic> overspending = {};
  Map<String, dynamic> anomalies = {};

  double _n(dynamic v) => v is num ? v.toDouble() : 0.0;

  // Dashboard screen eke ekama use karanna puluwan getters
  double get totalIncome => _n(summary['total_income']);
  double get totalExpenses => _n(summary['total_expenses']);
  double get netSavings => _n(summary['net_savings']);
  double get savingsRatePct => _n(summary['savings_rate_percentage']);
  String get currency => (summary['currency'] ?? 'LKR').toString();

  bool get hasData => ((summary['total_transaction_count'] ?? 0) as num) > 0;

  List<dynamic> get anomalyList => (anomalies['anomalies'] as List?) ?? [];
  List<dynamic> get budgetList => (budget['category_budgets'] as List?) ?? [];
  List<dynamic> get overspendingList =>
      (overspending['categories'] as List?) ?? [];
  List<dynamic> get savingCuts =>
      (savings['discretionary_cuts'] as List?) ?? [];
  List<dynamic> get subscriptions =>
      (savings['recurring_subscriptions'] as List?) ?? [];

  /// Dashboard open wenakota (initState eke) meka call karanna.
  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();

    final userId = currentUserId();
    try {
      final r = await Future.wait<Object>([
        _repo.getSummary(userId),
        _repo.getCategories(userId),
        _repo.getTransactions(userId),
        _repo.getBudget(userId),
        _repo.getSavings(userId),
        _repo.getOverspending(userId),
        _repo.getAnomalies(userId),
      ]);

      summary = r[0] as Map<String, dynamic>;
      categories = r[1] as List<Map<String, dynamic>>;
      transactions = r[2] as List<Map<String, dynamic>>;
      budget = r[3] as Map<String, dynamic>;
      savings = r[4] as Map<String, dynamic>;
      overspending = r[5] as Map<String, dynamic>;
      anomalies = r[6] as Map<String, dynamic>;
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }
}
