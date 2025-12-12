import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/shop.dart';
import '../services/shop_service.dart';
import '../utils/app_theme.dart';

class ShopInfoScreen extends StatefulWidget {
  const ShopInfoScreen({super.key});

  @override
  State<ShopInfoScreen> createState() => _ShopInfoScreenState();
}

class _ShopInfoScreenState extends State<ShopInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  Shop? _shop;
  bool _isLoading = true;
  bool _isSaving = false;
  
  File? _logoFile;
  File? _bannerFile;
  String? _logoUrl;
  String? _bannerUrl;
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadShopData() async {
    setState(() => _isLoading = true);
    
    final result = await ShopService.getMyShop();
    
    if (result['success'] == true) {
      _shop = result['data'];
      _shopNameController.text = _shop!.shopName;
      _descriptionController.text = _shop!.description ?? '';
      _addressController.text = _shop!.address ?? '';
      _phoneController.text = _shop!.phoneNumber ?? '';
      _logoUrl = _shop!.logoUrl;
      _bannerUrl = _shop!.bannerUrl;
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage(ImageSource source, bool isLogo) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: isLogo ? 500 : 1200,
        maxHeight: isLogo ? 500 : 600,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (isLogo) {
            _logoFile = File(pickedFile.path);
          } else {
            _bannerFile = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chọn ảnh: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog(bool isLogo) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, isLogo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, isLogo);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveShop() async {
    if (!_formKey.currentState!.validate()) return;
    if (_shop == null) return;

    setState(() => _isSaving = true);

    try {
      // Upload logo if changed
      String? newLogoUrl = _logoUrl;
      if (_logoFile != null) {
        final logoResult = await ShopService.uploadLogo(_logoFile!);
        if (logoResult['success'] == true) {
          newLogoUrl = logoResult['data'];
        } else {
          throw Exception(logoResult['message']);
        }
      }

      // Upload banner if changed
      String? newBannerUrl = _bannerUrl;
      if (_bannerFile != null) {
        final bannerResult = await ShopService.uploadBanner(_bannerFile!);
        if (bannerResult['success'] == true) {
          newBannerUrl = bannerResult['data'];
        } else {
          throw Exception(bannerResult['message']);
        }
      }

      // Update shop info
      final result = await ShopService.updateShop(
        shopId: _shop!.shopId,
        shopName: _shopNameController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        logoUrl: newLogoUrl,
        bannerUrl: newBannerUrl,
      );

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cập nhật thông tin thành công'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cửa hàng'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Banner Section
                  _buildBannerSection(),
                  
                  // Logo Section (overlapping banner)
                  Transform.translate(
                    offset: const Offset(0, -50),
                    child: _buildLogoSection(),
                  ),

                  // Form Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          
                          // Shop Name
                          _buildTextField(
                            controller: _shopNameController,
                            label: 'Tên cửa hàng',
                            hint: 'Nhập tên cửa hàng',
                            icon: Icons.store,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập tên cửa hàng';
                              }
                              if (value.length < 3) {
                                return 'Tên cửa hàng phải có ít nhất 3 ký tự';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Description
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'Mô tả',
                            hint: 'Nhập mô tả về cửa hàng',
                            icon: Icons.description,
                            maxLines: 4,
                          ),
                          const SizedBox(height: 16),

                          // Address
                          _buildTextField(
                            controller: _addressController,
                            label: 'Địa chỉ',
                            hint: 'Nhập địa chỉ cửa hàng',
                            icon: Icons.location_on,
                          ),
                          const SizedBox(height: 16),

                          // Phone Number
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Số điện thoại',
                            hint: 'Nhập số điện thoại',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value)) {
                                  return 'Số điện thoại không hợp lệ';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Status Badge
                          if (_shop != null) _buildStatusSection(),
                          const SizedBox(height: 24),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveShop,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Lưu thay đổi',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBannerSection() {
    return GestureDetector(
      onTap: () => _showImageSourceDialog(false),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          image: _bannerFile != null
              ? DecorationImage(
                  image: FileImage(_bannerFile!),
                  fit: BoxFit.cover,
                )
              : _bannerUrl != null && _bannerUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(_bannerUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
        ),
        child: _bannerFile == null && (_bannerUrl == null || _bannerUrl!.isEmpty)
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text(
                    'Thêm ảnh bìa',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              )
            : Stack(
                children: [
                  Positioned(
                    right: 16,
                    top: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Center(
      child: GestureDetector(
        onTap: () => _showImageSourceDialog(true),
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            image: _logoFile != null
                ? DecorationImage(
                    image: FileImage(_logoFile!),
                    fit: BoxFit.cover,
                  )
                : _logoUrl != null && _logoUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(_logoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
          ),
          child: _logoFile == null && (_logoUrl == null || _logoUrl!.isEmpty)
              ? Icon(Icons.store, size: 50, color: Colors.grey[400])
              : Stack(
                  children: [
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (_shop!.status) {
      case 'ACTIVE':
        statusColor = Colors.green;
        statusText = 'Đang hoạt động';
        statusIcon = Icons.check_circle;
        break;
      case 'PENDING':
        statusColor = Colors.orange;
        statusText = 'Chờ duyệt';
        statusIcon = Icons.pending;
        break;
      case 'SUSPENDED':
        statusColor = Colors.red;
        statusText = 'Tạm ngừng';
        statusIcon = Icons.block;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Không xác định';
        statusIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trạng thái cửa hàng',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
