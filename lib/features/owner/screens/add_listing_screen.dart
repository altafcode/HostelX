import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/storage_service.dart';
import '../../../domain/entities/hostel_entity.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/primary_button.dart';
import '../widgets/photo_upload.dart';
import '../../../features/student/services/hostel_service.dart';
import '../../../features/student/providers/hostel_provider.dart';
import '../../../data/services/notification_service.dart';

class AddListingScreen extends StatefulWidget {
  final HostelEntity? hostel;
  const AddListingScreen({super.key, this.hostel});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final StorageService _storageService = StorageService();
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _ownerPhoneCtrl = TextEditingController();
  final _ownerWhatsappCtrl = TextEditingController();
  HostelType _type = HostelType.boys;

  // Pricing & Capacity
  final _totalRoomsCtrl = TextEditingController();
  final _securityDepositCtrl = TextEditingController();
  final _contractDurationCtrl = TextEditingController();
  final _rentIncrementCtrl = TextEditingController();

  // Room Types
  bool _hasSingle = true;
  bool _hasDouble = true;
  bool _hasTriple = false;
  bool _hasQuad = false;
  final _singleCountCtrl = TextEditingController(text: '5');
  final _singlePriceCtrl = TextEditingController(text: '12000');
  final _doubleCountCtrl = TextEditingController(text: '5');
  final _doublePriceCtrl = TextEditingController(text: '8000');
  final _tripleCountCtrl = TextEditingController(text: '5');
  final _triplePriceCtrl = TextEditingController(text: '6500');
  final _quadCountCtrl = TextEditingController(text: '5');
  final _quadPriceCtrl = TextEditingController(text: '5000');

  final List<String> _allAmenities = [
    'WiFi',
    'Meals',
    'AC',
    'Heating',
    'Generator',
    'Laundry',
    'Security',
    'CCTV',
    'Parking',
    'Kitchen',
    'Study Room',
    'Prayer Room'
  ];
  List<String> _selectedFacilities = [];
  final Map<String, String> _documentUrls = {};
  String? _uploadingDocument;
  List<String> _existingImageUrls =
      []; // URLs already on Cloudinary (edit mode)
  final List<File> _newImageFiles = [];

  bool get _isEditMode => widget.hostel != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final h = widget.hostel!;
      _nameCtrl.text = h.name;
      _locCtrl.text = h.location;
      _cityCtrl.text = h.city;
      _latCtrl.text = h.lat == 0 ? '' : h.lat.toString();
      _lngCtrl.text = h.lng == 0 ? '' : h.lng.toString();
      _descCtrl.text = h.description;
      _priceCtrl.text = h.price.toString();
      _ownerPhoneCtrl.text = h.ownerPhone;
      _ownerWhatsappCtrl.text = h.ownerWhatsapp;
      _type = h.type;
      _selectedFacilities = List.from(h.facilities);
      _documentUrls.addAll(h.documentUrls);
      _existingImageUrls = List.from(h.images);
      _totalRoomsCtrl.text = h.totalRooms.toString();
      _securityDepositCtrl.text = h.securityDeposit.toString();
      _contractDurationCtrl.text = h.minContractMonths.toString();
      _rentIncrementCtrl.text = h.rentIncrementPercentage.toString();
      _loadRoomConfigurations(h);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locCtrl.dispose();
    _cityCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _ownerPhoneCtrl.dispose();
    _ownerWhatsappCtrl.dispose();
    _totalRoomsCtrl.dispose();
    _securityDepositCtrl.dispose();
    _contractDurationCtrl.dispose();
    _rentIncrementCtrl.dispose();
    _singleCountCtrl.dispose();
    _singlePriceCtrl.dispose();
    _doubleCountCtrl.dispose();
    _doublePriceCtrl.dispose();
    _tripleCountCtrl.dispose();
    _triplePriceCtrl.dispose();
    _quadCountCtrl.dispose();
    _quadPriceCtrl.dispose();
    super.dispose();
  }

  void _loadRoomConfigurations(HostelEntity hostel) {
    if (hostel.roomConfigurations.isEmpty) {
      final price = hostel.price > 0 ? hostel.price : 8000;
      _singlePriceCtrl.text = (price + 4000).toString();
      _doublePriceCtrl.text = price.toString();
      _triplePriceCtrl.text = (price > 3000 ? price - 3000 : price).toString();
      _quadPriceCtrl.text = (price > 6000 ? price - 6000 : price).toString();
      return;
    }

    _hasSingle = false;
    _hasDouble = false;
    _hasTriple = false;
    _hasQuad = false;

    for (final config in hostel.roomConfigurations) {
      final type = _normalizeRoomType(config.type);
      final count = config.count.toString();
      final price = config.price.toString();
      if (type == 'Single Room') {
        _hasSingle = true;
        _singleCountCtrl.text = count;
        _singlePriceCtrl.text = price;
      } else if (type == '2 Seater') {
        _hasDouble = true;
        _doubleCountCtrl.text = count;
        _doublePriceCtrl.text = price;
      } else if (type == '3 Seater') {
        _hasTriple = true;
        _tripleCountCtrl.text = count;
        _triplePriceCtrl.text = price;
      } else if (type == '4 Seater') {
        _hasQuad = true;
        _quadCountCtrl.text = count;
        _quadPriceCtrl.text = price;
      }
    }
  }

  String _normalizeRoomType(String value) {
    final lower = value.toLowerCase().replaceAll('-', ' ').trim();
    if (lower.contains('single') || lower.contains('1 seater')) {
      return 'Single Room';
    }
    if (lower.contains('2')) return '2 Seater';
    if (lower.contains('3')) return '3 Seater';
    if (lower.contains('4')) return '4 Seater';
    return value.trim();
  }

  List<RoomTypeConfigEntity> _buildRoomConfigurations() {
    final configs = <RoomTypeConfigEntity>[];

    void addConfig(
      bool enabled,
      String type,
      TextEditingController countCtrl,
      TextEditingController priceCtrl,
    ) {
      final count = int.tryParse(countCtrl.text.trim()) ?? 0;
      final price = int.tryParse(priceCtrl.text.trim()) ?? 0;
      if (enabled && count > 0) {
        configs.add(RoomTypeConfigEntity(
          type: type,
          count: count,
          price: price,
        ));
      }
    }

    addConfig(_hasSingle, 'Single Room', _singleCountCtrl, _singlePriceCtrl);
    addConfig(_hasDouble, '2 Seater', _doubleCountCtrl, _doublePriceCtrl);
    addConfig(_hasTriple, '3 Seater', _tripleCountCtrl, _triplePriceCtrl);
    addConfig(_hasQuad, '4 Seater', _quadCountCtrl, _quadPriceCtrl);

    return configs;
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;
    if (_existingImageUrls.isEmpty && _newImageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    try {
      if (!_isEditMode) {
        // ... Maintenance checks ...
      }

      // Geocoding: Try to get Lat/Lng from address if not provided
      double finalLat = double.tryParse(_latCtrl.text.trim()) ?? 0.0;
      double finalLng = double.tryParse(_lngCtrl.text.trim()) ?? 0.0;

      if (finalLat == 0.0 && finalLng == 0.0) {
        try {
          final query = '${_locCtrl.text.trim()}, ${_cityCtrl.text.trim()}, Pakistan';
          List<Location> locations = await locationFromAddress(query);
          if (locations.isNotEmpty) {
            finalLat = locations.first.latitude;
            finalLng = locations.first.longitude;
          }
        } catch (e) {
          debugPrint('Geocoding failed: $e');
        }
      }

      // Upload new images to Cloudinary
      List<String> newUrls = [];
      if (_newImageFiles.isNotEmpty) {
        newUrls = await _storageService.uploadMultipleImages(
          _newImageFiles,
          folder: 'hostelx/hostels',
        );
      }

      // Combine existing + new URLs
      final allImageUrls = [..._existingImageUrls, ...newUrls];

      if (!mounted) return;
      final hostelProvider = context.read<HostelProvider>();
      final hostelService = HostelService();
      final roomConfigurations = _buildRoomConfigurations();
      final configuredRooms = roomConfigurations.fold<int>(
        0,
        (total, config) => total + config.count,
      );

      final hostel = HostelEntity(
        id: widget.hostel?.id ?? '',
        name: _nameCtrl.text.trim(),
        location: _locCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        lat: finalLat,
        lng: finalLng,
        price: int.tryParse(_priceCtrl.text.trim()) ?? 0,
        rating: widget.hostel?.rating ?? 0.0,
        reviewsCount: widget.hostel?.reviewsCount ?? 0,
        images: allImageUrls,
        facilities: _selectedFacilities,
        type: _type,
        availability: HostelAvailability.open,
        description: _descCtrl.text.trim(),
        ownerId: user.id,
        ownerName: user.name,
        ownerPhone: _ownerPhoneCtrl.text.trim(),
        ownerWhatsapp: _ownerWhatsappCtrl.text.trim().isEmpty
            ? _ownerPhoneCtrl.text.trim()
            : _ownerWhatsappCtrl.text.trim(),
        documentUrls: Map<String, String>.from(_documentUrls),
        approvalStatus: ApprovalStatus.pending,
        isRecentlyAdded: !_isEditMode,
        minContractMonths: int.tryParse(_contractDurationCtrl.text.trim()) ?? 6,
        securityDeposit: int.tryParse(_securityDepositCtrl.text.trim()) ?? 0,
        totalRooms: configuredRooms > 0
            ? configuredRooms
            : int.tryParse(_totalRoomsCtrl.text.trim()) ?? 0,
        rentIncrementPercentage:
            double.tryParse(_rentIncrementCtrl.text.trim()) ?? 0.0,
        roomConfigurations: roomConfigurations,
        createdAt: widget.hostel?.createdAt,
      );

      String hostelId = '';
      if (_isEditMode) {
        await hostelService.updateHostel(widget.hostel!.id, hostel.toMap());
        hostelId = widget.hostel!.id;
        hostelProvider.updateHostel(hostel.copyWith(id: hostelId));
      } else {
        hostelId = await hostelService.saveHostel(hostel);
        hostelProvider.addHostel(hostel.copyWith(id: hostelId));

        await NotificationService().sendNotificationToRole(
          role: 'admin',
          title: 'New Hostel Approval Request',
          body:
              '${user.name} has submitted a new hostel "${hostel.name}" for approval.',
          type: 'system',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing submitted for admin review!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImages() async {
    final files = await _storageService.pickMultipleImages(
      maxCount: 5 - _existingImageUrls.length,
    );
    if (files.isNotEmpty) {
      setState(() => _newImageFiles.addAll(files));
    }
  }

  Future<void> _uploadDocument(String title) async {
    setState(() => _uploadingDocument = title);
    try {
      final url = await _storageService.pickAndUpload(
        folder: 'hostelx/documents/${context.read<AuthProvider>().user?.id}',
      );
      if (url != null && mounted) {
        setState(() => _documentUrls[title] = url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingDocument = null);
    }
  }

  Future<void> _openDocument(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open document.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Listing' : 'Add New Hostel',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Basic Info'),
              _buildTextField('Hostel Name', _nameCtrl),
              const SizedBox(height: 16),
              const Text('Type',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildTypeRadio(HostelType.boys, 'Boys')),
                  Expanded(child: _buildTypeRadio(HostelType.girls, 'Girls')),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('City', _cityCtrl),
              const SizedBox(height: 16),
              _buildTextField('Price', _priceCtrl, isNumber: true),
              const SizedBox(height: 16),
              _buildTextField('Full Address', _locCtrl),
              const SizedBox(height: 16),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: const Text(
                    'Manual Coordinates (Advanced)',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  tilePadding: EdgeInsets.zero,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Latitude',
                            _latCtrl,
                            isNumber: true,
                            requiredField: false,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            'Longitude',
                            _lngCtrl,
                            isNumber: true,
                            requiredField: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'If left empty, we will try to find your location automatically from the address.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField('Description', _descCtrl, maxLines: 3),
              const Divider(height: 48),
              _buildSectionTitle('Owner Contact'),
              _buildTextField('Owner Phone Number', _ownerPhoneCtrl,
                  isNumber: true),
              const SizedBox(height: 16),
              _buildTextField('WhatsApp Number', _ownerWhatsappCtrl,
                  isNumber: true),
              const Divider(height: 48),
              _buildSectionTitle('Pricing & Capacity'),
              Row(
                children: [
                  Expanded(
                      child: _buildTextField('Total Rooms', _totalRoomsCtrl,
                          isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildTextField(
                          'Security Deposit', _securityDepositCtrl,
                          isNumber: true)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Room Types & Pricing',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              _buildRoomTypeSelection(
                'Single Room',
                _hasSingle,
                (val) => setState(() => _hasSingle = val ?? false),
                _singleCountCtrl,
                _singlePriceCtrl,
              ),
              _buildRoomTypeSelection(
                '2-Seater',
                _hasDouble,
                (val) => setState(() => _hasDouble = val ?? false),
                _doubleCountCtrl,
                _doublePriceCtrl,
              ),
              _buildRoomTypeSelection(
                '3-Seater',
                _hasTriple,
                (val) => setState(() => _hasTriple = val ?? false),
                _tripleCountCtrl,
                _triplePriceCtrl,
              ),
              _buildRoomTypeSelection(
                '4-Seater',
                _hasQuad,
                (val) => setState(() => _hasQuad = val ?? false),
                _quadCountCtrl,
                _quadPriceCtrl,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildTextField(
                          'Min. Contract (Months)', _contractDurationCtrl,
                          isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildTextField(
                          'Annual Increment %', _rentIncrementCtrl,
                          isNumber: true)),
                ],
              ),
              const Divider(height: 48),
              _buildSectionTitle('Amenities'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allAmenities.map((facility) {
                  final isSelected = _selectedFacilities.contains(facility);
                  return FilterChip(
                    label: Text(facility),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedFacilities.add(facility);
                        } else {
                          _selectedFacilities.remove(facility);
                        }
                      });
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.1),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const Divider(height: 48),
              _buildSectionTitle('Photos'),
              PhotoUploadBox(
                existingImages: _existingImageUrls,
                newFiles: _newImageFiles,
                onAdd: _pickImages,
                onRemove: (index, isExisting) {
                  setState(() {
                    if (isExisting) {
                      _existingImageUrls.removeAt(index);
                    } else {
                      _newImageFiles.removeAt(index);
                    }
                  });
                },
              ),
              const Divider(height: 48),
              _buildSectionTitle('Documents Verification'),
              _buildDocUpload('CNIC Copy (Front & Back)'),
              const SizedBox(height: 12),
              _buildDocUpload('Property Ownership Proof / Lease'),
              const SizedBox(height: 12),
              _buildDocUpload('NOC from Local Authority'),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: _isEditMode
                      ? 'Update Listing'
                      : 'Submit for Admin Approval',
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _submitListing,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    int maxLines = 1,
    bool requiredField = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (val) {
        if (requiredField && (val == null || val.trim().isEmpty)) {
          return 'Required field';
        }
        if (!requiredField &&
            val != null &&
            val.trim().isNotEmpty &&
            double.tryParse(val.trim()) == null) {
          return 'Invalid number';
        }
        return null;
      },
    );
  }

  Widget _buildTypeRadio(HostelType type, String label) {
    return RadioListTile<HostelType>(
      title: Text(label, style: const TextStyle(fontSize: 13)),
      value: type,
      // ignore: deprecated_member_use
      groupValue: _type,
      // ignore: deprecated_member_use
      onChanged: (val) => setState(() => _type = val!),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildRoomTypeSelection(
    String title,
    bool value,
    ValueChanged<bool?> onChanged,
    TextEditingController countCtrl,
    TextEditingController priceCtrl,
  ) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
        if (value) ...[
          Expanded(child: _buildTextField('Count', countCtrl, isNumber: true)),
          const SizedBox(width: 8),
          Expanded(child: _buildTextField('Price', priceCtrl, isNumber: true)),
        ]
      ],
    );
  }

  Widget _buildDocUpload(String title) {
    final url = _documentUrls[title];
    final isUploading = _uploadingDocument == title;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.borderLight, style: BorderStyle.solid),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                if (url != null)
                  const Text('Uploaded',
                      style: TextStyle(
                          color: AppColors.emerald,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          if (url != null)
            IconButton(
              onPressed: () => _openDocument(url),
              icon: const Icon(Icons.visibility_rounded,
                  color: AppColors.primary, size: 18),
            ),
          OutlinedButton.icon(
            onPressed: isUploading ? null : () => _uploadDocument(title),
            icon: isUploading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file, size: 16),
            label: Text(url == null ? 'Upload' : 'Replace'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          )
        ],
      ),
    );
  }
}
