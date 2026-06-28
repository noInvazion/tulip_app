import 'package:flutter/material.dart';
import '../models/tulip_case.dart';
import '../screens/dashboard_screen.dart';
import '../screens/worklist_screen.dart';
import '../screens/intake_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/model_settings_screen.dart';
import '../screens/audit_log_screen.dart';
import '../screens/case_detail_panel.dart';
import 'sidebar.dart';
import 'top_bar.dart';

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _navIndex = 0;
  TulipCase? _selectedCase;
  TulipCase? _lastAddedCase;
  late final List<TulipCase> _cases = List.of(mockCases);

  static int _urgency(CaseStatus s) {
    switch (s) {
      case CaseStatus.urgent:  return 3;
      case CaseStatus.review:  return 2;
      case CaseStatus.pending: return 1;
      case CaseStatus.cleared: return 0;
    }
  }

  List<TulipCase> get _sorted {
    final list = List<TulipCase>.of(_cases);
    list.sort((a, b) {
      final tier = _urgency(b.status).compareTo(_urgency(a.status));
      return tier != 0 ? tier : b.confidence.compareTo(a.confidence);
    });
    return list;
  }

  final List<AuditEntry> _auditEntries = [];

  void _addCase(TulipCase c) => setState(() { _cases.add(c); _lastAddedCase = c; });

  // Model-suggested BI-RADS per scenario (used to detect overrides)
  static int _modelBirads(TulipCase c) => switch (c.scenarioIndex ?? 0) {
    1 => 1,
    2 => 3,
    _ => 4,
  };

  static CaseStatus _biradStatus(int b) => switch (b) {
    1 || 2 => CaseStatus.cleared,
    3      => CaseStatus.review,
    _      => CaseStatus.urgent,
  };

  void _signOffCase(TulipCase c, int birads, String rec, String notes) {
    final now = DateTime.now();
    final hh  = now.hour.toString().padLeft(2, '0');
    final mm  = now.minute.toString().padLeft(2, '0');
    final isOverride = birads != _modelBirads(c);
    final detail = isOverride
        ? 'BI-RADS ${_modelBirads(c)} → $birads · $rec'
        : 'BI-RADS $birads confirmed · $rec';

    setState(() {
      _cases.remove(c);
      _auditEntries.insert(0, AuditEntry(
        caseId:      c.id,
        demographics: c.demographics,
        action:      'Signed off',
        detail:      detail,
        radiologist: 'Dr. Okafor',
        timestamp:   'Today, $hh:$mm',
        status:      _biradStatus(birads),
        override:    isOverride,
      ));
    });
  }

  final List<NavItem> _navItems = const [
    NavItem(label: 'Dashboard',      icon: Icons.home_outlined,        activeIcon: Icons.home_rounded),
    NavItem(label: 'Worklist',       icon: Icons.list_alt_outlined,    activeIcon: Icons.list_alt_rounded,  badge: '3'),
    NavItem(label: 'New intake',     icon: Icons.add_circle_outline,   activeIcon: Icons.add_circle_rounded),
    NavItem(label: 'Analytics',      icon: Icons.show_chart_rounded,   activeIcon: Icons.show_chart_rounded),
    NavItem(label: 'Model settings', icon: Icons.settings_outlined,    activeIcon: Icons.settings_rounded),
    NavItem(label: 'Audit log',      icon: Icons.description_outlined, activeIcon: Icons.description_rounded),
  ];

  void _openCase(TulipCase c) => setState(() => _selectedCase = c);
  void _closeCase()           => setState(() => _selectedCase = null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            items: _navItems,
            selectedIndex: _navIndex,
            onSelect: (i) => setState(() { _navIndex = i; _selectedCase = null; }),
          ),
          Expanded(
            child: Column(
              children: [
                TopBar(
                  screenTitles: const [
                    'Dashboard', 'Worklist', 'New intake', 'Analytics',
                    'Model settings', 'Audit log',
                  ],
                  index: _navIndex,
                ),
                Expanded(
                  child: Stack(
                    children: [
                      IndexedStack(
                        index: _navIndex,
                        children: [
                          DashboardScreen(onOpenCase: _openCase, cases: _sorted),
                          WorklistScreen(
                            onOpenCase: _openCase,
                            cases: _sorted,
                            onNewIntake: () => setState(() => _navIndex = 2),
                          ),
                          IntakeScreen(
                            onIntakeComplete: _addCase,
                            onViewInWorklist: () => setState(() {
                              _navIndex = 1;
                              _selectedCase = _lastAddedCase;
                            }),
                          ),
                          const AnalyticsScreen(),
                          const ModelSettingsScreen(),
                          AuditLogScreen(liveEntries: _auditEntries),
                        ],
                      ),
                      if (_selectedCase != null) ...[
                        GestureDetector(
                          onTap: _closeCase,
                          child: Container(color: Colors.black26),
                        ),
                        Positioned(
                          top: 0, bottom: 0, right: 0,
                          width: 860,
                          child: CaseDetailPanel(
                            tulipCase: _selectedCase!,
                            onClose: _closeCase,
                            onSignOff: (birads, rec, notes) =>
                                _signOffCase(_selectedCase!, birads, rec, notes),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
