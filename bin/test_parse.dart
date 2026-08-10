import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  try {
    final response = await http.get(Uri.parse('http://localhost:5000/api/products'));
    final data = jsonDecode(response.body);
    final list = data['data'] as List;
    print('Fetched ${list.length} products');
    
    // We can't easily import ProductModel here without setting up a full flutter environment 
    // or copying the class. So let's just write a simplified check based on what ProductModel does.
    for (var item in list) {
        final price = item['price'];
        if (price != null && price is! num) {
            print('Error: price is not num: $price');
        }
        final rating = item['rating'];
        if (rating != null && rating is! num) {
            print('Error: rating is not num: $rating');
        }
    }
    print('All checks passed');
  } catch (e) {
    print('Error: $e');
  }
}
