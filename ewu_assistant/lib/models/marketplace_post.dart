import 'package:cloud_firestore/cloud_firestore.dart';

class MarketplacePost {
  const MarketplacePost({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.condition,
    required this.contactInfo,
    required this.imageUrl,
    required this.authorUid,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String price;
  final String condition;
  final String contactInfo;
  final String imageUrl;
  final String authorUid;
  final DateTime createdAt;

  MarketplacePost copyWith({
    String? id,
    String? title,
    String? description,
    String? price,
    String? condition,
    String? contactInfo,
    String? imageUrl,
    String? authorUid,
    DateTime? createdAt,
  }) {
    return MarketplacePost(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      condition: condition ?? this.condition,
      contactInfo: contactInfo ?? this.contactInfo,
      imageUrl: imageUrl ?? this.imageUrl,
      authorUid: authorUid ?? this.authorUid,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MarketplacePost.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return MarketplacePost(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      price: data['price']?.toString() ?? '',
      condition: data['condition']?.toString() ?? '',
      contactInfo: data['contactInfo']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      authorUid: data['authorUid']?.toString() ?? '',
      createdAt: _parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'price': price,
      'condition': condition,
      'contactInfo': contactInfo,
      'imageUrl': imageUrl,
      'authorUid': authorUid,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _parseDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
