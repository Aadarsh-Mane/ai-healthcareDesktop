// screens/new_chat_screen.dart

import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/model/chat_model.dart';
import 'package:doctordesktop/providers/chat_provider.dart';
import 'package:doctordesktop/screens/ChatScreen.dart';
import 'package:doctordesktop/services/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<ChatUser> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId != null && mounted) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query.trim();
    });

    try {
      // Get auth token directly from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final results = await ChatService.searchDoctors(
        query: query.trim(),
        token: token,
      );

      // Filter out current user
      final filteredResults =
          results.where((user) => user.id != _currentUserId).toList();

      if (mounted) {
        setState(() {
          _searchResults = filteredResults;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: HospitalTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _startChatWithUser(ChatUser user) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final chat =
          await ref.read(chatListProvider.notifier).createChatWithUser(user.id);

      // Hide loading
      if (mounted) Navigator.pop(context);

      if (chat != null) {
        // Navigate to chat screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreenDesktop(chat: chat),
            ),
          );
        }
      } else {
        throw Exception('Failed to create chat');
      }
    } catch (e) {
      // Hide loading
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: $e'),
            backgroundColor: HospitalTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 768;

    return Scaffold(
      backgroundColor: HospitalTheme.background,
      appBar: _buildAppBar(context, isTablet),
      body: Column(
        children: [
          _buildSearchBar(isTablet),
          Expanded(
            child: _buildSearchResults(isTablet),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isTablet) {
    return AppBar(
      backgroundColor: HospitalTheme.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'New Chat',
        style: TextStyle(
          color: Colors.white,
          fontSize: isTablet ? 22 : 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: HospitalTheme.border),
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: TextStyle(fontSize: isTablet ? 16 : 14),
        decoration: InputDecoration(
          hintText: 'Search doctors, nurses...',
          hintStyle: TextStyle(
            color: HospitalTheme.textLight,
            fontSize: isTablet ? 16 : 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: HospitalTheme.primary,
            size: isTablet ? 24 : 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: HospitalTheme.textMedium,
                    size: isTablet ? 24 : 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                )
              : null,
          filled: true,
          fillColor: HospitalTheme.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            borderSide: BorderSide(color: HospitalTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            borderSide: BorderSide(color: HospitalTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            borderSide: BorderSide(color: HospitalTheme.primary, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 16 : 12,
          ),
        ),
        onChanged: (value) {
          setState(() {});

          // Debounce search
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_searchController.text == value) {
              _performSearch(value);
            }
          });
        },
        onSubmitted: _performSearch,
      ),
    );
  }

  Widget _buildSearchResults(bool isTablet) {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchQuery.isEmpty) {
      return _buildInitialState(isTablet);
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyResults(isTablet);
    }

    return ListView.separated(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: isTablet ? 16 : 12),
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserTile(user, isTablet);
      },
    );
  }

  Widget _buildInitialState(bool isTablet) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 40 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: isTablet ? 80 : 64,
              color: HospitalTheme.textLight,
            ),
            SizedBox(height: isTablet ? 24 : 20),
            Text(
              'Find Healthcare Professionals',
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Text(
              'Search for doctors, nurses, and other healthcare professionals to start a conversation.',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: HospitalTheme.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 32 : 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSearchSuggestion('cardio', isTablet),
                SizedBox(width: isTablet ? 12 : 8),
                _buildSearchSuggestion('nurse', isTablet),
                SizedBox(width: isTablet ? 12 : 8),
                _buildSearchSuggestion('ortho', isTablet),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSuggestion(String suggestion, bool isTablet) {
    return GestureDetector(
      onTap: () {
        _searchController.text = suggestion;
        _performSearch(suggestion);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: HospitalTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HospitalTheme.primary.withOpacity(0.3)),
        ),
        child: Text(
          suggestion,
          style: TextStyle(
            color: HospitalTheme.primary,
            fontSize: isTablet ? 14 : 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyResults(bool isTablet) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 40 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: isTablet ? 64 : 48,
              color: HospitalTheme.textLight,
            ),
            SizedBox(height: isTablet ? 20 : 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              'No healthcare professionals found for "$_searchQuery"',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: HospitalTheme.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 24 : 20),
            Text(
              'Try searching with different keywords like:\n• Name or department\n• Specialization\n• Role (doctor, nurse)',
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: HospitalTheme.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(ChatUser user, bool isTablet) {
    final isOnline = ref.watch(isUserOnlineProvider(user.id));

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        side: BorderSide(color: HospitalTheme.border),
      ),
      child: InkWell(
        onTap: () => _startChatWithUser(user),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Row(
            children: [
              _buildUserAvatar(user, isOnline, isTablet),
              SizedBox(width: isTablet ? 20 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                    SizedBox(height: isTablet ? 6 : 4),
                    if (user.usertype.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 10 : 8,
                          vertical: isTablet ? 4 : 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _getUserTypeColor(user.usertype).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.usertype.toUpperCase(),
                          style: TextStyle(
                            fontSize: isTablet ? 12 : 10,
                            fontWeight: FontWeight.bold,
                            color: _getUserTypeColor(user.usertype),
                          ),
                        ),
                      ),
                    if (user.department != null) ...[
                      SizedBox(height: isTablet ? 8 : 6),
                      Row(
                        children: [
                          Icon(
                            Icons.business,
                            size: isTablet ? 16 : 14,
                            color: HospitalTheme.textMedium,
                          ),
                          SizedBox(width: isTablet ? 8 : 6),
                          Expanded(
                            child: Text(
                              user.department!,
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 12,
                                color: HospitalTheme.textMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (user.speciality != null) ...[
                      SizedBox(height: isTablet ? 6 : 4),
                      Row(
                        children: [
                          Icon(
                            Icons.medical_services,
                            size: isTablet ? 16 : 14,
                            color: HospitalTheme.textMedium,
                          ),
                          SizedBox(width: isTablet ? 8 : 6),
                          Expanded(
                            child: Text(
                              user.speciality!,
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 12,
                                color: HospitalTheme.textMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chat_bubble_outline,
                color: HospitalTheme.primary,
                size: isTablet ? 24 : 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(ChatUser user, bool isOnline, bool isTablet) {
    final size = isTablet ? 70.0 : 60.0;

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: HospitalTheme.surfaceLight,
            image: user.imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(
                      Methods().getGoogleDriveDirectLink(user.imageUrl!),
                    ),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: user.imageUrl == null
              ? Icon(
                  _getUserTypeIcon(user.usertype),
                  size: size * 0.5,
                  color: _getUserTypeColor(user.usertype),
                )
              : null,
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: HospitalTheme.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Color _getUserTypeColor(String userType) {
    switch (userType.toLowerCase()) {
      case 'doctor':
        return HospitalTheme.medical;
      case 'nurse':
        return HospitalTheme.pharmacy;
      default:
        return HospitalTheme.primary;
    }
  }

  IconData _getUserTypeIcon(String userType) {
    switch (userType.toLowerCase()) {
      case 'doctor':
        return Icons.medical_services;
      case 'nurse':
        return Icons.local_hospital;
      default:
        return Icons.person;
    }
  }
}
