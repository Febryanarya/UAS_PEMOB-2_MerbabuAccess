import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/paket_pendakian.dart';
import '../../models/cart_item_model.dart';
import '../../services/cart_service.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';

class DetailPaketScreen extends StatefulWidget {
  final PaketPendakian paket;

  const DetailPaketScreen({super.key, required this.paket});

  @override
  State<DetailPaketScreen> createState() => _DetailPaketScreenState();
}

class _DetailPaketScreenState extends State<DetailPaketScreen>
    with SingleTickerProviderStateMixin {
  final CartService _cartService = CartService();
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  int _jumlahOrang = 1;
  bool _isAddingToCart = false;
  final PageController _imageController = PageController();
  int _currentImageIndex = 0;
  final ScrollController _scrollController = ScrollController();

  // Simulasi gallery images
  final List<String> _galleryImages = [
    'assets/images/thekelan.jpg',
    'assets/images/wekas.jpg',
    'assets/images/suwanting.jpeg',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _imageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _addToCart() async {
    if (_isAddingToCart) return;

    setState(() => _isAddingToCart = true);

    try {
      final cartItem = CartItem(
        paketId: widget.paket.id,
        paketName: widget.paket.name,
        paketRoute: widget.paket.route,
        paketPrice: widget.paket.price.toDouble(),
        imageUrl: widget.paket.image,
        tanggalBooking: _selectedDate,
        jumlahOrang: _jumlahOrang,
      );

      await _cartService.addToCart(cartItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.paket.name} ditambahkan ke keranjang'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'Lihat',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
            textColor: Colors.white,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      setState(() => _isAddingToCart = false);
    }
  }

  double get _totalPrice {
    return widget.paket.price * _jumlahOrang;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            NestedScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  // ✅ HERO IMAGE SLIVER
                  SliverAppBar(
                    expandedHeight: 280,
                    collapsedHeight: kToolbarHeight + MediaQuery.of(context).padding.top,
                    pinned: true,
                    floating: true,
                    snap: false,
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: _buildHeroImage(),
                      titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                      title: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.paket.route.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, size: 20),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.share, size: 20),
                        ),
                        onPressed: () {
                          // Share functionality
                        },
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite_border, size: 20),
                        ),
                        onPressed: () {
                          // Favorite functionality
                        },
                      ),
                    ],
                  ),
                ];
              },
              body: Column(
                children: [
                  // ✅ PACKET HEADER INFO
                  Container(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.paket.name,
                                      style: AppTheme.headlineSmall.copyWith(
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.terrain,
                                          size: 16,
                                          color: AppTheme.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Gunung Merbabu',
                                          style: AppTheme.bodyMedium.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.primaryColor,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Rp ${_formatPrice(widget.paket.price)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    Text(
                                      'per orang',
                                      style: AppTheme.labelSmall.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ✅ RATING & REVIEW
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.cardDecoration,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.amber.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '4.8/5.0',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.amber[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ulasan Terbaik',
                                        style: AppTheme.labelMedium.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        '250+ pendaki puas',
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppTheme.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ✅ TAB BAR HEADER
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primaryColor,
                      unselectedLabelColor: AppTheme.textSecondary,
                      indicatorColor: AppTheme.primaryColor,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(text: 'Deskripsi'),
                        Tab(text: 'Fasilitas'),
                        Tab(text: 'Syarat'),
                      ],
                    ),
                  ),

                  // ✅ TAB VIEW CONTENT
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDescriptionTab(),
                        _buildFacilitiesTab(),
                        _buildRequirementsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ✅ STICKY BOOKING PANEL (BOTTOM)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBookingPanel(),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ HERO IMAGE WITH GALLERY
  Widget _buildHeroImage() {
    return Stack(
      children: [
        PageView.builder(
          controller: _imageController,
          itemCount: _galleryImages.length,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return Image.asset(
              _galleryImages[index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            );
          },
        ),
        
        // Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        
        // Image Dots Indicator
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _galleryImages.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == index
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ DESCRIPTION TAB
  Widget _buildDescriptionTab() {
    return SingleChildScrollView(
      controller: ScrollController(),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tentang Pendakian',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.paket.description,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            'Itinerary Pendakian',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildItineraryItem(
            day: 'Hari 1',
            time: '06:00 - 09:00',
            title: 'Registrasi & Briefing',
            description: 'Registrasi di basecamp dan briefing keamanan',
          ),
          _buildItineraryItem(
            day: 'Hari 1',
            time: '09:00 - 15:00',
            title: 'Pendakian ke Pos 3',
            description: 'Pendakian melalui jalur hutan pinus',
          ),
          _buildItineraryItem(
            day: 'Hari 1',
            time: '15:00 - 17:00',
            title: 'Setup Camp',
            description: 'Mendirikan tenda dan persiapan malam',
          ),
          _buildItineraryItem(
            day: 'Hari 2',
            time: '03:00 - 06:00',
            title: 'Sunrise Summit',
            description: 'Pendakian ke puncak untuk melihat sunrise',
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Tingkat Kesulitan',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDifficultyLevel('Pemula', 1, total: 5),
              _buildDifficultyLevel('Menengah', 3, total: 5),
              _buildDifficultyLevel('Expert', 5, total: 5),
            ],
          ),
          
          const SizedBox(height: 80), // Extra space for bottom panel
        ],
      ),
    );
  }

  // ✅ FACILITIES TAB
  Widget _buildFacilitiesTab() {
    final facilities = [
      {'icon': Icons.holiday_village, 'title': 'Tenda Camping', 'desc': 'Tenda 2-3 orang'},
      {'icon': Icons.restaurant_menu, 'title': 'Makan 3x', 'desc': 'Sarapan, makan siang, makan malam'},
      {'icon': Icons.local_drink, 'title': 'Air Mineral', 'desc': 'Supply air selama pendakian'},
      {'icon': Icons.medical_services, 'title': 'P3K', 'desc': 'Kit pertolongan pertama'},
      {'icon': Icons.person, 'title': 'Pemandu', 'desc': 'Guide profesional'},
      {'icon': Icons.backpack, 'title': 'Porter', 'desc': 'Bantuan membawa barang'},
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fasilitas Termasuk',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
            ),
            itemCount: facilities.length,
            itemBuilder: (context, index) {
              final facility = facilities[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      facility['icon'] as IconData,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      facility['title'] as String,
                      style: AppTheme.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      facility['desc'] as String,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Tidak Termasuk',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          
          Column(
            children: [
              _buildExcludedItem('Transportasi ke basecamp'),
              _buildExcludedItem('Asuransi perjalanan'),
              _buildExcludedItem('Perlengkapan pribadi'),
              _buildExcludedItem('Tips untuk guide dan porter'),
            ],
          ),
          
          const SizedBox(height: 80), // Extra space for bottom panel
        ],
      ),
    );
  }

  // ✅ REQUIREMENTS TAB
  Widget _buildRequirementsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Persyaratan Peserta',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildRequirementItem(
            'Usia minimal 17 tahun',
            'Harus menunjukkan KTP/SIM',
          ),
          _buildRequirementItem(
            'Kesehatan fisik yang baik',
            'Disarankan medical check-up',
          ),
          _buildRequirementItem(
            'Pengalaman pendakian',
            'Minimal pernah naik gunung rendah',
          ),
          _buildRequirementItem(
            'Surat izin orang tua',
            'Untuk peserta di bawah 21 tahun',
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Dokumen yang Diperlukan',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDocumentChip('KTP/SIM'),
              _buildDocumentChip('Kartu Vaksin'),
              _buildDocumentChip('Surat Sehat'),
              _buildDocumentChip('Asuransi'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Colors.orange[800],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Penting!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Pendakian dapat dibatalkan jika kondisi cuaca tidak memungkinkan. Keputusan guide dan tim safety adalah mutlak.',
                  style: AppTheme.bodyMedium.copyWith(
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 80), // Extra space for bottom panel
        ],
      ),
    );
  }

  // ✅ BOOKING PANEL (STICKY BOTTOM)
  Widget _buildBookingPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Date & People Selector
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tanggal',
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialEntryMode: DatePickerEntryMode.calendar,
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppTheme.primaryColor,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _selectedDate = pickedDate;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd MMM yyyy').format(_selectedDate),
                              style: AppTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jumlah Orang',
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_jumlahOrang > 1) {
                                setState(() => _jumlahOrang--);
                              }
                            },
                            icon: Icon(
                              Icons.remove,
                              size: 20,
                              color: _jumlahOrang > 1
                                  ? AppTheme.primaryColor
                                  : AppTheme.textDisabled,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Text(
                            '$_jumlahOrang',
                            style: AppTheme.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (_jumlahOrang < widget.paket.quota) {
                                setState(() => _jumlahOrang++);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Maksimal ${widget.paket.quota} orang'),
                                    backgroundColor: AppTheme.warningColor,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            icon: Icon(
                              Icons.add,
                              size: 20,
                              color: _jumlahOrang < widget.paket.quota
                                  ? AppTheme.primaryColor
                                  : AppTheme.textDisabled,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Price Summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Pembayaran',
                      style: AppTheme.labelMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      'Rp ${_formatPrice(_totalPrice)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_jumlahOrang} orang × Rp ${_formatPrice(widget.paket.price)}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isAddingToCart ? null : _addToCart,
                  icon: _isAddingToCart
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : const Icon(Icons.shopping_cart_outlined, size: 20),
                  label: Text(
                    _isAddingToCart ? '...' : 'Keranjang',
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.bookingForm,
                      arguments: widget.paket,
                    );
                  },
                  icon: const Icon(Icons.rocket_launch, size: 20),
                  label: const Text(
                    'Booking Sekarang',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ HELPER WIDGETS
  Widget _buildItineraryItem({
    required String day,
    required String time,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              day,
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: AppTheme.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyLevel(String label, int level, {int total = 5}) {
    final isActive = level <= 3; // Example: Beginner friendly
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTheme.labelSmall.copyWith(
                color: isActive
                    ? AppTheme.primaryColor
                    : AppTheme.textDisabled,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(total, (index) {
                return Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < level
                        ? (isActive
                            ? AppTheme.primaryColor
                            : Colors.grey)
                        : Colors.grey.withOpacity(0.3),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExcludedItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.close,
            size: 16,
            color: AppTheme.errorColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppTheme.successColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Text(
        text,
        style: AppTheme.labelSmall.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ✅ HELPER: FORMAT PRICE
  String _formatPrice(double price) {
    return NumberFormat('#,##0', 'id_ID').format(price);
  }
}