import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isImageCached = false;

  @override
  void initState() {
    super.initState();
    // Pre-cache image di background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheAssets();
    });
  }

  Future<void> _precacheAssets() async {
    try {
      await precacheImage(
        const AssetImage('assets/images/Merbabu.jpg'),
        context,
      );
      setState(() => _isImageCached = true);
    } catch (e) {
      // Jika image tidak ada, tetap lanjut
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    // Unfocus keyboard untuk performance
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      if (mounted) {
        // Delay minimal untuk smooth transition
        await Future.delayed(const Duration(milliseconds: 200));
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains('network')
            ? 'Koneksi internet bermasalah'
            : 'Email atau password salah';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final safePadding = mediaQuery.padding.top;

    return Scaffold(
      resizeToAvoidBottomInset: false, // ⚡ Hindari rebuild berlebihan
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFB2DFDB),
              const Color(0xFFE0F2F1).withOpacity(0.9),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.6, 1.0], // ⚡ Optimasi gradient
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(), // ⚡ Lebih smooth
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: safePadding + 20,
                  bottom: 24 + 10,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - safePadding,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildHeader(),
                        SizedBox(height: screenHeight * 0.03),
                        Expanded(
                          child: _buildFormCard(),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // ⚡ LOGO OPTIMIZED - VERSION 4 (CircleAvatar + Pre-cached)
        CircleAvatar(
          radius: 40,
          backgroundColor: AppTheme.primaryColor,
          backgroundImage: _isImageCached
              ? const AssetImage('assets/images/Merbabu.jpg')
              : null,
          child: _isImageCached
              ? null
              : Icon(
                  Icons.terrain,
                  color: Colors.white,
                  size: 40,
                ),
        ),
        const SizedBox(height: 16),
        // ⚡ CACHE TEXT STYLES
        _buildCachedText(
          'MerbabuAccess',
          style: GoogleFonts.poppins(
            fontSize: 30,
            fontWeight: FontWeight.w700, // ⚡ w700 lebih optimal dari bold
            color: AppTheme.primaryColor,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        _buildCachedText(
          'Pendakian Digital Gunung Merbabu',
          style: GoogleFonts.nunito(
            fontSize: 13, // ⚡ Sedikit lebih kecil
            color: Colors.grey.shade700,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCachedText(String text,
      {required TextStyle style, TextAlign? textAlign}) {
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFormCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300), // ⚡ Lebih cepat
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(18), // ⚡ Padding lebih kecil
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // ⚡ Radius lebih kecil
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // ⚡ Lebih transparan
            blurRadius: 10, // ⚡ Lebih kecil
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorMessage != null) ...[
              _buildErrorMessage(),
              const SizedBox(height: 10),
            ],
            _buildEmailField(),
            const SizedBox(height: 10), // ⚡ Spasi lebih kecil
            _buildPasswordField(),
            const SizedBox(height: 18),
            _buildLoginButton(),
            const SizedBox(height: 10),
            _buildForgotPassword(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCachedText(
          'Email',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
          decoration: _inputDecoration(
            hintText: 'nama@email.com',
            icon: Icons.email_outlined,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email harus diisi';
            }
            final emailRegex = RegExp(
                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
            if (!emailRegex.hasMatch(value)) {
              return 'Format email tidak valid';
            }
            return null;
          },
          onFieldSubmitted: (_) =>
              FocusScope.of(context).nextFocus(), // ⚡ Navigasi field
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCachedText(
          'Password',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          decoration: _inputDecoration(
            hintText: 'Masukkan password',
            icon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20, // ⚡ Icon lebih kecil
                color: Colors.grey.shade600,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              padding: EdgeInsets.zero, // ⚡ Padding zero
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password harus diisi';
            }
            if (value.length < 6) {
              return 'Minimal 6 karakter';
            }
            return null;
          },
          onFieldSubmitted: (_) => _login(),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.nunito(
        fontSize: 14,
        color: Colors.grey.shade500,
      ),
      prefixIcon: Icon(
        icon,
        size: 20, // ⚡ Icon lebih kecil
        color: Colors.grey.shade600,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14, // ⚡ Padding lebih kecil
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        gapPadding: 0,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
      isDense: true, // ⚡ Kurang padding internal
    );
  }

  Widget _buildErrorMessage() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(_errorMessage),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade100, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCachedText(
                _errorMessage!,
                style: GoogleFonts.poppins(
                  color: Colors.red.shade800,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 44, // ⚡ Lebih kecil
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login_rounded, size: 18),
                  const SizedBox(width: 8),
                  _buildCachedText(
                    'Masuk ke Akun',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return TextButton(
      onPressed: _isLoading ? null : () => _showForgotPasswordDialog(context),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: _buildCachedText(
        'Lupa Password?',
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

    Widget _buildFooter() {
  return IntrinsicHeight( // ⚡ GUNAKAN IntrinsicHeight untuk mengatur tinggi dinamis
    child: Column(
      mainAxisSize: MainAxisSize.min, // ⚡ PASTIKAN mainAxisSize.min
      children: [
        _buildCachedText(
          'Belum punya akun?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6), // ⚡ KURANGI dari 8 jadi 6
        SizedBox(
          height: 40, // ⚡ KURANGI dari 42 jadi 40
          child: OutlinedButton(
            onPressed: _isLoading
                ? null
                : () => Navigator.pushNamed(context, AppRoutes.register),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.primaryColor, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 6),
                _buildCachedText(
                  'Daftar Sekarang',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18), // ⚡ KURANGI dari 20 jadi 18
        _buildCachedText(
          '© 2026 MerbabuAccess',
          style: GoogleFonts.nunito(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    ),
  );
}
  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    final emailController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: _buildCachedText(
          'Reset Password',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCachedText(
              'Masukkan email untuk reset password',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(
                hintText: 'email@domain.com',
                icon: Icons.email,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: _buildCachedText(
              'Batal',
              style: GoogleFonts.poppins(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: _buildCachedText(
                    'Link reset password telah dikirim',
                    style: GoogleFonts.nunito(color: Colors.white),
                  ),
                  backgroundColor: AppTheme.primaryColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: _buildCachedText('Kirim', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    emailController.dispose();
  }
}