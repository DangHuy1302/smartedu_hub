import 'package:flutter/material.dart';
import 'package:smartedu_hub/services/google_sign_in_service.dart';
import 'package:smartedu_hub/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  final _formKey = GlobalKey<FormState>();

  // Services
  final _googleSignInService = GoogleSignInService();
  final _authService = AuthService();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  static const Color _primaryBlue = Color(0xFF1E88E5);
  static const Color _darkBlue = Color(0xFF1565C0);
  static const Color _lightBlueGradientStart = Color(0xFFE3F2FD);
  static const Color _textPrimary = Color(0xFF000000);
  static const Color _textSecondary = Color(0xFF757575);

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _authService.loginWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng nhập thành công'), backgroundColor: Colors.green),
          );
          // Xóa stack cũ để không bị nút back thừa
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      } else {
        final fullName = _nameController.text.trim();
        await _authService.registerWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: fullName,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng ký thành công'), backgroundColor: Colors.green),
          );
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Lỗi xác thực';
      switch (e.code) {
        case 'user-not-found': msg = 'Email không tồn tại.'; break;
        case 'wrong-password': msg = 'Mật khẩu không đúng.'; break;
        case 'email-already-in-use': msg = 'Email đã được sử dụng.'; break;
        case 'weak-password': msg = 'Mật khẩu quá yếu.'; break;
        case 'invalid-email': msg = 'Email không hợp lệ.'; break;
        default: msg = e.message ?? msg;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      final userCredential = await _googleSignInService.signInWithGoogle();
      if (userCredential == null) {
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng nhập thành công: ${userCredential.user?.email}'), backgroundColor: Colors.green),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi đăng nhập Google'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth > 800;

    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_lightBlueGradientStart, Colors.white]),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 450 : 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'logo',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: _primaryBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.school, size: 64, color: _primaryBlue),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('SmartEdu Hub', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _darkBlue, letterSpacing: -0.5)),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: _primaryBlue.withValues(alpha: 0.15), blurRadius: 15, spreadRadius: 2)],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(labelText: 'Họ và tên', prefixIcon: const Icon(Icons.person_outline, color: _primaryBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ và tên' : null,
                            ),
                            const SizedBox(height: 24),
                          ],
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email_outlined, color: _primaryBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập email' : null,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu',
                              prefixIcon: const Icon(Icons.lock_outline, color: _primaryBlue),
                              suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: _primaryBlue), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) => (v == null || v.length < 6) ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_isLogin ? 'Đăng nhập' : 'Tạo tài khoản', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                            icon: const Icon(Icons.g_mobiledata, color: _primaryBlue),
                            label: Text(_isGoogleLoading ? 'Đang xử lý...' : 'Tiếp tục với Google', style: const TextStyle(color: _primaryBlue, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: _primaryBlue, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_isLogin ? 'Chưa có tài khoản?' : 'Đã có tài khoản?', style: const TextStyle(color: _textSecondary)),
                      TextButton(onPressed: _toggleAuthMode, child: Text(_isLogin ? 'Đăng ký ngay' : 'Đăng nhập', style: const TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
