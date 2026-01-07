import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/meme_grid_item_widget.dart';
import './widgets/selection_action_bar_widget.dart';

class MemeGallery extends StatefulWidget {
  const MemeGallery({Key? key}) : super(key: key);

  @override
  State<MemeGallery> createState() => _MemeGalleryState();
}

class _MemeGalleryState extends State<MemeGallery> {
  final _supabaseService = SupabaseService.instance;
  final _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  List<Map<String, dynamic>> _memes = [];
  Set<String> _selectedMemes = {};
  bool _isSelectionMode = false;

  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadMemes();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreMemes();
      }
    }
  }

  Future<void> _loadMemes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 0;
      });

      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _error = 'Please log in to continue';
        });
        return;
      }

      final memes = await _supabaseService.getUserMemes(
        userId: currentUser.id,
        limit: _pageSize,
        offset: 0,
      );

      setState(() {
        _memes = memes;
        _hasMore = memes.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load memes: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreMemes() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return;

      final nextPage = _currentPage + 1;
      final moreMemes = await _supabaseService.getUserMemes(
        userId: currentUser.id,
        limit: _pageSize,
        offset: nextPage * _pageSize,
      );

      setState(() {
        _memes.addAll(moreMemes);
        _currentPage = nextPage;
        _hasMore = moreMemes.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more: ${e.toString()}')),
        );
      }
    }
  }

  void _toggleSelection(String memeId) {
    setState(() {
      if (_selectedMemes.contains(memeId)) {
        _selectedMemes.remove(memeId);
        if (_selectedMemes.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedMemes.add(memeId);
        _isSelectionMode = true;
      }
    });
  }

  Future<void> _handleDelete() async {
    if (_selectedMemes.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Memes'),
        content: Text('Delete ${_selectedMemes.length} meme(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      for (final memeId in _selectedMemes) {
        await _supabaseService.deleteMeme(memeId);
      }

      setState(() {
        _memes.removeWhere((meme) => _selectedMemes.contains(meme['id']));
        _selectedMemes.clear();
        _isSelectionMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Memes deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: ${e.toString()}')),
        );
      }
    }
  }

  void _handleShare() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing ${_selectedMemes.length} meme(s)')),
    );
  }

  void _handleFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => FilterBottomSheetWidget(
        selectedSort: 'date_desc',
        onSortChanged: (sort) {
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              SizedBox(height: 2.h),
              Text(
                _error!,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              ElevatedButton(onPressed: _loadMemes, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_memes.isEmpty) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: EmptyStateWidget(
          onCreateTap: () {
            // Navigate to create meme screen
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadMemes,
            child: GridView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(4.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 3.w,
                mainAxisSpacing: 2.h,
                childAspectRatio: 0.75,
              ),
              itemCount: _memes.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _memes.length) {
                  return const Center(child: CircularProgressIndicator());
                }

                final meme = _memes[index];
                final memeId = meme['id'] as String;
                return MemeGridItemWidget(
                  meme: meme,
                  isSelected: _selectedMemes.contains(memeId),
                  onTap: () => _toggleSelection(memeId),
                  onLongPress: () {
                    setState(() {
                      _isSelectionMode = true;
                      _selectedMemes.add(memeId);
                    });
                  },
                );
              },
            ),
          ),
          if (_isSelectionMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SelectionActionBarWidget(
                selectedCount: _selectedMemes.length,
                onSelectAll: () {
                  setState(() {
                    _selectedMemes = _memes.map((m) => m['id'] as String).toSet();
                  });
                },
                onDelete: _handleDelete,
                onShare: _handleShare,
                onExport: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Exporting ${_selectedMemes.length} meme(s)')),
                  );
                },
                onCancel: () {
                  setState(() {
                    _selectedMemes.clear();
                    _isSelectionMode = false;
                  });
                },
              ),
            ),
        ],
      ),
      floatingActionButton: !_isSelectionMode
          ? FloatingActionButton(
              onPressed: _handleFilter,
              child: const Icon(Icons.filter_list),
            )
          : null,
    );
  }
}