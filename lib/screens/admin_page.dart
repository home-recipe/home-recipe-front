import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  AdminMenu _selectedMenu = AdminMenu.userManagement;
  List<AdminUserResponse> _allUsers = [];
  List<AdminUserResponse> _filteredUsers = [];
  Role? _selectedRoleFilter;
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    // 저장된 role 확인
    final role = await TokenService.getUserRole();
    
    if (role == 'ADMIN') {
      setState(() {
        _isAdmin = true;
        _isLoading = false;
      });
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
              fontFamily: 'Cafe24PROSlimFit',
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
                  fontFamily: 'Cafe24PROSlimFit',
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
                fontFamily: 'Cafe24PROSlimFit',
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
      _applyFilter();
    });
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
                  fontFamily: 'Cafe24PROSlimFit',
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
                      fontFamily: 'Cafe24PROSlimFit',
                      letterSpacing: 0.5,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  RadioListTile<Role>(
                    title: const Text(
                      'ADMIN',
                      style: TextStyle(
                        fontFamily: 'Cafe24PROSlimFit',
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
                        fontFamily: 'Cafe24PROSlimFit',
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
                      fontFamily: 'Cafe24PROSlimFit',
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
                      fontFamily: 'Cafe24PROSlimFit',
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
                  fontFamily: 'Cafe24PROSlimFit',
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
                  fontFamily: 'Cafe24PROSlimFit',
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
                fontFamily: 'Cafe24PROSlimFit',
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
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF2C2C2C)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          '페이지 관리',
                          style: TextStyle(
                            fontFamily: 'Cafe24PROSlimFit',
                            letterSpacing: 0.5,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C2C2C),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // 뒤로가기 버튼과 대칭을 위한 공간
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: kIsWeb ? 40 : 20,
                      vertical: 12,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 메뉴 탭
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedMenu = AdminMenu.userManagement;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _selectedMenu == AdminMenu.userManagement
                                          ? const Color(0xFFDEAE71)
                                          : Colors.white.withOpacity(0.5),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        topRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      '사용자 관리',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Cafe24PROSlimFit',
                                        letterSpacing: 0.5,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedMenu == AdminMenu.userManagement
                                            ? Colors.white
                                            : const Color(0xFF2C2C2C),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedMenu = AdminMenu.videoManagement;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _selectedMenu == AdminMenu.videoManagement
                                          ? const Color(0xFFDEAE71)
                                          : Colors.white.withOpacity(0.5),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        topRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      '동영상 관리',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Cafe24PROSlimFit',
                                        letterSpacing: 0.5,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedMenu == AdminMenu.videoManagement
                                            ? Colors.white
                                            : const Color(0xFF2C2C2C),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // 선택된 메뉴에 따른 콘텐츠
                          if (_selectedMenu == AdminMenu.userManagement) ...[
                          // Role 필터와 조회 버튼
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ChoiceChip(
                                          label: const Text(
                                            '전체',
                                            style: TextStyle(
                                              fontFamily: 'Cafe24PROSlimFit',
                                              letterSpacing: 0.5,
                                              fontSize: 12,
                                            ),
                                          ),
                                          selected: _selectedRoleFilter == null,
                                          onSelected: (selected) {
                                            if (selected) {
                                              _onRoleFilterChanged(null);
                                            }
                                          },
                                          selectedColor: const Color(0xFFDEAE71),
                                          labelStyle: TextStyle(
                                            color: _selectedRoleFilter == null
                                                ? Colors.white
                                                : const Color(0xFF2C2C2C),
                                            fontSize: 12,
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: ChoiceChip(
                                          label: const Text(
                                            'ADMIN',
                                            style: TextStyle(
                                              fontFamily: 'Cafe24PROSlimFit',
                                              letterSpacing: 0.5,
                                              fontSize: 12,
                                            ),
                                          ),
                                          selected: _selectedRoleFilter == Role.ADMIN,
                                          onSelected: (selected) {
                                            if (selected) {
                                              _onRoleFilterChanged(Role.ADMIN);
                                            }
                                          },
                                          selectedColor: const Color(0xFFDEAE71),
                                          labelStyle: TextStyle(
                                            color: _selectedRoleFilter == Role.ADMIN
                                                ? Colors.white
                                                : const Color(0xFF2C2C2C),
                                            fontSize: 12,
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: ChoiceChip(
                                          label: const Text(
                                            'USER',
                                            style: TextStyle(
                                              fontFamily: 'Cafe24PROSlimFit',
                                              letterSpacing: 0.5,
                                              fontSize: 12,
                                            ),
                                          ),
                                          selected: _selectedRoleFilter == Role.USER,
                                          onSelected: (selected) {
                                            if (selected) {
                                              _onRoleFilterChanged(Role.USER);
                                            }
                                          },
                                          selectedColor: const Color(0xFFDEAE71),
                                          labelStyle: TextStyle(
                                            color: _selectedRoleFilter == Role.USER
                                                ? Colors.white
                                                : const Color(0xFF2C2C2C),
                                            fontSize: 12,
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isLoadingUsers ? null : _loadUsers,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDEAE71),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
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
                                          fontFamily: 'Cafe24PROSlimFit',
                                          letterSpacing: 0.5,
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // 사용자 목록
                          if (_filteredUsers.isEmpty && !_isLoadingUsers)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  '조회 버튼을 눌러 사용자 목록을 불러오세요.',
                                  style: TextStyle(
                                    fontFamily: 'Cafe24PROSlimFit',
                                    letterSpacing: 0.5,
                                    fontSize: 12,
                                    color: Color(0xFF2C2C2C),
                                  ),
                                ),
                              ),
                            )
                          else if (_isLoadingUsers)
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
                                    fontFamily: 'Cafe24PROSlimFit',
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
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
                                            style: const TextStyle(
                                              fontFamily: 'Cafe24PROSlimFit',
                                              letterSpacing: 0.5,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF2C2C2C),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '이름',
                                            style: const TextStyle(
                                              fontFamily: 'Cafe24PROSlimFit',
                                              letterSpacing: 0.5,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF2C2C2C),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            '이메일',
                                            style: const TextStyle(
                                              fontFamily: 'Cafe24PROSlimFit',
                                              letterSpacing: 0.5,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF2C2C2C),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            '권한 변경',
                                            style: const TextStyle(
                                              fontFamily: 'Cafe24PROSlimFit',
                                              letterSpacing: 0.5,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF2C2C2C),
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
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        color: Colors.transparent,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                user.id.toString(),
                                                style: const TextStyle(
                                                  fontFamily: 'Cafe24PROSlimFit',
                                                  letterSpacing: 0.5,
                                                  fontSize: 12,
                                                  color: Color(0xFF2C2C2C),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                user.name,
                                                style: const TextStyle(
                                                  fontFamily: 'Cafe24PROSlimFit',
                                                  letterSpacing: 0.5,
                                                  fontSize: 12,
                                                  color: Color(0xFF2C2C2C),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                user.email,
                                                style: const TextStyle(
                                                  fontFamily: 'Cafe24PROSlimFit',
                                                  letterSpacing: 0.5,
                                                  fontSize: 12,
                                                  color: Color(0xFF2C2C2C),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 80,
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  size: 18,
                                                  color: Color(0xFFDEAE71),
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
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  '동영상 관리 기능을 여기에 추가하세요.',
                                  style: TextStyle(
                                    fontFamily: 'Cafe24PROSlimFit',
                                    letterSpacing: 0.5,
                                    fontSize: 14,
                                    color: Color(0xFF2C2C2C),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
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
}
