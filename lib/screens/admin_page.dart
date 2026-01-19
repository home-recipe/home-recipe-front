import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import '../models/admin_user_response.dart';
import '../models/role.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => AdminPageState();
}

enum AdminMenu {
  userManagement,
  videoManagement,
}

class AdminPageState extends State<AdminPage> {
  bool _isLoading = true;
  bool _isAdmin = false;
  AdminMenu? _selectedMenu = AdminMenu.userManagement;
  List<AdminUserResponse> _allUsers = [];
  List<AdminUserResponse> _filteredUsers = [];
  Role? _selectedRoleFilter;
  bool _isLoadingUsers = false;
  bool _isUploadingVideo = false;
  PlatformFile? _selectedVideoFile;
  dynamic _selectedVideoData;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 메뉴 정보 리스트 - 메뉴 추가 시 여기에만 추가하면 됨
  final List<MapEntry<AdminMenu, String>> _menuItems = [
    const MapEntry(AdminMenu.userManagement, '사용자 관리'),
    const MapEntry(AdminMenu.videoManagement, '동영상 관리'),
  ];

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  void _onAdminAccessGranted() {
    // 관리자 권한이 확인되면 자동으로 사용자 목록 불러오기
    if (_selectedMenu == AdminMenu.userManagement) {
      _loadUsers();
    }
  }

  Future<void> _checkAdminAccess() async {
    // 저장된 role 확인
    final role = await TokenService.getUserRole();
    
    if (role == 'ADMIN') {
      setState(() {
        _isAdmin = true;
        _isLoading = false;
      });
      _onAdminAccessGranted();
    } else {
      // role이 없으면 API로 사용자 정보 조회
      try {
        final response = await ApiService.getCurrentUser();
        if (response.code == 200 && response.response.data != null) {
          final userRole = response.response.data!.role;
          if (userRole == 'ADMIN') {
            setState(() {
              _isAdmin = true;
              _isLoading = false;
            });
            _onAdminAccessGranted();
          } else {
            // ADMIN이 아니면 접근 거부
            _showAccessDenied();
          }
        } else {
          _showAccessDenied();
        }
      } catch (e) {
        _showAccessDenied();
      }
    }
  }

  void _showAccessDenied() {
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '관리자만 접근할 수 있는 페이지입니다',
            style: TextStyle(
              fontFamily: 'NanumGothicCoding-Regular',
              letterSpacing: 0.5,
              fontSize: 14,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      final response = await ApiService.getAllUsers();
      if (response.code == 200 && response.response.data != null) {
        setState(() {
          _allUsers = response.response.data!;
          _applyFilter();
          _isLoadingUsers = false;
        });
      } else {
        setState(() {
          _isLoadingUsers = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.message ?? '사용자 목록을 불러오는데 실패했습니다.',
                style: const TextStyle(
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                  fontSize: 14,
                ),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '사용자 목록을 불러오는데 실패했습니다.',
              style: TextStyle(
                fontFamily: 'NanumGothicCoding-Regular',
                letterSpacing: 0.5,
                fontSize: 14,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _applyFilter() {
    if (_selectedRoleFilter == null) {
      _filteredUsers = List.from(_allUsers);
    } else {
      _filteredUsers = _allUsers
          .where((user) => user.role == _selectedRoleFilter)
          .toList();
    }
  }

  void _onRoleFilterChanged(Role? role) {
    setState(() {
      _selectedRoleFilter = role;
      // 필터는 조회 버튼을 눌렀을 때만 적용
    });
  }

  Future<void> _pickVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null) {
        final file = result.files.single;
        
        // 웹에서는 bytes가, 모바일에서는 path가 필요
        if (kIsWeb && file.bytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '파일을 읽을 수 없습니다.',
                  style: TextStyle(
                    fontFamily: 'NanumGothicCoding-Regular',
                    letterSpacing: 0.5,
                    fontSize: 14,
                  ),
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        if (!kIsWeb && file.path == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '파일 경로를 가져올 수 없습니다.',
                  style: TextStyle(
                    fontFamily: 'NanumGothicCoding-Regular',
                    letterSpacing: 0.5,
                    fontSize: 14,
                  ),
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedVideoFile = file;
          if (kIsWeb) {
            _selectedVideoData = file.bytes;
          } else {
            _selectedVideoData = File(file.path!);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '파일 선택에 실패했습니다.',
              style: TextStyle(
                fontFamily: 'NanumGothicCoding-Regular',
                letterSpacing: 0.5,
                fontSize: 14,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _uploadVideo() async {
    if (_selectedVideoFile == null || _selectedVideoData == null) {
      return;
    }

    setState(() {
      _isUploadingVideo = true;
    });

    try {
      final response = await ApiService.uploadVideo(
        _selectedVideoData,
        _selectedVideoFile!.name,
      );

      if (mounted) {
        setState(() {
          _isUploadingVideo = false;
        });

        if (response.code == 200) {
          setState(() {
            _selectedVideoFile = null;
            _selectedVideoData = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '동영상이 성공적으로 업로드되었습니다.',
                style: TextStyle(
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                  fontSize: 14,
                ),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.message ?? '동영상 업로드에 실패했습니다.',
                style: const TextStyle(
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                  fontSize: 14,
                ),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingVideo = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '동영상 업로드에 실패했습니다.',
              style: TextStyle(
                fontFamily: 'NanumGothicCoding-Regular',
                letterSpacing: 0.5,
                fontSize: 14,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildMenuButton(String title, AdminMenu menu, {required bool isFirst}) {
    final isSelected = _selectedMenu == menu;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMenu = menu;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFDEAE71)
              : Colors.transparent,
          borderRadius: isFirst
              ? const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                )
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'NanumGothicCoding-Regular',
            letterSpacing: 0.5,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : const Color(0xFF2C2C2C),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xCCF2EFEB),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                '페이지 관리',
                style: TextStyle(
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: _menuItems.map((entry) {
                  final menu = entry.key;
                  final title = entry.value;
                  final isSelected = _selectedMenu == menu;
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: const Color(0xFFDEAE71).withOpacity(0.3),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFFDEAE71)
                            : const Color(0xFF2C2C2C),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedMenu = menu;
                      });
                      Navigator.of(context).pop(); // Drawer 닫기
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRoleChangeDialog(AdminUserResponse user) async {
    Role? selectedRole = user.role;

    final result = await showDialog<Role>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                '권한 변경',
                style: TextStyle(
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user.name}님의 권한을 변경하시겠습니까?',
                    style: const TextStyle(
                      fontFamily: 'NanumGothicCoding-Regular',
                      letterSpacing: 0.5,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  RadioListTile<Role>(
                    title: const Text(
                      'ADMIN',
                      style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 14,
                      ),
                    ),
                    value: Role.ADMIN,
                    groupValue: selectedRole,
                    onChanged: (Role? value) {
                      setDialogState(() {
                        selectedRole = value;
                      });
                    },
                  ),
                  RadioListTile<Role>(
                    title: const Text(
                      'USER',
                      style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 14,
                      ),
                    ),
                    value: Role.USER,
                    groupValue: selectedRole,
                    onChanged: (Role? value) {
                      setDialogState(() {
                        selectedRole = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '취소',
                    style: TextStyle(
                      fontFamily: 'NanumGothicCoding-Regular',
                      letterSpacing: 0.5,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedRole != null) {
                      Navigator.of(context).pop(selectedRole);
                    }
                  },
                  child: const Text(
                    '변경',
                    style: TextStyle(
                      fontFamily: 'NanumGothicCoding-Regular',
                      letterSpacing: 0.5,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result != user.role) {
      await _updateUserRole(user, result);
    }
  }

  Future<void> _updateUserRole(AdminUserResponse user, Role newRole) async {
    try {
      final response = await ApiService.updateUserRole(user.id, newRole);
      if (response.code == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${user.name}님의 권한이 변경되었습니다.',
                style: const TextStyle(
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                  fontSize: 14,
                ),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        // 사용자 목록 다시 불러오기
        await _loadUsers();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.message ?? '권한 변경에 실패했습니다.',
                style: const TextStyle(
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                  fontSize: 14,
                ),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '권한 변경에 실패했습니다.',
              style: TextStyle(
                fontFamily: 'NanumGothicCoding-Regular',
                letterSpacing: 0.5,
                fontSize: 14,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/homeimage2.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDEAE71)),
            ),
          ),
        ),
      );
    }

    if (!_isAdmin) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/homeimage2.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.4),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 헤더
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Color(0xFF2C2C2C)),
                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      const Expanded(
                        child: Text(
                          '페이지 관리',
                          style: TextStyle(
                            fontFamily: 'NanumGothicCoding-Regular',
                            letterSpacing: 0.5,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C2C2C),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF2C2C2C)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: kIsWeb ? 40 : 8,
                      vertical: 12,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: kIsWeb ? 32 : 8,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xCCF2EFEB),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: _buildContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedMenu == null) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 선택된 메뉴에 따른 콘텐츠
        if (_selectedMenu == AdminMenu.userManagement) ...[
          // Role 필터와 조회 버튼
          kIsWeb
              ? Row(
                  children: [
                    SizedBox(
                      height: 48,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFDEAE71).withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButton<Role?>(
                        value: _selectedRoleFilter,
                        hint: const Text(
                          '전체',
                          style: TextStyle(
                            fontFamily: 'NanumGothicCoding-Regular',
                            letterSpacing: 0.5,
                            fontSize: 15,
                            color: Color(0xFF2C2C2C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<Role?>(
                            value: null,
                            child: Text(
                              '전체',
                              style: TextStyle(
                                fontFamily: 'NanumGothicCoding-Regular',
                                letterSpacing: 0.5,
                                fontSize: 15,
                                color: Color(0xFF2C2C2C),
                              ),
                            ),
                          ),
                          const DropdownMenuItem<Role?>(
                            value: Role.ADMIN,
                            child: Text(
                              'ADMIN',
                              style: TextStyle(
                                fontFamily: 'NanumGothicCoding-Regular',
                                letterSpacing: 0.5,
                                fontSize: 15,
                                color: Color(0xFF2C2C2C),
                              ),
                            ),
                          ),
                          const DropdownMenuItem<Role?>(
                            value: Role.USER,
                            child: Text(
                              'USER',
                              style: TextStyle(
                                fontFamily: 'NanumGothicCoding-Regular',
                                letterSpacing: 0.5,
                                fontSize: 15,
                                color: Color(0xFF2C2C2C),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (Role? value) {
                          _onRoleFilterChanged(value);
                        },
                        underline: Container(),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFFDEAE71),
                          size: 24,
                        ),
                        isExpanded: false,
                        style: const TextStyle(
                          fontFamily: 'NanumGothicCoding-Regular',
                          letterSpacing: 0.5,
                          fontSize: 15,
                          color: Color(0xFF2C2C2C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoadingUsers ? null : _loadUsers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDEAE71),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoadingUsers
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                '조회',
                                style: TextStyle(
                                  fontFamily: 'NanumGothicCoding-Regular',
                                  letterSpacing: 0.5,
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                          child: SizedBox(
                            height: 48,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFDEAE71).withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownButton<Role?>(
                              value: _selectedRoleFilter,
                              hint: const Text(
                                '전체',
                                style: TextStyle(
                                  fontFamily: 'NanumGothicCoding-Regular',
                                  letterSpacing: 0.5,
                                  fontSize: 15,
                                  color: Color(0xFF2C2C2C),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<Role?>(
                                  value: null,
                                  child: Text(
                                    '전체',
                                    style: TextStyle(
                                      fontFamily: 'NanumGothicCoding-Regular',
                                      letterSpacing: 0.5,
                                      fontSize: 15,
                                      color: Color(0xFF2C2C2C),
                                    ),
                                  ),
                                ),
                                const DropdownMenuItem<Role?>(
                                  value: Role.ADMIN,
                                  child: Text(
                                    'ADMIN',
                                    style: TextStyle(
                                      fontFamily: 'NanumGothicCoding-Regular',
                                      letterSpacing: 0.5,
                                      fontSize: 15,
                                      color: Color(0xFF2C2C2C),
                                    ),
                                  ),
                                ),
                                const DropdownMenuItem<Role?>(
                                  value: Role.USER,
                                  child: Text(
                                    'USER',
                                    style: TextStyle(
                                      fontFamily: 'NanumGothicCoding-Regular',
                                      letterSpacing: 0.5,
                                      fontSize: 15,
                                      color: Color(0xFF2C2C2C),
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (Role? value) {
                                _onRoleFilterChanged(value);
                              },
                              underline: Container(),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFFDEAE71),
                                size: 24,
                              ),
                              isExpanded: true,
                              style: const TextStyle(
                                fontFamily: 'NanumGothicCoding-Regular',
                                letterSpacing: 0.5,
                                fontSize: 15,
                                color: Color(0xFF2C2C2C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoadingUsers ? null : _loadUsers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDEAE71),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoadingUsers
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                '조회',
                                style: TextStyle(
                                  fontFamily: 'NanumGothicCoding-Regular',
                                  letterSpacing: 0.5,
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 12),
          // 사용자 목록
          if (_isLoadingUsers)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDEAE71)),
                ),
              ),
            )
          else if (_filteredUsers.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '사용자가 없습니다.',
                  style: TextStyle(
                    fontFamily: 'NanumGothicCoding-Regular',
                    letterSpacing: 0.5,
                    fontSize: 12,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // 테이블 헤더
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: kIsWeb ? 12 : 8,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDEAE71).withOpacity(0.3),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            'ID',
                            style: TextStyle(
                              fontFamily: 'NanumGothicCoding-Regular',
                              letterSpacing: 0.5,
                              fontSize: kIsWeb ? 13 : 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2C2C2C),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '이름',
                            style: TextStyle(
                              fontFamily: 'NanumGothicCoding-Regular',
                              letterSpacing: 0.5,
                              fontSize: kIsWeb ? 13 : 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2C2C2C),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '이메일',
                            style: TextStyle(
                              fontFamily: 'NanumGothicCoding-Regular',
                              letterSpacing: 0.5,
                              fontSize: kIsWeb ? 13 : 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2C2C2C),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: kIsWeb ? 80 : 90,
                          child: Text(
                            '권한 변경',
                            style: TextStyle(
                              fontFamily: 'NanumGothicCoding-Regular',
                              letterSpacing: 0.5,
                              fontSize: kIsWeb ? 13 : 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2C2C2C),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 사용자 목록
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredUsers.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: kIsWeb ? 12 : 8,
                          vertical: 12,
                        ),
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                user.id.toString(),
                                style: TextStyle(
                                  fontFamily: 'NanumGothicCoding-Regular',
                                  letterSpacing: 0.5,
                                  fontSize: kIsWeb ? 13 : 14,
                                  color: const Color(0xFF2C2C2C),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                user.name,
                                style: TextStyle(
                                  fontFamily: 'NanumGothicCoding-Regular',
                                  letterSpacing: 0.5,
                                  fontSize: kIsWeb ? 13 : 14,
                                  color: const Color(0xFF2C2C2C),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                user.email,
                                style: TextStyle(
                                  fontFamily: 'NanumGothicCoding-Regular',
                                  letterSpacing: 0.5,
                                  fontSize: kIsWeb ? 13 : 14,
                                  color: const Color(0xFF2C2C2C),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: kIsWeb ? 80 : 90,
                              child: IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  size: kIsWeb ? 18 : 20,
                                  color: const Color(0xFFDEAE71),
                                ),
                                onPressed: () {
                                  _showRoleChangeDialog(user);
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: '권한 변경',
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ] else if (_selectedMenu == AdminMenu.videoManagement) ...[
          // 동영상 관리 콘텐츠
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_library,
                  size: 64,
                  color: const Color(0xFFDEAE71).withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                const Text(
                  '동영상 업로드',
                  style: TextStyle(
                    fontFamily: 'NanumGothicCoding-Regular',
                    letterSpacing: 0.5,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '로컬 파일을 선택하여 동영상을 등록하세요.',
                  style: TextStyle(
                    fontFamily: 'NanumGothicCoding-Regular',
                    letterSpacing: 0.5,
                    fontSize: 14,
                    color: Color(0xFF2C2C2C),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _pickVideo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDEAE71),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.folder_open,
                      color: Colors.white,
                    ),
                    label: const Text(
                      '동영상 선택',
                      style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (_selectedVideoFile != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFDEAE71).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.video_file,
                          color: Color(0xFFDEAE71),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedVideoFile!.name,
                            style: const TextStyle(
                              fontFamily: 'NanumGothicCoding-Regular',
                              letterSpacing: 0.5,
                              fontSize: 14,
                              color: Color(0xFF2C2C2C),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isUploadingVideo ? null : _uploadVideo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDEAE71),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isUploadingVideo
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.upload,
                              color: Colors.white,
                            ),
                      label: Text(
                        _isUploadingVideo ? '업로드 중...' : '등록',
                        style: const TextStyle(
                          fontFamily: 'NanumGothicCoding-Regular',
                          letterSpacing: 0.5,
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
