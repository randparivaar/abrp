import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:mobile_app/core/utils/app_avatar.dart';
import 'package:mobile_app/core/utils/income_parser.dart';
import 'package:mobile_app/features/directory/presentation/directory_constants.dart';
import 'package:mobile_app/features/directory/presentation/family_tree_screen.dart' show MemberNode, familyTreeProvider;
import 'package:mobile_app/core/utils/image_cropper_screen.dart';

class AddMemberDialog extends ConsumerStatefulWidget {
  final int familyId;
  final String? defaultRelation;
  final String? defaultGender;
  final int? fatherId;
  final int? motherId;
  final int? spouseId;
  final MemberNode? memberToEdit;
  final VoidCallback onMemberAdded;
  final String? defaultAddress;
  final String? defaultCity;
  final String? defaultState;
  final String? defaultPincode;

  const AddMemberDialog({
    super.key,
    required this.familyId,
    this.defaultRelation,
    this.defaultGender,
    this.fatherId,
    this.motherId,
    this.spouseId,
    this.memberToEdit,
    required this.onMemberAdded,
    this.defaultAddress,
    this.defaultCity,
    this.defaultState,
    this.defaultPincode,
  });

  @override
  ConsumerState<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends ConsumerState<AddMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  // Controllers
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _gotraController = TextEditingController();
  final _mobileController = TextEditingController();
  final _educationController = TextEditingController();
  final _occupationDetailController = TextEditingController();
  final _incomeController = TextEditingController();
  final _specialRemarksController = TextEditingController();

  // Address Controllers
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');
  bool _isAutoFilling = false;
  bool _isAddressEditable = false;
  int _currentStep = 0;

  String _gender = 'male';
  String _relationship = 'son';
  String _bloodGroup = 'Don\'t Know';
  String _occupationType = 'other';
  int? _parsedIncome;
  bool _useAgeInsteadOfBirthDate = false;
  DateTime? _selectedBirthDate;
  String _maritalStatus = 'single';
  DateTime? _selectedAnniversaryDate;
  String? _avatarUrl;
  bool _isAvatarUploading = false;
  int? _fatherId;
  int? _motherId;
  int? _spouseId;

  // Business Profile State & Controllers
  bool _createBusinessProfile = false;
  final _businessNameController = TextEditingController();
  String _businessCategory = 'textiles';
  final _businessMobileController = TextEditingController();
  final _businessWhatsappController = TextEditingController();
  bool _businessWhatsappSameAsMobile = true;
  bool _businessAddressSameAsHome = true;
  final _businessAddressController = TextEditingController();
  final _businessCityController = TextEditingController();
  final _businessStateController = TextEditingController();
  final _businessPincodeController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _businessWebsiteController = TextEditingController();
  final _businessGstinController = TextEditingController();
  final _businessDescController = TextEditingController();
  final _googleMapsLinkController = TextEditingController();
  final _customTagController = TextEditingController();
  String? _businessLogoUrl;
  bool _isBusinessLogoUploading = false;
  List<String> _selectedBusinessTags = [];
  bool _isBusinessAutoFilling = false;
  bool _isBusinessAddressEditable = true;
  String _operatingDays = 'Mon - Sat';
  String _operatingOpen = '10:00 AM';
  String _operatingClose = '08:30 PM';
  String _perkType = 'percent';
  final _perkValueController = TextEditingController();
  final _perkDescController = TextEditingController();
  List<Map<String, dynamic>> _catalogItems = []; // max 10: [{'title': '', 'description': '', 'imageUrl': '', 'isUploading': false}]
  final ImagePicker _imagePicker = ImagePicker();

  final List<Map<String, String>> _relationships = [
    {'value': 'spouse', 'label': 'Spouse / जीवनसाथी'},
    {'value': 'son', 'label': 'Son / पुत्र'},
    {'value': 'daughter', 'label': 'Daughter / पुत्री'},
    {'value': 'father', 'label': 'Father / पिता'},
    {'value': 'mother', 'label': 'Mother / माता'},
    {'value': 'brother', 'label': 'Brother / भाई'},
    {'value': 'sister', 'label': 'Sister / बहन'},
    {'value': 'daughter_in_law', 'label': 'Daughter-in-law / पुत्रवधू'},
    {'value': 'son_in_law', 'label': 'Son-in-law / दामाद'},
    {'value': 'grandson', 'label': 'Grandson / पौत्र'},
    {'value': 'granddaughter', 'label': 'Granddaughter / पौत्री'},
    {'value': 'other', 'label': 'Other / अन्य'},
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.memberToEdit;
    if (edit != null) {
      _fullNameController.text = edit.fullName;
      _gender = edit.gender;
      _relationship = edit.relationshipToHead;
      _gotraController.text = edit.gotra ?? '';
      _mobileController.text = edit.mobile ?? '';
      _educationController.text = edit.education ?? '';
      _occupationType = edit.occupationType ?? 'other';
      _occupationDetailController.text = edit.occupationDetail ?? '';
      if (edit.bloodGroup != null) {
        _bloodGroup = edit.bloodGroup!;
      }
      if (edit.yearlyIncome != null) {
        _incomeController.text = IncomeParser.format(edit.yearlyIncome!);
        _parsedIncome = edit.yearlyIncome;
      }
      if (edit.birthDate != null) {
        _selectedBirthDate = edit.birthDate;
        _useAgeInsteadOfBirthDate = false;
      } else if (edit.estimatedAgeOnCreation != null) {
        _ageController.text = edit.estimatedAgeOnCreation.toString();
        _useAgeInsteadOfBirthDate = true;
      }
      _maritalStatus = edit.maritalStatus ?? 'single';
      _selectedAnniversaryDate = edit.anniversaryDate;
      _avatarUrl = edit.avatarUrl;
      _addressController.text = edit.currentAddress ?? widget.defaultAddress ?? '';
      _pincodeController.text = edit.currentPincode ?? widget.defaultPincode ?? '';
      _cityController.text = edit.currentCity ?? widget.defaultCity ?? '';
      _stateController.text = edit.currentState ?? widget.defaultState ?? '';
      _specialRemarksController.text = edit.specialRemarks ?? '';
      _fatherId = edit.fatherId;
      _motherId = edit.motherId;
      _spouseId = edit.spouseId;

      // Populate business profile from edit model if present
      if (edit.businessProfile != null) {
        final bp = edit.businessProfile!;
        _createBusinessProfile = true;
        _businessNameController.text = bp.businessName;
        _businessCategory = bp.industryCategory;
        _businessMobileController.text = bp.contactMobile;
        _businessWhatsappController.text = bp.whatsappMobile ?? '';
        _businessWhatsappSameAsMobile = bp.whatsappMobile == bp.contactMobile;
        _businessAddressSameAsHome = bp.address == edit.currentAddress;
        _businessAddressController.text = bp.address;
        _businessCityController.text = bp.city;
        _businessStateController.text = bp.state ?? '';
        _businessPincodeController.text = bp.pincode ?? '';
        _businessWebsiteController.text = bp.websiteUrl ?? '';
        _businessGstinController.text = bp.gstin ?? '';
        _businessDescController.text = bp.description ?? '';
        _businessLogoUrl = bp.logoUrl;
        _googleMapsLinkController.text = bp.googleMapsLink ?? '';
        _selectedBusinessTags = bp.tags ?? [];
        if (bp.operatingHours != null) {
          _operatingDays = bp.operatingHours!['days'] ?? 'Mon - Sat';
          _operatingOpen = bp.operatingHours!['open'] ?? '10:00 AM';
          _operatingClose = bp.operatingHours!['close'] ?? '08:30 PM';
        }
        if (bp.communityPerk != null) {
          _perkType = bp.communityPerk!['type'] ?? 'percent';
          _perkValueController.text = bp.communityPerk!['value'] ?? '';
          _perkDescController.text = bp.communityPerk!['description'] ?? '';
        }
        if (bp.catalog != null) {
          _catalogItems = List<Map<String, dynamic>>.from(bp.catalog!.map((item) => {
            'title': item['title'] ?? '',
            'description': item['description'] ?? '',
            'imageUrl': item['imageUrl'] ?? '',
            'isUploading': false,
          }));
        }
      }
    } else {
      if (widget.defaultGender != null) {
        _gender = widget.defaultGender!;
      }
      if (widget.defaultRelation != null) {
        _relationship = widget.defaultRelation!;
      }
      _fatherId = widget.fatherId;
      _motherId = widget.motherId;
      _spouseId = widget.spouseId;
      if (_relationship == 'spouse' || _spouseId != null) {
        _maritalStatus = 'married';
      }
      _addressController.text = widget.defaultAddress ?? '';
      _pincodeController.text = widget.defaultPincode ?? '';
      _cityController.text = widget.defaultCity ?? '';
      _stateController.text = widget.defaultState ?? '';
    }
  }

  Future<void> _fetchAddressFromPincode(String pincode) async {
    if (pincode.length != 6) return;
    setState(() => _isAutoFilling = true);
    try {
      final dio = Dio();
      final response = await dio.get('https://api.postalpincode.in/pincode/$pincode');
      if (response.statusCode == 200 && response.data is List && response.data.isNotEmpty) {
        final data = response.data[0];
        if (data['Status'] == 'Success') {
          final postOffices = data['PostOffice'] as List<dynamic>;
          if (postOffices.isNotEmpty) {
            final first = postOffices[0];
            setState(() {
              _cityController.text = first['District'] ?? '';
              _stateController.text = first['State'] ?? '';
              _countryController.text = first['Country'] ?? 'India';
              _isAddressEditable = false;
            });
          }
        } else {
          setState(() => _isAddressEditable = true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pincode not found. Please enter city/state manually.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching pincode: $e');
      setState(() => _isAddressEditable = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to auto-fill address. Please enter manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() => _isAutoFilling = false);
    }
  }

  Future<void> _fetchBusinessAddressFromPincode(String pincode) async {
    if (pincode.length != 6) return;
    setState(() => _isBusinessAutoFilling = true);
    try {
      final dio = Dio();
      final response = await dio.get('https://api.postalpincode.in/pincode/$pincode');
      if (response.statusCode == 200 && response.data is List && response.data.isNotEmpty) {
        final data = response.data[0];
        if (data['Status'] == 'Success') {
          final postOffices = data['PostOffice'] as List<dynamic>;
          if (postOffices.isNotEmpty) {
            final first = postOffices[0];
            setState(() {
              _businessCityController.text = first['District'] ?? '';
              _businessStateController.text = first['State'] ?? '';
              _isBusinessAddressEditable = false;
            });
          }
        } else {
          setState(() => _isBusinessAddressEditable = true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pincode not found. Please enter city/state manually.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching business pincode: $e');
      setState(() => _isBusinessAddressEditable = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to auto-fill address. Please enter manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() => _isBusinessAutoFilling = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _gotraController.dispose();
    _mobileController.dispose();
    _educationController.dispose();
    _occupationDetailController.dispose();
    _incomeController.dispose();
    _specialRemarksController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();

    _businessNameController.dispose();
    _businessMobileController.dispose();
    _businessWhatsappController.dispose();
    _businessAddressController.dispose();
    _businessCityController.dispose();
    _businessStateController.dispose();
    _businessPincodeController.dispose();
    _businessEmailController.dispose();
    _businessWebsiteController.dispose();
    _businessGstinController.dispose();
    _businessDescController.dispose();
    _googleMapsLinkController.dispose();
    _customTagController.dispose();
    _perkValueController.dispose();
    _perkDescController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = ref.read(apiClientProvider);

      final Map<String, dynamic> payload = {
        'familyId': widget.familyId,
        'fullName': _fullNameController.text.trim(),
        'gender': _gender,
        'relationshipToHead': _relationship,
        'birthDate': !_useAgeInsteadOfBirthDate && _selectedBirthDate != null 
            ? _selectedBirthDate!.toIso8601String() 
            : null,
        'estimatedAgeOnCreation': _useAgeInsteadOfBirthDate && _ageController.text.isNotEmpty 
            ? int.tryParse(_ageController.text) 
            : null,
        'mobile': _mobileController.text.trim().isNotEmpty ? _mobileController.text.trim() : null,
        'whatsappMobile': _mobileController.text.trim().isNotEmpty ? _mobileController.text.trim() : null,
        'gotra': _gotraController.text.trim().isNotEmpty ? _gotraController.text.trim() : null,
        'bloodGroup': _bloodGroup != 'Don\'t Know' ? _bloodGroup : null,
        'maritalStatus': (_relationship == 'spouse' || _spouseId != null) ? 'married' : _maritalStatus,
        'anniversaryDate': _selectedAnniversaryDate?.toIso8601String(),
        'education': _educationController.text.trim().isNotEmpty ? _educationController.text.trim() : null,
        'currentAddress': _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        'currentPincode': _pincodeController.text.trim().isNotEmpty ? _pincodeController.text.trim() : null,
        'currentCity': _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        'currentState': _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : null,
        'country': _countryController.text.trim().isNotEmpty ? _countryController.text.trim() : null,
        'occupationType': _occupationType,
        'occupationDetail': _occupationDetailController.text.trim().isNotEmpty 
            ? _occupationDetailController.text.trim() 
            : null,
        'yearlyIncome': _parsedIncome,
        'fatherId': _fatherId,
        'motherId': _motherId,
        'spouseId': _spouseId,
        'avatarUrl': _avatarUrl,
        'specialRemarks': _specialRemarksController.text.trim().isNotEmpty ? _specialRemarksController.text.trim() : null,
      };

      if (_createBusinessProfile) {
        payload['businessProfile'] = {
          'businessName': _businessNameController.text.trim(),
          'industryCategory': _businessCategory,
          'contactMobile': _businessMobileController.text.trim(),
          'whatsappMobile': _businessWhatsappSameAsMobile 
              ? _businessMobileController.text.trim()
              : _businessWhatsappController.text.trim(),
          'email': _businessEmailController.text.trim().isNotEmpty
              ? _businessEmailController.text.trim()
              : null,
          'websiteUrl': _businessWebsiteController.text.trim().isNotEmpty 
              ? _businessWebsiteController.text.trim() 
              : null,
          'gstin': _businessGstinController.text.trim().isNotEmpty 
              ? _businessGstinController.text.trim() 
              : null,
          'description': _businessDescController.text.trim().isNotEmpty 
              ? _businessDescController.text.trim() 
              : null,
          'tags': _selectedBusinessTags,
          'operatingHours': {
            'days': _operatingDays,
            'open': _operatingOpen,
            'close': _operatingClose,
          },
          'communityPerk': {
            'type': _perkType,
            'value': _perkValueController.text.trim(),
            'description': _perkDescController.text.trim(),
          },
          'catalog': _catalogItems.map((item) => {
            'title': item['title'],
            'description': item['description'],
            'imageUrl': item['imageUrl'],
          }).toList(),
          'address': _businessAddressSameAsHome 
              ? _addressController.text.trim()
              : _businessAddressController.text.trim(),
          'city': _businessAddressSameAsHome 
              ? _cityController.text.trim()
              : _businessCityController.text.trim(),
          'state': _businessAddressSameAsHome 
              ? _stateController.text.trim()
              : _businessStateController.text.trim(),
          'pincode': _businessAddressSameAsHome 
              ? _pincodeController.text.trim()
              : _businessPincodeController.text.trim(),
          'logoUrl': _businessLogoUrl,
          'googleMapsLink': _googleMapsLinkController.text.trim().isNotEmpty 
              ? _googleMapsLinkController.text.trim() 
              : null,
        };
      }

      final isEdit = widget.memberToEdit != null;
      final response = isEdit
          ? await dio.put('/directory/member/${widget.memberToEdit!.id}', data: payload)
          : await dio.post('/directory/member', data: payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        widget.onMemberAdded();
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = (e as dynamic).response?.data['error'] ?? e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.memberToEdit != null ? 'Edit Family Member' : 'Add Family Member',
          style: GoogleFonts.inter(
            color: secondary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress indicator (Instagram story style)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(3, (index) {
                    final isActive = index == _currentStep;
                    final isCompleted = index < _currentStep;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2.0),
                        decoration: BoxDecoration(
                          color: isActive
                              ? primary
                              : (isCompleted ? secondary : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  _getStepTitle(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: KeyedSubtree(
                    key: ValueKey<int>(_currentStep),
                    child: _buildStepContent(theme),
                  ),
                ),
              ),
            ),
          ),

          const Divider(height: 1),
          // Actions
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                    ),
                    child: Text(
                      'CANCEL',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Row(
                    children: [
                      if (_currentStep > 0) ...[
                        OutlinedButton(
                          onPressed: () => setState(() => _currentStep--),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: secondary),
                            foregroundColor: secondary,
                            minimumSize: const Size(110, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('BACK'),
                        ),
                        const SizedBox(width: 8),
                      ],
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  final maxSteps = _createBusinessProfile ? 3 : 2;
                                  if (_currentStep < maxSteps) {
                                    setState(() => _currentStep++);
                                  } else {
                                    _submit();
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                minimumSize: const Size(110, 40),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _currentStep < (_createBusinessProfile ? 3 : 2)
                                    ? 'NEXT'
                                    : (widget.memberToEdit != null ? 'SAVE' : 'SUBMIT'),
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                              ),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'STEP 1: Personal Details / व्यक्तिगत जानकारी';
      case 1:
        return 'STEP 2: Address Details / पते का विवरण';
      case 2:
        return 'STEP 3: Profession & Education / शिक्षा और व्यवसाय';
      case 3:
        return 'STEP 4: Business Directory Card / व्यापार डायरेक्टरी कार्ड';
      default:
        return '';
    }
  }

  Widget _buildStepContent(ThemeData theme) {
    if (_errorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade800, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
        ],
      );
    }

    switch (_currentStep) {
      case 0:
        return _buildPersonalStep(theme);
      case 1:
        return _buildAddressStep(theme);
      case 2:
        return _buildProfessionalStep(theme);
      case 3:
        return _buildBusinessStep(theme);
      default:
        return Container();
    }
  }

  Widget _buildPersonalStep(ThemeData theme) {
    final treeAsync = ref.watch(familyTreeProvider(widget.familyId));
    final familyMembers = treeAsync.value?.members ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Photo Picker
        Center(
          child: Stack(
            children: [
              GestureDetector(
                onTap: _isAvatarUploading ? null : _pickAndUploadAvatar,
                child: Container(
                  child: _isAvatarUploading
                      ? CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.grey.shade200,
                          child: const CircularProgressIndicator(),
                        )
                      : AppAvatar(
                          name: _fullNameController.text.trim().isNotEmpty ? _fullNameController.text : 'Member',
                          imageUrl: _avatarUrl,
                          radius: 45,
                          fontSize: 36,
                          border: Border.all(color: theme.colorScheme.primary, width: 2.0),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isAvatarUploading ? null : _pickAndUploadAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.0),
                    ),
                    child: Icon(
                      _avatarUrl != null ? Icons.edit : Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
              if (_avatarUrl != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _avatarUrl = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Full Name
        TextFormField(
          controller: _fullNameController,
          decoration: const InputDecoration(
            labelText: 'Full Name / पूरा नाम *',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Please enter name';
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Relationship Dropdown
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _relationship == 'self' ? 'self' : _relationship,
          decoration: const InputDecoration(
            labelText: 'Relationship to Head / मुखिया से संबंध *',
            prefixIcon: Icon(Icons.people_outline),
            border: OutlineInputBorder(),
          ),
          items: [
            if (_relationship == 'self')
              const DropdownMenuItem<String>(
                value: 'self',
                child: Text('Head of Family / परिवार के मुखिया', overflow: TextOverflow.ellipsis),
              ),
            ..._relationships.map((r) {
              return DropdownMenuItem<String>(
                value: r['value'],
                child: Text(r['label']!, overflow: TextOverflow.ellipsis),
              );
            }),
          ],
          onChanged: _relationship == 'self'
              ? null
              : (val) {
                  setState(() {
                    _relationship = val ?? 'son';
                    _spouseId = null;
                    _fatherId = null;
                    _motherId = null;

                    // Auto-set gender based on relationship
                    if (_relationship == 'son' || 
                        _relationship == 'father' || 
                        _relationship == 'brother' || 
                        _relationship == 'son_in_law' || 
                        _relationship == 'grandson') {
                      _gender = 'male';
                    } else if (_relationship == 'daughter' || 
                               _relationship == 'mother' || 
                               _relationship == 'sister' || 
                               _relationship == 'daughter_in_law' || 
                               _relationship == 'granddaughter') {
                      _gender = 'female';
                    }

                    if (_relationship == 'spouse' || _relationship == 'daughter_in_law' || _relationship == 'son_in_law') { 
                      _maritalStatus = 'married';
                    } else {
                      _maritalStatus = 'single';
                    }
                  });
                },
        ),
        const SizedBox(height: 16),

        // Dynamic Spouse/Parent Selectors — show for all non-head, non-spouse relationship types
        if (_relationship != 'self' && _relationship != 'spouse' &&
            _relationship != 'father' && _relationship != 'mother' &&
            _relationship != 'brother' && _relationship != 'sister') ...[
          _buildRelationshipSelectors(theme, familyMembers),
          const SizedBox(height: 16),
        ],

        // Gender Choice Chips
        Text(
          'Gender / लिंग *',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Row(
          children: DirectoryConstants.genders.map((g) {
            final isSelected = _gender == g['value'];
            final isFixedGender = !(_relationship == 'spouse' || _relationship == 'other' || _relationship == 'self');
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(g['label']!.split(' / ')[0]),
                  selected: isSelected,
                  onSelected: isFixedGender
                      ? null
                      : (selected) {
                          if (selected) setState(() => _gender = g['value']!);
                        },
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  checkmarkColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? theme.colorScheme.primary : (isFixedGender ? Colors.grey : theme.colorScheme.onSurface),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Date of Birth / Age Selection
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _useAgeInsteadOfBirthDate ? 'Estimated Age / अनुमानित उम्र' : 'Date of Birth / जन्म तिथि',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _useAgeInsteadOfBirthDate = !_useAgeInsteadOfBirthDate),
              icon: Icon(_useAgeInsteadOfBirthDate ? Icons.calendar_month : Icons.hourglass_bottom, size: 16),
              label: Text(
                _useAgeInsteadOfBirthDate ? 'Use Date of Birth' : "Don't know? Enter Age",
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_useAgeInsteadOfBirthDate)
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Age / उम्र *',
              prefixIcon: Icon(Icons.hourglass_empty),
              border: OutlineInputBorder(),
            ),
            validator: (val) {
              if (_useAgeInsteadOfBirthDate) {
                if (val == null || val.trim().isEmpty) return 'Please enter age';
              }
              return null;
            },
          )
        else
          OutlinedButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _selectedBirthDate = date);
              }
            },
            icon: const Icon(Icons.calendar_month),
            label: Text(
              _selectedBirthDate == null
                  ? 'Choose Date'
                  : '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              alignment: Alignment.centerLeft,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        const SizedBox(height: 16),

        // Gotra & Mobile Row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _gotraController,
                decoration: const InputDecoration(
                  labelText: 'Gotra / गोत्र',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile / मोबाइल',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Blood Group Selection
        Text(
          'Blood Group / रक्त समूह',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: DirectoryConstants.bloodGroups.map((bg) {
              final isSelected = _bloodGroup == bg;
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: ChoiceChip(
                  label: Text(bg),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _bloodGroup = bg);
                  },
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  checkmarkColor: theme.colorScheme.primary,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Marital Status Selection
        if (_relationship != 'spouse' && _spouseId == null) ...[
          Text(
            'Marital Status / वैवाहिक स्थिति *',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: DirectoryConstants.maritalStatuses.map((item) {
              final isSelected = _maritalStatus == item['value'];
              return ChoiceChip(
                label: Text(item['label']!.split(' / ')[0]),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _maritalStatus = item['value']!;
                      if (_maritalStatus != 'married') {
                        _selectedAnniversaryDate = null;
                      }
                    });
                  }
                },
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                checkmarkColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Marriage Anniversary Date
        if (_relationship == 'spouse' || _spouseId != null || _maritalStatus == 'married') ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Anniversary Date / विवाह की तारीख',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              if (_selectedAnniversaryDate != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 16, color: Colors.red),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _selectedAnniversaryDate = null),
                ),
            ],
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedAnniversaryDate ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _selectedAnniversaryDate = date);
              }
            },
            icon: const Icon(Icons.celebration_outlined),
            label: Text(
              _selectedAnniversaryDate == null
                  ? 'Choose Anniversary Date'
                  : '${_selectedAnniversaryDate!.day}/${_selectedAnniversaryDate!.month}/${_selectedAnniversaryDate!.year}',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              alignment: Alignment.centerLeft,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  /// Returns the generation depth of a member:
  /// Head = 0, Head's children = 1, Grandchildren = 2, etc.
  int _getMemberGeneration(MemberNode member, List<MemberNode> allMembers) {
    // Find Head
    final head = allMembers.firstWhere(
      (m) => m.relationshipToHead == 'self',
      orElse: () => MemberNode(id: -1, familyId: -1, fullName: '', gender: '', relationshipToHead: ''),
    );
    if (head.id == -1 || member.id == head.id) return 0;

    // BFS to find depth
    final Map<int, int> depthMap = {head.id: 0};
    final queue = [head];
    final headSpouse = allMembers.firstWhere(
      (m) => (head.spouseId != null && m.id == head.spouseId) || m.spouseId == head.id,
      orElse: () => MemberNode(id: -1, familyId: -1, fullName: '', gender: '', relationshipToHead: ''),
    );
    if (headSpouse.id != -1) depthMap[headSpouse.id] = 0;

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final currentDepth = depthMap[current.id] ?? 0;
      for (final m in allMembers) {
        if (depthMap.containsKey(m.id)) continue;
        if (m.fatherId == current.id || m.motherId == current.id) {
          depthMap[m.id] = currentDepth + 1;
          // Also map their spouse at same depth
          if (m.spouseId != null) {
            final sp = allMembers.where((x) => x.id == m.spouseId).firstOrNull;
            if (sp != null && !depthMap.containsKey(sp.id)) {
              depthMap[sp.id] = currentDepth + 1;
            }
          }
          queue.add(m);
        }
      }
    }
    return depthMap[member.id] ?? -1;
  }

  /// Auto-compute the correct relationshipToHead based on the selected father's generation.
  String _autoRelationFromParent(MemberNode father, List<MemberNode> allMembers) {
    final depth = _getMemberGeneration(father, allMembers);
    // depth 0 = head level → child is son/daughter
    // depth 1 = son/daughter level → child is grandson/granddaughter
    // depth 2+ = great-grandchild, etc.
    if (depth <= 0) return _gender == 'female' ? 'daughter' : 'son';
    if (depth == 1) return _gender == 'female' ? 'granddaughter' : 'grandson';
    return 'other'; // great-grandchild and beyond → other
  }

  Widget _buildRelationshipSelectors(ThemeData theme, List<MemberNode> familyMembers) {
    // Find Head and Spouse IDs to exclude from parent dropdowns for deeper generations
    final head = familyMembers.firstWhere(
      (m) => m.relationshipToHead == 'self',
      orElse: () => MemberNode(id: -1, familyId: -1, fullName: '', gender: '', relationshipToHead: ''),
    );
    final headSpouse = head.id != -1
        ? familyMembers.firstWhere(
            (m) => (head.spouseId != null && m.id == head.spouseId) || m.spouseId == head.id,
            orElse: () => MemberNode(id: -1, familyId: -1, fullName: '', gender: '', relationshipToHead: ''),
          )
        : MemberNode(id: -1, familyId: -1, fullName: '', gender: '', relationshipToHead: '');
    final headLevelIds = {if (head.id != -1) head.id, if (headSpouse.id != -1) headSpouse.id};

    // For son/daughter: eligible fathers are Head-level members (depth 0)
    // For grandson/granddaughter: eligible fathers are Level-1 members (depth 1) — exclude head-level
    final bool isGrandChild = _relationship == 'grandson' || _relationship == 'granddaughter';
    final bool isDIL = _relationship == 'daughter_in_law';
    final bool isSIL = _relationship == 'son_in_law';

    if (isDIL) {
      // Daughter-in-law: select her husband (a male family member)
      final eligibleHusbands = familyMembers
          .where((m) => m.gender == 'male' && m.id != widget.memberToEdit?.id)
          .toList();
      final spouseValue = eligibleHusbands.any((m) => m.id == _spouseId) ? _spouseId : null;

      return DropdownButtonFormField<int>(
        key: ValueKey('dil_spouse_$_spouseId'),
        initialValue: spouseValue,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Select Husband (Son) / पति (पुत्र) का चयन करें *',
          prefixIcon: Icon(Icons.people_outline),
          border: OutlineInputBorder(),
        ),
        items: eligibleHusbands.map((m) {
          return DropdownMenuItem<int>(
            value: m.id,
            child: Text(m.fullName),
          );
        }).toList(),
        validator: (val) {
          if (val == null) return 'Please select Husband';
          return null;
        },
        onChanged: (val) {
          setState(() {
            _spouseId = val;
          });
        },
      );
    }

    if (isSIL) {
      // Son-in-law: select his wife (a female family member)
      final eligibleWives = familyMembers
          .where((m) => m.gender == 'female' && m.id != widget.memberToEdit?.id)
          .toList();
      final spouseValue = eligibleWives.any((m) => m.id == _spouseId) ? _spouseId : null;

      return DropdownButtonFormField<int>(
        key: ValueKey('sil_spouse_$_spouseId'),
        initialValue: spouseValue,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Select Wife (Daughter) / पत्नी (पुत्री) का चयन करें *',
          prefixIcon: Icon(Icons.people_outline),
          border: OutlineInputBorder(),
        ),
        items: eligibleWives.map((m) {
          return DropdownMenuItem<int>(
            value: m.id,
            child: Text(m.fullName),
          );
        }).toList(),
        validator: (val) {
          if (val == null) return 'Please select Wife';
          return null;
        },
        onChanged: (val) {
          setState(() {
            _spouseId = val;
          });
        },
      );
    }

    // For son/daughter/grandson/granddaughter: show Father + Mother dropdowns
    // Grandson/granddaughter: exclude Head-level members from father dropdown
    final eligibleFathers = familyMembers.where((m) {
      if (m.gender != 'male') return false;
      if (m.id == widget.memberToEdit?.id) return false;
      if (isGrandChild && headLevelIds.contains(m.id)) return false; // exclude head for grandchild
      return true;
    }).toList();

    final eligibleMothers = familyMembers.where((m) {
      if (m.gender != 'female') return false;
      if (m.id == widget.memberToEdit?.id) return false;
      if (isGrandChild && headLevelIds.contains(m.id)) return false; // exclude head's wife for grandchild
      return true;
    }).toList();

    final fatherValue = eligibleFathers.any((m) => m.id == _fatherId) ? _fatherId : null;
    final motherValue = eligibleMothers.any((m) => m.id == _motherId) ? _motherId : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info banner for grandchild
        if (isGrandChild) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Select the parent (Son/Daughter of Head). Relation will be auto-set.',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Father Dropdown
        DropdownButtonFormField<int>(
          key: ValueKey('father_${_fatherId}_$_relationship'),
          initialValue: fatherValue,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Select Father / पिता का चयन करें',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('Not specified / निर्दिष्ट नहीं है'),
            ),
            ...eligibleFathers.map((m) {
              final depth = _getMemberGeneration(m, familyMembers);
              final depthLabel = depth == 0 ? ' (Head Level)' : depth == 1 ? ' (Son Level)' : depth == 2 ? ' (Grandson Level)' : '';
              return DropdownMenuItem<int>(
                value: m.id,
                child: Text('${m.fullName}$depthLabel'),
              );
            }),
          ],
          onChanged: (val) {
            setState(() {
              _fatherId = val;
              if (val != null) {
                // Auto-set relation based on father's generation
                final father = familyMembers.firstWhere((m) => m.id == val,
                    orElse: () => MemberNode(id: -1, familyId: -1, fullName: '', gender: '', relationshipToHead: ''));
                if (father.id != -1) {
                  _relationship = _autoRelationFromParent(father, familyMembers);
                  // Auto-link father's spouse as mother
                  if (father.spouseId != null) {
                    final fatherSpouse = familyMembers.where((m) => m.id == father.spouseId).firstOrNull;
                    if (fatherSpouse != null) {
                      _motherId = fatherSpouse.id;
                    }
                  } else {
                    // Try reverse: find member whose spouseId == father.id
                    final fatherSpouse = familyMembers.where((m) => m.spouseId == father.id).firstOrNull;
                    if (fatherSpouse != null) {
                      _motherId = fatherSpouse.id;
                    }
                  }
                  // Auto-set gender based on updated relation
                  if (_relationship == 'son' || _relationship == 'grandson') {
                    _gender = 'male';
                  } else if (_relationship == 'daughter' || _relationship == 'granddaughter') {
                    _gender = 'female';
                  }
                }
              } else {
                _motherId = null;
              }
            });
          },
        ),
        const SizedBox(height: 12),
        // Mother Dropdown (may be auto-filled)
        DropdownButtonFormField<int>(
          key: ValueKey('mother_${_motherId}_$_relationship'),
          initialValue: motherValue,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Select Mother / माता का चयन करें',
            prefixIcon: const Icon(Icons.person_outline),
            border: const OutlineInputBorder(),
            suffixIcon: _motherId != null
                ? Tooltip(
                    message: 'Auto-linked from Father\'s spouse',
                    child: Icon(Icons.auto_awesome, size: 16, color: theme.colorScheme.primary),
                  )
                : null,
          ),
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('Not specified / निर्दिष्ट नहीं है'),
            ),
            ...eligibleMothers.map((m) {
              return DropdownMenuItem<int>(
                value: m.id,
                child: Text(m.fullName),
              );
            }),
          ],
          onChanged: (val) {
            setState(() {
              _motherId = val;
              // If mother selected and no father yet, auto-link mother's spouse as father
              if (val != null && _fatherId == null) {
                final mother = familyMembers.firstWhere((m) => m.id == val,
                    orElse: () => MemberNode(id: -1, familyId: -1, fullName: '', gender: '', relationshipToHead: ''));
                if (mother.id != -1) {
                  if (mother.spouseId != null) {
                    final motherSpouse = familyMembers.where((m) => m.id == mother.spouseId).firstOrNull;
                    if (motherSpouse != null) {
                      _fatherId = motherSpouse.id;
                      _relationship = _autoRelationFromParent(motherSpouse, familyMembers);
                    }
                  } else {
                    final motherSpouse = familyMembers.where((m) => m.spouseId == mother.id).firstOrNull;
                    if (motherSpouse != null) {
                      _fatherId = motherSpouse.id;
                      _relationship = _autoRelationFromParent(motherSpouse, familyMembers);
                    }
                  }
                }
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildAddressStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pincode
        TextFormField(
          controller: _pincodeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          decoration: InputDecoration(
            labelText: 'Pincode / पिनकोड',
            prefixIcon: const Icon(Icons.pin_outlined),
            border: const OutlineInputBorder(),
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
            if (val.trim().length == 6) {
              _fetchAddressFromPincode(val.trim());
            } else {
              setState(() => _isAddressEditable = true);
            }
          },
        ),
        const SizedBox(height: 16),

        // Address Details
        TextFormField(
          controller: _addressController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Current Address / वर्तमान पता',
            prefixIcon: Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(),
            hintText: 'House/Flat No, Area, Landmark...',
          ),
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
                  labelText: 'City / शहर',
                  prefixIcon: Icon(Icons.location_city_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _stateController,
                enabled: _isAddressEditable,
                decoration: const InputDecoration(
                  labelText: 'State / राज्य',
                  border: OutlineInputBorder(),
                ),
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
            labelText: 'Country / देश',
            prefixIcon: Icon(Icons.public_outlined),
            border: OutlineInputBorder(),
          ),
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
              _isAddressEditable ? 'Lock Fields' : 'Edit Address Fields Manually',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _getOccupationDetailsDecoration() {
    switch (_occupationType) {
      case 'business':
        return const InputDecoration(
          labelText: 'Shop/Business Name & Type / दुकान/व्यवसाय का नाम और प्रकार',
          prefixIcon: Icon(Icons.storefront_outlined),
          border: OutlineInputBorder(),
          hintText: 'e.g. Kirana Store, Textile Trader, Manufacturer...',
        );
      case 'salaried':
        return const InputDecoration(
          labelText: 'Company Name & Designation / कंपनी का नाम और पद',
          prefixIcon: Icon(Icons.badge_outlined),
          border: OutlineInputBorder(),
          hintText: 'e.g. TCS - Software Engineer, Bank Clerk...',
        );
      case 'professional':
        return const InputDecoration(
          labelText: 'Practice/Profession & Field / पेशा और क्षेत्र',
          prefixIcon: Icon(Icons.psychology_outlined),
          border: OutlineInputBorder(),
          hintText: 'e.g. CA Practice, Doctor - Pediatrician, Lawyer...',
        );
      case 'student':
        return const InputDecoration(
          labelText: 'School/College Name & Course / स्कूल/कॉलेज और कोर्स',
          prefixIcon: Icon(Icons.school_outlined),
          border: OutlineInputBorder(),
          hintText: 'e.g. ABC School - Class 10, University - B.Com...',
        );
      case 'retired':
        return const InputDecoration(
          labelText: 'Previous Profession / सेवानिवृत्ति विवरण',
          prefixIcon: Icon(Icons.work_history_outlined),
          border: OutlineInputBorder(),
          hintText: 'e.g. Retired Govt. Teacher, Ex-Railway Guard...',
        );
      case 'other':
      default:
        return const InputDecoration(
          labelText: 'Occupation Details / विवरण',
          prefixIcon: Icon(Icons.business_center_outlined),
          border: OutlineInputBorder(),
          hintText: 'e.g. Farming, Freelancing, Social Work...',
        );
    }
  }

  Widget _buildProfessionalStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Education
        TextFormField(
          controller: _educationController,
          decoration: const InputDecoration(
            labelText: 'Education / शिक्षा',
            prefixIcon: Icon(Icons.school_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Occupation chips
        Text(
          'Occupation Type / व्यवसाय का प्रकार',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: DirectoryConstants.occupations.map((item) {
            final isSelected = _occupationType == item['value'];
            return ChoiceChip(
              label: Text(item['label']!.split(' / ')[0]),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _occupationType = item['value']!);
              },
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              checkmarkColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Occupation Details
        if (_occupationType != 'homemaker') ...[
          TextFormField(
            controller: _occupationDetailController,
            decoration: _getOccupationDetailsDecoration(),
          ),
          const SizedBox(height: 16),
        ],

        // Income field
        TextFormField(
          controller: _incomeController,
          decoration: InputDecoration(
            labelText: 'Yearly Income / वार्षिक आय',
            prefixIcon: const Icon(Icons.currency_rupee),
            border: const OutlineInputBorder(),
            helperText: _parsedIncome != null
                ? 'Processed: ₹${IncomeParser.format(_parsedIncome!)}'
                : 'Shortcut examples: "15 lakh", "5K"',
            helperStyle: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
          ),
          onChanged: (val) {
            setState(() {
              _parsedIncome = IncomeParser.parse(val);
            });
          },
          validator: (val) {
            if (val != null && val.trim().isNotEmpty) {
              if (IncomeParser.parse(val) == null) {
                return 'Format error. Try "12 lakh" or "600000"';
              }
            }
            return null;
          },
        ),


        // Special Remarks
        TextFormField(
          controller: _specialRemarksController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Special Remarks / विशेष टिप्पणी',
            prefixIcon: Icon(Icons.comment_outlined),
            border: OutlineInputBorder(),
          ),
        ),

        if (_occupationType != 'homemaker') ...[
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary.withValues(alpha: 0.05), theme.colorScheme.secondary.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: SwitchListTile(
              title: Text(
                'List in Community Business Directory? / व्यापार डायरेक्टरी में जोड़ें?',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.primary),
              ),
              subtitle: const Text(
                'Create a business card, list up to 10 products with images, set operation timings and discount perks for Samaj.',
                style: TextStyle(fontSize: 11),
              ),
              value: _createBusinessProfile,
              onChanged: (val) {
                setState(() {
                  _createBusinessProfile = val;
                });
              },
              activeThumbColor: theme.colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }
  Widget _buildBusinessStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title banner
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.storefront, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Community Directory Card / समुदाय निर्देशिका कार्ड',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Business Banner Upload
        Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _isBusinessLogoUploading ? null : _pickAndUploadBusinessLogo,
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      width: 1.0,
                    ),
                    image: _businessLogoUrl != null && _businessLogoUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(_businessLogoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _isBusinessLogoUploading
                      ? const Center(child: CircularProgressIndicator())
                      : (_businessLogoUrl != null && _businessLogoUrl!.isNotEmpty
                          ? const SizedBox.shrink()
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: theme.colorScheme.primary,
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Upload Business Banner / व्यवसाय बैनर अपलोड करें',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Recommended 2:1 ratio (e.g. 800x400)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            )),
                ),
              ),
              if (_businessLogoUrl != null && _businessLogoUrl!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _pickAndUploadBusinessLogo,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Change Banner / बैनर बदलें', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _businessLogoUrl = null;
                        });
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Remove / हटाएं', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Business/Professional Name
        TextFormField(
          controller: _businessNameController,
          decoration: const InputDecoration(
            labelText: 'Business Name / व्यवसाय का नाम *',
            prefixIcon: Icon(Icons.store_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (val) {
            if (_createBusinessProfile && (val == null || val.trim().isEmpty)) {
              return 'Business name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Industry category Dropdown
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _businessCategory,
          decoration: const InputDecoration(
            labelText: 'Industry Category / उद्योग श्रेणी *',
            prefixIcon: Icon(Icons.category_outlined),
            border: OutlineInputBorder(),
          ),
          items: DirectoryConstants.industryCategories.map((cat) {
            return DropdownMenuItem<String>(
              value: cat['value']!,
              child: Text(
                cat['label']!,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _businessCategory = val);
            }
          },
        ),
        const SizedBox(height: 16),

        // Contact details
        TextFormField(
          controller: _businessMobileController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Business Contact Number / संपर्क नंबर *',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (val) {
            if (_createBusinessProfile && (val == null || val.trim().isEmpty)) {
              return 'Contact mobile is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        SwitchListTile(
          title: const Text('WhatsApp Same as Contact Mobile? / व्हाट्सएप भी यही नंबर है?'),
          value: _businessWhatsappSameAsMobile,
          onChanged: (val) {
            setState(() => _businessWhatsappSameAsMobile = val);
          },
          activeThumbColor: theme.colorScheme.primary,
          contentPadding: EdgeInsets.zero,
        ),

        if (!_businessWhatsappSameAsMobile) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _businessWhatsappController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'WhatsApp Mobile Number / व्हाट्सएप नंबर',
              prefixIcon: Icon(Icons.chat_outlined),
              border: OutlineInputBorder(),
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Email & Website
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _businessEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Business Email / ईमेल',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _businessWebsiteController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Website / वेबसाइट',
                  prefixIcon: Icon(Icons.language_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // GSTIN & Description
        TextFormField(
          controller: _businessGstinController,
          decoration: const InputDecoration(
            labelText: 'GSTIN (Optional) / जीएसटी नंबर',
            prefixIcon: Icon(Icons.description_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _businessDescController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Business Description / व्यवसाय का विवरण',
            prefixIcon: Icon(Icons.info_outline),
            border: OutlineInputBorder(),
            hintText: 'Tell the community about your services or products...',
          ),
        ),
        const SizedBox(height: 16),

        // Address Section
        SwitchListTile(
          title: const Text('Address Same as Home Address? / पता घर के पते जैसा ही है?'),
          value: _businessAddressSameAsHome,
          onChanged: (val) {
            setState(() => _businessAddressSameAsHome = val);
          },
          activeThumbColor: theme.colorScheme.primary,
          contentPadding: EdgeInsets.zero,
        ),

        if (!_businessAddressSameAsHome) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _businessPincodeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            decoration: InputDecoration(
              labelText: 'Pincode / पिनकोड',
              prefixIcon: const Icon(Icons.pin_outlined),
              border: const OutlineInputBorder(),
              suffixIcon: _isBusinessAutoFilling
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
              if (val.trim().length == 6) {
                _fetchBusinessAddressFromPincode(val.trim());
              } else {
                setState(() => _isBusinessAddressEditable = true);
              }
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _businessAddressController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Business Address / व्यवसाय का पता *',
              prefixIcon: Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (val) {
              if (_createBusinessProfile && !_businessAddressSameAsHome && (val == null || val.trim().isEmpty)) {
                return 'Business address is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _businessCityController,
                  enabled: _isBusinessAddressEditable,
                  decoration: const InputDecoration(
                    labelText: 'City / शहर *',
                    prefixIcon: Icon(Icons.location_city_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (_createBusinessProfile && !_businessAddressSameAsHome && (val == null || val.trim().isEmpty)) {
                      return 'City is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _businessStateController,
                  enabled: _isBusinessAddressEditable,
                  decoration: const InputDecoration(
                    labelText: 'State / राज्य',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),

        // Google Maps Link
        TextFormField(
          controller: _googleMapsLinkController,
          decoration: const InputDecoration(
            labelText: 'Google Maps Link / गूगल मैप्स लिंक',
            prefixIcon: Icon(Icons.map_outlined),
            border: OutlineInputBorder(),
            helperText: 'Paste link from Google Maps (optional)',
          ),
          validator: (val) {
            if (val != null && val.trim().isNotEmpty) {
              if (!val.trim().contains('http')) {
                return 'Please enter a valid URL (starting with http/https)';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Operating timing section
        Text(
          'Operating Timings / संचालन का समय',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _operatingDays,
          decoration: const InputDecoration(
            labelText: 'Days / दिन',
            border: OutlineInputBorder(),
          ),
          items: DirectoryConstants.daysOptions.map((day) {
            return DropdownMenuItem<String>(
              value: day,
              child: Text(day, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _operatingDays = val);
            }
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _operatingOpen,
                decoration: const InputDecoration(
                  labelText: 'Open / खुलने का समय',
                  border: OutlineInputBorder(),
                ),
                items: DirectoryConstants.timeOptions.map((time) {
                  return DropdownMenuItem<String>(
                    value: time,
                    child: Text(time, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _operatingOpen = val);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _operatingClose,
                decoration: const InputDecoration(
                  labelText: 'Close / बंद होने का समय',
                  border: OutlineInputBorder(),
                ),
                items: DirectoryConstants.timeOptions.map((time) {
                  return DropdownMenuItem<String>(
                    value: time,
                    child: Text(time, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _operatingClose = val);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tags Section
        Text(
          'Business Tags / व्यवसाय टैग',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            ...DirectoryConstants.commonTags,
            ..._selectedBusinessTags.where((tag) => !DirectoryConstants.commonTags.contains(tag)),
          ].map((tag) {
            final isSelected = _selectedBusinessTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (!_selectedBusinessTags.contains(tag)) {
                      _selectedBusinessTags.add(tag);
                    }
                  } else {
                    _selectedBusinessTags.remove(tag);
                  }
                });
              },
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              checkmarkColor: theme.colorScheme.primary,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _customTagController,
                decoration: const InputDecoration(
                  labelText: 'Add Custom Tag / अन्य टैग जोड़ें',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onFieldSubmitted: (val) {
                  if (val.trim().isNotEmpty && !_selectedBusinessTags.contains(val.trim())) {
                    setState(() {
                      _selectedBusinessTags.add(val.trim());
                      _customTagController.clear();
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () {
                final val = _customTagController.text.trim();
                if (val.isNotEmpty && !_selectedBusinessTags.contains(val)) {
                  setState(() {
                    _selectedBusinessTags.add(val);
                    _customTagController.clear();
                  });
                }
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Samaj Perk Section (Discount / Coupon)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_offer_outlined, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'Samaj Perk / समाज के लिए विशेष छूट',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade900),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _perkType,
                decoration: const InputDecoration(
                  labelText: 'Discount Type / छूट प्रकार',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'percent', child: Text('Percentage (%)')),
                  DropdownMenuItem(value: 'fixed', child: Text('Fixed Amt (₹)')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom Offer')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _perkType = val);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _perkValueController,
                decoration: const InputDecoration(
                  labelText: 'Perk Value / छूट का मान',
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: 'e.g. 10% / 100/-',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _perkDescController,
                decoration: const InputDecoration(
                  labelText: 'Instructions / निर्देश',
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: 'e.g. Show your digital Samaj ID card at checkout.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Product Catalog Section (Max 10 items)
        Text(
          'Product / Service Catalog (Max 10 Items)\nउत्पाद / सेवा सूची (अधिकतम 10)',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _catalogItems.length,
          itemBuilder: (context, idx) {
            final item = _catalogItems[idx];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: theme.colorScheme.primary,
                          child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Product / Service #${idx + 1}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _catalogItems.removeAt(idx);
                            });
                          },
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: item['title'],
                      decoration: const InputDecoration(
                        labelText: 'Title / नाम *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        item['title'] = val;
                      },
                      validator: (val) {
                        if (_createBusinessProfile && (val == null || val.trim().isEmpty)) {
                          return 'Product title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: item['description'],
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional) / विवरण',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        item['description'] = val;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Image picker section
                    Row(
                      children: [
                        if (item['imageUrl'] != null && item['imageUrl'].toString().isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item['imageUrl'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: item['isUploading'] == true
                              ? const Center(child: CircularProgressIndicator())
                              : OutlinedButton.icon(
                                  onPressed: () => _pickAndUploadCatalogImage(idx),
                                  icon: const Icon(Icons.add_photo_alternate_outlined),
                                  label: Text(item['imageUrl'] != null && item['imageUrl'].toString().isNotEmpty
                                      ? 'Change Image'
                                      : 'Add Product Image'),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        if (_catalogItems.length < 10) ...[
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _catalogItems.add({
                  'title': '',
                  'description': '',
                  'imageUrl': '',
                  'isUploading': false,
                });
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Product or Service'),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _pickAndUploadCatalogImage(int index) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image == null) return;

      if (!mounted) return;
      final File? croppedFile = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) => CropImageScreen(imageFile: File(image.path), isCircle: false),
        ),
      );

      if (croppedFile == null) return;

      setState(() {
        _catalogItems[index]['isUploading'] = true;
      });

      final filename = 'catalog_${DateTime.now().millisecondsSinceEpoch}.png';
      const contentType = 'image/png';

      final dio = ref.read(apiClientProvider);
      final presignedResponse = await dio.post('/upload/presigned-url', data: {
        'filename': filename,
        'contentType': contentType,
      });

      final uploadUrl = presignedResponse.data['uploadUrl'] as String;
      final publicUrl = presignedResponse.data['publicUrl'] as String;

      final bytes = await croppedFile.readAsBytes();
      final uploadDio = Dio();
      final uploadResponse = await uploadDio.put(
        uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': bytes.length,
          },
        ),
      );

      if (uploadResponse.statusCode == 200) {
        setState(() {
          _catalogItems[index]['imageUrl'] = publicUrl;
          _catalogItems[index]['isUploading'] = false;
        });
      } else {
        throw Exception('R2 upload failed');
      }
    } catch (e) {
      setState(() {
        _catalogItems[index]['isUploading'] = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image == null) return;

      if (!mounted) return;
      final File? croppedFile = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) => CropImageScreen(imageFile: File(image.path)),
        ),
      );

      if (croppedFile == null) return;

      setState(() {
        _isAvatarUploading = true;
      });

      final filename = 'avatar_${DateTime.now().millisecondsSinceEpoch}.png';
      const contentType = 'image/png';

      final dio = ref.read(apiClientProvider);
      final presignedResponse = await dio.post('/upload/presigned-url', data: {
        'filename': filename,
        'contentType': contentType,
      });

      final uploadUrl = presignedResponse.data['uploadUrl'] as String;
      final publicUrl = presignedResponse.data['publicUrl'] as String;

      final bytes = await croppedFile.readAsBytes();
      final uploadDio = Dio();
      final uploadResponse = await uploadDio.put(
        uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': bytes.length,
          },
        ),
      );

      if (uploadResponse.statusCode == 200) {
        setState(() {
          _avatarUrl = publicUrl;
          _isAvatarUploading = false;
        });
      } else {
        throw Exception('R2 upload failed');
      }
    } catch (e) {
      setState(() {
        _isAvatarUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload profile photo: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUploadBusinessLogo() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image == null) return;

      if (!mounted) return;
      final File? croppedFile = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) => CropImageScreen(imageFile: File(image.path), isCircle: false),
        ),
      );

      if (croppedFile == null) return;

      setState(() {
        _isBusinessLogoUploading = true;
      });

      final filename = 'logo_${DateTime.now().millisecondsSinceEpoch}.png';
      const contentType = 'image/png';

      final dio = ref.read(apiClientProvider);
      final presignedResponse = await dio.post('/upload/presigned-url', data: {
        'filename': filename,
        'contentType': contentType,
      });

      final uploadUrl = presignedResponse.data['uploadUrl'] as String;
      final publicUrl = presignedResponse.data['publicUrl'] as String;

      final bytes = await croppedFile.readAsBytes();
      final uploadDio = Dio();
      final uploadResponse = await uploadDio.put(
        uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': bytes.length,
          },
        ),
      );

      if (uploadResponse.statusCode == 200) {
        setState(() {
          _businessLogoUrl = publicUrl;
          _isBusinessLogoUploading = false;
        });
      } else {
        throw Exception('R2 upload failed');
      }
    } catch (e) {
      setState(() {
        _isBusinessLogoUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload business logo banner: $e')),
        );
      }
    }
  }
}
