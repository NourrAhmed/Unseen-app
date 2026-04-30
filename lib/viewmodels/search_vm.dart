import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../models/unseen_model.dart';
import '../models/search_model.dart';

class SearchViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<UnSeenModel> _searchResults = [];
  List<SearchModel> _recentSearches = [];
  bool _isSearching = false;
  String _lastQuery = '';
  String _lastCategory = '';

  List<UnSeenModel> get searchResults => _searchResults;
  List<SearchModel> get recentSearches => _recentSearches;
  bool get isSearching => _isSearching;

  static const int _maxRecentSearches = 10;

  // Load recent searches from Firestore
  Future<void> loadRecentSearches() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recentSearches')
          .orderBy('timestamp', descending: true)
          .limit(_maxRecentSearches)
          .get();

      _recentSearches = snapshot.docs
          .map((doc) => SearchModel.fromFirestore(doc))
          .toList();

      notifyListeners();
    } catch (e) {
      print('❌ Error loading recent searches: $e');
    }
  }

  // Save search to history (Public method)
  Future<void> saveSearch(SearchModel search) async {
    await _saveSearchToHistory(search);
  }

  // Save search to history (Private implementation)
  Future<void> _saveSearchToHistory(SearchModel search) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Don't save empty searches
    if (search.query.isEmpty && search.categories.isEmpty) return;

    try {
      final recentSearchesRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('recentSearches');

      // Check if similar search exists
      final existingQuery = await recentSearchesRef
          .where('query', isEqualTo: search.query)
          .where('categories', isEqualTo: search.categories)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        // Update timestamp of existing search
        await existingQuery.docs.first.reference.update({
          'timestamp': Timestamp.fromDate(DateTime.now()),
        });
      } else {
        // Add new search
        await recentSearchesRef.add(search.toMap());

        // Delete old searches if we exceed the limit
        final allSearches = await recentSearchesRef
            .orderBy('timestamp', descending: true)
            .get();

        if (allSearches.docs.length > _maxRecentSearches) {
          for (int i = _maxRecentSearches; i < allSearches.docs.length; i++) {
            await allSearches.docs[i].reference.delete();
          }
        }
      }

      // Reload recent searches
      await loadRecentSearches();
    } catch (e) {
      print('❌ Error saving search to history: $e');
    }
  }

  // Delete a specific search from history
  Future<void> deleteRecentSearch(SearchModel search) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recentSearches')
          .where('query', isEqualTo: search.query)
          .where('categories', isEqualTo: search.categories)
          .limit(1)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      await loadRecentSearches();
    } catch (e) {
      print('❌ Error deleting recent search: $e');
    }
  }

  // Clear all recent searches
  Future<void> clearAllRecentSearches() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recentSearches')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      _recentSearches.clear();
      notifyListeners();
    } catch (e) {
      print('❌ Error clearing recent searches: $e');
    }
  }

  // Search unseens by query and/or category
  Future<void> searchUnseens({
    String query = '',
    String category = '',
  }) async {
    // Avoid duplicate searches
    if (query == _lastQuery && category == _lastCategory) {
      return;
    }

    _isSearching = true;
    _lastQuery = query;
    _lastCategory = category;
    notifyListeners();

    try {
      Query<Map<String, dynamic>> unseenQuery = _firestore.collection('unseens');

      // Filter by category if provided
      if (category.isNotEmpty) {
        unseenQuery = unseenQuery.where('categories', arrayContains: category);
      }

      final snapshot = await unseenQuery.get();
      
      _searchResults = snapshot.docs
          .map((doc) => UnSeenModel.fromMap(doc.data(), doc.id))
          .toList();

      // Filter by text query (title or story) locally
      if (query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        _searchResults = _searchResults.where((unseen) {
          final titleMatch = unseen.title.toLowerCase().contains(lowerQuery);
          final storyMatch = unseen.story.toLowerCase().contains(lowerQuery);
          return titleMatch || storyMatch;
        }).toList();
      }

      // Sort by most recent first
      _searchResults.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Save to search history
      final searchModel = SearchModel(
        query: query,
        categories: category.isNotEmpty ? [category] : [],
      );
      await _saveSearchToHistory(searchModel);

    } catch (e) {
      print('❌ Error searching unseens: $e');
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  // Search by location (within radius)
  Future<void> searchByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    String category = '',
  }) async {
    _isSearching = true;
    notifyListeners();

    try {
      Query<Map<String, dynamic>> unseenQuery = _firestore.collection('unseens');

      // Filter by category if provided
      if (category.isNotEmpty) {
        unseenQuery = unseenQuery.where('categories', arrayContains: category);
      }

      final snapshot = await unseenQuery.get();
      
      List<UnSeenModel> allUnseens = snapshot.docs
          .map((doc) => UnSeenModel.fromMap(doc.data(), doc.id))
          .toList();

      // Filter by distance
      _searchResults = allUnseens.where((unseen) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          unseen.location.latitude,
          unseen.location.longitude,
        );
        return distance <= radiusKm;
      }).toList();

      // Sort by distance (closest first)
      _searchResults.sort((a, b) {
        final distA = _calculateDistance(
          latitude, longitude,
          a.location.latitude, a.location.longitude,
        );
        final distB = _calculateDistance(
          latitude, longitude,
          b.location.latitude, b.location.longitude,
        );
        return distA.compareTo(distB);
      });

      // Save to search history
      final searchModel = SearchModel(
        query: '',
        categories: category.isNotEmpty ? [category] : [],
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      await _saveSearchToHistory(searchModel);

    } catch (e) {
      print('❌ Error searching by location: $e');
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  // Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Clear search results
  void clearSearch() {
    _searchResults = [];
    _lastQuery = '';
    _lastCategory = '';
    notifyListeners();
  }
}