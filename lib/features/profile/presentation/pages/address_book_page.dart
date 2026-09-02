import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/profile/presentation/bloc/address_cubit.dart';
import '../../../../features/profile/presentation/bloc/address_state.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/user_profile.dart';
import '../../../checkout/presentation/widgets/map_location_picker_sheet.dart';

class AddressBookPage extends StatefulWidget {
  const AddressBookPage({super.key});

  @override
  State<AddressBookPage> createState() => _AddressBookPageState();
}

class _AddressBookPageState extends State<AddressBookPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Addresses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: 'Add Address',
            onPressed: () => _showAddressFormSheet(context),
          ),
        ],
      ),
      body: BlocBuilder<AddressCubit, AddressState>(
        builder: (context, addressState) {
          final addresses = addressState.addresses;

          if (addresses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_off_outlined,
                        size: 56,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Saved Addresses',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your delivery addresses for seamless, 1-tap checkout.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _showAddressFormSheet(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Your First Address'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final addr = addresses[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: addr.isDefault
                        ? AppColors.accent
                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
                    width: addr.isDefault ? 1.8 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Label, Icon, Default Badge, and Popup Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getLabelIcon(addr.label),
                              color: AppColors.accent,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              addr.label,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (addr.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.accentLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'DEFAULT',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onSelected: (action) {
                            if (action == 'edit') {
                              _showAddressFormSheet(context, existingAddress: addr);
                            } else if (action == 'default') {
                              context.read<AddressCubit>().setDefaultAddress(addr.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Set "${addr.label}" as default address'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else if (action == 'delete') {
                              _confirmDeleteAddress(context, addr);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit Address'),
                                ],
                              ),
                            ),
                            if (!addr.isDefault)
                              const PopupMenuItem(
                                value: 'default',
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle_outline, size: 18),
                                    SizedBox(width: 8),
                                    Text('Set as Default'),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, color: AppColors.discountRed, size: 18),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: AppColors.discountRed)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Recipient Name
                    Text(
                      addr.recipientName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 3),

                    // Full formatted address
                    Text(
                      addr.formattedAddress,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Phone
                    Text(
                      'Phone: ${addr.phone}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!addr.isDefault)
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            onPressed: () {
                              context.read<AddressCubit>().setDefaultAddress(addr.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Set "${addr.label}" as default address'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.check, size: 15),
                            label: const Text('Set as Default'),
                          ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: isDark ? Colors.white70 : Colors.black87,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () => _showAddressFormSheet(context, existingAddress: addr),
                          icon: const Icon(Icons.edit, size: 14),
                          label: const Text('Edit'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddressFormSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add New Address'),
      ),
    );
  }

  IconData _getLabelIcon(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return Icons.home_outlined;
      case 'office':
      case 'work':
        return Icons.business_outlined;
      case 'apartment':
      case 'condo':
        return Icons.apartment_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }

  void _confirmDeleteAddress(BuildContext context, ShippingAddress addr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Are you sure you want to delete "${addr.label}" (${addr.street})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.discountRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AddressCubit>().deleteAddress(addr.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted "${addr.label}" address'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddressFormSheet(BuildContext context, {ShippingAddress? existingAddress}) {
    final isEditing = existingAddress != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.read<AuthBloc>().state.currentUser;

    final formKey = GlobalKey<FormState>();
    String selectedLabel = existingAddress?.label ?? 'Home';
    final nameController = TextEditingController(
      text: existingAddress?.recipientName ?? (user?.name.isNotEmpty == true ? user!.name : 'Customer'),
    );
    final phoneController = TextEditingController(
      text: existingAddress?.phone ?? (user?.phone.isNotEmpty == true ? user!.phone : '+1 (555) 019-2834'),
    );
    final streetController = TextEditingController(text: existingAddress?.street ?? '');
    final cityController = TextEditingController(text: existingAddress?.city ?? '');
    final stateController = TextEditingController(text: existingAddress?.state ?? '');
    final zipController = TextEditingController(text: existingAddress?.zipCode ?? '');
    bool isDefault = existingAddress?.isDefault ?? (context.read<AddressCubit>().state.addresses.isEmpty);

    final labelOptions = ['Home', 'Office', 'Apartment', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing ? 'Edit Address' : 'Add New Address',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.of(sheetCtx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Label Chips
                      const Text(
                        'Address Type / Label',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: labelOptions.map((lbl) {
                          final isSelected = selectedLabel == lbl;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(lbl),
                              selected: isSelected,
                              selectedColor: AppColors.accent,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : null,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setModalState(() {
                                    selectedLabel = lbl;
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Recipient Name
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Recipient Full Name *',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                        validator: (val) =>
                            (val == null || val.trim().isEmpty) ? 'Please enter recipient name' : null,
                      ),
                      const SizedBox(height: 12),

                      // Phone Number
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Contact Phone Number *',
                          prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        ),
                        validator: (val) =>
                            (val == null || val.trim().isEmpty) ? 'Please enter phone number' : null,
                      ),
                      const SizedBox(height: 14),

                      // Interactive Map Picker Trigger Button
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 14),
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await MapLocationPickerSheet.show(context);
                            if (picked != null) {
                              setModalState(() {
                                streetController.text = picked.street;
                                cityController.text = picked.cityProvince;
                                stateController.text = picked.district;
                                if (zipController.text.isEmpty) {
                                  zipController.text = '12000';
                                }
                              });
                            }
                          },
                          icon: const Icon(Icons.map_outlined, color: AppColors.accent, size: 20),
                          label: const Text(
                            '📍 Pick Address on Interactive Map',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppColors.accent, width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),

                      // Street Address
                      TextFormField(
                        controller: streetController,
                        decoration: const InputDecoration(
                          labelText: 'Street Address & Apt / Suite *',
                          prefixIcon: Icon(Icons.streetview_outlined, size: 20),
                        ),
                        validator: (val) =>
                            (val == null || val.trim().isEmpty) ? 'Please enter street address' : null,
                      ),
                      const SizedBox(height: 12),

                      // City & State Row
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: cityController,
                              decoration: const InputDecoration(
                                labelText: 'City *',
                                prefixIcon: Icon(Icons.location_city_outlined, size: 20),
                              ),
                              validator: (val) =>
                                   (val == null || val.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: stateController,
                              decoration: const InputDecoration(
                                labelText: 'State *',
                              ),
                              validator: (val) =>
                                  (val == null || val.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Zip Code
                      TextFormField(
                        controller: zipController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Postal / ZIP Code *',
                          prefixIcon: Icon(Icons.markunread_mailbox_outlined, size: 20),
                        ),
                        validator: (val) =>
                            (val == null || val.trim().isEmpty) ? 'Please enter zip code' : null,
                      ),
                      const SizedBox(height: 12),

                      // Default Address Switch
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Set as Default Delivery Address',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        value: isDefault,
                        activeThumbColor: AppColors.accent,
                        onChanged: (val) {
                          setModalState(() {
                            isDefault = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState?.validate() ?? false) {
                              final addressId = existingAddress?.id ??
                                  'addr_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}';

                              final newAddr = ShippingAddress(
                                id: addressId,
                                label: selectedLabel,
                                recipientName: nameController.text.trim(),
                                phone: phoneController.text.trim(),
                                street: streetController.text.trim(),
                                city: cityController.text.trim(),
                                state: stateController.text.trim(),
                                zipCode: zipController.text.trim(),
                                isDefault: isDefault,
                              );

                              if (isEditing) {
                                context.read<AddressCubit>().updateAddress(newAddr);
                              } else {
                                context.read<AddressCubit>().addAddress(newAddr);
                              }

                              Navigator.of(sheetCtx).pop();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEditing
                                        ? 'Updated "${newAddr.label}" address'
                                        : 'Added "${newAddr.label}" address',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: Text(
                            isEditing ? 'Save Changes' : 'Save Address',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
