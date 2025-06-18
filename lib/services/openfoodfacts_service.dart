import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/openfoodfacts_models.dart';

class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';

  /// Fetch product information from OpenFoodFacts API using barcode
  static Future<OpenFoodFactsProduct> getProduct(String barcode) async {
    try {
      final url = Uri.parse('$_baseUrl/$barcode.json');
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'RyzeApp/1.0.0 (contact@ryze.app)',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final product = OpenFoodFactsProduct.fromJson(data);
        
        // Créer une nouvelle instance avec le code-barres ajouté
        return OpenFoodFactsProduct(
          productName: product.productName,
          brands: product.brands,
          quantity: product.quantity,
          imageUrl: product.imageUrl,
          nutriments: product.nutriments,
          status: product.status,
          statusVerbose: product.statusVerbose,
          barcode: barcode, // Ajouter le code-barres
        );
      } else {
        // Return a product with status 0 for HTTP errors
        return OpenFoodFactsProduct(
          status: 0,
          statusVerbose: 'HTTP Error: ${response.statusCode}',
          barcode: barcode, // Ajouter le code-barres même en cas d'erreur
        );
      }
    } catch (e) {
      // Return a product with status 0 for network/parsing errors
      return OpenFoodFactsProduct(
        status: 0,
        statusVerbose: 'Network Error: $e',
        barcode: barcode, // Ajouter le code-barres même en cas d'erreur
      );
    }
  }

  /// Check if the product was found successfully
  static bool isProductFound(OpenFoodFactsProduct product) {
    return product.status == 1 && product.productName != null;
  }

  /// Get a user-friendly error message for failed requests
  static String getErrorMessage(OpenFoodFactsProduct product) {
    if (product.status == 0) {
      return 'Produit non trouvé dans la base de données';
    } else if (product.productName == null || product.productName!.isEmpty) {
      return 'Informations du produit incomplètes';
    } else {
      return 'Erreur lors de la récupération du produit';
    }
  }
} 