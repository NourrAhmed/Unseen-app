import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/unseen_vm.dart';
import '../viewmodels/user_vm.dart';
import '../viewmodels/category_vm.dart';
import '../viewmodels/search_vm.dart';
import '../models/unseen_model.dart';
import '../models/search_model.dart';
import '../components/search_card.dart';
import '../screens/View_UnSeen.dart';

class SearchUnSeen extends StatefulWidget {
  const SearchUnSeen({Key? key}) : super(key: key);

  @override
  State<SearchUnSeen> createState() => _SearchUnSeenState();
}

class _SearchUnSeenState extends State<SearchUnSeen> {
  final _searchController = TextEditingController();
  String _selectedCategory = '';
  String _searchQuery = '';
  bool _isLoading = false;
  Map<String, String> _usernames = {}; 
  Set<String> _savedUnseens = {}; 
  bool _showRecentSearches = true;

  @override
  void initState() {
    super.initState();
    _loadUnseens();
    _loadUserData();
    _loadCategories();
    _loadRecentSearches();
  }

  Future<void> _loadCategories() async {
    try {
      await context.read<CategoryViewModel>().fetchCategories();
    } catch (e) {
      print('❌ Error loading categories: $e');
    }
  }

  Future<void> _loadRecentSearches() async {
    try {
      await context.read<SearchViewModel>().loadRecentSearches();
    } catch (e) {
      print('❌ Error loading recent searches: $e');
    }
  }

  Future<void> _loadUserData() async {
    final userVM = context.read<UserViewModel>();
    if (userVM.currentUser != null) {
      setState(() {
        _savedUnseens = userVM.currentUser!.savedUnseens.toSet();
      });
      print('📋 Loaded saved unseens: $_savedUnseens');
    }
  }

  Future<String> _getUsernameForUnseen(String userId) async {
    if (_usernames.containsKey(userId)) {
      return _usernames[userId]!;
    }

    try {
      final userVM = context.read<UserViewModel>();
      final username = await userVM.getUsernameById(userId);
      setState(() {
        _usernames[userId] = username;
      });
      return username;
    } catch (e) {
      print('❌ Error fetching username: $e');
      return 'Unknown User';
    }
  }

  void _toggleSave(String unseenId) async {
    final userVM = context.read<UserViewModel>();
    final wasSaved = _savedUnseens.contains(unseenId);

    setState(() {
      if (wasSaved) {
        _savedUnseens.remove(unseenId);
      } else {
        _savedUnseens.add(unseenId);
      }
    });

    try {
      if (!wasSaved) {
        await userVM.addSavedUnseen(unseenId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved to your collection')),
          );
        }
      } else {
        await userVM.removeSavedUnseen(unseenId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from your collection')),
          );
        }
      }
    } catch (e) {
      print('❌ Error toggling save: $e');
      setState(() {
        if (wasSaved) {
          _savedUnseens.add(unseenId);
        } else {
          _savedUnseens.remove(unseenId);
        }
      });
    }
  }

  void _performSearch() async {
    setState(() {
      _showRecentSearches = false;
    });

    // Save the search to recent searches if query is not empty
    if (_searchQuery.isNotEmpty || _selectedCategory.isNotEmpty) {
      try {
        final searchVM = context.read<SearchViewModel>();
        final searchModel = SearchModel(
          query: _searchQuery,
          categories: _selectedCategory.isNotEmpty ? [_selectedCategory] : [],
          latitude: null,
          longitude: null,
          radiusKm: null,
          timestamp: DateTime.now(),
        );
        print('💾 Saving search: $_searchQuery with category: $_selectedCategory');
        await searchVM.saveSearch(searchModel);
        print('✅ Search saved successfully');
      } catch (e) {
        print('❌ Error saving search: $e');
      }
    }

    _loadUnseens();
  }

  void _applyRecentSearch(SearchModel search) {
    setState(() {
      _searchQuery = search.query;
      _searchController.text = search.query;
      _selectedCategory = search.categories.isNotEmpty ? search.categories.first : '';
      _showRecentSearches = false;
    });
    _loadUnseens();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUnseens() async {
    setState(() => _isLoading = true);
    try {
      await context.read<UnSeenViewModel>().fetchUnSeens();
    } catch (e) {
      print('❌ Error loading unseens: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<UnSeenModel> _getFilteredUnseens() {
    final unseenVM = context.watch<UnSeenViewModel>();
    List<UnSeenModel> unseens = unseenVM.unseens;

    if (_selectedCategory.isNotEmpty) {
      unseens = unseens.where((unseen) {
        return unseen.categories.contains(_selectedCategory);
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      unseens = unseens.where((unseen) {
        final titleMatch = unseen.title.toLowerCase().contains(_searchQuery.toLowerCase());
        final storyMatch = unseen.story.toLowerCase().contains(_searchQuery.toLowerCase());
        return titleMatch || storyMatch;
      }).toList();
    }

    return unseens;
  }

  @override
  Widget build(BuildContext context) {
    final filteredUnseens = _getFilteredUnseens();
    final categories = context.watch<CategoryViewModel>().categories;
    final searchVM = context.watch<SearchViewModel>();
    final recentSearches = searchVM.recentSearches;

    // Show recent searches only when search bar is empty and no category selected
    final shouldShowRecentSearches = _showRecentSearches && 
        _searchQuery.isEmpty && 
        _selectedCategory.isEmpty && 
        recentSearches.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _showRecentSearches = value.isEmpty;
              });
            },
            onSubmitted: (_) => _performSearch(),
            decoration: InputDecoration(
              hintText: 'Search unseens...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                          _showRecentSearches = true;
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Categories
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: categories.map((category) {
                final isSelected = _selectedCategory == category.name;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = isSelected ? '' : category.name;
                        _showRecentSearches = false;
                      });
                      _performSearch();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF2E2952) : const Color(0xFFE8E3F3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF2E2952),
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Results count or Recent Searches header
          if (shouldShowRecentSearches)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Searches',
                    style: TextStyle(
                      color: Color(0xFF2E2952),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear All'),
                          content: const Text('Clear all recent searches?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await searchVM.clearAllRecentSearches();
                      }
                    },
                    child: const Text(
                      'Clear All',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_searchQuery.isNotEmpty || _selectedCategory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${filteredUnseens.length} result${filteredUnseens.length != 1 ? 's' : ''} found',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          // Results area or Recent Searches list
          Expanded(
            child: shouldShowRecentSearches
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: recentSearches.length,
                    itemBuilder: (context, index) {
                      final search = recentSearches[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: const Icon(
                          Icons.history,
                          color: Color(0xFF2E2952),
                        ),
                        title: Text(
                          search.displayText,
                          style: const TextStyle(
                            color: Color(0xFF2E2952),
                            fontSize: 14,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                          onPressed: () => searchVM.deleteRecentSearch(search),
                        ),
                        onTap: () => _applyRecentSearch(search),
                      );
                    },
                  )
                : _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2E2952),
                        ),
                      )
                    : filteredUnseens.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchQuery.isEmpty && _selectedCategory.isEmpty
                                      ? Icons.explore
                                      : Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty && _selectedCategory.isEmpty
                                      ? 'Search or select a category\nto explore unseens'
                                      : 'No unseens found',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadUnseens,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredUnseens.length,
                              itemBuilder: (context, index) {
                                final unseen = filteredUnseens[index];
                                return FutureBuilder<String>(
                                  future: _getUsernameForUnseen(unseen.creatorId),
                                  builder: (context, snapshot) {
                                    final username = snapshot.data ?? 'Loading...';
                                    return SearchCard(
                                      unseen: unseen,
                                      username: username,
                                      isSaved: _savedUnseens.contains(unseen.unseenId),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ViewUnseen(unseen: unseen),
                                          ),
                                        );
                                      },
                                      onSaveToggle: () => _toggleSave(unseen.unseenId),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}