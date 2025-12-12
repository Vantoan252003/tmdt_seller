import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_theme.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/shop.dart';
import '../services/category_service.dart';
import '../services/seller_service.dart';
import '../services/shop_service.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _weightController;
  late TextEditingController _discountController;

  // Data
  List<Category> _categories = [];
  String? _selectedCategoryId;
  String _selectedStatus = 'ACTIVE';
  bool _isLoading = false;
  bool _isLoadingData = true;
  Shop? _shop;

  // Images - current images from server
  String? _currentMainImageUrl;
  String? _currentImage1Url;
  String? _currentImage2Url;
  String? _currentImage3Url;
  String? _currentImage4Url;

  // New images to upload
  File? _mainImage;
  File? _image1;
  File? _image2;
  File? _image3;
  File? _image4;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadCategories();
    _loadProductData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.product.productName);
    _descriptionController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _stockController = TextEditingController(text: widget.product.stockQuantity.toString());
    _weightController = TextEditingController(text: widget.product.weight.toString());
    _discountController = TextEditingController(text: widget.product.discountPercentage.toString());
    _selectedCategoryId = widget.product.categoryId;
    _selectedStatus = widget.product.status;

    // Load current images
    _currentMainImageUrl = widget.product.mainImageUrl;
    _currentImage1Url = widget.product.imageUrl1;
    _currentImage2Url = widget.product.imageUrl2;
    _currentImage3Url = widget.product.imageUrl3;
    _currentImage4Url = widget.product.imageUrl4;
  }

  Future<void> _loadCategories() async {
    try {
      final categoryService = CategoryService();
      final categories = await categoryService.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh mục: $e')),
        );
      }
    }
  }

  Future<void> _loadProductData() async {
    try {
      // Load shop information
      final shopResult = await ShopService.getMyShop();
      if (shopResult['success'] == true) {
        _shop = shopResult['data'];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thông tin shop: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _weightController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chỉnh sửa sản phẩm'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa sản phẩm'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Product Images
            _buildImageSection(),
            const SizedBox(height: 24),

            // Product Name
            _buildTextField(
              controller: _nameController,
              label: 'Tên sản phẩm',
              hint: 'Nhập tên sản phẩm',
              icon: Icons.shopping_bag_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên sản phẩm';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'Mô tả sản phẩm',
              hint: 'Nhập mô tả chi tiết',
              icon: Icons.description_outlined,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mô tả';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category
            _buildCategoryDropdown(),
            const SizedBox(height: 16),

            // Price and Discount
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _priceController,
                    label: 'Giá (đ)',
                    hint: '0',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nhập giá';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _discountController,
                    label: 'Giảm giá (%)',
                    hint: '0',
                    icon: Icons.discount_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stock and Weight
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _stockController,
                    label: 'Số lượng',
                    hint: '0',
                    icon: Icons.inventory_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nhập số lượng';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _weightController,
                    label: 'Khối lượng (g)',
                    hint: '0',
                    icon: Icons.fitness_center_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status
            _buildStatusDropdown(),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Cập nhật sản phẩm',
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
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hình ảnh sản phẩm',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        // Main Image
        _buildImagePicker(
          label: 'Ảnh chính',
          currentImageUrl: _currentMainImageUrl,
          newImage: _mainImage,
          onTap: () => _pickImage(0),
          onRemove: () => _removeImage(0),
        ),
        const SizedBox(height: 12),
        // Additional Images
        const Text(
          'Ảnh phụ (tùy chọn)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSmallImagePicker(
                currentImageUrl: _currentImage1Url,
                newImage: _image1,
                onTap: () => _pickImage(1),
                onRemove: () => _removeImage(1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSmallImagePicker(
                currentImageUrl: _currentImage2Url,
                newImage: _image2,
                onTap: () => _pickImage(2),
                onRemove: () => _removeImage(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSmallImagePicker(
                currentImageUrl: _currentImage3Url,
                newImage: _image3,
                onTap: () => _pickImage(3),
                onRemove: () => _removeImage(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSmallImagePicker(
                currentImageUrl: _currentImage4Url,
                newImage: _image4,
                onTap: () => _pickImage(4),
                onRemove: () => _removeImage(4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePicker({
    required String label,
    required String? currentImageUrl,
    required File? newImage,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              image: newImage != null
                  ? DecorationImage(
                      image: FileImage(newImage),
                      fit: BoxFit.cover,
                    )
                  : currentImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(currentImageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
            ),
            child: (newImage == null && currentImageUrl == null)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Thêm hình ảnh',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: onRemove,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallImagePicker({
    required String? currentImageUrl,
    required File? newImage,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          image: newImage != null
              ? DecorationImage(
                  image: FileImage(newImage),
                  fit: BoxFit.cover,
                )
              : currentImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(currentImageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
        ),
        child: (newImage == null && currentImageUrl == null)
            ? Icon(
                Icons.add_photo_alternate_outlined,
                size: 32,
                color: Colors.grey[400],
              )
            : Stack(
                children: [
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      switch (index) {
        case 0:
          _mainImage = null;
          _currentMainImageUrl = null;
          break;
        case 1:
          _image1 = null;
          _currentImage1Url = null;
          break;
        case 2:
          _image2 = null;
          _currentImage2Url = null;
          break;
        case 3:
          _image3 = null;
          _currentImage3Url = null;
          break;
        case 4:
          _image4 = null;
          _currentImage4Url = null;
          break;
      }
    });
  }

  Future<void> _pickImage(int index) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          switch (index) {
            case 0:
              _mainImage = File(pickedFile.path);
              break;
            case 1:
              _image1 = File(pickedFile.path);
              break;
            case 2:
              _image2 = File(pickedFile.path);
              break;
            case 3:
              _image3 = File(pickedFile.path);
              break;
            case 4:
              _image4 = File(pickedFile.path);
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e')),
        );
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
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
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh mục',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategoryId,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.category_outlined, color: AppTheme.primaryColor),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          hint: const Text('Chọn danh mục'),
          items: _categories.map((category) {
            return DropdownMenuItem<String>(
              value: category.categoryId,
              child: Text(category.categoryName),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategoryId = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng chọn danh mục';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trạng thái',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedStatus,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.check_circle_outline, color: AppTheme.primaryColor),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: const [
            DropdownMenuItem(value: 'ACTIVE', child: Text('Đang bán')),
            DropdownMenuItem(value: 'INACTIVE', child: Text('Ngừng bán')),
            DropdownMenuItem(value: 'OUT_OF_STOCK', child: Text('Hết hàng')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedStatus = value ?? 'ACTIVE';
            });
          },
        ),
      ],
    );
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_shop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đợi tải thông tin shop')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Determine which image URLs to send
      // If user selected new images, don't send current URLs (let upload handle it)
      // If no new images, send current URLs to preserve them
      String? mainImageUrlToSend;
      String? imageUrl1ToSend;
      String? imageUrl2ToSend;
      String? imageUrl3ToSend;
      String? imageUrl4ToSend;

      if (_mainImage == null && _currentMainImageUrl != null) {
        mainImageUrlToSend = _currentMainImageUrl;
      }
      if (_image1 == null && _currentImage1Url != null) {
        imageUrl1ToSend = _currentImage1Url;
      }
      if (_image2 == null && _currentImage2Url != null) {
        imageUrl2ToSend = _currentImage2Url;
      }
      if (_image3 == null && _currentImage3Url != null) {
        imageUrl3ToSend = _currentImage3Url;
      }
      if (_image4 == null && _currentImage4Url != null) {
        imageUrl4ToSend = _currentImage4Url;
      }

      final result = await SellerService.updateProduct(
        shopId: _shop!.shopId,
        productId: widget.product.productId,
        categoryId: _selectedCategoryId!,
        productName: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        stockQuantity: int.parse(_stockController.text),
        discountPercentage: double.tryParse(_discountController.text) ?? 0.0,
        weight: double.tryParse(_weightController.text) ?? 0.0,
        status: _selectedStatus,
        mainImageUrl: mainImageUrlToSend,
        imageUrl1: imageUrl1ToSend,
        imageUrl2: imageUrl2ToSend,
        imageUrl3: imageUrl3ToSend,
        imageUrl4: imageUrl4ToSend,
      );

      if (result['success'] == true) {
        // Upload new images if any
        if (_mainImage != null || _image1 != null || _image2 != null || _image3 != null || _image4 != null) {
          final uploadResult = await SellerService.uploadProductImages(
            productId: widget.product.productId,
            mainImage: _mainImage,
            image1: _image1,
            image2: _image2,
            image3: _image3,
            image4: _image4,
          );

          if (uploadResult['success'] != true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Cảnh báo: ${uploadResult['message']}')),
            );
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}