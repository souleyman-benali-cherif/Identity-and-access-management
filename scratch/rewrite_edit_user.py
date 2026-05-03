import os

code = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/utils/temp_password_gen.dart';
import '../../../core/utils/password_utils.dart';
import '../../../models/person_model.dart';
import '../../../models/student_model.dart';
import '../../../models/faculty_model.dart';
import '../../../models/staff_model.dart';
import '../../../models/contractor_model.dart';
import '../../../models/auth_credentials_model.dart';
import 'package:bcrypt/bcrypt.dart';

class EditUserScreen extends ConsumerStatefulWidget {
  final String personId; // 'new' for creation
  const EditUserScreen({super.key, required this.personId});

  @override
  ConsumerState<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends ConsumerState<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.personId != 'new';
  bool _isLoading = false;
  PersonModel? _existingPerson;

  // Alumni Specific State
  String _userType = AppConstants.typeUndergraduate;
  final _alumniSearchCtrl = TextEditingController();
  final _alumniGradYearCtrl = TextEditingController();
  PersonModel? _foundAlumniStudent;
  StudentModel? _foundAlumniStudentDetails;

  // Common Fields
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _pobCtrl = TextEditingController();
  final _nationalityCtrl = TextEditingController(text: 'Algerian');
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _gender = 'Male';

  // Student Fields
  final _nationalIdCtrl = TextEditingController();
  final _diplomaTypeCtrl = TextEditingController();
  final _diplomaYearCtrl = TextEditingController();
  String _diplomaHonors = AppConstants.diplomaHonors.first;
  final _majorCtrl = TextEditingController();
  final _entryYearCtrl = TextEditingController(text: DateTime.now().year.toString());
  final _facultyCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _grpCtrl = TextEditingController();
  bool _scholarshipStatus = false;
  final _supervisingProfCtrl = TextEditingController(); // PhD
  final _stayStartCtrl = TextEditingController();       // Int
  final _stayEndCtrl = TextEditingController();         // Int

  // Faculty Fields
  String _rank = AppConstants.facultyRanks.first;
  final _empCategoryCtrl = TextEditingController();
  final _apptStartCtrl = TextEditingController();
  final _primaryDeptCtrl = TextEditingController();
  final _secondaryDeptsCtrl = TextEditingController(); // comma separated
  final _officeBldgCtrl = TextEditingController();
  final _officeFloorCtrl = TextEditingController();
  final _officeRoomCtrl = TextEditingController();
  final _phdInstCtrl = TextEditingController();
  final _researchAreasCtrl = TextEditingController(); // comma separated
  bool _habilitation = false;
  String _contractType = AppConstants.contractTypes.first;
  final _contractStartCtrl = TextEditingController();
  final _contractEndCtrl = TextEditingController();
  final _teachingHoursCtrl = TextEditingController();

  // Staff Fields
  final _staffDeptCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  final _dateOfEntryCtrl = TextEditingController();

  // Contractor Fields
  final _purposeCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExistingData();
    }
  }

  @override
  void dispose() {
    _alumniSearchCtrl.dispose();
    _alumniGradYearCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _dobCtrl.dispose();
    _pobCtrl.dispose();
    _nationalityCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _nationalIdCtrl.dispose();
    _diplomaTypeCtrl.dispose();
    _diplomaYearCtrl.dispose();
    _majorCtrl.dispose();
    _entryYearCtrl.dispose();
    _facultyCtrl.dispose();
    _deptCtrl.dispose();
    _grpCtrl.dispose();
    _supervisingProfCtrl.dispose();
    _stayStartCtrl.dispose();
    _stayEndCtrl.dispose();
    _empCategoryCtrl.dispose();
    _apptStartCtrl.dispose();
    _primaryDeptCtrl.dispose();
    _secondaryDeptsCtrl.dispose();
    _officeBldgCtrl.dispose();
    _officeFloorCtrl.dispose();
    _officeRoomCtrl.dispose();
    _phdInstCtrl.dispose();
    _researchAreasCtrl.dispose();
    _contractStartCtrl.dispose();
    _contractEndCtrl.dispose();
    _teachingHoursCtrl.dispose();
    _staffDeptCtrl.dispose();
    _jobTitleCtrl.dispose();
    _gradeCtrl.dispose();
    _dateOfEntryCtrl.dispose();
    _purposeCtrl.dispose();
    _expiryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoading = true);
    final idService = ref.read(identityServiceProvider);
    final person = await idService.getPersonById(widget.personId);
    if (!mounted) return;
    if (person == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found')));
      context.pop();
      return;
    }

    _existingPerson = person;
    _firstNameCtrl.text = person.firstName;
    _lastNameCtrl.text = person.lastName;
    _dobCtrl.text = person.dateOfBirth;
    _pobCtrl.text = person.placeOfBirth;
    _nationalityCtrl.text = person.nationality;
    _emailCtrl.text = person.personalEmail;
    _phoneCtrl.text = person.phoneNumber;
    _gender = person.gender;
    _userType = person.userType;

    setState(() => _isLoading = false);
  }

  Future<void> _findAlumniStudent() async {
    final idStr = _alumniSearchCtrl.text.trim();
    if (idStr.isEmpty) return;

    setState(() => _isLoading = true);
    final idService = ref.read(identityServiceProvider);
    final person = await idService.getPersonById(idStr);
    
    if (!mounted) return;
    
    if (person == null || (!person.uniqueId.startsWith('STU') && !person.uniqueId.startsWith('PHD'))) {
      setState(() {
        _isLoading = false;
        _foundAlumniStudent = null;
        _foundAlumniStudentDetails = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No student found with this ID.'))
      );
      return;
    }

    if (person.isAlumni) {
      setState(() {
        _isLoading = false;
        _foundAlumniStudent = null;
        _foundAlumniStudentDetails = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This person is already marked as alumni.'))
      );
      return;
    }

    final details = await idService.getStudent(person.uniqueId);
    
    setState(() {
      _isLoading = false;
      _foundAlumniStudent = person;
      _foundAlumniStudentDetails = details;
    });
  }

  Future<void> _submitAlumni() async {
    if (_foundAlumniStudent == null) return;
    final yearStr = _alumniGradYearCtrl.text.trim();
    final year = int.tryParse(yearStr);
    
    if (year == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Graduation year must be a valid number.')));
      return;
    }
    if (year > DateTime.now().year) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Graduation year cannot be in the future.')));
      return;
    }

    setState(() => _isLoading = true);
    final idService = ref.read(identityServiceProvider);
    final operatorId = ref.read(authProvider).personId!;
    
    try {
      await idService.markAsAlumni(_foundAlumniStudent!.uniqueId, year);
      
      await idService.logModification(
        personId: _foundAlumniStudent!.uniqueId,
        fieldChanged: 'isAlumni',
        oldValue: 'false',
        newValue: 'true',
        changedBy: operatorId,
      );
      
      await idService.logModification(
        personId: _foundAlumniStudent!.uniqueId,
        fieldChanged: 'graduationYear',
        oldValue: 'null',
        newValue: year.toString(),
        changedBy: operatorId,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Alumni Status Added'),
          content: Text('${_foundAlumniStudent!.firstName} ${_foundAlumniStudent!.lastName} has been marked as an alumni. Their ID remains ${_foundAlumniStudent!.uniqueId}.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        ),
      );
      
      // Reset alumni state
      setState(() {
        _alumniSearchCtrl.clear();
        _alumniGradYearCtrl.clear();
        _foundAlumniStudent = null;
        _foundAlumniStudentDetails = null;
        _userType = AppConstants.typeUndergraduate; // Reset drop down to first item per instructions
      });
      
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final idService = ref.read(identityServiceProvider);
    final authService = ref.read(authServiceProvider);
    final operatorId = ref.read(authProvider).personId!;

    try {
      if (!_isEditing) {
        // --- CREATION FLOW ---

        // Check duplicates
        final dup = await idService.checkDuplicate(
          _firstNameCtrl.text,
          _lastNameCtrl.text,
          _dobCtrl.text,
        );

        if (dup != null) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Possible duplicate found: ${dup.uniqueId}. Please verify.')),
          );
          return;
        }

        // Email check
        final isUniqueEmail = await idService.isEmailUnique(_emailCtrl.text.trim());
        if (!isUniqueEmail) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email is already in use by another account.')),
          );
          return;
        }
        
        // PhD Supervisor check
        if (_userType == AppConstants.typePhD) {
          final exists = await idService.checkProfessorExists(_supervisingProfCtrl.text.trim());
          if (!exists) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Supervising Professor ID is invalid or does not exist.')),
            );
            return;
          }
        }

        final now = DateTime.now().toUtc().toIso8601String();
        final uniqueId = await IdGenerator.generateUniqueId(_userType, DateTime.now().year);

        final newPerson = PersonModel(
          uniqueId: uniqueId,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          dateOfBirth: _dobCtrl.text.trim(),
          placeOfBirth: _pobCtrl.text.trim(),
          nationality: _nationalityCtrl.text.trim(),
          gender: _gender,
          personalEmail: _emailCtrl.text.trim().toLowerCase(),
          phoneNumber: _phoneCtrl.text.trim(),
          userType: _userType,
          status: AppConstants.statusPending,
          createdAt: now,
          isAlumni: false,
        );

        await idService.createPerson(newPerson);

        // Save Subtypes
        final isStudent = [AppConstants.typeUndergraduate, AppConstants.typeContinuingEducation, AppConstants.typePhD, AppConstants.typeInternational].contains(_userType);
        final isFaculty = [AppConstants.typeTenured, AppConstants.typeAdjunct, AppConstants.typeVisitingResearcher].contains(_userType);
        final isStaff = [AppConstants.typeAdministrativeStaff, AppConstants.typeTechnicalStaff, AppConstants.typeTemporaryStaff, AppConstants.typeITAdmin].contains(_userType);

        if (isStudent) {
          await idService.saveStudent(StudentModel(
            uniqueId: uniqueId,
            nationalIdNumber: _nationalIdCtrl.text.trim(),
            diplomaType: _diplomaTypeCtrl.text.trim(),
            diplomaYear: int.tryParse(_diplomaYearCtrl.text.trim()),
            diplomaHonors: _diplomaHonors,
            chosenMajor: _majorCtrl.text.trim(),
            entryYear: int.tryParse(_entryYearCtrl.text.trim()),
            faculty: _facultyCtrl.text.trim(),
            department: _deptCtrl.text.trim(),
            grp: _grpCtrl.text.trim(),
            scholarshipStatus: _scholarshipStatus,
            supervisingProfessorId: _userType == AppConstants.typePhD ? _supervisingProfCtrl.text.trim() : null,
            stayStartDate: _userType == AppConstants.typeInternational ? _stayStartCtrl.text.trim() : null,
            stayEndDate: _userType == AppConstants.typeInternational ? _stayEndCtrl.text.trim() : null,
          ));
        } else if (isFaculty) {
           await idService.saveFaculty(FacultyModel(
            uniqueId: uniqueId,
            rank: _rank,
            employmentCategory: _empCategoryCtrl.text.trim(),
            appointmentStartDate: _apptStartCtrl.text.trim(),
            primaryDepartment: _primaryDeptCtrl.text.trim(),
            secondaryDepartments: _secondaryDeptsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
            officeBuilding: _officeBldgCtrl.text.trim(),
            officeFloor: _officeFloorCtrl.text.trim(),
            officeRoom: _officeRoomCtrl.text.trim(),
            phdInstitution: _phdInstCtrl.text.trim(),
            researchAreas: _researchAreasCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
            habilitationToSupervise: _habilitation,
            contractType: _contractType,
            contractStartDate: _contractStartCtrl.text.trim(),
            contractEndDate: (_contractType == 'Permanent') ? null : _contractEndCtrl.text.trim(),
            teachingHoursPerWeek: int.tryParse(_teachingHoursCtrl.text.trim()),
          ));
        } else if (isStaff) {
          await idService.saveStaff(StaffModel(
            uniqueId: uniqueId,
            assignedDepartment: _staffDeptCtrl.text.trim(),
            jobTitle: _jobTitleCtrl.text.trim(),
            grade: _gradeCtrl.text.trim(),
            dateOfEntry: _dateOfEntryCtrl.text.trim(),
          ));
        } else if (_userType == AppConstants.typeContractor) {
          await idService.saveContractor(ContractorModel(
            uniqueId: uniqueId,
            contractPurpose: _purposeCtrl.text.trim(),
            accessExpiryDate: _expiryCtrl.text.trim(),
          ));
        }

        // Generate Credentials
        final tempPassword = TempPasswordGenerator.generate();
        final hashed = await PasswordUtils.hashPassword(tempPassword);

        final creds = AuthCredentialsModel(
          personId: uniqueId,
          hashedPassword: hashed,
          salt: BCrypt.gensalt(logRounds: 12),
          isFirstLogin: true,
          authLevel: AppConstants.defaultAuthLevel(_userType),
          accountLocked: false,
          failedAttempts: 0,
        );

        await authService.createCredentials(creds);

        if (!mounted) return;
        setState(() => _isLoading = false);
        _showCreationSuccessDialog(uniqueId, tempPassword);
        
      } else {
        // --- EDIT FLOW ---
        final oldEmail = _existingPerson!.personalEmail;
        final newEmail = _emailCtrl.text.trim().toLowerCase();

        if (oldEmail != newEmail) {
          final isUniqueEmail = await idService.isEmailUnique(newEmail);
          if (!isUniqueEmail) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email is already in use by another account.')),
            );
            return;
          }
        }

        final updated = _existingPerson!.copyWith(
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          placeOfBirth: _pobCtrl.text.trim(),
          nationality: _nationalityCtrl.text.trim(),
          gender: _gender,
          personalEmail: newEmail,
          phoneNumber: _phoneCtrl.text.trim(),
        );

        await idService.updatePerson(updated);

        if (oldEmail != newEmail) {
          await idService.logModification(
            personId: updated.uniqueId,
            fieldChanged: 'personalEmail',
            oldValue: oldEmail,
            newValue: newEmail,
            changedBy: operatorId,
          );
        }

        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated successfully.')));
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showCreationSuccessDialog(String uniqueId, String tempPassword) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('User Created')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The user has been created successfully. Please securely share the following credentials:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.withValues(alpha: 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID: $uniqueId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Temp Password: $tempPassword', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildAlumniFlow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('STEP 2 — SEARCH FOR EXISTING STUDENT', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _alumniSearchCtrl,
                decoration: const InputDecoration(
                  labelText: 'Enter existing student unique ID',
                  helperText: "Enter the student's STU or PHD ID to find their record.",
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _findAlumniStudent,
              child: const Text('Find'),
            ),
          ],
        ),
        if (_foundAlumniStudent != null) ...[
          const SizedBox(height: 32),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Found Student: ${_foundAlumniStudent!.firstName} ${_foundAlumniStudent!.lastName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Unique ID: ${_foundAlumniStudent!.uniqueId}'),
                  Text('Student Type: ${_foundAlumniStudent!.userType}'),
                  Text('Current Status: ${_foundAlumniStudent!.status}'),
                  Text('Entry Year: ${_foundAlumniStudentDetails?.entryYear ?? "N/A"}'),
                  Text('Faculty & Dept: ${_foundAlumniStudentDetails?.faculty ?? "N/A"} / ${_foundAlumniStudentDetails?.department ?? "N/A"}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text('STEP 4 — ENTER GRADUATION YEAR', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _alumniGradYearCtrl,
            decoration: const InputDecoration(labelText: 'Graduation year', hintText: 'e.g. 2024'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitAlumni,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Mark as Alumni'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStudentFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text('Student Specific Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const Divider(),
        TextFormField(controller: _nationalIdCtrl, decoration: const InputDecoration(labelText: 'National ID Number'), validator: Validators.required),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _diplomaTypeCtrl, decoration: const InputDecoration(labelText: 'HS Diploma Type'), validator: Validators.required)),
            const SizedBox(width: 16),
            Expanded(child: TextFormField(controller: _diplomaYearCtrl, decoration: const InputDecoration(labelText: 'HS Diploma Year'), validator: (v) => Validators.notFutureYear(int.tryParse(v ?? ''), fieldLabel: 'Diploma Year'))),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _diplomaHonors,
                decoration: const InputDecoration(labelText: 'HS Diploma Honors'),
                items: AppConstants.diplomaHonors.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _diplomaHonors = v!),
              )
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _majorCtrl, decoration: const InputDecoration(labelText: 'Chosen Major'), validator: Validators.required)),
            const SizedBox(width: 16),
            Expanded(child: TextFormField(controller: _entryYearCtrl, decoration: const InputDecoration(labelText: 'Entry Year'), validator: (v) => Validators.notFutureYear(int.tryParse(v ?? ''), fieldLabel: 'Entry Year'))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _facultyCtrl, decoration: const InputDecoration(labelText: 'Faculty'), validator: Validators.required)),
            const SizedBox(width: 16),
            Expanded(child: TextFormField(controller: _deptCtrl, decoration: const InputDecoration(labelText: 'Department'), validator: Validators.required)),
            const SizedBox(width: 16),
            Expanded(child: TextFormField(controller: _grpCtrl, decoration: const InputDecoration(labelText: 'Group'), validator: Validators.required)),
          ],
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Scholarship Status'),
          value: _scholarshipStatus,
          onChanged: (v) => setState(() => _scholarshipStatus = v),
          contentPadding: EdgeInsets.zero,
        ),
        if (_userType == AppConstants.typePhD) ...[
          const SizedBox(height: 16),
          TextFormField(controller: _supervisingProfCtrl, decoration: const InputDecoration(labelText: 'Supervising Professor ID (starts with FAC)'), validator: Validators.required),
        ],
        if (_userType == AppConstants.typeInternational) ...[
          const SizedBox(height: 16),
          Row(
            children: [
               Expanded(child: TextFormField(controller: _stayStartCtrl, decoration: const InputDecoration(labelText: 'Stay Start Date (YYYY-MM-DD)'), validator: Validators.required)),
               const SizedBox(width: 16),
               Expanded(child: TextFormField(controller: _stayEndCtrl, decoration: const InputDecoration(labelText: 'Stay End Date (YYYY-MM-DD)'), validator: Validators.required)),
            ],
          )
        ],
      ],
    );
  }

  Widget _buildFacultyFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text('Faculty Specific Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const Divider(),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _rank,
                decoration: const InputDecoration(labelText: 'Rank'),
                items: AppConstants.facultyRanks.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _rank = v!),
              )
            ),
            const SizedBox(width: 16),
            Expanded(child: TextFormField(controller: _empCategoryCtrl, decoration: const InputDecoration(labelText: 'Employment Category'), validator: Validators.required)),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(controller: _apptStartCtrl, decoration: const InputDecoration(labelText: 'Appointment Start Date (YYYY-MM-DD)'), validator: Validators.required),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _primaryDeptCtrl, decoration: const InputDecoration(labelText: 'Primary Department'), validator: Validators.required)),
            const SizedBox(width: 16),
            Expanded(child: TextFormField(controller: _secondaryDeptsCtrl, decoration: const InputDecoration(labelText: 'Secondary Departments (comma-separated)', hintText: 'Optional'))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _officeBldgCtrl, decoration: const InputDecoration(labelText: 'Office Building'), validator: Validators.required)),
            const SizedBox(width: 16),
            Expanded(child: TextFormField(controller: _officeFloorCtrl, decoration: const InputDecoration(labelText: 'Office Floor'), validator: Validators.required)),
            const SizedBox(width: 16),
            Expanded(child: TextFormField(controller: _officeRoomCtrl, decoration: const InputDecoration(labelText: 'Office Room'), validator: Validators.required)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _phdInstCtrl, decoration: const InputDecoration(labelText: 'PhD Institution'), validator: Validators.required)),
            const SizedBox(width: 16),
            Expanded(child: TextFormField(controller: _researchAreasCtrl, decoration: const InputDecoration(labelText: 'Research Areas (comma-separated)', hintText: 'Optional'))),
          ],
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Habilitation to Supervise Research'),
          value: _habilitation,
          onChanged: (v) => setState(() => _habilitation = v),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _contractType,
                decoration: const InputDecoration(labelText: 'Contract Type'),
                items: AppConstants.contractTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _contractType = v!),
              )
            ),
            const SizedBox(width: 16),
            Expanded(child: TextFormField(controller: _contractStartCtrl, decoration: const InputDecoration(labelText: 'Contract Start Date (YYYY-MM-DD)'), validator: Validators.required)),
            if (_contractType != 'Permanent') ...[
              const SizedBox(width: 16),
              Expanded(child: TextFormField(controller: _contractEndCtrl, decoration: const InputDecoration(labelText: 'Contract End Date'), validator: Validators.required)),
            ],
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(controller: _teachingHoursCtrl, decoration: const InputDecoration(labelText: 'Teaching Hours per Week'), keyboardType: TextInputType.number, validator: (v) => Validators.numberInRange(int.tryParse(v ?? ''), 1, 100, fieldLabel: 'Hours')),
      ],
    );
  }

  Widget _buildStaffFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text('Staff Specific Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const Divider(),
        Row(
          children: [
             Expanded(child: TextFormField(controller: _staffDeptCtrl, decoration: const InputDecoration(labelText: 'Assigned Department'), validator: Validators.required)),
             const SizedBox(width: 16),
             Expanded(child: TextFormField(controller: _jobTitleCtrl, decoration: const InputDecoration(labelText: 'Job Title'), validator: Validators.required)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
             Expanded(child: TextFormField(controller: _gradeCtrl, decoration: const InputDecoration(labelText: 'Grade'), validator: Validators.required)),
             const SizedBox(width: 16),
             Expanded(child: TextFormField(controller: _dateOfEntryCtrl, decoration: const InputDecoration(labelText: 'Date of Entry (YYYY-MM-DD)'), validator: Validators.required)),
          ],
        )
      ],
    );
  }

  Widget _buildContractorFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text('Contractor Specific Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const Divider(),
        TextFormField(controller: _purposeCtrl, decoration: const InputDecoration(labelText: 'Contract Purpose'), validator: Validators.required),
        const SizedBox(height: 16),
        TextFormField(
          controller: _expiryCtrl,
          decoration: const InputDecoration(labelText: 'Expiry Date (YYYY-MM-DD)', hintText: '2026-12-31'),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Expiry date is required';
            try {
              final dt = DateTime.parse(v);
              return Validators.futureDate(dt);
            } catch (_) {
              return 'Invalid date format';
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStudentType = [AppConstants.typeUndergraduate, AppConstants.typeContinuingEducation, AppConstants.typePhD, AppConstants.typeInternational].contains(_userType);
    final isFacultyType = [AppConstants.typeTenured, AppConstants.typeAdjunct, AppConstants.typeVisitingResearcher].contains(_userType);
    final isStaffType = [AppConstants.typeAdministrativeStaff, AppConstants.typeTechnicalStaff, AppConstants.typeTemporaryStaff, AppConstants.typeITAdmin].contains(_userType);
    
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit User' : 'Create New User')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800), // widened for larger form
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_isEditing ? 'Update Details' : 'Registration Form', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 24),
                      
                      if (!_isEditing) ...[
                        const Text('STEP 1 — SELECT TYPE', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _userType,
                          decoration: const InputDecoration(labelText: 'User Type'),
                          items: [
                            AppConstants.typeUndergraduate,
                            AppConstants.typePhD,
                            AppConstants.typeInternational,
                            AppConstants.typeTenured,
                            AppConstants.typeAdjunct,
                            AppConstants.typeAdministrativeStaff,
                            AppConstants.typeTechnicalStaff,
                            AppConstants.typeContractor,
                            AppConstants.typeAlumni,
                          ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (v) {
                            setState(() {
                              _userType = v!;
                              // Clear alumni state if they toggle away
                              if (v != AppConstants.typeAlumni) {
                                _foundAlumniStudent = null;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 32),
                      ],

                      if (_userType == AppConstants.typeAlumni && !_isEditing)
                        _buildAlumniFlow()
                      else ...[
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: _firstNameCtrl, decoration: const InputDecoration(labelText: 'First Name'), validator: Validators.name)),
                            const SizedBox(width: 16),
                            Expanded(child: TextFormField(controller: _lastNameCtrl, decoration: const InputDecoration(labelText: 'Last Name'), validator: Validators.name)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _dobCtrl,
                                decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)', hintText: '2000-01-01'),
                                enabled: !_isEditing,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'DOB is required';
                                  try {
                                    final dt = DateTime.parse(v);
                                    return Validators.dateOfBirth(dt, checkStudentAge: isStudentType);
                                  } catch (_) {
                                    return 'Invalid format (YYYY-MM-DD)';
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _gender,
                                decoration: const InputDecoration(labelText: 'Gender'),
                                items: ['Male', 'Female', 'Other'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                onChanged: (v) => setState(() => _gender = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: _pobCtrl, decoration: const InputDecoration(labelText: 'Place of Birth'), validator: Validators.required)),
                            const SizedBox(width: 16),
                            Expanded(child: TextFormField(controller: _nationalityCtrl, decoration: const InputDecoration(labelText: 'Nationality'), validator: Validators.required)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Personal Email'), validator: Validators.email)),
                            const SizedBox(width: 16),
                            Expanded(child: TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number'), validator: Validators.phone, keyboardType: TextInputType.phone)),
                          ],
                        ),

                        if (!_isEditing) ...[
                          if (isStudentType) _buildStudentFields(),
                          if (isFacultyType) _buildFacultyFields(),
                          if (isStaffType) _buildStaffFields(),
                          if (_userType == AppConstants.typeContractor) _buildContractorFields(),
                        ],

                        const SizedBox(height: 32),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isEditing ? 'Save Changes' : 'Create User'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
"""

with open(r'd:\flutter_workplace\iam_projectt\lib\screens\admin_staff\edit_user_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code)
