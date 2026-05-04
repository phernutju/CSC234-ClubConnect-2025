import 'package:flutter/material.dart';
import '../models/review_model.dart';

/// Holds all submitted reviews in memory for the current session.
class ReviewProvider extends ChangeNotifier {
  final List<ReviewModel> _reviews = [];

  List<ReviewModel> get reviews => List.unmodifiable(_reviews);

  void addReview(ReviewModel review) {
    _reviews.add(review);
    notifyListeners();
  }
}
