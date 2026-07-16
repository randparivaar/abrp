import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:mobile_app/features/auth/presentation/auth_controller.dart';
// To reuse CommunityEmblem if needed
import 'package:mobile_app/core/utils/income_parser.dart';

// Secure Storage key for draft
const String _draftKey = 'onboarding_family_head_draft';

// Simple model representing the villages list
class Village {
  final int id;
  final String name;
  final String regionName;

  Village({required this.id, required this.name, required this.regionName});

  factory Village.fromJson(Map<String, dynamic> json) {
    return Village(
      id: json['id'] as int,
      name: json['name'] as String,
      regionName: (json['region']?['name'] ?? '') as String,
    );
  }
}

// FutureProvider for fetching and caching villages list
final villagesProvider = FutureProvider<List<Village>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final response = await dio.get('/directory/villages');
  final list = response.data['villages'] as List<dynamic>;
  return list.map((json) => Village.fromJson(json)).toList();
});

class FamilyOnboardingScreen extends ConsumerStatefulWidget {
  const FamilyOnboardingScreen({super.key});

  @override
  ConsumerState<FamilyOnboardingScreen> createState() => _FamilyOnboardingScreenState();
}

class _FamilyOnboardingScreenState extends ConsumerState<FamilyOnboardingScreen> {
  final _storage = const FlutterSecureStorage();
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;
  String? _villageError;

  // Step 1: Origin & Address
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');
  bool _isAutoFilling = false;
  bool _isAddressEditable = false;
  Village? _selectedVillage;

  Future<void> _fetchAddressFromPincode(String pincode) async {
    if (pincode.length != 6) return;

    setState(() {
      _isAutoFilling = true;
      _errorMessage = null;
    });

    try {
      final dio = Dio();
      final response = await dio.get('https://api.postalpincode.in/pincode/$pincode');
      
      if (response.statusCode == 200 && response.data is List && response.data.isNotEmpty) {
        final data = response.data[0];
        final status = data['Status'];
        if (status == 'Success') {
          final postOffices = data['PostOffice'] as List<dynamic>;
          if (postOffices.isNotEmpty) {
            final first = postOffices[0];
            final city = first['District'] ?? '';
            final state = first['State'] ?? '';
            final country = first['Country'] ?? 'India';

            setState(() {
              _cityController.text = city;
              _stateController.text = state;
              _countryController.text = country;
              _isAddressEditable = false;
            });
            _saveDraft();
          }
        } else {
          setState(() {
            _isAddressEditable = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pincode details not found. Please enter details manually.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching address from pincode: $e');
      setState(() {
        _isAddressEditable = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to auto-fill address. Please enter details manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() {
        _isAutoFilling = false;
      });
    }
  }

  // Step 2: Personal Profile
  final _fullNameController = TextEditingController();
  String _gender = 'male'; // 'male', 'female', 'other'
  bool _useAgeInsteadOfBirthDate = false;
  final _ageController = TextEditingController();
  DateTime? _selectedBirthDate;
  final _gotraController = TextEditingController();
  String _bloodGroup = 'O+';

  // Step 3: Contact & Professional details
  final _mobileController = TextEditingController();
  bool _isWhatsappActive = true;
  final _educationController = TextEditingController();
  String _occupationType = 'business'; // 'business', 'salaried', etc.
  final _occupationDetailController = TextEditingController();
  final _incomeController = TextEditingController();
  int? _parsedIncome;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Don\'t Know'];
  final List<Map<String, String>> _occupations = [
    {'value': 'business', 'label': 'Business / व्यापार'},
    {'value': 'salaried', 'label': 'Salaried Job / नौकरी'},
    {'value': 'professional', 'label': 'Professional / पेशेवर (CA, Doctor, Engineer)'},
    {'value': 'student', 'label': 'Student / विद्यार्थी'},
    {'value': 'homemaker', 'label': 'Homemaker / गृहणी'},
    {'value': 'retired', 'label': 'Retired / सेवानिवृत्त'},
    {'value': 'other', 'label': 'Other / अन्य'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDraft();
      // Autofill mobile with logged-in user if available
      final user = ref.read(authProvider).user;
      if (user != null && _mobileController.text.isEmpty) {
        // Try parsing mobile if it's set in user metadata
        // For simplicity, just prefill name
        if (_fullNameController.text.isEmpty) {
          _fullNameController.text = user.fullName;
        }
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _fullNameController.dispose();
    _ageController.dispose();
    _gotraController.dispose();
    _mobileController.dispose();
    _educationController.dispose();
    _occupationDetailController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  // --- LOCAL CACHE AUTO-SAVE & DRAFT LOGIC ---

  Future<void> _loadDraft() async {
    try {
      final draftStr = await _storage.read(key: _draftKey);
      if (draftStr != null) {
        final draft = jsonDecode(draftStr) as Map<String, dynamic>;
        
        // Ask to restore
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              final dialogTheme = Theme.of(ctx);
              return AlertDialog(
                backgroundColor: dialogTheme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                title: Text(
                  'Resume Onboarding?',
                  style: TextStyle(color: dialogTheme.colorScheme.error, fontWeight: FontWeight.bold),
                ),
                content: const Text(
                  'We found an unsaved family head onboarding draft. Would you like to resume where you left off?',
                  style: TextStyle(color: Colors.black87),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      _clearDraft();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Start Fresh', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _applyDraftData(draft);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dialogTheme.colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Resume', style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Error reading onboarding draft: $e');
    }
  }

  void _applyDraftData(Map<String, dynamic> draft) {
    setState(() {
      _currentStep = draft['currentStep'] ?? 0;

      // Step 1
      _addressController.text = draft['address'] ?? '';
      _cityController.text = draft['city'] ?? '';
      _stateController.text = draft['state'] ?? '';
      _pincodeController.text = draft['pincode'] ?? '';
      _countryController.text = draft['country'] ?? 'India';
      _isAddressEditable = draft['isAddressEditable'] ?? false;
      final savedVillageId = draft['villageId'] as int?;
      
      // Step 2
      _fullNameController.text = draft['fullName'] ?? '';
      _gender = draft['gender'] ?? 'male';
      _useAgeInsteadOfBirthDate = draft['useAgeInsteadOfBirthDate'] ?? true;
      _ageController.text = draft['estimatedAge'] ?? '';
      if (draft['birthDate'] != null) {
        _selectedBirthDate = DateTime.tryParse(draft['birthDate']);
      }
      _gotraController.text = draft['gotra'] ?? '';
      _bloodGroup = draft['bloodGroup'] ?? 'O+';

      // Step 3
      _mobileController.text = draft['mobile'] ?? '';
      _isWhatsappActive = draft['isWhatsappActive'] ?? true;
      _educationController.text = draft['education'] ?? '';
      _occupationType = draft['occupationType'] ?? 'business';
      _occupationDetailController.text = draft['occupationDetail'] ?? '';
      _incomeController.text = draft['incomeRaw'] ?? '';
      if (_incomeController.text.isNotEmpty) {
        _parsedIncome = IncomeParser.parse(_incomeController.text);
      }

      // Try matching selected village if villages are loaded
      final villagesAsync = ref.read(villagesProvider);
      villagesAsync.whenData((villagesList) {
        if (savedVillageId != null) {
          _selectedVillage = villagesList.firstWhere(
            (v) => v.id == savedVillageId,
            orElse: () => villagesList.first,
          );
        }
      });
    });
  }

  Future<void> _saveDraft() async {
    final draft = {
      'currentStep': _currentStep,
      // Step 1
      'address': _addressController.text,
      'city': _cityController.text,
      'state': _stateController.text,
      'pincode': _pincodeController.text,
      'country': _countryController.text,
      'isAddressEditable': _isAddressEditable,
      'villageId': _selectedVillage?.id,
      // Step 2
      'fullName': _fullNameController.text,
      'gender': _gender,
      'useAgeInsteadOfBirthDate': _useAgeInsteadOfBirthDate,
      'estimatedAge': _ageController.text,
      'birthDate': _selectedBirthDate?.toIso8601String(),
      'gotra': _gotraController.text,
      'bloodGroup': _bloodGroup,
      // Step 3
      'mobile': _mobileController.text,
      'isWhatsappActive': _isWhatsappActive,
      'education': _educationController.text,
      'occupationType': _occupationType,
      'occupationDetail': _occupationDetailController.text,
      'incomeRaw': _incomeController.text,
    };
    await _storage.write(key: _draftKey, value: jsonEncode(draft));
  }

  Future<void> _clearDraft() async {
    await _storage.delete(key: _draftKey);
  }

  // --- STEP NAVIGATION & SUBMIT ---

  void _nextStep() {
    // Step 0: also validate village separately (not inside FormField)
    if (_currentStep == 0 && _selectedVillage == null) {
      setState(() => _villageError = 'Please select a native village / मूल निवास चुनें');
    }

    FormState? form;
    if (_currentStep == 0) form = _formKey1.currentState;
    if (_currentStep == 1) form = _formKey2.currentState;

    if (form != null && !form.validate()) return;
    if (_currentStep == 0 && _selectedVillage == null) return;

    setState(() => _villageError = null);

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _saveDraft();
    } else {
      _submitOnboarding();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _saveDraft();
    }
  }

  Future<void> _submitOnboarding() async {
    if (!_formKey3.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = ref.read(apiClientProvider);

      final payload = {
        'family': {
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
          'state': _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : null,
          'pincode': _pincodeController.text.trim().isNotEmpty ? _pincodeController.text.trim() : null,
          'country': _countryController.text.trim().isNotEmpty ? _countryController.text.trim() : null,
          'villageId': _selectedVillage!.id,
        },
        'head': {
          'fullName': _fullNameController.text.trim(),
          'gender': _gender,
          'birthDate': !_useAgeInsteadOfBirthDate && _selectedBirthDate != null 
              ? _selectedBirthDate!.toIso8601String() 
              : null,
          'estimatedAgeOnCreation': _useAgeInsteadOfBirthDate && _ageController.text.isNotEmpty 
              ? int.tryParse(_ageController.text) 
              : null,
          'gotra': _gotraController.text.trim().isNotEmpty ? _gotraController.text.trim() : null,
          'bloodGroup': _bloodGroup != 'Don\'t Know' ? _bloodGroup : null,
          'mobile': _mobileController.text.trim().isNotEmpty ? _mobileController.text.trim() : null,
          'whatsappMobile': _isWhatsappActive && _mobileController.text.trim().isNotEmpty 
              ? _mobileController.text.trim() 
              : null,
          'education': _educationController.text.trim().isNotEmpty ? _educationController.text.trim() : null,
          'occupationType': _occupationType,
          'occupationDetail': _occupationDetailController.text.trim().isNotEmpty 
              ? _occupationDetailController.text.trim() 
              : null,
          'yearlyIncome': _parsedIncome,
        }
      };

      final response = await dio.post('/directory/onboard-family', data: payload);

      if (response.statusCode == 201) {
        await _clearDraft();
        final familyId = response.data['family']['id'] as int;

        if (mounted) {
          final theme = Theme.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Family Head onboarded successfully! Let\'s build your tree.'),
              backgroundColor: theme.colorScheme.secondary,
            ),
          );
          // Redirect to family tree screen
          context.replace('/family/$familyId/tree');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = (e as dynamic).response?.data['error'] ?? e.toString();
        _isLoading = false;
      });
    }
  }

  // --- WIDGET RENDERERS ---

  Widget _buildStepIndicator(ThemeData theme) {
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Row(
            children: [
              // Circle
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive 
                      ? primary 
                      : (isCompleted ? secondary : Colors.white),
                  border: Border.all(
                    color: isActive || isCompleted ? Colors.transparent : secondary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    if (isActive)
                      BoxShadow(
                        color: primary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                  ]
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive ? Colors.white : secondary.withValues(alpha: 0.8),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
              // Line separator
              if (index < 2)
                Container(
                  width: 48,
                  height: 2,
                  color: index < _currentStep 
                      ? secondary 
                      : secondary.withValues(alpha: 0.15),
                ),
            ],
          );
        }),
      ),
    );
  }

  // --- STEP 1 FORM (Roots) ---
  Widget _buildStep1(ThemeData theme) {
    final villagesAsyncValue = ref.watch(villagesProvider);

    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Family Origin & Native Roots',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Provide the family\'s geographical tags and current residence details.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 20),
          
          // Searchable Native Village picker
          villagesAsyncValue.when(
            data: (list) {
              return _VillageSearchField(
                villages: list,
                selected: _selectedVillage,
                errorText: _villageError,
                onChanged: (val) {
                  setState(() {
                    _selectedVillage = val;
                    _villageError = null;
                  });
                  _saveDraft();
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) => Text('Error loading villages: $e',
                style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 16),

          // Pincode
          TextFormField(
            controller: _pincodeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            decoration: InputDecoration(
              labelText: 'Pincode / पिनकोड *',
              prefixIcon: const Icon(Icons.pin_outlined),
              suffixIcon: _isAutoFilling
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            onChanged: (val) {
              _saveDraft();
              if (val.trim().length == 6) {
                _fetchAddressFromPincode(val.trim());
              }
            },
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Please enter pincode';
              if (val.trim().length != 6) return 'Pincode must be exactly 6 digits';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Current Address
          TextFormField(
            controller: _addressController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Current Address *',
              prefixIcon: Icon(Icons.location_on_outlined),
              hintText: 'House no, street detail, area...',
            ),
            onChanged: (val) => _saveDraft(),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Please enter current address';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // City & State Row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  enabled: _isAddressEditable,
                  decoration: const InputDecoration(
                    labelText: 'City / शहर *',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  onChanged: (val) => _saveDraft(),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter city';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _stateController,
                  enabled: _isAddressEditable,
                  decoration: const InputDecoration(
                    labelText: 'State / राज्य *',
                  ),
                  onChanged: (val) => _saveDraft(),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter state';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Country
          TextFormField(
            controller: _countryController,
            enabled: _isAddressEditable,
            decoration: const InputDecoration(
              labelText: 'Country / देश *',
              prefixIcon: Icon(Icons.public_outlined),
            ),
            onChanged: (val) => _saveDraft(),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Please enter country';
              return null;
            },
          ),
          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _isAddressEditable = !_isAddressEditable;
                });
              },
              icon: Icon(_isAddressEditable ? Icons.lock_outline : Icons.edit_outlined, size: 16),
              label: Text(
                _isAddressEditable ? 'Lock Fields' : 'Edit City/State/Country Manually',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 2 FORM (Personal Profile) ---
  Widget _buildStep2(ThemeData theme) {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Family Head Details',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter the personal details of the Family Head.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Full Name
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name *',
              prefixIcon: Icon(Icons.person_outline),
              hintText: 'e.g. Ramesh Chandra Rander',
            ),
            onChanged: (val) => _saveDraft(),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Please enter full name';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Gender Selection (Custom Visual Segmented Cards)
          Text('Gender / लिंग *', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildGenderCard('male', Icons.male, 'Male', theme),
              const SizedBox(width: 12),
              _buildGenderCard('female', Icons.female, 'Female', theme),
              const SizedBox(width: 12),
              _buildGenderCard('other', Icons.transgender, 'Other', theme),
            ],
          ),
          const SizedBox(height: 20),

          // Age or Birthdate selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _useAgeInsteadOfBirthDate ? 'Enter Estimated Age' : 'Date of Birth',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _useAgeInsteadOfBirthDate = !_useAgeInsteadOfBirthDate;
                  });
                  _saveDraft();
                },
                icon: Icon(_useAgeInsteadOfBirthDate ? Icons.calendar_month : Icons.hourglass_bottom),
                label: Text(_useAgeInsteadOfBirthDate ? 'Use Date of Birth' : "Don't know? Enter Age"),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (_useAgeInsteadOfBirthDate)
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Estimated Age / अनुमानित उम्र *',
                prefixIcon: Icon(Icons.calendar_today_outlined),
                hintText: 'e.g. 52',
              ),
              onChanged: (val) => _saveDraft(),
              validator: (val) {
                if (_useAgeInsteadOfBirthDate) {
                  if (val == null || val.trim().isEmpty) return 'Please enter estimated age';
                  final age = int.tryParse(val);
                  if (age == null || age <= 0 || age > 120) return 'Please enter a valid age (1-120)';
                }
                return null;
              },
            )
          else
            OutlinedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().subtract(const Duration(days: 365 * 40)),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _selectedBirthDate = date;
                  });
                  _saveDraft();
                }
              },
              icon: const Icon(Icons.date_range),
              label: Text(
                _selectedBirthDate == null 
                    ? 'Choose Date' 
                    : '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          const SizedBox(height: 16),

          // Gotra & Blood Group Row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _gotraController,
                  decoration: const InputDecoration(
                    labelText: 'Gotra / गोत्र',
                    prefixIcon: Icon(Icons.people_outline),
                    hintText: 'e.g. Rander',
                  ),
                  onChanged: (val) => _saveDraft(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _bloodGroup,
                  decoration: const InputDecoration(
                    labelText: 'Blood Group',
                  ),
                  items: _bloodGroups.map((bg) {
                    return DropdownMenuItem<String>(
                      value: bg,
                      child: Text(bg),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _bloodGroup = val ?? 'O+';
                    });
                    _saveDraft();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCard(String value, IconData icon, String label, ThemeData theme) {
    final isSelected = _gender == value;
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _gender = value;
          });
          _saveDraft();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primary.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? primary : secondary.withValues(alpha: 0.15),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? primary : Colors.grey, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? primary : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- STEP 3 FORM (Work & Contact Details) ---
  Widget _buildStep3(ThemeData theme) {
    return Form(
      key: _formKey3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Contact & Profession Details',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter contact numbers and yearly income (used to support professional matching).',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Mobile Number
          TextFormField(
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile Number',
              prefixIcon: Icon(Icons.phone_outlined),
              hintText: '10 digit number',
            ),
            onChanged: (val) => _saveDraft(),
          ),
          const SizedBox(height: 8),

          // WhatsApp Active Flag
          SwitchListTile(
            title: const Text('This number is active on WhatsApp'),
            subtitle: Text('WhatsApp पर उपलब्ध है', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            value: _isWhatsappActive,
            activeThumbColor: theme.colorScheme.primary,
            onChanged: (val) {
              setState(() {
                _isWhatsappActive = val;
              });
              _saveDraft();
            },
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          const SizedBox(height: 8),

          // Education details
          TextFormField(
            controller: _educationController,
            decoration: const InputDecoration(
              labelText: 'Education Qualification',
              prefixIcon: Icon(Icons.school_outlined),
              hintText: 'e.g. Graduate, CA, MBA',
            ),
            onChanged: (val) => _saveDraft(),
          ),
          const SizedBox(height: 16),

          // Occupation Category Dropdown
          DropdownButtonFormField<String>(
            initialValue: _occupationType,
            decoration: const InputDecoration(
              labelText: 'Occupation Category',
              prefixIcon: Icon(Icons.work_outline),
            ),
            items: _occupations.map((item) {
              return DropdownMenuItem<String>(
                value: item['value'],
                child: Text(item['label']!),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _occupationType = val ?? 'other';
              });
              _saveDraft();
            },
          ),
          const SizedBox(height: 16),

          // Specific details about job/business
          TextFormField(
            controller: _occupationDetailController,
            decoration: const InputDecoration(
              labelText: 'Profession/Business Details',
              prefixIcon: Icon(Icons.business_center_outlined),
              hintText: 'e.g. Senior Manager, Marble factory owner',
            ),
            onChanged: (val) => _saveDraft(),
          ),
          const SizedBox(height: 16),

          // Yearly Income - With Smart live conversion helper text
          TextFormField(
            controller: _incomeController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              labelText: 'Yearly Income / वार्षिक आय',
              prefixIcon: const Icon(Icons.currency_rupee),
              hintText: 'e.g. 15 lakh, 50 hazar, 1.5 cr, 800000',
              helperText: _parsedIncome != null 
                  ? 'Processed: ₹${IncomeParser.format(_parsedIncome!)}'
                  : 'Allows shortcut strings like "lakh", "hazar", "cr", "K"',
              helperStyle: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
            ),
            onChanged: (val) {
              setState(() {
                _parsedIncome = IncomeParser.parse(val);
              });
              _saveDraft();
            },
            validator: (val) {
              if (val != null && val.trim().isNotEmpty) {
                if (IncomeParser.parse(val) == null) {
                  return 'Format error. Examples: "15 lakh", "50 hazar", "800000"';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Family Registration'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step indication bar
            _buildStepIndicator(theme),
            const Divider(height: 1),

            // Form container
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_currentStep == 0) _buildStep1(theme),
                    if (_currentStep == 1) _buildStep2(theme),
                    if (_currentStep == 2) _buildStep3(theme),
                  ],
                ),
              ),
            ),

            // Step controller actions
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  // Back button
                  if (_currentStep > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _prevStep,
                        child: const Text('BACK'),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],

                  // Next / Submit button
                  Expanded(
                    child: _isLoading 
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _nextStep,
                            child: Text(_currentStep == 2 ? 'SUBMIT' : 'NEXT'),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Searchable Village Picker ────────────────────────────────────────────────

/// Plain StatelessWidget — validation is handled manually in _nextStep.
class _VillageSearchField extends StatelessWidget {
  final List<Village> villages;
  final Village? selected;
  final String? errorText;
  final ValueChanged<Village?> onChanged;

  const _VillageSearchField({
    required this.villages,
    required this.selected,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return _VillagePickerTile(
      villages: villages,
      selected: selected,
      errorText: errorText,
      onChanged: onChanged,
    );
  }
}

class _VillagePickerTile extends StatelessWidget {
  final List<Village> villages;
  final Village? selected;
  final String? errorText;
  final ValueChanged<Village?> onChanged;

  const _VillagePickerTile({
    required this.villages,
    required this.selected,
    required this.errorText,
    required this.onChanged,
  });

  void _openSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VillageSearchSheet(
        villages: villages,
        selected: selected,
        onSelected: (v) {
          onChanged(v);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.secondary;
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _openSearch(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasError
                    ? theme.colorScheme.error
                    : selected != null
                        ? secondary
                        : Colors.grey.shade400,
                width: selected != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.home_work_outlined,
                  color: hasError ? theme.colorScheme.error : secondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: selected == null
                      ? Text(
                          'Native Village / मूल निवास *',
                          style: TextStyle(
                            color: hasError ? theme.colorScheme.error : Colors.grey.shade600,
                            fontSize: 15,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected!.name,
                              style: TextStyle(
                                color: secondary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              selected!.regionName,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            ),
                          ],
                        ),
                ),
                Icon(
                  Icons.search,
                  color: hasError ? theme.colorScheme.error : Colors.grey.shade500,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              errorText!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _VillageSearchSheet extends StatefulWidget {
  final List<Village> villages;
  final Village? selected;
  final ValueChanged<Village> onSelected;

  const _VillageSearchSheet({
    required this.villages,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<_VillageSearchSheet> createState() => _VillageSearchSheetState();
}

class _VillageSearchSheetState extends State<_VillageSearchSheet> {
  final _searchController = TextEditingController();
  List<Village> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.villages;
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? widget.villages
          : widget.villages
              .where((v) =>
                  v.name.toLowerCase().contains(query) ||
                  v.regionName.toLowerCase().contains(query))
              .toList();
    });
  }

  /// Groups filtered villages by regionName
  Map<String, List<Village>> _grouped() {
    final map = <String, List<Village>>{};
    for (final v in _filtered) {
      map.putIfAbsent(v.regionName, () => []).add(v);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.secondary;
    final grouped = _grouped();
    final regions = grouped.keys.toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.home_work_outlined, color: secondary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Select Native Village / मूल निवास',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: secondary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Search field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search village or region...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: secondary.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: secondary, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),

              const Divider(height: 1),

              // Results count
              if (_searchController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_filtered.length} result${_filtered.length == 1 ? '' : 's'}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ),
                ),

              // Village list grouped by region
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No villages found',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: regions.length,
                        itemBuilder: (ctx, rIdx) {
                          final regionName = regions[rIdx];
                          final villageList = grouped[regionName]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Region header
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                color: secondary.withValues(alpha: 0.07),
                                child: Text(
                                  regionName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: secondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              // Village tiles
                              ...villageList.map((village) {
                                final isSelected = widget.selected?.id == village.id;
                                return ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                                  leading: Icon(
                                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                    color: isSelected ? secondary : Colors.grey.shade400,
                                    size: 20,
                                  ),
                                  title: Text(
                                    village.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? secondary : Colors.black87,
                                    ),
                                  ),
                                  onTap: () => widget.onSelected(village),
                                );
                              }),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
