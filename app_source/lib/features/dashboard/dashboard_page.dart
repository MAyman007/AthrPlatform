import 'package:athr/core/models/incident.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:athr/core/locator.dart';
import 'package:athr/core/services/firebase_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:ui';

import 'dashboard_viewmodel.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 75,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/athr_logo.png', height: 50),
            const SizedBox(width: 16),
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 22,
                color: Theme.of(
                  context,
                ).textTheme.bodyLarge?.color?.withOpacity(0.7),
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          // Alerts Button
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'New Alerts',
            onPressed: () => context.push('/dashboard/alerts'),
          ),
          // Incidents Button
          IconButton(
            icon: const Icon(Icons.list_alt_outlined),
            tooltip: 'All Incidents',
            onPressed: () => context.push('/dashboard/incidents'),
          ),
          const VerticalDivider(indent: 12, endIndent: 12),
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DashboardViewModel>().isLoading
                ? null
                : context.read<DashboardViewModel>().loadData(),
          ),
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/dashboard/settings');
            },
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final bool? didRequestLogout = await showDialog<bool>(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                      ),
                      TextButton(
                        child: const Text('Logout'),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                      ),
                    ],
                  );
                },
              );
              if (didRequestLogout == true) {
                locator<FirebaseService>().signOut();
              }
            },
          ),
        ],
      ),
      body: Consumer<DashboardViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.incidents.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: ${viewModel.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: viewModel.loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Key Metrics Section
                  Text(
                    'Overall Metrics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Wrap(
                    spacing: 16.0,
                    runSpacing: 16.0,
                    children: [
                      _MetricCard(
                        title: 'Total Incidents',
                        value: viewModel.totalIncidents.toString(),
                        icon: Icons.warning_amber_rounded,
                        color: Colors.orange,
                        onTap: () =>
                            context.push('/dashboard/details/total-incidents'),
                      ),
                      _MetricCard(
                        title: 'Leaked Credentials',
                        value: viewModel.totalLeakedCredentials.toString(),
                        icon: Icons.key_off_outlined,
                        color: Colors.red,
                        onTap: () => context.push(
                          '/dashboard/details/leaked-credentials',
                        ),
                      ),
                      _MetricCard(
                        title: 'Compromised Machines',
                        value: viewModel.totalCompromisedMachines.toString(),
                        icon: Icons.computer_outlined,
                        color: Colors.blue,
                        onTap: () => context.push(
                          '/dashboard/details/compromised-machines',
                        ),
                      ),
                      _MetricCard(
                        title: 'High Severity',
                        value: viewModel.highSeverityCount.toString(),
                        icon: Icons.security_update_warning,
                        color: Colors.purple,
                        onTap: () =>
                            context.push('/dashboard/details/high-severity'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 74),

                  // Use a LayoutBuilder to create a responsive layout for charts
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 800) {
                        // Wide layout: Charts side-by-side
                        return Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildSeverityChart(viewModel)),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: _buildDateChart(context, viewModel),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildCategoryChart(
                                    context,
                                    viewModel,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: _buildSourceChart(context, viewModel),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildCountryChart(context, viewModel),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: _buildUsernameChart(
                                    context,
                                    viewModel,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      } else {
                        // Narrow layout: Charts stacked
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSeverityChart(viewModel),
                            const SizedBox(height: 24),
                            _buildDateChart(context, viewModel),
                            const SizedBox(height: 24),
                            _buildCategoryChart(context, viewModel),
                            const SizedBox(height: 24),
                            _buildSourceChart(context, viewModel),
                            const SizedBox(height: 24),
                            _buildCountryChart(context, viewModel),
                            const SizedBox(height: 24),
                            _buildUsernameChart(context, viewModel),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeverityChart(DashboardViewModel viewModel) {
    return _ChartSection(
      title: 'Incidents by Severity',
      child: SizedBox(
        height: 250,
        child: _SeverityPieChart(viewModel: viewModel),
      ),
    );
  }

  Widget _buildDateChart(BuildContext context, DashboardViewModel viewModel) {
    return _ChartSection(
      title: 'Incidents Over Time',
      child: SizedBox(
        height: 250,
        width: double.infinity,
        child: _DateLineChart(
          data: viewModel.incidentsByDate,
          color: Colors.blueAccent,
          title: 'Incidents',
        ),
      ),
    );
  }

  Widget _buildCategoryChart(
    BuildContext context,
    DashboardViewModel viewModel,
  ) {
    return _ChartSection(
      title: 'Incidents by Category',
      child: SizedBox(
        height: 250,
        width: double.infinity,
        child: _VerticalBarChart(
          data: viewModel.incidentsByCategory,
          color: Theme.of(context).primaryColor,
          title: 'Categories',
          maxItems: null,
          baseOffset: 1.0,
          touchedOffset: 1.6,
          useGradient: true,
        ),
      ),
    );
  }

  Widget _buildSourceChart(BuildContext context, DashboardViewModel viewModel) {
    return _ChartSection(
      title: 'Top Leak Sources',
      child: SizedBox(
        height: 250,
        width: double.infinity,
        child: _VerticalBarChart(
          data: viewModel.incidentsBySource,
          color: Colors.teal,
          title: 'Sources',
        ),
      ),
    );
  }

  Widget _buildCountryChart(
    BuildContext context,
    DashboardViewModel viewModel,
  ) {
    return _ChartSection(
      title: 'Compromised Assets by Country',
      child: SizedBox(
        height: 250,
        width: double.infinity,
        child: _VerticalBarChart(
          data: viewModel.machinesByCountry,
          color: Colors.indigo,
          title: 'Countries',
        ),
      ),
    );
  }

  Widget _buildUsernameChart(
    BuildContext context,
    DashboardViewModel viewModel,
  ) {
    return _ChartSection(
      title: 'Top Affected User Accounts',
      child: SizedBox(
        height: 250,
        width: double.infinity,
        child: _VerticalBarChart(
          data: viewModel.incidentsByUsername,
          color: Colors.green,
          title: 'Usernames',
        ),
      ),
    );
  }
}

/// A legend widget for the severity pie chart.
class _SeverityLegend extends StatelessWidget {
  final Map<IncidentSeverity, int> incidentsBySeverity;

  const _SeverityLegend({required this.incidentsBySeverity});

  @override
  Widget build(BuildContext context) {
    // Sort severities for a consistent order in the legend.
    final sortedEntries = incidentsBySeverity.entries.toList()
      ..sort((a, b) => b.key.index.compareTo(a.key.index));

    if (sortedEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedEntries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Container(width: 16, height: 16, color: entry.key.color),
                  const SizedBox(width: 8),
                  Text(
                    // Capitalize the first letter of the severity name.
                    '${entry.key.name[0].toUpperCase()}${entry.key.name.substring(1)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

/// A pie chart that displays the distribution of incidents by severity.
class _SeverityPieChart extends StatefulWidget {
  final DashboardViewModel viewModel;

  const _SeverityPieChart({required this.viewModel});

  @override
  State<_SeverityPieChart> createState() => _SeverityPieChartState();
}

class _SeverityPieChartState extends State<_SeverityPieChart> {
  int? _touchedIndex;
  int? _lastTouchedIndex;
  bool _isTooltipHovered = false;
  Timer? _clearTimer;

  void _scheduleClearLastIndex([int ms = 220]) {
    _clearTimer?.cancel();
    _clearTimer = Timer(Duration(milliseconds: ms), () {
      if (!_isTooltipHovered && _touchedIndex == null) {
        setState(() {
          _lastTouchedIndex = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    if (viewModel.incidentsBySeverity.isEmpty) {
      return const Center(child: Text('No severity data available.'));
    }

    final entries = viewModel.incidentsBySeverity.entries.toList();

    final displayIndex = _touchedIndex ?? _lastTouchedIndex;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: entries.asMap().entries.map((mapEntry) {
                    final index = mapEntry.key;
                    final entry = mapEntry.value;
                    final severity = entry.key;
                    final count = entry.value;
                    final isTouched =
                        _touchedIndex == index ||
                        (_touchedIndex == null &&
                            _lastTouchedIndex == index &&
                            _isTooltipHovered);
                    return PieChartSectionData(
                      gradient: LinearGradient(
                        colors: [
                          severity.color.withOpacity(0.7),
                          severity.color,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      value: count.toDouble(),
                      title: count.toString(),
                      radius: isTouched ? 105 : 90,
                      titleStyle: TextStyle(
                        fontSize: isTouched ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 2),
                        ],
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 35,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          // user left the pie - clear active touch but keep last index so tooltip can be hovered
                          // preserve previous last index if available so tooltip remains visible while pointer moves to it
                          _lastTouchedIndex =
                              _lastTouchedIndex ?? _touchedIndex;
                          _touchedIndex = null;
                          // If tooltip is not hovered, schedule clearing; otherwise keep showing until tooltip exit.
                          if (!_isTooltipHovered) {
                            _scheduleClearLastIndex();
                          }
                        } else {
                          final idx = pieTouchResponse
                              .touchedSection!
                              .touchedSectionIndex;
                          _touchedIndex = idx >= 0 ? idx : null;
                          _lastTouchedIndex = _touchedIndex;
                          _clearTimer?.cancel();
                        }
                      });
                    },
                  ),
                ),
              ),
              if ((displayIndex != null) &&
                  displayIndex >= 0 &&
                  displayIndex < entries.length)
                Positioned(
                  top: 16,
                  child: MouseRegion(
                    onEnter: (_) {
                      setState(() {
                        _isTooltipHovered = true;
                        _clearTimer?.cancel();
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        _isTooltipHovered = false;
                      });
                      _scheduleClearLastIndex();
                    },
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildTooltip(entries[displayIndex]),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: _SeverityLegend(
            incidentsBySeverity: viewModel.incidentsBySeverity,
          ),
        ),
      ],
    );
  }

  Widget _buildTooltip(MapEntry<IncidentSeverity, int> entry) {
    final severity = entry.key;
    final count = entry.value;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: severity.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${severity.name[0].toUpperCase()}${severity.name.substring(1)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$count incident${count == 1 ? '' : 's'}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

/// A reusable vertical bar chart widget with hover/touch animations for Sources, Countries, Usernames and Categories.
class _VerticalBarChart extends StatefulWidget {
  final Map<String, int> data;
  final Color color;
  final String title;
  final int? maxItems; // null means show all items in insertion order
  final double
  baseOffset; // base vertical offset added to every bar (used by category chart)
  final double
  touchedOffset; // additional offset applied when bar is touched/hovered
  final bool useGradient; // whether to draw a gradient like the category chart

  const _VerticalBarChart({
    required this.data,
    required this.color,
    required this.title,
    this.maxItems = 10,
    this.baseOffset = 0.0,
    this.touchedOffset = 0.0,
    this.useGradient = false,
  });

  @override
  State<_VerticalBarChart> createState() => _VerticalBarChartState();
}

class _VerticalBarChartState extends State<_VerticalBarChart> {
  int? _touchedIndex;

  void _onTouch(FlTouchEvent event, BarTouchResponse? response) {
    setState(() {
      if (!event.isInterestedForInteractions ||
          response == null ||
          response.spot == null) {
        _touchedIndex = null;
      } else {
        _touchedIndex = response.spot!.touchedBarGroupIndex;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return Center(child: Text('No data available for ${widget.title}.'));
    }

    // Determine entries:
    // - If maxItems == null -> keep original insertion order and show all (used for categories)
    // - Otherwise sort descending and take top N
    final List<MapEntry<String, int>> entries = widget.maxItems == null
        ? widget.data.entries.toList()
        : (widget.data.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .take(widget.maxItems!)
              .toList();

    if (entries.isEmpty) {
      return Center(child: Text('No data available for ${widget.title}.'));
    }

    // Compute maxY based on mode
    final int maxValue = entries
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    final double maxY = widget.baseOffset > 0
        ? (maxValue.toDouble() + 3) // category-style padding
        : (maxValue.toDouble() * 1.2);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: _onTouch,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final entry = entries[groupIndex];
              final displayedValue = (rod.toY - widget.baseOffset)
                  .round()
                  .clamp(0, 1 << 30);
              return BarTooltipItem(
                '${entry.key}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text:
                        '$displayedValue incident${displayedValue == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < entries.length) {
                  return SideTitleWidget(
                    meta: meta,
                    space: 8.0,
                    child: Text(
                      entries[index].key,
                      style: const TextStyle(fontSize: 10),
                      overflow: widget.maxItems == null
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                  );
                }
                return Container();
              },
              reservedSize: 60,
            ),
          ),
          leftTitles: widget.baseOffset > 0
              ? AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value == 0 || value == meta.max) {
                        return Container();
                      }
                      return Text(
                        (value - widget.baseOffset).toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.left,
                      );
                    },
                  ),
                )
              : const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: entries.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final isTouched = _touchedIndex == index;
          final baseWidth = 16.0;
          final width = isTouched ? baseWidth + 8 : baseWidth;
          final double toY =
              data.value.toDouble() +
              (isTouched ? widget.touchedOffset : widget.baseOffset);

          final rod = widget.useGradient
              ? BarChartRodData(
                  toY: toY,
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withOpacity(isTouched ? 0.95 : 0.72),
                      widget.color.withOpacity(1.0),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: width,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                )
              : BarChartRodData(
                  toY: toY,
                  color: isTouched
                      ? widget.color.withOpacity(0.95)
                      : widget.color,
                  width: width,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                );

          return BarChartGroupData(x: index, barRods: [rod]);
        }).toList(),
      ),
      duration: const Duration(milliseconds: 120),
    );
  }
}

/// A reusable line chart widget for time-series data.
class _DateLineChart extends StatefulWidget {
  final Map<DateTime, int> data;
  final Color color;
  final String title;

  const _DateLineChart({
    required this.data,
    required this.color,
    required this.title,
  });

  @override
  State<_DateLineChart> createState() => _DateLineChartState();
}

class _DateLineChartState extends State<_DateLineChart>
    with TickerProviderStateMixin {
  int? _touchedIndex;
  late final AnimationController _hoverController;
  late final Animation<double> _hoverCurve;
  late final AnimationController _rippleController;
  double get _rippleProgress => _rippleController.value;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _hoverCurve =
        CurvedAnimation(
          parent: _hoverController,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        )..addListener(() {
          // rebuild to reflect hover animation progress
          setState(() {});
        });

    _rippleController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 700),
          )
          ..addListener(() {
            // rebuild to reflect ripple progress
            setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              // reset so ripple can be triggered again
              _rippleController.reset();
            }
          });
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  double get _hoverProgress => _hoverCurve.value;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final color = widget.color;
    final title = widget.title;

    if (data.isEmpty) {
      return Center(child: Text('No data available for $title.'));
    }

    // Sort data by date
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = sortedEntries
        .map(
          (entry) => FlSpot(
            entry.key.millisecondsSinceEpoch.toDouble(),
            entry.value.toDouble(),
          ),
        )
        .toList();

    // animated visual tuning driven by hover progress (reduced glow)
    final double topAreaOpacity = lerpDouble(0.3, 0.6, _hoverProgress) ?? 0.3;
    final double bottomAreaOpacity =
        lerpDouble(0.0, 0.12, _hoverProgress) ?? 0.0;
    final Color animatedDotColor =
        Color.lerp(
          color,
          Colors.white,
          (_hoverProgress * 0.45).clamp(0.0, 1.0),
        ) ??
        color;

    // Defensive interval computation (avoid division by zero)
    final double? interval = spots.length > 1
        ? (spots.last.x - spots.first.x) / 4
        : null;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: interval,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return SideTitleWidget(
                  meta: meta,
                  space: 8.0,
                  child: Text(
                    DateFormat.MMM().format(date),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Glow layer (drawn under the main line) — appears on hover to create a soft bloom
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                (Color.lerp(color, Colors.white, 0.5) ?? color).withOpacity(
                  0.06 * _hoverProgress,
                ),
                (Color.lerp(color, Colors.white, 0.9) ?? color).withOpacity(
                  0.03 * _hoverProgress,
                ),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            barWidth: lerpDouble(0, 12, _hoverProgress) ?? 0,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(
                    lerpDouble(0.01, topAreaOpacity, _hoverProgress) ?? 0.01,
                  ),
                  color.withOpacity(
                    lerpDouble(0.0, bottomAreaOpacity, _hoverProgress) ?? 0.0,
                  ),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Main line (interactive)
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                color.withOpacity(lerpDouble(0.3, 0.65, _hoverProgress) ?? 0.5),
                (Color.lerp(
                      color,
                      Colors.white,
                      (_hoverProgress * 0.35).clamp(0.0, 1.0),
                    ) ??
                    color),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            barWidth: lerpDouble(5, 10, _hoverProgress) ?? 5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, idx) {
                final isActive = _touchedIndex != null && _touchedIndex == idx;
                final double animatedRadius = isActive
                    ? (lerpDouble(6, 14, _hoverProgress) ?? 8)
                    : 0;
                final double animatedStroke = isActive
                    ? (lerpDouble(2, 8, _hoverProgress) ?? 2)
                    : 0;
                if (!isActive) {
                  // invisible dot for non-active points
                  return FlDotCirclePainter(
                    radius: 0,
                    color: Colors.transparent,
                    strokeWidth: 0,
                  );
                }
                // Animated filled dot with stronger halo; radius/stroke driven by hover curve
                return FlDotCirclePainter(
                  radius: animatedRadius,
                  color: animatedDotColor,
                  strokeWidth: animatedStroke,
                  strokeColor: animatedDotColor.withOpacity(0.95),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(topAreaOpacity),
                  color.withOpacity(bottomAreaOpacity),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            if (!event.isInterestedForInteractions ||
                response == null ||
                response.lineBarSpots == null ||
                response.lineBarSpots!.isEmpty) {
              // clear active touch and reverse hover animation
              setState(() {
                _touchedIndex = null;
              });
              _hoverController.reverse();
            } else {
              final newIndex = response.lineBarSpots!.first.spotIndex;
              setState(() {
                _touchedIndex = newIndex;
              });
              _hoverController.forward();
              // trigger ripple animation each time a new point is hovered/tapped
              _rippleController.forward(from: 0.0);
            }
          },
          getTouchedSpotIndicator: (barData, indicators) {
            return indicators.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(color: Colors.white24, strokeWidth: 1),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, idx) {
                    final isActive =
                        _touchedIndex != null && _touchedIndex == idx;
                    final double baseRadius = isActive
                        ? (lerpDouble(6, 12, _hoverProgress) ?? 8)
                        : 4;
                    final double baseStroke = isActive
                        ? (lerpDouble(2, 6, _hoverProgress) ?? 2)
                        : 1;
                    // ripple expands and fades using _rippleProgress
                    final double rippleRadius =
                        (lerpDouble(
                          baseRadius,
                          baseRadius + 28,
                          _rippleProgress,
                        ) ??
                        baseRadius);
                    final double rippleStroke =
                        (lerpDouble(
                          baseStroke,
                          baseStroke + 8,
                          _rippleProgress,
                        ) ??
                        baseStroke);
                    final double rippleOpacity =
                        (1.0 - _rippleProgress).clamp(0.0, 1.0) *
                        (isActive ? 0.95 : 0.5);
                    // Draw only the expanding ring here. The main filled dot is drawn by the line's dotData.
                    return FlDotCirclePainter(
                      radius: rippleRadius,
                      color: Colors.transparent,
                      strokeWidth: rippleStroke,
                      strokeColor: animatedDotColor.withOpacity(rippleOpacity),
                    );
                  },
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.blueGrey.withOpacity(0.8),
            getTooltipItems: (touchedSpots) {
              // We MUST return a list of the same size as touchedSpots.
              // We will map [spot0, spot1] to [null, tooltipItem1]
              return touchedSpots.map((spot) {
                // Check the barIndex.
                if (spot.barIndex == 0) {
                  // This is the "Glow" line, return null to show nothing
                  return null;
                }

                // This is the "Main" line (barIndex 1)
                final date = DateTime.fromMillisecondsSinceEpoch(
                  spot.x.toInt(),
                );

                return LineTooltipItem(
                  '${DateFormat.yMMM().format(date)}\n${spot.y.toInt()} incidents',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

/// A reusable horizontal bar chart widget.
// class _HorizontalBarChart extends StatelessWidget {
//   final Map<String, int> data;
//   final Color barColor;
//   final String title;

//   const _HorizontalBarChart({
//     required this.data,
//     required this.barColor,
//     required this.title,
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (data.isEmpty) {
//       return Center(child: Text('No data available for $title.'));
//     }

//     // Sort data to show the highest values on top and take top 10
//     final sortedEntries = data.entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));
//     final topEntries = sortedEntries
//         .take(10)
//         .toList()
//         .reversed
//         .toList(); // Reverse for chart

//     final double maxY =
//         topEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2;

//     return BarChart(
//       BarChartData(
//         alignment: BarChartAlignment.spaceAround,
//         maxY: maxY,
//         barTouchData: BarTouchData(
//           enabled: true,
//           touchTooltipData: BarTouchTooltipData(
//             getTooltipColor: (group) => Colors.blueGrey,
//             getTooltipItem: (group, groupIndex, rod, rodIndex) {
//               final entry = topEntries[groupIndex];
//               return BarTooltipItem(
//                 '${entry.key}\n',
//                 const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14,
//                 ),
//                 children: <TextSpan>[
//                   TextSpan(
//                     text:
//                         '${entry.value} incident${entry.value == 1 ? '' : 's'}',
//                     style: const TextStyle(
//                       color: Colors.yellow,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),
//         ),
//         titlesData: FlTitlesData(
//           show: true,
//           leftTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               getTitlesWidget: (double value, TitleMeta meta) {
//                 final index = value.toInt();
//                 if (index >= 0 && index < topEntries.length) {
//                   return SideTitleWidget(
//                     meta: meta,
//                     space: 8.0,
//                     child: Text(
//                       topEntries[index].key,
//                       style: const TextStyle(fontSize: 10),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   );
//                 }
//                 return Container();
//               },
//               reservedSize: 100,
//             ),
//           ),
//           bottomTitles: const AxisTitles(
//             sideTitles: SideTitles(showTitles: false),
//           ),
//           topTitles: const AxisTitles(
//             sideTitles: SideTitles(showTitles: false),
//           ),
//           rightTitles: const AxisTitles(
//             sideTitles: SideTitles(showTitles: false),
//           ),
//         ),
//         borderData: FlBorderData(show: false),
//         barGroups: topEntries.asMap().entries.map((entry) {
//           final index = entry.key;
//           final data = entry.value;
//           return BarChartGroupData(
//             x: index,
//             barRods: [
//               BarChartRodData(
//                 toY: data.value.toDouble(),
//                 color: barColor,
//                 width: 12,
//                 borderRadius: BorderRadius.circular(4),
//               ),
//             ],
//           );
//         }).toList(),
//         gridData: const FlGridData(show: false),
//       ),
//       swapAnimationDuration: const Duration(milliseconds: 150),
//     );
//   }
// }

/// A styled container for a chart with a title.
class _ChartSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

/// A reusable card widget for displaying a key metric.
class _MetricCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MetricCard({
    // ignore: unused_element
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  State<_MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<_MetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final duration = const Duration(milliseconds: 200);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: duration,
          width: 220,
          transform: Matrix4.translationValues(0, _isHovered ? -5 : 0, 0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: widget.color, width: 5)),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_isHovered ? 0.2 : 0.05),
                blurRadius: _isHovered ? 15 : 10,
                offset: _isHovered ? const Offset(0, 8) : const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(widget.icon, size: 32, color: widget.color),
              const SizedBox(height: 16),
              Text(
                widget.value,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.title,
                style: textTheme.bodyMedium?.copyWith(
                  color: textTheme.bodySmall?.color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
