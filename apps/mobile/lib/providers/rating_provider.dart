import 'package:flutter/material.dart';
import '../models/rating_model.dart';

/// Holds all submitted ratings in memory for the current session.
class RatingProvider extends ChangeNotifier {
  final List<RatingModel> _ratings = [];

  List<RatingModel> get ratings => List.unmodifiable(_ratings);

  void addRating(RatingModel rating) {
    _ratings.add(rating);
    notifyListeners();
  }
}
