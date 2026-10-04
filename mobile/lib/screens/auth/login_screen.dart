import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/socket_provider.dart';
import '../../router/app_router.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool initialSignUp;
  const LoginScreen({super.key, this.initialSignUp = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Mode toggle: Login vs Sign Up
  late bool _isSignUp;

  // Login Controllers & State
  final TextEditingController _phoneController = TextEditingController(text: '+6281234567890');
  final TextEditingController _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoginLoading = false;

  // Sign Up Controllers & State
  final TextEditingController _signUpNameController = TextEditingController();
  final TextEditingController _signUpPhoneController = TextEditingController();
  final TextEditingController _signUpPasswordController = TextEditingController();
  final TextEditingController _signUpConfirmPasswordController = TextEditingController();
  bool _signUpObscurePassword = true;
  bool _signUpObscureConfirm = true;
  bool _signUpAgreeTerms = true;
  bool _isRegisterLoading = false;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialSignUp;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _signUpNameController.dispose();
    _signUpPhoneController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor telepon tidak boleh kosong'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoginLoading = true);
    try {
      final res = await ApiService.loginOrRegister(phoneNumber: phone);
      if (res != null && res['user'] != null) {
        final user = res['user'];
        final uId = user['id'] ?? 'user_rq';
        ref.read(authProvider.notifier).state = true;
        ref.read(socketProvider.notifier).connect(uId);
      } else {
        ref.read(authProvider.notifier).state = true;
        ref.read(socketProvider.notifier).connect(ApiService.currentUserId);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal login: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoginLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    final name = _signUpNameController.text.trim();
    final phone = _signUpPhoneController.text.trim();
    final password = _signUpPasswordController.text;
    final confirmPassword = _signUpConfirmPasswordController.text;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan Full name Anda'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan Phone number Anda'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (password.isNotEmpty && password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal 6 karakter'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (password.isNotEmpty && password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirm password tidak cocok'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (!_signUpAgreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus menyetujui Ketentuan Layanan & Kebijakan Privasi'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isRegisterLoading = true);

    try {
      final res = await ApiService.registerUser(
        phoneNumber: phone,
        name: name,
        aboutStatus: 'Hey there! I am using QuickChat.',
      );

      if (res != null && res['user'] != null) {
        final user = res['user'];
        final uId = user['id'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pendaftaran berhasil! Selamat datang, ${user['name'] ?? name}'),
            backgroundColor: AppTheme.primaryTeal,
          ),
        );

        ref.read(authProvider.notifier).state = true;
        ref.read(socketProvider.notifier).connect(uId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res?['error'] ?? 'Gagal mendaftar. Nomor mungkin sudah terdaftar.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isRegisterLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isSignUp ? _buildSignUpView() : _buildLoginView(),
    );
  }

  // ==========================================
  // VIEW 1: LOGIN (Welcome Back)
  // ==========================================
  Widget _buildLoginView() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Logo
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: AppTheme.mintLight,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.chat_bubble_rounded,
                    size: 44,
                    color: AppTheme.primaryTeal,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Title & Subtitle
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue to QuickChat',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 36),

              // Phone Input
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFDFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8ECEF)),
                ),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Phone number',
                    hintStyle: TextStyle(color: Color(0xFFA0AEC0), fontSize: 15),
                    prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primaryTeal),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password Input
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFDFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8ECEF)),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 15),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryTeal),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFFA0AEC0),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Remember Me & Forgot Password Row
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: AppTheme.primaryTeal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      onChanged: (val) {
                        setState(() {
                          _rememberMe = val ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Remember me',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {},
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Log In Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isLoginLoading ? null : _handleLogin,
                  child: _isLoginLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 28),

              // Divider: Or login with
              Row(
                children: [
                  Expanded(child: Container(height: 1, color: const Color(0xFFE8ECEF))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'Or login with',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFA0AEC0),
                      ),
                    ),
                  ),
                  Expanded(child: Container(height: 1, color: const Color(0xFFE8ECEF))),
                ],
              ),
              const SizedBox(height: 22),

              // Social Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFE8ECEF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {},
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'G',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFEA4335),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Google',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFE8ECEF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {},
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.facebook, color: Color(0xFF1877F2), size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Facebook',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Sign Up Footer with explicit click area
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _isSignUp = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryTeal,
                          ),
                        ),
                      ),
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

  // ==========================================
  // VIEW 2: SIGN UP (Create Account - Exact Mockup)
  // ==========================================
  Widget _buildSignUpView() {
    return Stack(
      children: [
        // Top subtle pastel glow circle
        Positioned(
          top: -40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppTheme.mintLight.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),

        SafeArea(
          child: Column(
            children: [
              // Top Bar with back arrow
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 24),
                      onPressed: () {
                        setState(() {
                          _isSignUp = false;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Main Form
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Title & Subtitle
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Join QuickChat and connect with friends',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 1. Full name
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBFDFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE8ECEF)),
                          ),
                          child: TextField(
                            controller: _signUpNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'Full name',
                              hintStyle: TextStyle(color: Color(0xFFA0AEC0), fontSize: 15),
                              prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryTeal),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 2. Phone number (+62...)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBFDFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE8ECEF)),
                          ),
                          child: TextField(
                            controller: _signUpPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: 'Phone number (+62...)',
                              hintStyle: TextStyle(color: Color(0xFFA0AEC0), fontSize: 15),
                              prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primaryTeal),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 3. Password (min. 6 chars)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBFDFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE8ECEF)),
                          ),
                          child: TextField(
                            controller: _signUpPasswordController,
                            obscureText: _signUpObscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Password (min. 6 chars)',
                              hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 15),
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryTeal),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _signUpObscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: const Color(0xFFA0AEC0),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _signUpObscurePassword = !_signUpObscurePassword;
                                  });
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 4. Confirm password
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBFDFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE8ECEF)),
                          ),
                          child: TextField(
                            controller: _signUpConfirmPasswordController,
                            obscureText: _signUpObscureConfirm,
                            decoration: InputDecoration(
                              hintText: 'Confirm password',
                              hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 15),
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryTeal),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _signUpObscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: const Color(0xFFA0AEC0),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _signUpObscureConfirm = !_signUpObscureConfirm;
                                  });
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Terms Checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _signUpAgreeTerms,
                                activeColor: AppTheme.primaryTeal,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                onChanged: (val) {
                                  setState(() {
                                    _signUpAgreeTerms = val ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'I agree to the Terms of Service and Privacy Policy',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryTeal,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _isRegisterLoading ? null : _handleRegister,
                            child: _isRegisterLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Divider: Or sign up with
                        Row(
                          children: [
                            Expanded(child: Container(height: 1, color: const Color(0xFFE8ECEF))),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                'Or sign up with',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFA0AEC0),
                                ),
                              ),
                            ),
                            Expanded(child: Container(height: 1, color: const Color(0xFFE8ECEF))),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Social Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: Color(0xFFE8ECEF)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () {},
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      'G',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFEA4335),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Google',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: Color(0xFFE8ECEF)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () {},
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.facebook, color: Color(0xFF1877F2), size: 22),
                                    SizedBox(width: 8),
                                    Text(
                                      'Facebook',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Footer: Already have an account? Log in
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() {
                                    _isSignUp = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                  child: const Text(
                                    'Log in',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryTeal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
