import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/quote_doc.dart';
import '../storage/local_db.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'documents_list_screen.dart';
import 'backup_screen.dart';

enum _ChartGranularity { day, week, month }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  _ChartGranularity _granularity = _ChartGranularity.month;
  bool _bannerDismissed = false;

  @override
  Widget build(BuildContext context) {
    final docs = LocalDB.instance.getDocuments();
    final quotations = docs.where((d) => d.type == DocType.quotation).toList();
    final invoices = docs.where((d) => d.type == DocType.invoice).toList();

    final totalQuoted = quotations.fold(0.0, (s, d) => s + d.total);
    final totalInvoiced = invoices.fold(0.0, (s, d) => s + d.total);
    // Counts an invoice as fully paid (its whole total) when its status is
    // Paid, even if "Amount Paid" wasn't separately typed in — and uses the
    // actual partial amount otherwise. Covers both new and older documents.
    final totalPaid = invoices.fold(
      0.0,
      (s, d) => s + (d.status == DocStatus.paid ? d.total : d.amountPaid),
    );
    final totalOutstanding = invoices.fold(
      0.0,
      (s, d) => s + (d.status == DocStatus.paid ? 0.0 : d.balanceDue),
    );

    final overdueInvoices = invoices.where((d) => d.isOverdue).toList();
    final overdueTotal = overdueInvoices.fold(0.0, (s, d) => s + d.balanceDue);

    final chart = _buildChartData(invoices);
    final lastBackup = LocalDB.instance.getLastBackupAt();
    final needsBackupReminder = !_bannerDismissed &&
        (lastBackup == null || DateTime.now().difference(lastBackup).inDays >= 30);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (needsBackupReminder) _backupReminderBanner(lastBackup),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.7,
            children: [
              _statCard('Quotations', quotations.length.toString(), formatRupees(totalQuoted)),
              _statCard('Invoices', invoices.length.toString(), formatRupees(totalInvoiced)),
              _statCard('Amount Paid', '', formatRupees(totalPaid), color: AppColors.ok),
              _statCard('Outstanding', '', formatRupees(totalOutstanding), color: AppColors.danger),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('INVOICE TOTAL',
                  style: TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.blueprintDk, letterSpacing: 0.5)),
              _granularityChips(),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: chart.maxVal == 0
                ? const Center(child: Text('No invoices yet', style: TextStyle(color: AppColors.inkSoft)))
                : BarChart(
                    BarChartData(
                      maxY: chart.maxVal * 1.25,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.blueprintDk,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                            formatRupees(rod.toY),
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                      ),
                      barGroups: List.generate(
                        chart.values.length,
                        (i) => BarChartGroupData(x: i, barRods: [
                          BarChartRodData(
                            toY: chart.values[i],
                            color: AppColors.blueprint,
                            width: chart.values.length > 8 ? 14 : 22,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ]),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= chart.labels.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(chart.labels[i], style: const TextStyle(fontSize: 9.5, color: AppColors.inkSoft)),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          _overdueCard(overdueInvoices.length, overdueTotal),
        ],
      ),
    );
  }

  Widget _granularityChips() {
    Widget chip(String label, _ChartGranularity g) => Padding(
          padding: const EdgeInsets.only(left: 6),
          child: ChoiceChip(
            label: Text(label, style: const TextStyle(fontSize: 11)),
            visualDensity: VisualDensity.compact,
            selected: _granularity == g,
            onSelected: (_) => setState(() => _granularity = g),
          ),
        );
    return Row(
      children: [
        chip('Day', _ChartGranularity.day),
        chip('Week', _ChartGranularity.week),
        chip('Month', _ChartGranularity.month),
      ],
    );
  }

  _ChartData _buildChartData(List<QuoteDoc> invoices) {
    final now = DateTime.now();
    List<double> values;
    List<String> labels;

    switch (_granularity) {
      case _ChartGranularity.day:
        final days = List.generate(6, (i) => DateTime(now.year, now.month, now.day - (5 - i)));
        values = days
            .map((d) => invoices
                .where((inv) => inv.date.year == d.year && inv.date.month == d.month && inv.date.day == d.day)
                .fold(0.0, (s, inv) => s + inv.total))
            .toList();
        labels = days.map((d) => '${d.day}/${d.month}').toList();
        break;
      case _ChartGranularity.week:
        final weeks = List.generate(6, (i) => now.subtract(Duration(days: (5 - i) * 7)));
        values = weeks.map((wEnd) {
          final wStart = wEnd.subtract(const Duration(days: 6));
          return invoices
              .where((inv) =>
                  !inv.date.isBefore(DateTime(wStart.year, wStart.month, wStart.day)) &&
                  !inv.date.isAfter(DateTime(wEnd.year, wEnd.month, wEnd.day, 23, 59, 59)))
              .fold(0.0, (s, inv) => s + inv.total);
        }).toList();
        labels = weeks.map((d) => '${d.day}/${d.month}').toList();
        break;
      case _ChartGranularity.month:
        final months = List.generate(6, (i) => DateTime(now.year, now.month - (5 - i)));
        values = months
            .map((m) => invoices
                .where((inv) => inv.date.year == m.year && inv.date.month == m.month)
                .fold(0.0, (s, inv) => s + inv.total))
            .toList();
        const monthLabels = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
        labels = months.map((m) => monthLabels[m.month - 1]).toList();
        break;
    }

    final maxVal = values.fold(0.0, (a, b) => a > b ? a : b);
    return _ChartData(values: values, labels: labels, maxVal: maxVal);
  }

  Widget _overdueCard(int count, double amount) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DocumentsListScreen(docType: DocType.invoice, overdueOnly: true)),
      ),
      child: Card(
        color: count > 0 ? const Color(0xFFFBEFEC) : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: count > 0 ? AppColors.danger : AppColors.line),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('OVERDUE INVOICES',
                        style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w700,
                          color: count > 0 ? AppColors.danger : AppColors.inkSoft,
                        )),
                    const SizedBox(height: 4),
                    Text(
                      count == 0 ? 'None — you\'re all caught up' : '$count invoice${count == 1 ? '' : 's'} • ${formatRupees(amount)}',
                      style: TextStyle(fontWeight: FontWeight.w700, color: count > 0 ? AppColors.danger : AppColors.ink),
                    ),
                  ],
                ),
              ),
              if (count > 0) const Icon(Icons.chevron_right, color: AppColors.danger),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backupReminderBanner(DateTime? lastBackup) {
    final neverBackedUp = lastBackup == null;
    return Card(
      color: const Color(0xFFFFF6E5),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.backup_outlined, color: AppColors.rebar),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                neverBackedUp
                    ? 'You haven\'t backed up this device\'s data yet.'
                    : 'It\'s been over 30 days since your last backup.',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BackupScreen()));
                setState(() {});
              },
              child: const Text('Back up'),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _bannerDismissed = true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String count, String amount, {Color color = AppColors.ink}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label.toUpperCase(),
                style: const TextStyle(fontSize: 10.5, color: AppColors.inkSoft, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            if (count.isNotEmpty)
              Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            Text(amount, style: TextStyle(fontSize: count.isEmpty ? 18 : 12.5, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _ChartData {
  final List<double> values;
  final List<String> labels;
  final double maxVal;
  _ChartData({required this.values, required this.labels, required this.maxVal});
}
