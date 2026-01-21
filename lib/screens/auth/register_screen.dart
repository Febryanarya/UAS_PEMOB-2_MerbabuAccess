import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ⚡ Hanya gunakan controller yang diperlukan
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  final AuthService _authService = AuthService();
  
  // ⚡ State minimalis
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;
  int _currentStep = 0;
  String? _errorMessage;

  // ⚡ Hapus _RegisterFormData yang tidak perlu
  // ⚡ Hapus real-time validation yang berat
  // ⚡ Gunakan Form Key hanya untuk validation final

  @override
  void initState() {
    super.initState();
    // ⚡ Hindari listener yang berat, validation cukup di form submit
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // ⚡ Validasi ringan tanpa real-time
    if (_fullNameController.text.trim().length < 3) {
      _showError('Nama minimal 3 karakter');
      return;
    }
    
    final email = _emailController.text.trim();
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      _showError('Format email tidak valid');
      return;
    }
    
    final phone = _phoneController.text.trim();
    if (phone.length < 10 || phone.length > 13 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      _showError('Nomor telepon 10-13 digit angka');
      return;
    }
    
    final password = _passwordController.text.trim();
    if (password.length < 6) {
      _showError('Password minimal 6 karakter');
      return;
    }
    
    if (password != _confirmPasswordController.text.trim()) {
      _showError('Password tidak cocok');
      return;
    }
    
    if (!_termsAccepted) {
      _showError('Harap setujui Syarat & Ketentuan');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.register(
        email: email,
        password: password,
        fullName: _fullNameController.text.trim(),
        phoneNumber: phone,
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      _handleRegistrationError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
      
      // ⚡ Auto clear error setelah 4 detik
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted && _errorMessage != null) {
          setState(() => _errorMessage = null);
        }
      });
    }
  }

  void _handleRegistrationError(dynamic e) {
    String errorMessage;
    
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Email sudah terdaftar';
          break;
        case 'weak-password':
          errorMessage = 'Password terlalu lemah';
          break;
        case 'invalid-email':
          errorMessage = 'Format email tidak valid';
          break;
        case 'network-request-failed':
          errorMessage = 'Koneksi internet bermasalah';
          break;
        case 'too-many-requests':
          errorMessage = 'Terlalu banyak percobaan';
          break;
        default:
          errorMessage = 'Registrasi gagal. Silakan coba lagi';
      }
    } else {
      errorMessage = 'Terjadi kesalahan. Silakan coba lagi';
    }
    
    _showError(errorMessage);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // ⚡ Lebih kecil
        ),
        child: Padding(
          padding: const EdgeInsets.all(24), // ⚡ Lebih kecil
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60, // ⚡ Lebih kecil
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 36, // ⚡ Lebih kecil
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Berhasil!',
                style: GoogleFonts.poppins(
                  fontSize: 20, // ⚡ Lebih kecil
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Akun Anda telah berhasil dibuat',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13, // ⚡ Lebih kecil
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, AppRoutes.home);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14), // ⚡ Lebih kecil
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Mulai',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepCircle(0, 'Data'),
          Container(
            height: 2,
            width: 30, // ⚡ Lebih kecil
            color: _currentStep >= 1 ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
          _buildStepCircle(1, 'Akun'),
          Container(
            height: 2,
            width: 30,
            color: _currentStep >= 2 ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
          _buildStepCircle(2, 'Selesai'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    bool isActive = step <= _currentStep;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32, // ⚡ Lebih kecil
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : Colors.grey.shade300,
            shape: BoxShape.circle,
            border: step == _currentStep 
                ? Border.all(color: Colors.white, width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              (step + 1).toString(),
              style: GoogleFonts.poppins(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11, // ⚡ Lebih kecil
            color: isActive ? AppTheme.primaryColor : Colors.grey.shade500,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data Diri',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Lengkapi data diri Anda',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),

        // Full Name
        _buildTextField(
          controller: _fullNameController,
          label: 'Nama Lengkap',
          hint: 'Masukkan nama lengkap',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),

        // Email
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'nama@email.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),

        // Phone Number
        _buildTextField(
          controller: _phoneController,
          label: 'Nomor Telepon',
          hint: '081234567890',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildAccountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keamanan Akun',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Buat password yang aman',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),

        // Password
        _buildPasswordField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Minimal 6 karakter',
          obscure: _obscurePassword,
          onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        const SizedBox(height: 16),

        // Confirm Password
        _buildPasswordField(
          controller: _confirmPasswordController,
          label: 'Konfirmasi Password',
          hint: 'Ulangi password',
          obscure: _obscureConfirmPassword,
          onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
      ],
    );
  }

  Widget _buildVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verifikasi',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tinjau data Anda',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),

        // Review Data - Simple version
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewItem('Nama', _fullNameController.text),
              const SizedBox(height: 8),
              _buildReviewItem('Email', _emailController.text),
              const SizedBox(height: 8),
              _buildReviewItem('Telepon', _phoneController.text),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Terms & Conditions - Simple
        Row(
          children: [
            Checkbox(
              value: _termsAccepted,
              onChanged: (value) => setState(() => _termsAccepted = value ?? false),
              activeColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _showSimpleTerms(context),
                child: Text(
                  'Saya setuju dengan Syarat & Ketentuan',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isNotEmpty ? value : '-',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  // ⚡ REUSABLE COMPONENTS
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.next,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
            prefixIcon: Icon(
              icon,
              size: 20,
              color: Colors.grey.shade600,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          textInputAction: TextInputAction.next,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              size: 20,
              color: Colors.grey.shade600,
            ),
            suffixIcon: IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: Colors.grey.shade600,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }

  void _showSimpleTerms(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Syarat & Ketentuan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'Dengan mendaftar di MerbabuAccess, Anda menyetujui bahwa data yang diberikan adalah akurat, bertanggung jawab atas keamanan akun, dan akan mengikuti semua peraturan pendakian yang berlaku di Taman Nasional Gunung Merbabu.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Mengerti',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _errorMessage != null
          ? Container(
              key: ValueKey(_errorMessage),
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _errorMessage = null),
                    child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _fullNameController.text.trim().isNotEmpty &&
               _emailController.text.trim().isNotEmpty &&
               _phoneController.text.trim().isNotEmpty;
      case 1:
        return _passwordController.text.trim().isNotEmpty &&
               _confirmPasswordController.text.trim().isNotEmpty;
      case 2:
        return _termsAccepted;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final safePadding = mediaQuery.padding.top;

    return Scaffold(
      resizeToAvoidBottomInset: false, // ⚡ Penting untuk performance
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFFE8F5E9).withOpacity(0.7),
            ],
            stops: const [0.0, 0.7],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ⚡ SIMPLE HEADER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Daftar Akun',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            'Langkah ${_currentStep + 1} dari 3',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(), // ⚡ Lebih smooth
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Step Indicator
                      _buildStepIndicator(),

                      // Error Message
                      _buildErrorMessage(),

                      const SizedBox(height: 16),

                      // Current Step Content
                      _currentStep == 0
                          ? _buildPersonalInfoStep()
                          : _currentStep == 1
                              ? _buildAccountStep()
                              : _buildVerificationStep(),

                      const SizedBox(height: 32),

                      // Navigation Buttons
                      Row(
                        children: [
                          if (_currentStep > 0)
                            SizedBox(
                              width: 48,
                              child: IconButton(
                                onPressed: () {
                                  setState(() => _currentStep--);
                                },
                                icon: const Icon(Icons.arrow_back),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.grey.shade200,
                                ),
                              ),
                            ),
                          if (_currentStep > 0) const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _currentStep < 2
                                  ? () {
                                      if (_validateCurrentStep()) {
                                        setState(() => _currentStep++);
                                      } else {
                                        _showError('Lengkapi data terlebih dahulu');
                                      }
                                    }
                                  : _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _currentStep < 2 ? 'Lanjut' : 'Daftar',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Login Link
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.login,
                            );
                          },
                          child: RichText(
                            text: TextSpan(
                              text: 'Sudah punya akun? ',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Masuk',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}