import 'package:flutter/material.dart';
import 'package:merbabuaccess_app/services/paket_service.dart';
import 'package:merbabuaccess_app/models/paket_pendakian.dart';
import 'package:merbabuaccess_app/core/routes/app_routes.dart';
import 'package:merbabuaccess_app/core/theme/app_theme.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late Future<List<PaketPendakian>> _paketFuture;
  final PaketService _paketService = PaketService();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _paketFuture = _paketService.fetchPaketPendakian();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));
    
    setState(() {
      _paketFuture = _paketService.fetchPaketPendakian();
      _isRefreshing = false;
    });
  }

  // ✅ HELPER: GET IMAGE ASSET BASED ON INDEX
  String _getImageAsset(int index) {
    final images = [
      'assets/images/thekelan.jpg',
      'assets/images/wekas.jpg', 
      'assets/images/suwanting.jpeg',
    ];
    return images[index % images.length];
  }

  // ✅ HELPER: GET ROUTE BADGE COLOR
  Color _getRouteColor(String route) {
    final routeLower = route.toLowerCase();
    if (routeLower.contains('thekelan')) return Colors.blue;
    if (routeLower.contains('wekas')) return Colors.green;
    if (routeLower.contains('suwanting')) return Colors.orange;
    return AppTheme.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.primaryColor,
      backgroundColor: Colors.white,
      displacement: 40,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: CustomScrollView(
        slivers: [
          // ✅ HERO SECTION
          SliverAppBar(
            expandedHeight: 200,
            collapsedHeight: 0,
            toolbarHeight: 0,
            pinned: false,
            floating: true,
            snap: false,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Stack(
                  children: [
                    // Background Icons
                    Positioned(
                      right: 20,
                      top: 20,
                      child: Icon(
                        Icons.terrain,
                        size: 100,
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    Positioned(
                      left: 30,
                      bottom: 30,
                      child: Icon(
                        Icons.park,
                        size: 80,
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),

                    // ================= CONTENT =================
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 40,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang di',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'MerbabuAccess',
                            style: const TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Temukan pengalaman pendakian tak terlupakan di Gunung Merbabu',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.85),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ✅ HEADER SECTION
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Paket Pendakian',
                    style: AppTheme.titleLarge.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: FutureBuilder<List<PaketPendakian>>(
                      future: _paketFuture,
                      builder: (context, snapshot) {
                        final count = snapshot.hasData ? snapshot.data!.length : 0;
                        return Text(
                          '$count Paket',
                          style: AppTheme.labelMedium.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ PACKAGE LIST - PERBAIKAN UTAMA DI SINI
          FutureBuilder<List<PaketPendakian>>(
            future: _paketFuture,
            builder: (context, snapshot) {
              // LOADING STATE
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingShimmer();
              }

              // ERROR STATE
              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              // EMPTY STATE
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              // SUCCESS STATE - BUILD PACKAGE LIST
              final paketList = snapshot.data!;
              return _buildPaketList(paketList); // Ubah dari _buildPaketGrid
            },
          ),
        ],
      ),
    );
  }

  // ✅ LOADING SHIMMER EFFECT
  Widget _buildLoadingShimmer() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: AppTheme.borderRadiusMedium,
              ),
            );
          },
          childCount: 6,
        ),
      ),
    );
  }

  // ✅ ERROR STATE
  Widget _buildErrorState(String error) {
    return SliverFillRemaining(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Terjadi Kesalahan',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Gagal memuat data paket pendakian',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                error,
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.red[400],
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.borderRadiusMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ EMPTY STATE
  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 70,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Belum Ada Paket Tersedia',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Saat ini belum ada paket pendakian yang tersedia. Silakan cek kembali nanti atau hubungi admin untuk informasi lebih lanjut.',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.borderRadiusMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ PACKAGE LIST - DIPERBAIKI MENGGUNAKAN LIST VIEW UNTUK TAMPILAN YANG LEBIH RAPI
  Widget _buildPaketList(List<PaketPendakian> paketList) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final paket = paketList[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPaketCard(paket, index),
            );
          },
          childCount: paketList.length,
        ),
      ),
    );
  }

  // ✅ PACKAGE CARD - DIPERBAIKI AGAR LEBIH SESUAI DENGAN DESAIN GAMBAR
  Widget _buildPaketCard(PaketPendakian paket, int index) {
    final routeColor = _getRouteColor(paket.route);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusLarge,
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.detailPaket,
            arguments: paket,
          );
        },
        borderRadius: AppTheme.borderRadiusLarge,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ HEADER DENGAN NAMA PAKET DAN RATING
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      paket.name,
                      style: AppTheme.titleMedium.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '4.8',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ✅ JALUR BADGE
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: routeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: routeColor.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  'Jalur ${paket.route}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: routeColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ IMAGE SECTION
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(_getImageAsset(index)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ DETAILS SECTION
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    paket.duration,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.terrain,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    paket.route,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ✅ PRICE AND BUTTON SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mulai dari',
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.textDisabled,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${_formatPrice(paket.price)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ HELPER: FORMAT PRICE WITH COMMAS
  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}