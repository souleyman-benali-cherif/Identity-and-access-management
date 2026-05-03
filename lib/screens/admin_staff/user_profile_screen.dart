import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/person_model.dart';
import '../../../models/student_model.dart';
import '../../../models/faculty_model.dart';
import '../../../models/staff_model.dart';
import '../../../models/contractor_model.dart';
import '../../../models/status_history_model.dart';
import '../../../models/modification_log_model.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String personId;
  const UserProfileScreen({super.key, required this.personId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  PersonModel? _person;
  StudentModel? _student;
  FacultyModel? _faculty;
  StaffModel? _staff;
  ContractorModel? _contractor;

  List<StatusHistoryModel> _statusHistory = [];
  List<ModificationLogModel> _modificationLog = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final idService = ref.read(identityServiceProvider);

    final person = await idService.getPersonById(widget.personId);
    if (person == null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('User not found.')));
        context.pop();
      }
      return;
    }

    final statusHist = await idService.getStatusHistory(widget.personId);
    final modLog = await idService.getModificationLog(widget.personId);

    // Load type specific data
    StudentModel? student;
    FacultyModel? faculty;
    StaffModel? staff;
    ContractorModel? contractor;

    if (person.userType.contains('Student') ||
        person.userType == 'Undergraduate' ||
        person.userType == 'PhD' ||
        person.userType == 'International' ||
        person.userType == 'ContinuingEducation') {
      student = await idService.getStudent(person.uniqueId);
    } else if (person.userType.contains('Faculty') ||
        person.userType == 'Tenured' ||
        person.userType == 'Adjunct' ||
        person.userType == 'VisitingResearcher') {
      faculty = await idService.getFaculty(person.uniqueId);
    } else if (person.userType.contains('Staff') ||
        person.userType == 'ITAdmin') {
      staff = await idService.getStaff(person.uniqueId);
    } else if (person.userType == 'Contractor') {
      contractor = await idService.getContractor(person.uniqueId);
    }

    if (mounted) {
      setState(() {
        _person = person;
        _student = student;
        _faculty = faculty;
        _staff = staff;
        _contractor = contractor;
        _statusHistory = statusHist;
        _modificationLog = modLog;
        _isLoading = false;
      });
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 140,
              child: Text(label,
                  style: const TextStyle(color: AppTheme.textSecondary))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.accent),
            const SizedBox(width: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const Divider(height: 24),
      ],
    );
  }

  Widget _buildStatusHistoryTab() {
    if (_statusHistory.isEmpty) {
      return const Center(child: Text('No status history recorded.'));
    }

    return ListView.separated(
      itemCount: _statusHistory.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final sh = _statusHistory[index];
        final dt = DateTime.parse(sh.timestamp).toLocal();
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text('${sh.oldStatus ?? "Created"} → ${sh.newStatus}'),
          subtitle: Text(
              'Changed by ${sh.changedBy} on ${dt.toString().substring(0, 16)}'),
        );
      },
    );
  }

  Widget _buildModificationLogTab() {
    if (_modificationLog.isEmpty) {
      return const Center(child: Text('No modifications recorded.'));
    }

    return ListView.separated(
      itemCount: _modificationLog.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final mod = _modificationLog[index];
        final dt = DateTime.parse(mod.timestamp).toLocal();
        return ListTile(
          leading: const Icon(Icons.edit_note),
          title: Text('Changed ${mod.fieldChanged}'),
          subtitle: Text(
              '${mod.oldValue} → ${mod.newValue}\nBy ${mod.changedBy} on ${dt.toString().substring(0, 16)}'),
          isThreeLine: true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final p = _person!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Profile'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit User',
              onPressed: () => context
                  .push(AppRoutes.editUser.replaceAll(':id', p.uniqueId))
                  .then((_) => _loadData()),
            ),
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Change Status',
              onPressed: () => context
                  .push(AppRoutes.changeStatus.replaceAll(':id', p.uniqueId))
                  .then((_) => _loadData()),
            ),
            const SizedBox(width: 16),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Profile Information'),
              Tab(text: 'Status History'),
              Tab(text: 'Modification Log'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Profile Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Core Info
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor:
                                      AppTheme.accent.withValues(alpha: 0.2),
                                  child: Text(p.firstName[0] + p.lastName[0],
                                      style: const TextStyle(
                                          fontSize: 24,
                                          color: AppTheme.accent)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(p.fullName,
                                          style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold)),
                                      Text('${p.uniqueId} • ${p.userType}',
                                          style: const TextStyle(
                                              color: AppTheme.textSecondary)),
                                    ],
                                  ),
                                ),
                                Chip(
                                  label: Text(p.status),
                                  backgroundColor:
                                      AppTheme.statusColor(p.status)
                                          .withValues(alpha: 0.1),
                                  labelStyle: TextStyle(
                                      color: AppTheme.statusColor(p.status)),
                                  side: BorderSide.none,
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            _buildSectionHeader(
                                'Personal Information', Icons.person),
                            _buildInfoRow('First Name', p.firstName),
                            _buildInfoRow('Last Name', p.lastName),
                            _buildInfoRow('Date of Birth', p.dateOfBirth),
                            _buildInfoRow('Place of Birth', p.placeOfBirth),
                            _buildInfoRow('Nationality', p.nationality),
                            _buildInfoRow('Gender', p.gender),
                            const SizedBox(height: 24),
                            _buildSectionHeader(
                                'Contact Information', Icons.contact_mail),
                            _buildInfoRow('Email', p.personalEmail),
                            _buildInfoRow('Phone', p.phoneNumber),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Right Column: Specific Info
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_student != null) ...[
                              _buildSectionHeader(
                                  'Student Details', Icons.school),
                              _buildInfoRow(
                                  'Major', _student!.chosenMajor ?? 'N/A'),
                              _buildInfoRow(
                                  'Faculty', _student!.faculty ?? 'N/A'),
                              _buildInfoRow(
                                  'Department', _student!.department ?? 'N/A'),
                              _buildInfoRow('Entry Year',
                                  _student!.entryYear?.toString() ?? 'N/A'),
                              _buildInfoRow('Diploma Type',
                                  _student!.diplomaType ?? 'N/A'),
                            ] else if (_faculty != null) ...[
                              _buildSectionHeader(
                                  'Faculty Details', Icons.work),
                              _buildInfoRow('Rank', _faculty!.rank ?? 'N/A'),
                              _buildInfoRow('Department',
                                  _faculty!.primaryDepartment ?? 'N/A'),
                              _buildInfoRow('Contract Type',
                                  _faculty!.contractType ?? 'N/A'),
                            ] else if (_staff != null) ...[
                              _buildSectionHeader(
                                  'Staff Details', Icons.admin_panel_settings),
                              _buildInfoRow(
                                  'Job Title', _staff!.jobTitle ?? 'N/A'),
                              _buildInfoRow('Department',
                                  _staff!.assignedDepartment ?? 'N/A'),
                              _buildInfoRow('Grade', _staff!.grade ?? 'N/A'),
                            ] else if (_contractor != null) ...[
                              _buildSectionHeader(
                                  'Contractor Details', Icons.handyman),
                              _buildInfoRow('Purpose',
                                  _contractor!.contractPurpose ?? 'N/A'),
                              _buildInfoRow(
                                  'Expiry Date',
                                  _contractor!.accessExpiryDate
                                      .substring(0, 10)),
                            ] else ...[
                              _buildSectionHeader(
                                  'Additional Details', Icons.info_outline),
                              const Text(
                                  'No additional role-specific details available.'),
                            ],
                            if (p.isAlumni) ...[
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  border:
                                      Border.all(color: Colors.blue.shade200),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: Colors.blue.shade700),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Your access is limited to the alumni network.',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildSectionHeader('Alumni Information',
                                  Icons.workspace_premium),
                              _buildInfoRow('Graduation Year',
                                  p.graduationYear?.toString() ?? 'N/A'),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Status History Tab
            _buildStatusHistoryTab(),

            // Modification Log Tab
            _buildModificationLogTab(),
          ],
        ),
      ),
    );
  }
}
