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

  // Color palette (matching home_screen)
  static const Color _primaryBlue = Color(0xFF1E88E5);
  static const Color _darkBlue = Color(0xFF1565C0);
  static const Color _lightBlueGradientStart = Color(0xFFE3F2FD);
  static const Color _textPrimary = Color(0xFF000000);
  static const Color _textSecondary = Color(0xFF757575); // Colors.black54 equivalent

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
        // Login
        final credential = await _authService.loginWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng nhập thành công'), backgroundColor: Colors.green),
          );
          Navigator.pushReplacementNamed(context, '/');
        }
      } else {
        // Register
        final fullName = _nameController.text.trim();
        final credential = await _authService.registerWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: fullName,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng ký thành công'), backgroundColor: Colors.green),
          );
          Navigator.pushReplacementNamed(context, '/');
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Lỗi xác thực';
      switch (e.code) {
        case 'user-not-found':
          msg = 'Email không tồn tại.';
          break;
        case 'wrong-password':
          msg = 'Mật khẩu không đúng.';
          break;
        case 'email-already-in-use':
          msg = 'Email đã được sử dụng.';
          break;
        case 'weak-password':
          msg = 'Mật khẩu quá yếu.';
          break;
        case 'invalid-email':
          msg = 'Email không hợp lệ.';
          break;
        default:
          msg = e.message ?? msg;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
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
        // User cancelled sign-in
        if (mounted) {
          setState(() => _isGoogleLoading = false);
        }
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập thành công: ${userCredential.user?.email ?? 'Người dùng'}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Navigate to home screen after successful login
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      }
    } catch (e) {
      if (mounted) {
        // Extract error message safely
        String errorMessage = 'Lỗi đăng nhập. Vui lòng thử lại.';
        if (e.toString().contains('popup_closed_by_user')) {
          errorMessage = 'Bạn đã đóng cửa sổ đăng nhập';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Lỗi kết nối. Kiểm tra internet của bạn.';
        } else if (e.toString().isNotEmpty) {
          errorMessage = e.toString();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth > 800;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_lightBlueGradientStart, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 450 : 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo & Title
                  Hero(
                    tag: 'logo',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _primaryBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school, size: 64, color: _primaryBlue),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'SmartEdu Hub',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _darkBlue,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? 'Chào mừng bạn quay trở lại!' : 'Bắt đầu hành trình học tập mới',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Auth Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryBlue.withValues(alpha: 0.15),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Họ và tên',
                                prefixIcon: const Icon(Icons.person_outline, color: _primaryBlue),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _primaryBlue, width: 2),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập họ và tên';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email_outlined, color: _primaryBlue),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: _primaryBlue, width: 2),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                              final emailRegex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+");
                              if (!emailRegex.hasMatch(v.trim())) return 'Email không hợp lệ';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu',
                              prefixIcon: const Icon(Icons.lock_outline, color: _primaryBlue),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: _primaryBlue,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: _primaryBlue, width: 2),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                              if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: _primaryBlue,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (v) => setState(() => _rememberMe = v!),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Ghi nhớ', style: TextStyle(color: _textPrimary)),
                              const Spacer(),
                              if (_isLogin)
                                TextButton(
                                  onPressed: () {},
                                  child: const Text(
                                    'Quên mật khẩu?',
                                    style: TextStyle(
                                      color: _primaryBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryBlue,
                              disabledBackgroundColor: _primaryBlue.withValues(alpha: 0.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(_primaryBlue.withValues(alpha: 0.5)),
                                    ),
                                  )
                                : Text(
                                    _isLogin ? 'Đăng nhập' : 'Tạo tài khoản',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                          
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[300])),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Hoặc',
                                  style: TextStyle(
                                    color: _textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey[300])),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          OutlinedButton.icon(
                            onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                            icon: _isGoogleLoading
                                ? SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(_primaryBlue.withValues(alpha: 0.7)),
                                    ),
                                  )
                                : const Icon(Icons.g_mobiledata, color: _primaryBlue),
                            label: Text(
                              _isGoogleLoading ? 'Đang xử lý...' : 'Tiếp tục với Google',
                              style: TextStyle(
                                color: _isGoogleLoading ? _primaryBlue.withValues(alpha: 0.5) : _primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: _isGoogleLoading ? _primaryBlue.withValues(alpha: 0.5) : _primaryBlue,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin ? 'Chưa có tài khoản?' : 'Đã có tài khoản?',
                        style: const TextStyle(color: _textSecondary),
                      ),
                      TextButton(
                        onPressed: _toggleAuthMode,
                        child: Text(
                          _isLogin ? 'Đăng ký ngay' : 'Đăng nhập',
                          style: const TextStyle(
                            color: _primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
