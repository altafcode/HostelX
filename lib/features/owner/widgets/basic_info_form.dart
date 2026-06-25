import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/hostel_entity.dart';
import '../../../widgets/common/app_text_field.dart';

class BasicInfoForm extends StatefulWidget {
  final TextEditingController nameCtrl;
  final TextEditingController locationCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController descCtrl;
  final HostelType selectedType;
  final ValueChanged<HostelType> onTypeChanged;
  final List<String> selectedFacilities;
  final Function(String, bool) onFacilityToggle;

  const BasicInfoForm({
    super.key,
    required this.nameCtrl,
    required this.locationCtrl,
    required this.cityCtrl,
    required this.priceCtrl,
    required this.descCtrl,
    required this.selectedType,
    required this.onTypeChanged,
    required this.selectedFacilities,
    required this.onFacilityToggle,
  });

  @override
  State<BasicInfoForm> createState() => _BasicInfoFormState();
}

class _BasicInfoFormState extends State<BasicInfoForm> {
  static const _availableFacilities = [
    'WiFi',
    'AC',
    'Mess',
    'Laundry',
    'Shuttle',
    'Generator',
    'Parking',
    'CCTV',
    'Geyser',
    'Backup'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionHeading(title: 'General Information'),
      const SizedBox(height: 16),
      AppTextField(
        label: 'Hostel Name',
        hint: 'e.g. Sunrise Boys Hostel',
        controller: widget.nameCtrl,
        validator: (v) => AppValidators.required(v, 'Hostel name'),
      ),
      const SizedBox(height: 14),
      AppTextField(
        label: 'Address / Location',
        hint: 'e.g. Johar Town, Lahore',
        controller: widget.locationCtrl,
        validator: (v) => AppValidators.required(v, 'Location'),
      ),
      const SizedBox(height: 14),
      AppTextField(
        label: 'City',
        hint: 'e.g. Lahore',
        controller: widget.cityCtrl,
        validator: (v) => AppValidators.required(v, 'City'),
      ),
      const SizedBox(height: 14),
      AppTextField(
        label: 'Monthly Rent (PKR)',
        hint: 'e.g. 15000',
        controller: widget.priceCtrl,
        keyboardType: TextInputType.number,
        validator: AppValidators.price,
      ),
      const SizedBox(height: 24),
      const _SectionHeading(title: 'Hostel Type'),
      const SizedBox(height: 12),
      Row(children: [
        _TypeChip(
          label: 'Boys',
          selected: widget.selectedType == HostelType.boys,
          onTap: () => widget.onTypeChanged(HostelType.boys),
        ),
        const SizedBox(width: 12),
        _TypeChip(
          label: 'Girls',
          selected: widget.selectedType == HostelType.girls,
          onTap: () => widget.onTypeChanged(HostelType.girls),
        ),
      ]),
      const SizedBox(height: 24),
      const _SectionHeading(title: 'Amenities'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _availableFacilities.map((f) {
          final isSelected = widget.selectedFacilities.contains(f);
          return FilterChip(
            label: Text(f),
            selected: isSelected,
            onSelected: (val) => widget.onFacilityToggle(f, val),
            selectedColor: AppColors.primary.withValues(alpha: 0.1),
            checkmarkColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                  color:
                      isSelected ? AppColors.primary : AppColors.borderLight),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 24),
      const _SectionHeading(title: 'Description'),
      const SizedBox(height: 12),
      AppTextField(
        hint: 'Describe your hostel, facilities, rules...',
        controller: widget.descCtrl,
        maxLines: 4,
        validator: (v) => AppValidators.required(v, 'Description'),
      ),
    ]);
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  const _SectionHeading({required this.title});
  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary),
      );
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.borderLight),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textSecondary,
              )),
        ),
      );
}
