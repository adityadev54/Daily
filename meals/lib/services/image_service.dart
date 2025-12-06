import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

/// Service for fetching food images using free APIs
class ImageService {
  // Curated list of high-quality food image URLs from Lorem Picsum and Pixabay
  static final List<String> _fallbackImages = [
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&h=300&fit=crop',
    'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400&h=300&fit=crop',
    'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&h=300&fit=crop',
    'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=400&h=300&fit=crop',
    'https://images.unsplash.com/photo-1476224203421-9ac39bcb3327?w=400&h=300&fit=crop',
    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&h=300&fit=crop',
    'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&h=300&fit=crop',
    'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=400&h=300&fit=crop',
    'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&h=300&fit=crop',
    'https://images.unsplash.com/photo-1482049016gy4afc8e53?w=400&h=300&fit=crop',
  ];

  /// Get a single food image URL based on the meal name (instance method)
  Future<String?> getFoodImage(String mealName) async {
    final results = await searchFoodImages(mealName, count: 1);
    return results.isNotEmpty ? results.first : null;
  }

  /// Search for multiple food images (instance method)
  Future<List<String>> searchFoodImages(String query, {int count = 10}) async {
    // Try Pixabay API (free, generous limits)
    try {
      final searchQuery = Uri.encodeComponent('$query food');
      final response = await http
          .get(
            Uri.parse(
              'https://pixabay.com/api/?key=47108591-e3c2e8b47d3b8a8a5f9f4c2d5&q=$searchQuery&image_type=photo&category=food&per_page=$count',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hits = data['hits'] as List<dynamic>?;
        if (hits != null && hits.isNotEmpty) {
          return hits.map((hit) => hit['webformatURL'] as String).toList();
        }
      }
    } catch (e) {
      // Fallback silently
    }

    // Generate curated Unsplash URLs with specific food photos
    return _generateFoodImageUrls(query, count);
  }

  /// Generate reliable food image URLs
  static List<String> _generateFoodImageUrls(String query, int count) {
    final foodKeywords = _extractFoodKeywords(query);
    final images = <String>[];

    // Use specific Unsplash photo IDs for reliable loading
    final photoIds = _getFoodPhotoIds(foodKeywords);

    for (int i = 0; i < count && i < photoIds.length; i++) {
      images.add(
        'https://images.unsplash.com/photo-${photoIds[i]}?w=400&h=300&fit=crop',
      );
    }

    // Fill remaining with random food images
    final random = Random(query.hashCode);
    while (images.length < count) {
      final idx = random.nextInt(_fallbackImages.length);
      if (!images.contains(_fallbackImages[idx])) {
        images.add(_fallbackImages[idx]);
      }
      if (images.length >= _fallbackImages.length) break;
    }

    return images;
  }

  /// Extract food-related keywords from query
  static String _extractFoodKeywords(String query) {
    return query
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), '')
        .split(' ')
        .where((w) => w.length > 2 && !_stopWords.contains(w))
        .take(2)
        .join(' ');
  }

  /// Get Unsplash photo IDs based on food type
  static List<String> _getFoodPhotoIds(String keywords) {
    final kw = keywords.toLowerCase();

    if (kw.contains('pasta') ||
        kw.contains('italian') ||
        kw.contains('spaghetti')) {
      return [
        '1621996346565-e3dbc646d9a9',
        '1563379926898-05f4575a45d8',
        '1473093295043-cdd812d0e601',
      ];
    }
    if (kw.contains('pizza')) {
      return [
        '1565299624946-b28f40a0ae38',
        '1574071318508-1cdbab80d002',
        '1513104890138-7c749659a591',
      ];
    }
    if (kw.contains('salad') || kw.contains('healthy')) {
      return [
        '1512621776951-a57141f2eefd',
        '1540189549336-e6e99c3679fe',
        '1546069901-ba9599a7e63c',
      ];
    }
    if (kw.contains('burger') || kw.contains('sandwich')) {
      return [
        '1568901346375-23c9450c58cd',
        '1550547660-d9450f859349',
        '1571091718767-18b5b1457add',
      ];
    }
    if (kw.contains('chicken') || kw.contains('meat') || kw.contains('steak')) {
      return [
        '1555939594-58d7cb561ad1',
        '1504674900247-0877df9cc836',
        '1432139555190-58524dae6a55',
      ];
    }
    if (kw.contains('soup')) {
      return [
        '1547592166-23ac45744acd',
        '1603105037880-880cd4edfb0d',
        '1534422298391-e4f8c172dddb',
      ];
    }
    if (kw.contains('breakfast') ||
        kw.contains('egg') ||
        kw.contains('pancake')) {
      return [
        '1567620905732-2d1ec7ab7445',
        '1484723091996-d7b9f7b57c9e',
        '1525351484163-7529414344d8',
      ];
    }
    if (kw.contains('dessert') || kw.contains('cake') || kw.contains('sweet')) {
      return [
        '1578985545062-69928b1d9587',
        '1551024601-bec78aea704b',
        '1488477181946-6428a0291777',
      ];
    }
    if (kw.contains('asian') ||
        kw.contains('chinese') ||
        kw.contains('noodle')) {
      return [
        '1569718212165-3a8922ada9dd',
        '1552611052-33e04de081de',
        '1585032226651-759b368d7246',
      ];
    }
    if (kw.contains('mexican') || kw.contains('taco')) {
      return [
        '1565299585323-38d6b0865b47',
        '1551504734-5ee1c4a1479b',
        '1564767619518-3e384a1e2d59',
      ];
    }
    if (kw.contains('indian') || kw.contains('curry')) {
      return [
        '1585937421612-70a008356c36',
        '1596797038530-2c107229654b',
        '1567337710282-00832b415979',
      ];
    }
    if (kw.contains('sushi') || kw.contains('japanese')) {
      return [
        '1579871494447-189754f2e219',
        '1553621042-f6e147245754',
        '1617196034796-73dfa7b1fd56',
      ];
    }
    if (kw.contains('seafood') ||
        kw.contains('fish') ||
        kw.contains('shrimp')) {
      return [
        '1559847844-5315695dadae',
        '1504674900247-0877df9cc836',
        '1485921325833-c519f76c4927',
      ];
    }

    // Default food images
    return [
      '1546069901-ba9599a7e63c',
      '1567620905732-2d1ec7ab7445',
      '1565299624946-b28f40a0ae38',
      '1540189549336-e6e99c3679fe',
      '1476224203421-9ac39bcb3327',
      '1504674900247-0877df9cc836',
      '1512621776951-a57141f2eefd',
      '1473093295043-cdd812d0e601',
      '1555939594-58d7cb561ad1',
      '1482049016gy4afc8e53',
    ];
  }

  /// Get a food image URL based on the meal name (static version)
  static Future<String?> getFoodImageUrl(String mealName) async {
    // Try Pixabay API first
    try {
      final searchQuery = Uri.encodeComponent('$mealName food');
      final response = await http
          .get(
            Uri.parse(
              'https://pixabay.com/api/?key=47108591-e3c2e8b47d3b8a8a5f9f4c2d5&q=$searchQuery&image_type=photo&category=food&per_page=1',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hits = data['hits'] as List<dynamic>?;
        if (hits != null && hits.isNotEmpty) {
          return hits.first['webformatURL'] as String;
        }
      }
    } catch (e) {
      // Fallback silently
    }

    // Fallback to curated Unsplash image
    final photoIds = _getFoodPhotoIds(_extractFoodKeywords(mealName));
    if (photoIds.isNotEmpty) {
      return 'https://images.unsplash.com/photo-${photoIds.first}?w=400&h=300&fit=crop';
    }

    return _fallbackImages[Random(
      mealName.hashCode,
    ).nextInt(_fallbackImages.length)];
  }

  /// Get a placeholder image URL for a meal type
  static String getPlaceholderUrl(String mealType) {
    final type = mealType.toLowerCase();
    final query = switch (type) {
      'breakfast' => 'breakfast,eggs,pancakes',
      'lunch' => 'lunch,salad,sandwich',
      'dinner' => 'dinner,meal,steak',
      'snack' => 'snack,fruit,healthy',
      _ => 'food,meal,delicious',
    };
    return 'https://source.unsplash.com/400x300/?$query';
  }

  /// Get curated food images based on cuisine
  static String getCuisineImageUrl(String? cuisine) {
    final cuisineType = (cuisine ?? 'food').toLowerCase();
    final query = switch (cuisineType) {
      'italian' => 'italian,pasta,pizza',
      'mexican' => 'mexican,tacos,burrito',
      'chinese' => 'chinese,noodles,rice',
      'indian' => 'indian,curry,naan',
      'japanese' => 'japanese,sushi,ramen',
      'thai' => 'thai,curry,padthai',
      'mediterranean' => 'mediterranean,hummus,falafel',
      'american' => 'american,burger,fries',
      'french' => 'french,croissant,baguette',
      'korean' => 'korean,bbq,kimchi',
      _ => 'food,delicious,meal',
    };
    return 'https://source.unsplash.com/400x300/?$query';
  }

  /// Generate an image search term from meal name
  static String generateImageSearchTerm(String mealName) {
    // Remove common words and create a clean search term
    final cleanName = mealName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), '')
        .split(' ')
        .where((word) => word.length > 2)
        .where((word) => !_stopWords.contains(word))
        .take(3)
        .join(' ');
    return cleanName.isEmpty ? 'food' : cleanName;
  }

  static const Set<String> _stopWords = {
    'the',
    'and',
    'with',
    'from',
    'for',
    'its',
    'has',
    'have',
    'this',
    'that',
    'which',
    'where',
    'when',
    'how',
    'why',
    'all',
    'each',
    'every',
    'both',
    'few',
    'more',
    'most',
    'other',
    'some',
    'such',
    'only',
    'own',
    'same',
    'into',
    'very',
    'just',
    'over',
    'under',
    'again',
    'further',
    'then',
    'once',
    'here',
    'there',
    'fresh',
    'healthy',
    'delicious',
    'homemade',
    'easy',
    'quick',
  };
}
