import 'package:admin_app/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductGallery extends StatefulWidget {
  final String productId; // Passed from the previous page
  const ProductGallery({super.key, required this.productId});

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  List<Map<String, dynamic>> _galleryImages = [];
  List<PlatformFile> _selectedFiles = [];
  bool _isUploading = false;

  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color(0xFFE94E1B);
  // static const Color fieldColor = Color(0xFF0D0D0D);

  @override
  void initState() {
    super.initState();
    fetchGallery();
  }

  Future<void> fetchGallery() async {
    try {
      final response = await supabase
          .from('tbl_gallery')
          .select()
          .eq('product_id', widget.productId);
      setState(() => _galleryImages = response);
    } catch (e) {
      debugPrint("Fetch Error: $e");
    }
  }

  Future<void> pickImages() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result != null) {
      setState(() {
        _selectedFiles = result.files;
      });
    }
  }

  Future<void> uploadAndSave() async {
    if (_selectedFiles.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      // We use a Future.wait or a loop to process all files
      for (var file in _selectedFiles) {
        if (file.bytes == null) continue;

        // Generate a unique path: gallery / productId / timestamp_filename
        final String extension = file.extension ?? 'jpg';
        final String fileName =
            "${DateTime.now().millisecondsSinceEpoch}_${file.name}";
        final String path = "gallery/${widget.productId}/$fileName";

        // 1. Upload to Supabase Storage
        // We use uploadBinary because we are on Web (using file.bytes)
        await supabase.storage
            .from('product')
            .uploadBinary(
              path,
              file.bytes!,
              fileOptions: FileOptions(
                contentType: 'image/$extension',
                upsert: true,
              ),
            );

        // 2. Get the Public URL
        final String imageUrl = supabase.storage
            .from('product')
            .getPublicUrl(path);

        // 3. Insert record into tbl_gallery linked to the current productId
        await supabase.from('tbl_gallery').insert({
          'gallery_file': imageUrl,
          'product_id': widget.productId, // This links it to your product
        });
      }

      _showSnackBar(
        'All images uploaded and saved successfully!',
        Colors.green,
      );

      // Clear the selection after success
      setState(() {
        _selectedFiles = [];
      });

      // Refresh the grid to show new images
      fetchGallery();
    } catch (e) {
      debugPrint("Detailed Upload Error: $e");
      _showSnackBar('Upload failed: ${e.toString()}', Colors.redAccent);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();

    return Scaffold(
      backgroundColor: bgColor,
      body: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: scrollController,
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1100),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildUploadCard(),
                  const SizedBox(height: 40),
                  const Text(
                    "Existing Gallery",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildImageGrid(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Product Gallery",
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "Manage additional photos for Product ID: ${widget.productId}",
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildUploadCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          if (_selectedFiles.isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _selectedFiles.map((file) {
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: MemoryImage(file.bytes!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedFiles.remove(file)),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          if (_selectedFiles.isNotEmpty) const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: pickImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text("SELECT IMAGES"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    side: const BorderSide(color: Colors.white10),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: _isUploading ? null : uploadAndSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 22,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "UPLOAD ${_selectedFiles.length} IMAGES",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    if (_galleryImages.isEmpty) {
      return const Center(
        child: Text(
          "No images in gallery yet",
          style: TextStyle(color: Colors.white24),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: _galleryImages.length,
      itemBuilder: (context, index) {
        final img = _galleryImages[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(img['gallery_file'], fit: BoxFit.cover),
                Positioned(
                  top: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () async {
                      await supabase
                          .from('tbl_gallery')
                          .delete()
                          .eq('gallery_id', img['gallery_id']);
                      fetchGallery();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
