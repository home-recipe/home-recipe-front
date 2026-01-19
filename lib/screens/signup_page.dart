import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/join_request.dart';
import '../services/api_service.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  final TextEditingController _emailPrefixController = TextEditingController();
  
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _passwordConfirmFocusNode = FocusNode();
  final FocusNode _emailPrefixFocusNode = FocusNode();

  // 이메일 도메인 목록
  final List<String> _emailDomains = [
    'naver.com',
    'gmail.com',
    'kakao.com',
    'daum.net',
    'hanmail.net',
  ];
  String _selectedDomain = 'naver.com';
  final GlobalKey _dropdownKey = GlobalKey();

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _emailPrefixController.dispose();
    _nameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _passwordConfirmFocusNode.dispose();
    _emailPrefixFocusNode.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return '이름을 입력해주세요';
    }
    if (value.length < 2 || value.length > 10) {
      return '이름은 2자 이상 10자 이하여야 합니다';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }
    if (value.length < 8 || value.length > 20) {
      return '비밀번호는 8자 이상 20자 이하여야 합니다';
    }
    return null;
  }

  String? _validatePasswordConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호 확인을 입력해주세요';
    }
    if (value != _passwordController.text) {
      return '비밀번호가 일치하지 않습니다';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요';
    }
    // 이메일 앞부분 검증
    final emailRegex = RegExp(r'^[\w-\.]+$');
    if (!emailRegex.hasMatch(value)) {
      return '올바른 이메일 형식을 입력해주세요';
    }
    return null;
  }

  String? _validateEmailComplete() {
    if (_emailPrefixController.text.isEmpty) {
      return '이메일을 입력해주세요';
    }
    final emailRegex = RegExp(r'^[\w-\.]+$');
    if (!emailRegex.hasMatch(_emailPrefixController.text)) {
      return '올바른 이메일 형식을 입력해주세요';
    }
    return null;
  }

  String get _fullEmail => '${_emailPrefixController.text}@$_selectedDomain';
  bool _isEmailChecked = false;
  bool _isEmailVerified = false; // 이메일 인증 성공 여부
  String? _emailCheckMessage;
  bool _isLoading = false;
  bool _isCheckingEmail = false;

  Future<void> _checkEmailDuplicate() async {
    // 이메일 형식 검증
    final emailError = _validateEmailComplete();
    if (emailError != null) {
      return;
    }

    // 이미 확인 중이면 중복 요청 방지
    if (_isCheckingEmail) {
      return;
    }

    setState(() {
      _isCheckingEmail = true;
      _isEmailChecked = false;
      _isEmailVerified = false;
      _emailCheckMessage = null;
    });

    try {
      final response = await ApiService.checkEmail(_fullEmail);

      if (!mounted) return;

      setState(() {
        _isCheckingEmail = false;
        _isEmailChecked = true;
        
        if (response.code == 200) {
          _isEmailVerified = true;
          _emailCheckMessage = '이메일 인증 완료';
        } else {
          _isEmailVerified = false;
          _emailCheckMessage = response.message ?? '이미 가입된 이메일입니다.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCheckingEmail = false;
        _isEmailChecked = true;
        _isEmailVerified = false;
        _emailCheckMessage = '이미 가입된 이메일입니다.';
      });
    }
  }

  Future<void> _handleSignUp() async {
    // 이메일 전체 검증
    final emailError = _validateEmailComplete();
    if (emailError != null) {
      return;
    }

    // 이메일 인증 여부 확인
    if (!_isEmailVerified) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 로딩 중이면 중복 요청 방지
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = JoinRequest(
        name: _nameController.text.trim(),
        password: _passwordController.text,
        email: _fullEmail,
      );

      final response = await ApiService.join(request);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (response.code == 201) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 앱 타이틀 (클릭 시 로그인 페이지로 이동)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: _buildRecookTitle(),
                  ),
                ),
                const SizedBox(height: 60),

                // 회원가입 폼 컨테이너
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontFamily: 'NanumGothicCoding-Regular',
                      letterSpacing: 0.5,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C2C2C),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(28.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF81B29A).withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: const Color(0xFFE07A5F).withValues(alpha: 0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 이름 입력 필드
                                _buildFormField(
                                  controller: _nameController,
                                  focusNode: _nameFocusNode,
                                  label: '이름',
                                  hintText: '',
                                  icon: Icons.person_outline,
                                  validator: _validateName,
                                  textInputAction: TextInputAction.next,
                                  onSubmitted: (_) {
                                    FocusScope.of(context).requestFocus(_emailPrefixFocusNode);
                                  },
                                ),
                                const SizedBox(height: 20),

                                // 이메일 입력 필드 (앞부분 + @ + 도메인 드롭다운)
                                _buildEmailField(),
                                const SizedBox(height: 20),

                                // 비밀번호 입력 필드
                                _buildFormField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  label: '비밀번호',
                                  hintText: '',
                                  icon: Icons.lock_outline,
                                  validator: _validatePassword,
                                  obscureText: true,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (_) {
                                    // 비밀번호가 변경되면 비밀번호 확인 필드도 재검증
                                    if (_passwordConfirmController.text.isNotEmpty) {
                                      setState(() {});
                                    }
                                  },
                                  onSubmitted: (_) {
                                    FocusScope.of(context).requestFocus(_passwordConfirmFocusNode);
                                  },
                                ),
                                const SizedBox(height: 20),

                                // 비밀번호 확인 입력 필드
                                _buildFormField(
                                  controller: _passwordConfirmController,
                                  focusNode: _passwordConfirmFocusNode,
                                  label: '비밀번호 확인',
                                  hintText: '',
                                  icon: Icons.lock_outline,
                                  validator: _validatePasswordConfirm,
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _handleSignUp(),
                                ),
                                const SizedBox(height: 32),

                                // 회원가입 버튼
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _handleSignUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE07A5F),
                                    foregroundColor: Colors.white,
                                    textStyle: const TextStyle(
                                      fontFamily: 'NanumGothicCoding-Regular',
                                      letterSpacing: 0.5,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 36,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 3,
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
                                      : const Text('회원가입'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // REC::OOK 스타일 타이틀 위젯
  Widget _buildRecookTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // REC::
        _buildStyledText('REC::', const Color(0xFFE07A5F)),
        // OOK
        _buildStyledText('OOK', const Color(0xFF81B29A)),
      ],
    );
  }

  // 스타일이 적용된 텍스트 위젯 (outline 포함)
  Widget _buildStyledText(String text, Color fillColor) {
    const outlineColor = Color(0xFF8B4513); // Rust brown outline
    const fontSize = 60.0;
    const outlineWidth = 3.0;
    
    return Stack(
      children: [
        // Outline (뒤에 그려짐) - 여러 방향으로 offset하여 outline 효과 생성
        ...List.generate(8, (index) {
          final angle = (index * 2 * math.pi) / 8;
          final offsetX = outlineWidth * math.cos(angle);
          final offsetY = outlineWidth * math.sin(angle);
          return Positioned(
            left: offsetX,
            top: offsetY,
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: outlineColor,
                letterSpacing: 1.0,
                fontFamily: 'Arial',
              ),
            ),
          );
        }),
        // Main text (앞에 그려짐)
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: fillColor,
            letterSpacing: 1.0,
            fontFamily: 'Arial',
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hintText,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF2C2C2C),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF81B29A), size: 22),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF81B29A),
                width: 2.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이메일',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        // 이메일 입력칸 (전체 너비)
        TextFormField(
          controller: _emailPrefixController,
          focusNode: _emailPrefixFocusNode,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(_passwordFocusNode);
          },
          validator: _validateEmail,
          onChanged: (_) {
            // 이메일 입력 변경 시 중복확인 초기화
            setState(() {
              _isEmailChecked = false;
              _isEmailVerified = false;
              _emailCheckMessage = null;
            });
          },
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF2C2C2C),
          ),
          decoration: InputDecoration(
            hintText: '이메일을 입력하세요',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
            ),
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: Color(0xFF81B29A),
              size: 22,
            ),
            suffixText: '@$_selectedDomain',
            suffixStyle: const TextStyle(
              fontSize: 15,
              color: Color(0xFF2C2C2C),
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF81B29A),
                width: 2.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 도메인 선택과 중복확인 버튼
        Row(
          children: [
            // 도메인 드롭다운
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isEmailChecked = false; // 도메인 변경 시 중복확인 초기화
                      _isEmailVerified = false;
                      _emailCheckMessage = null;
                    });
                    _showDomainDropdown(context);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    key: _dropdownKey,
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDomain,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF2C2C2C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF81B29A),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 중복확인 버튼
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isCheckingEmail ? null : _checkEmailDuplicate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF81B29A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: _isCheckingEmail
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '중복확인',
                        style: TextStyle(
                          fontFamily: 'NanumGothicCoding-Regular',
                          letterSpacing: 0.5,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
        // 이메일 중복확인 결과 메시지
        if (_isEmailChecked && _emailCheckMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              _emailCheckMessage!,
              style: TextStyle(
                fontSize: 12,
                color: _isEmailVerified 
                    ? Colors.green 
                    : Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  void _showDomainDropdown(BuildContext context) {
    final RenderBox? renderBox = _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Size size = renderBox.size;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx, // 왼쪽 정렬
        offset.dy + size.height + 4, // 항상 아래로 (4px 간격)
        offset.dx + size.width,
        offset.dy + size.height + 4 + 200, // 최대 높이
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      color: Colors.white,
      elevation: 8,
      items: _emailDomains.map((String domain) {
        final isSelected = domain == _selectedDomain;
        return PopupMenuItem<String>(
          value: domain,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFF81B29A).withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    domain,
                    style: TextStyle(
                      fontSize: 15,
                      color: isSelected 
                          ? const Color(0xFF81B29A)
                          : const Color(0xFF2C2C2C),
                      fontWeight: isSelected 
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check,
                    color: Color(0xFF81B29A),
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    ).then((String? selectedValue) {
      if (selectedValue != null) {
        setState(() {
          _selectedDomain = selectedValue;
        });
      }
    });
  }
}

