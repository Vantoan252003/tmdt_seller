import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/shop.dart';
import '../services/shop_service.dart';
import '../services/google_maps_service.dart';
import '../services/address_service.dart';
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

  // Address data
  double? _latitude;
  double? _longitude;
  String _addressLine = '';
  String _ward = '';
  String _district = '';
  String _city = '';
  String _fullAddress = '';

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

      // Fetch shop addresses to get detailed address data
      final addressesResult = await ShopService.getShopAddresses(_shop!.shopId);
      if (addressesResult['success'] == true) {
        final addresses = addressesResult['data'] as List<dynamic>;
        if (addresses.isNotEmpty) {
          // Use the first address or find the default one
          Map<String, dynamic>? defaultAddress;
          for (var addr in addresses) {
            if (addr['isDefault'] == true) {
              defaultAddress = addr;
              break;
            }
          }
          final address = defaultAddress ?? addresses[0];

          // Populate address fields
          _latitude = address['latitude'];
          _longitude = address['longitude'];
          _addressLine = address['addressLine'] ?? '';
          _ward = address['ward'] ?? '';
          _district = address['district'] ?? '';
          _city = address['city'] ?? '';
          _fullAddress = address['formattedAddress'] ?? address['addressLine'] ?? '';
          
          // Update the address controller to show the formatted address
          _addressController.text = _fullAddress;
        }
      }
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
                          _buildAddressField(),
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

  Widget _buildAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Địa chỉ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showShopAddressDialog(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _fullAddress.isNotEmpty 
                        ? _fullAddress 
                        : (_shop?.address != null && _shop!.address!.isNotEmpty 
                            ? _shop!.address! 
                            : 'Chọn địa chỉ cửa hàng'),
                    style: TextStyle(
                      color: _fullAddress.isNotEmpty || (_shop?.address != null && _shop!.address!.isNotEmpty) 
                          ? AppTheme.textPrimary 
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
                Icon(Icons.map, color: AppTheme.primaryColor),
              ],
            ),
          ),
        ),
      ],
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

  void _showShopAddressDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ShopMapAddressDialog(
          shop: _shop,
          initialAddress: _fullAddress,
          initialLatitude: _latitude,
          initialLongitude: _longitude,
          onAddressSelected: (addressData) {
            setState(() {
              _latitude = addressData['latitude'];
              _longitude = addressData['longitude'];
              _addressLine = addressData['addressLine'];
              _ward = addressData['ward'];
              _district = addressData['district'];
              _city = addressData['city'];
              _fullAddress = addressData['fullAddress'];
            });
          },
        );
      },
    );
  }
}

// Shop Map Address Dialog
class ShopMapAddressDialog extends StatefulWidget {
  final Shop? shop;
  final String initialAddress;
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(Map<String, dynamic>) onAddressSelected;

  const ShopMapAddressDialog({
    super.key,
    this.shop,
    required this.initialAddress,
    this.initialLatitude,
    this.initialLongitude,
    required this.onAddressSelected,
  });

  @override
  State<ShopMapAddressDialog> createState() => _ShopMapAddressDialogState();
}

class _ShopMapAddressDialogState extends State<ShopMapAddressDialog> {
  final _formKey = GlobalKey<FormState>();
  final _recipientNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _searchController = TextEditingController();

  GoogleMapController? _mapController;
  final GoogleMapsService _mapsService = GoogleMapsService();

  // Location data
  double? _latitude;
  double? _longitude;
  String _addressLine = '';
  String _ward = '';
  String _district = '';
  String _city = '';
  String _fullAddress = '';

  bool _isLoading = false;
  bool _isLoadingLocation = false;
  bool _isSearching = false;

  List<Map<String, dynamic>> _searchResults = [];
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();

    // Initialize with shop data
    if (widget.shop != null) {
      _recipientNameController.text = widget.shop!.shopName;
      _phoneController.text = widget.shop!.phoneNumber ?? '';
    }

    // Initialize with existing address data
    if (widget.initialAddress.isNotEmpty) {
      _fullAddress = widget.initialAddress;
      _latitude = widget.initialLatitude;
      _longitude = widget.initialLongitude;
      if (_latitude != null && _longitude != null) {
        _markers = {
          Marker(
            markerId: const MarkerId('selected_location'),
            position: LatLng(_latitude!, _longitude!),
            infoWindow: InfoWindow(
              title: 'Địa chỉ cửa hàng',
              snippet: _fullAddress,
            ),
          ),
        };
      }
    } else {
      // Get current location for new address
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    print('🗺️ ShopMapAddressDialog: Getting current location...');
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await _mapsService.getCurrentLocation();
      print('✅ Got GPS position: ${position.latitude}, ${position.longitude}');
      
      final addressData = await _mapsService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      print('📍 Address data: $addressData');

      if (addressData['success']) {
        print('✅ Address retrieved successfully');
        setState(() {
          _latitude = addressData['latitude'];
          _longitude = addressData['longitude'];
          _addressLine = addressData['addressLine'] ?? '';
          _ward = addressData['ward'] ?? '';
          _district = addressData['district'] ?? '';
          _city = addressData['city'] ?? '';
          _fullAddress = addressData['fullAddress'] ?? '';

          _markers = {
            Marker(
              markerId: const MarkerId('selected_location'),
              position: LatLng(_latitude!, _longitude!),
              infoWindow: InfoWindow(
                title: 'Vị trí hiện tại',
                snippet: _fullAddress,
              ),
            ),
          };
        });

        // Move camera to current location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_latitude!, _longitude!),
            16,
          ),
        );
      } else {
        print('❌ Address retrieval failed: ${addressData['message']}');
      }
    } catch (e) {
      print('❌ Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể lấy vị trí: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
      print('🗺️ ShopMapAddressDialog: Loading location finished');
      print('Current state - Lat: $_latitude, Lng: $_longitude, Address: $_fullAddress');
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _mapsService.searchPlaces(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tìm kiếm: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _selectPlace(String placeId) async {
    print('🗺️ Selecting place with ID: $placeId');
    setState(() {
      _isLoadingLocation = true;
      _searchResults = [];
      _searchController.clear();
    });

    try {
      final placeDetails = await _mapsService.getPlaceDetails(placeId);
      print('📍 Place details result: $placeDetails');

      if (placeDetails['success']) {
        print('✅ Place details retrieved successfully');
        setState(() {
          _latitude = placeDetails['latitude'];
          _longitude = placeDetails['longitude'];
          _addressLine = placeDetails['addressLine'] ?? '';
          _ward = placeDetails['ward'] ?? '';
          _district = placeDetails['district'] ?? '';
          _city = placeDetails['city'] ?? '';
          _fullAddress = placeDetails['fullAddress'] ?? '';

          _markers = {
            Marker(
              markerId: const MarkerId('selected_location'),
              position: LatLng(_latitude!, _longitude!),
              infoWindow: InfoWindow(
                title: 'Địa chỉ đã chọn',
                snippet: _fullAddress,
              ),
            ),
          };
        });

        // Move camera to selected location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_latitude!, _longitude!),
            16,
          ),
        );
      } else {
        print('❌ Place details retrieval failed');
      }
    } catch (e) {
      print('❌ Error selecting place: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn địa điểm: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _onMapTap(LatLng position) async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final addressData = await _mapsService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (addressData['success']) {
        setState(() {
          _latitude = addressData['latitude'];
          _longitude = addressData['longitude'];
          _addressLine = addressData['addressLine'] ?? '';
          _ward = addressData['ward'] ?? '';
          _district = addressData['district'] ?? '';
          _city = addressData['city'] ?? '';
          _fullAddress = addressData['fullAddress'] ?? '';

          _markers = {
            Marker(
              markerId: const MarkerId('selected_location'),
              position: LatLng(_latitude!, _longitude!),
              infoWindow: InfoWindow(
                title: 'Địa chỉ đã chọn',
                snippet: _fullAddress,
              ),
            ),
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lấy địa chỉ: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _phoneController.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
                const Expanded(
                  child: Text(
                    'Chọn địa chỉ cửa hàng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48), // Balance for close button
              ],
            ),
            const SizedBox(height: 16),

            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm địa điểm...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: _searchPlaces,
            ),

            // Search results
            if (_searchResults.isNotEmpty)
              Expanded(
                flex: 1,
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(result['description'] ?? ''),
                      onTap: () => _selectPlace(result['place_id']),
                    );
                  },
                ),
              )
            else
              // Map
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _latitude != null && _longitude != null
                            ? LatLng(_latitude!, _longitude!)
                            : const LatLng(10.8231, 106.6297), // Default to Ho Chi Minh City
                        zoom: 12,
                      ),
                      onMapCreated: (controller) {
                        _mapController = controller;
                        if (_latitude != null && _longitude != null) {
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              LatLng(_latitude!, _longitude!),
                              16,
                            ),
                          );
                        }
                      },
                      markers: _markers,
                      onTap: _onMapTap,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                    ),
                    if (_isLoadingLocation)
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Recipient Name (Shop Name)
                  TextFormField(
                    controller: _recipientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên cửa hàng',
                      prefixIcon: Icon(Icons.store),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên cửa hàng';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Phone
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
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
                  const SizedBox(height: 12),

                  // Address display
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _fullAddress.isNotEmpty
                                ? _fullAddress
                                : 'Chưa chọn địa chỉ',
                            style: TextStyle(
                              color: _fullAddress.isNotEmpty
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Lưu địa chỉ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn địa chỉ trên bản đồ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // First, get existing shop addresses
      final existingAddressesResult = await ShopService.getShopAddresses(widget.shop!.shopId);
      
      if (existingAddressesResult['success'] == true) {
        final existingAddresses = existingAddressesResult['data'] as List<dynamic>;
        
        // Delete all existing shop addresses
        final addressService = AddressService();
        for (var address in existingAddresses) {
          final addressId = address['addressId'] ?? address['id'];
          if (addressId != null) {
            try {
              await addressService.deleteAddress(addressId.toString());
              print('Deleted existing shop address: $addressId');
            } catch (deleteError) {
              print('Error deleting address $addressId: $deleteError');
              // Continue with other deletions
            }
          }
        }
      }

      // Now create the new shop address
      final result = await ShopService.updateShopAddress(
        shopId: widget.shop!.shopId,
        recipientName: _recipientNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        addressLine: _addressLine,
        ward: _ward,
        district: _district,
        city: _city,
        latitude: _latitude!,
        longitude: _longitude!,
        formattedAddress: _fullAddress,
      );

      if (result['success'] == true) {
        // Pass the address data back
        widget.onAddressSelected({
          'latitude': _latitude,
          'longitude': _longitude,
          'addressLine': _addressLine,
          'ward': _ward,
          'district': _district,
          'city': _city,
          'fullAddress': _fullAddress,
        });

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật địa chỉ thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Lỗi cập nhật địa chỉ'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
