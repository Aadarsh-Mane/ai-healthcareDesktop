import 'package:flutter/material.dart';
import 'package:doctordesktop/files/theme.dart';

void main() => runApp(const HmsApp());

class HmsApp extends StatelessWidget {
  const HmsApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'HMS — OPD Dashboard',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const OpdDashboardScreen(),
      );
}

// ── Data models ──────────────────────────────────────────────────────────────
class Patient {
  final String token, name, age, gender, department, doctor, waitMins, status;
  const Patient({
    required this.token,
    required this.name,
    required this.age,
    required this.gender,
    required this.department,
    required this.doctor,
    required this.waitMins,
    required this.status,
  });
}

const _patients = [
  Patient(
      token: '#001',
      name: 'Aarav Mehta',
      age: '34',
      gender: 'M',
      department: 'Cardiology',
      doctor: 'Dr. Priya Nair',
      waitMins: '5',
      status: 'In Consultation'),
  Patient(
      token: '#002',
      name: 'Sunita Deshpande',
      age: '52',
      gender: 'F',
      department: 'Orthopedics',
      doctor: 'Dr. Rohan Desai',
      waitMins: '18',
      status: 'Waiting'),
  Patient(
      token: '#003',
      name: 'Kiran Patil',
      age: '28',
      gender: 'M',
      department: 'Dermatology',
      doctor: 'Dr. Anjali Shah',
      waitMins: '32',
      status: 'Waiting'),
  Patient(
      token: '#004',
      name: 'Meena Iyer',
      age: '61',
      gender: 'F',
      department: 'Neurology',
      doctor: 'Dr. Vikram Joshi',
      waitMins: '45',
      status: 'Waiting'),
  Patient(
      token: '#005',
      name: 'Rahul Sharma',
      age: '19',
      gender: 'M',
      department: 'General',
      doctor: 'Dr. Priya Nair',
      waitMins: '52',
      status: 'Waiting'),
  Patient(
      token: '#006',
      name: 'Geeta Kulkarni',
      age: '44',
      gender: 'F',
      department: 'Gynecology',
      doctor: 'Dr. Anjali Shah',
      waitMins: '0',
      status: 'Completed'),
  Patient(
      token: '#007',
      name: 'Suresh Bhat',
      age: '38',
      gender: 'M',
      department: 'ENT',
      doctor: 'Dr. Rohan Desai',
      waitMins: '0',
      status: 'Completed'),
];

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

const _navItems = [
  _NavItem(Icons.dashboard_rounded, 'Dashboard'),
  _NavItem(Icons.people_alt_rounded, 'Patients'),
  _NavItem(Icons.calendar_month_rounded, 'OPD Queue'),
  _NavItem(Icons.bed_rounded, 'IPD'),
  _NavItem(Icons.science_rounded, 'Laboratory'),
  _NavItem(Icons.medication_rounded, 'Pharmacy'),
  _NavItem(Icons.receipt_long_rounded, 'Billing'),
  _NavItem(Icons.bar_chart_rounded, 'Reports'),
  _NavItem(Icons.settings_rounded, 'Settings'),
];

// ── Main Screen ──────────────────────────────────────────────────────────────
class OpdDashboardScreen extends StatefulWidget {
  const OpdDashboardScreen({super.key});
  @override
  State<OpdDashboardScreen> createState() => _OpdDashboardScreenState();
}

class _OpdDashboardScreenState extends State<OpdDashboardScreen> {
  int _selectedNav = 2;
  Patient? _selected = _patients[0];
  String _filterStatus = 'All';

  List<Patient> get _filtered => _filterStatus == 'All'
      ? _patients
      : _patients.where((p) => p.status == _filterStatus).toList();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.pageBg,
        body: Row(children: [
          _Sidebar(
              selected: _selectedNav,
              onTap: (i) => setState(() => _selectedNav = i)),
          Expanded(
            child: Column(children: [
              _TopBar(),
              Expanded(
                child: Row(children: [
                  Expanded(
                    child: _MainContent(
                      filter: _filterStatus,
                      patients: _filtered,
                      selectedPatient: _selected,
                      onFilterChange: (f) => setState(() => _filterStatus = f),
                      onPatientTap: (p) => setState(() => _selected = p),
                    ),
                  ),
                  if (_selected != null)
                    _PatientPanel(
                      patient: _selected!,
                      onClose: () => setState(() => _selected = null),
                    ),
                ]),
              ),
            ]),
          ),
        ]),
      );
}

// ── Sidebar ──────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _Sidebar({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        width: AppSpacing.sidebarWidth,
        color: AppColors.sectionBg,
        child: Column(children: [
          // Logo
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s20, vertical: 18),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border))),
            child: Row(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.md)),
                child: const Icon(Icons.local_hospital_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('MediCare', style: AppTypography.headingXs),
                Text('HMS v2.0', style: AppTypography.bodyXs),
              ]),
            ]),
          ),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.s12, horizontal: AppSpacing.s10),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 6, top: 4),
                  child: Text('MAIN MENU', style: AppTypography.overline),
                ),
                ...List.generate(
                    _navItems.length,
                    (i) => _SidebarItem(
                          icon: _navItems[i].icon,
                          label: _navItems[i].label,
                          isSelected: selected == i,
                          onTap: () => onTap(i),
                        )),
              ],
            ),
          ),

          // Doctor card
          Container(
            margin: const EdgeInsets.all(AppSpacing.s12),
            padding: const EdgeInsets.all(AppSpacing.s12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primarySurface,
                child: Text('PN',
                    style: AppTypography.labelSm
                        .copyWith(color: AppColors.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Dr. Priya Nair', style: AppTypography.labelMd),
                    Text('Cardiologist', style: AppTypography.bodyXs),
                  ])),
              const Icon(Icons.more_vert_rounded,
                  color: AppColors.textSecondary, size: 16),
            ]),
          ),
        ]),
      );
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _SidebarItem(
      {required this.icon,
      required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Material(
          color: isSelected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s12, vertical: AppSpacing.s10),
              decoration: isSelected
                  ? const BoxDecoration(
                      border: Border(
                          left: BorderSide(color: AppColors.primary, width: 3)),
                      borderRadius:
                          BorderRadius.all(Radius.circular(AppRadius.md)),
                    )
                  : null,
              child: Row(children: [
                Icon(icon,
                    size: 18,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary),
                const SizedBox(width: 10),
                Text(label,
                    style: AppTypography.bodyMd.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    )),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle)),
                ],
              ]),
            ),
          ),
        ),
      );
}

// ── Top Bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: AppSpacing.topBarHeight,
        color: AppColors.background,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(children: [
          Text('OPD',
              style: AppTypography.bodyMd
                  .copyWith(color: AppColors.textSecondary)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('/',
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.textDisabled)),
          ),
          Text('Queue Management', style: AppTypography.labelLg),
          const Spacer(),

          // Search
          Container(
            width: 220,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.pageBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(children: [
              SizedBox(width: 10),
              Icon(Icons.search_rounded,
                  size: 16, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Expanded(
                  child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search patients...',
                  border: InputBorder.none,
                  hintStyle:
                      TextStyle(fontSize: 13, color: AppColors.textDisabled),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(fontSize: 13),
              )),
            ]),
          ),
          const SizedBox(width: 12),

          // Notification
          Stack(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppRadius.md)),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 18, color: AppColors.textSecondary),
            ),
            Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.danger, shape: BoxShape.circle),
                )),
          ]),
          const SizedBox(width: 10),

          // Date chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Row(children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(_todayDate(),
                  style:
                      AppTypography.labelSm.copyWith(color: AppColors.primary)),
            ]),
          ),
        ]),
      );

  String _todayDate() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

// ── Main Content ─────────────────────────────────────────────────────────────
class _MainContent extends StatelessWidget {
  final String filter;
  final List<Patient> patients;
  final Patient? selectedPatient;
  final ValueChanged<String> onFilterChange;
  final ValueChanged<Patient> onPatientTap;

  const _MainContent({
    required this.filter,
    required this.patients,
    required this.selectedPatient,
    required this.onFilterChange,
    required this.onPatientTap,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Stats row
          Row(children: [
            _StatCard(
                label: 'Total Today',
                value: '127',
                icon: Icons.people_alt_rounded,
                color: AppColors.primary,
                bg: AppColors.primaryLight),
            const SizedBox(width: AppSpacing.cardGap),
            _StatCard(
                label: 'In Consultation',
                value: '8',
                icon: Icons.medical_services_rounded,
                color: AppColors.info,
                bg: AppColors.infoLight),
            const SizedBox(width: AppSpacing.cardGap),
            _StatCard(
                label: 'Waiting',
                value: '34',
                icon: Icons.hourglass_top_rounded,
                color: AppColors.warning,
                bg: AppColors.warningLight),
            const SizedBox(width: AppSpacing.cardGap),
            _StatCard(
                label: 'Completed',
                value: '85',
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                bg: AppColors.successLight),
          ]),
          const SizedBox(height: AppSpacing.sectionGap),

          // Queue header row
          Row(children: [
            Text('OPD Queue', style: AppTypography.headingSm),
            const Spacer(),
            _FilterChip(
                label: 'All',
                selected: filter == 'All',
                onTap: () => onFilterChange('All')),
            const SizedBox(width: AppSpacing.s8),
            _FilterChip(
                label: 'Waiting',
                selected: filter == 'Waiting',
                onTap: () => onFilterChange('Waiting')),
            const SizedBox(width: AppSpacing.s8),
            _FilterChip(
                label: 'In Consultation',
                selected: filter == 'In Consultation',
                onTap: () => onFilterChange('In Consultation')),
            const SizedBox(width: AppSpacing.s8),
            _FilterChip(
                label: 'Completed',
                selected: filter == 'Completed',
                onTap: () => onFilterChange('Completed')),
            const SizedBox(width: 12),
            _AddButton(),
          ]),
          const SizedBox(height: 14),

          // Table
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              _TableHeader(),
              ...patients.asMap().entries.map((e) => _PatientRow(
                    patient: e.value,
                    isSelected: selectedPatient?.token == e.value.token,
                    isLast: e.key == patients.length - 1,
                    onTap: () => onPatientTap(e.value),
                  )),
            ]),
          ),
        ]),
      );
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, bg;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.bg});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: AppTypography.bodyXs
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: AppTypography.headingXl),
            ]),
          ]),
        ),
      );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.surface,
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(label,
              style: AppTypography.labelSm.copyWith(
                color: selected ? AppColors.primary : AppColors.textSecondary,
              )),
        ),
      );
}

class _AddButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 34,
        child: Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text('Add Patient',
                    style: AppTypography.labelMd.copyWith(color: Colors.white)),
              ]),
            ),
          ),
        ),
      );
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.sectionBg,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppRadius.lg),
              topRight: Radius.circular(AppRadius.lg)),
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: const Row(children: [
          _TH(label: 'Token', flex: 1),
          _TH(label: 'Patient', flex: 3),
          _TH(label: 'Department', flex: 2),
          _TH(label: 'Doctor', flex: 3),
          _TH(label: 'Wait', flex: 1),
          _TH(label: 'Status', flex: 2),
          _TH(label: '', flex: 1),
        ]),
      );
}

class _TH extends StatelessWidget {
  final String label;
  final int flex;
  const _TH({required this.label, required this.flex});
  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(label, style: AppTypography.overline),
      );
}

class _PatientRow extends StatefulWidget {
  final Patient patient;
  final bool isSelected, isLast;
  final VoidCallback onTap;
  const _PatientRow(
      {required this.patient,
      required this.isSelected,
      required this.isLast,
      required this.onTap});
  @override
  State<_PatientRow> createState() => _PatientRowState();
}

class _PatientRowState extends State<_PatientRow> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16, vertical: 13),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.primaryLight
                  : _hovered
                      ? AppColors.surfaceHover
                      : AppColors.surface,
              border: !widget.isLast
                  ? const Border(bottom: BorderSide(color: AppColors.border))
                  : null,
              borderRadius: widget.isLast
                  ? const BorderRadius.only(
                      bottomLeft: Radius.circular(AppRadius.lg),
                      bottomRight: Radius.circular(AppRadius.lg))
                  : null,
            ),
            child: Row(children: [
              Expanded(
                  flex: 1,
                  child: Text(widget.patient.token,
                      style: AppTypography.labelMd
                          .copyWith(color: AppColors.primary))),
              Expanded(
                  flex: 3,
                  child: Row(children: [
                    CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primarySurface,
                        child: Text(widget.patient.name[0],
                            style: AppTypography.labelSm
                                .copyWith(color: AppColors.primary))),
                    const SizedBox(width: 8),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.patient.name,
                              style: AppTypography.labelMd),
                          Text(
                              '${widget.patient.age}y · ${widget.patient.gender}',
                              style: AppTypography.bodyXs),
                        ]),
                  ])),
              Expanded(
                  flex: 2,
                  child: Text(widget.patient.department,
                      style: AppTypography.bodyMd)),
              Expanded(
                  flex: 3,
                  child: Text(widget.patient.doctor,
                      style: AppTypography.bodyMd
                          .copyWith(color: AppColors.textSecondary))),
              Expanded(
                  flex: 1,
                  child: widget.patient.status == 'Completed'
                      ? Text('—',
                          style: AppTypography.bodyMd
                              .copyWith(color: AppColors.textDisabled))
                      : Row(children: [
                          const Icon(Icons.access_time_rounded,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text('${widget.patient.waitMins}m',
                              style: AppTypography.bodySm),
                        ])),
              Expanded(
                  flex: 2, child: _StatusBadge(status: widget.patient.status)),
              Expanded(
                  flex: 1,
                  child: Row(children: [
                    _RowIcon(
                        icon: Icons.visibility_rounded, onTap: widget.onTap),
                    const SizedBox(width: 4),
                    _RowIcon(icon: Icons.more_horiz_rounded, onTap: () {}),
                  ])),
            ]),
          ),
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg, fg;
    final IconData icon;
    switch (status) {
      case 'In Consultation':
        bg = AppColors.infoLight;
        fg = const Color(0xFF1D4ED8);
        icon = Icons.medical_services_rounded;
        break;
      case 'Completed':
        bg = AppColors.successLight;
        fg = const Color(0xFF15803D);
        icon = Icons.check_circle_rounded;
        break;
      default:
        bg = AppColors.warningLight;
        fg = const Color(0xFFB45309);
        icon = Icons.hourglass_top_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: fg),
        const SizedBox(width: 4),
        Text(status,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
      ]),
    );
  }
}

class _RowIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RowIcon({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 15, color: AppColors.textSecondary),
          ),
        ),
      );
}

// ── Patient Detail Panel ──────────────────────────────────────────────────────
class _PatientPanel extends StatelessWidget {
  final Patient patient;
  final VoidCallback onClose;
  const _PatientPanel({required this.patient, required this.onClose});

  @override
  Widget build(BuildContext context) => Container(
        width: 300,
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(left: BorderSide(color: AppColors.border)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s20, vertical: AppSpacing.s16),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border))),
            child: Row(children: [
              Text('Patient Details', style: AppTypography.headingXs),
              const Spacer(),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textSecondary),
              ),
            ]),
          ),

          Expanded(
              child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Avatar + name
              Center(
                  child: Column(children: [
                CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(patient.name[0],
                        style: AppTypography.headingLg
                            .copyWith(color: AppColors.primary))),
                const SizedBox(height: 12),
                Text(patient.name, style: AppTypography.headingSm),
                const SizedBox(height: 4),
                Text('Token ${patient.token}', style: AppTypography.bodySm),
                const SizedBox(height: 8),
                _StatusBadge(status: patient.status),
              ])),
              const SizedBox(height: AppSpacing.s24),

              _PanelSection(title: 'Patient Info', items: [
                _InfoRow(label: 'Age', value: '${patient.age} years'),
                _InfoRow(
                    label: 'Gender',
                    value: patient.gender == 'M' ? 'Male' : 'Female'),
                _InfoRow(label: 'Visit', value: 'OPD'),
              ]),
              const SizedBox(height: AppSpacing.s20),

              _PanelSection(title: 'Appointment', items: [
                _InfoRow(label: 'Department', value: patient.department),
                _InfoRow(label: 'Doctor', value: patient.doctor),
                _InfoRow(
                    label: 'Wait Time',
                    value: patient.status == 'Completed'
                        ? 'Done'
                        : '${patient.waitMins} min'),
              ]),
              const SizedBox(height: AppSpacing.s20),

              _PanelSection(title: 'Vitals', items: [
                _InfoRow(label: 'BP', value: '122/80 mmHg'),
                _InfoRow(label: 'Temp', value: '98.6 °F'),
                _InfoRow(label: 'SpO2', value: '98%'),
                _InfoRow(label: 'Pulse', value: '72 bpm'),
              ]),
              const SizedBox(height: AppSpacing.s24),

              SizedBox(
                  width: double.infinity,
                  child: _PrimaryButton(
                      label: 'Start Consultation',
                      icon: Icons.play_arrow_rounded,
                      onTap: () {})),
              const SizedBox(height: AppSpacing.s8),
              SizedBox(
                  width: double.infinity,
                  child: _OutlineButton(
                      label: 'View Full Record',
                      icon: Icons.folder_open_rounded,
                      onTap: () {})),
              const SizedBox(height: AppSpacing.s8),
              SizedBox(
                  width: double.infinity,
                  child: _OutlineButton(
                      label: 'Print Token',
                      icon: Icons.print_rounded,
                      onTap: () {})),
            ]),
          )),
        ]),
      );
}

class _PanelSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _PanelSection({required this.title, required this.items});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTypography.overline),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.pageBg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: items),
        ),
      ]);
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s14, vertical: AppSpacing.s10),
        decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: AppColors.border, width: 0.5))),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: AppTypography.bodySm),
          Text(value, style: AppTypography.labelMd),
        ]),
      );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryButton(
      {required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: AppSpacing.buttonPaddingAll,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(label,
                  style: AppTypography.labelLg.copyWith(color: Colors.white)),
            ]),
          ),
        ),
      );
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _OutlineButton(
      {required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: AppSpacing.buttonPaddingAll,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Text(label, style: AppTypography.labelMd),
            ]),
          ),
        ),
      );
}
