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
        
        if (response.success) {
          // 성공: 200 OK - 이메일 사용 가능
          _isEmailVerified = true;
          _emailCheckMessage = '이메일 인증 완료';
        } else {
          // 실패: 409 등 - 이메일 중복
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

      // HTTP 상태 코드가 201이거나 success가 true면 성공
      if (response.statusCode == 201 || response.success) {
        // 회원가입 성공 - 로그인 화면으로 리다이렉트
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
      body: Stack(
        children: [
          // 배경 이미지
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/homeimage2.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 배경 이미지 위에 오버레이 추가 (가독성 향상)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
          // 회원가입 폼
          SafeArea(
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
                        child: const Text(
                          '냉장고 프로젝트',
                          style: TextStyle(
                            fontFamily: 'GowunBatang',
                            fontSize: 50,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C2C2C),
                            shadows: [
                              Shadow(
                                color: Colors.white,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 회원가입 폼 컨테이너
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          fontFamily: 'GowunBatang',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C2C2C),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: const Color(0xCCF2EFEB),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
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
                                    backgroundColor: const Color(0xFFDEAE71),
                                    foregroundColor: Colors.white,
                                    textStyle: const TextStyle(
                                      fontFamily: 'GowunBatang',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
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
        ],
      ),
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
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
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
              fontSize: 16,
            ),
            prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 22),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF2C2C2C),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
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
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // 이메일 앞부분 입력
            Expanded(
              flex: 2,
              child: TextFormField(
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
                  hintText: '',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Colors.grey,
                    size: 22,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2C2C2C),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 1,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // @ 기호
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '@',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 도메인 드롭다운
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isEmailChecked = false; // 도메인 변경 시 중복확인 초기화
                    _isEmailVerified = false;
                    _emailCheckMessage = null;
                  });
                  _showDomainDropdown(context);
                },
                child: Container(
                  key: _dropdownKey,
                  height: 49, // 고정 높이로 크기 제한
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDomain,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF2C2C2C),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF2C2C2C),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 중복확인 버튼
            SizedBox(
              height: 49,
              child: ElevatedButton(
                onPressed: _isCheckingEmail ? null : _checkEmailDuplicate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDEAE71),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
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
                          fontFamily: 'GowunBatang',
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
        borderRadius: BorderRadius.circular(12),
      ),
      items: _emailDomains.map((String domain) {
        return PopupMenuItem<String>(
          value: domain,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              domain,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF2C2C2C),
              ),
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

