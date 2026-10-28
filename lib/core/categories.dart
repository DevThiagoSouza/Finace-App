import 'package:flutter/material.dart';
import 'theme.dart';

class Category {
  const Category(this.id, this.label, this.icon, this.color);
  final String id;
  final String label;
  final IconData icon;
  final Color color;
}

const List<Category> kCategories = [
  Category('Supermercado', 'Mercado', Icons.shopping_cart_rounded, SC.amber500),
  Category('Contas', 'Contas', Icons.bolt_rounded, SC.yellow500),
  Category('Transporte', 'Transporte', Icons.directions_car_rounded, SC.blue500),
  Category('Alimentacao', 'Lazer/Rest', Icons.local_pizza_rounded, SC.purple500),
  Category('Saude', 'Saúde', Icons.medical_services_rounded, SC.red500),
  Category('Salario', 'Salário', Icons.payments_rounded, SC.brand500),
  Category('Moradia', 'Moradia', Icons.home_rounded, SC.indigo500),
  Category('Outros', 'Outros', Icons.category_rounded, SC.slate400),
];

Category categoryOf(String id) =>
    kCategories.firstWhere((c) => c.id == id, orElse: () => kCategories.last);
