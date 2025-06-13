class Meal {
  final String time;
  final String name;
  final List<FoodItem> items;

  Meal({
    required this.time,
    required this.name,
    required this.items,
  });
  
  void addItem(FoodItem item) {
    items.add(item);
  }
}

class FoodItem {
  final String name;
  final int calories;
  final String portion;

  FoodItem({
    required this.name,
    required this.calories,
    required this.portion,
  });
} 
