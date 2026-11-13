const products = <Map<String, dynamic>>[
  {
    'id': 'brasa-classico', 'name': 'Brasa Clássico', 'category': 'Burgers', 'price': 29.90,
    'description': 'Burger smash 150g, queijo prato, alface, tomate e molho da casa.',
    'image': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=1000&q=88',
    'badge': 'Mais pedido', 'isFeatured': true,
  },
  {
    'id': 'duplo-defumado', 'name': 'Duplo Defumado', 'category': 'Burgers', 'price': 38.90,
    'description': 'Dois burgers, cheddar cremoso, cebola caramelizada e barbecue.',
    'image': 'https://images.unsplash.com/photo-1553979459-d2229ba7433a?w=1000&q=88', 'badge': 'Intenso',
  },
  {
    'id': 'cheddar-crocante', 'name': 'Cheddar Crocante', 'category': 'Burgers', 'price': 34.90,
    'description': 'Burger 150g, cheddar, crispy de cebola e maionese verde.',
    'image': 'https://images.unsplash.com/photo-1594212699903-ec8a3eca50f5?w=1000&q=88', 'badge': 'Novidade',
  },
  {
    'id': 'frango-crocante', 'name': 'Chicken Crocante', 'category': 'Burgers', 'price': 31.90,
    'description': 'Frango empanado crocante, queijo, picles e molho especial.',
    'image': 'https://images.unsplash.com/photo-1606755962773-d324e0a13086?w=1000&q=88',
  },
  {
    'id': 'combo-brasa', 'name': 'Combo Brasa', 'category': 'Combos', 'price': 44.90,
    'description': 'Brasa Clássico + fritas crocantes + bebida 350ml.',
    'image': 'https://images.unsplash.com/photo-1550547660-d9450f859349?w=1000&q=88', 'badge': 'Combo favorito', 'isFeatured': true,
  },
  {
    'id': 'combo-duplo', 'name': 'Combo Duplo', 'category': 'Combos', 'price': 56.90,
    'description': 'Duplo Defumado + fritas médias + bebida 500ml.',
    'image': 'https://images.unsplash.com/photo-1561758033-d89a9ad46330?w=1000&q=88',
  },
  {
    'id': 'fritas-rusticas', 'name': 'Fritas da Casa', 'category': 'Acompanhamentos', 'price': 16.90,
    'description': 'Batatas rústicas, páprica defumada e toque de ervas.',
    'image': 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=1000&q=88',
  },
  {
    'id': 'onion-rings', 'name': 'Onion Rings', 'category': 'Acompanhamentos', 'price': 18.90,
    'description': 'Anéis de cebola empanados, dourados e crocantes.',
    'image': 'https://images.unsplash.com/photo-1639024471283-03518883512d?w=1000&q=88',
  },
  {
    'id': 'milkshake-choco', 'name': 'Milk-shake Chocolate', 'category': 'Bebidas', 'price': 19.90,
    'description': 'Milk-shake cremoso de chocolate com calda.',
    'image': 'https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=1000&q=88', 'badge': 'Geladinho',
  },
  {
    'id': 'limonada', 'name': 'Limonada da Casa', 'category': 'Bebidas', 'price': 9.90,
    'description': 'Limão espremido, água bem gelada e hortelã.',
    'image': 'https://images.unsplash.com/photo-1513558161293-cdaf765edfd47?w=1000&q=88',
  },
  {
    'id': 'brownie', 'name': 'Brownie com Creme', 'category': 'Sobremesas', 'price': 17.90,
    'description': 'Brownie de chocolate com creme de baunilha.',
    'image': 'https://images.unsplash.com/photo-1564355808539-22fda35bed7e?w=1000&q=88', 'badge': 'Doce final',
  },
];

const addOns = <Map<String, dynamic>>[
  {'id': 'extra-burger', 'name': 'Burger extra 100g', 'price': 9.90},
  {'id': 'cheddar', 'name': 'Cheddar cremoso', 'price': 4.50},
  {'id': 'bacon', 'name': 'Bacon crocante', 'price': 5.50},
  {'id': 'queijo', 'name': 'Queijo prato', 'price': 3.50},
  {'id': 'cebola', 'name': 'Cebola caramelizada', 'price': 3.00},
  {'id': 'ovo', 'name': 'Ovo na chapa', 'price': 3.50},
  {'id': 'molho', 'name': 'Molho da casa extra', 'price': 2.00},
];

const _burgerAddOns = [
  'extra-burger', 'cheddar', 'bacon', 'queijo', 'cebola', 'ovo', 'molho',
];

const _defaultAddOns = {
  'brasa-classico': _burgerAddOns,
  'duplo-defumado': _burgerAddOns,
  'cheddar-crocante': _burgerAddOns,
  'frango-crocante': ['cheddar', 'bacon', 'queijo', 'cebola', 'ovo', 'molho'],
  'combo-brasa': _burgerAddOns,
  'combo-duplo': _burgerAddOns,
  'fritas-rusticas': ['cheddar', 'bacon', 'molho'],
  'onion-rings': ['molho'],
  'frango-frito': ['molho'],
};

List<String> allowedAddOnIds(String productId) =>
    _defaultAddOns[productId] ?? const [];

Map<String, dynamic> get menuResponse => {
  'categories': ['Todos', 'Burgers', 'Combos', 'Acompanhamentos', 'Bebidas', 'Sobremesas'],
  'products': [
    for (final product in products)
      {...product, 'allowedAddOnIds': allowedAddOnIds(product['id'] as String)},
  ],
  'addOns': addOns,
  'coupons': [
    {'code': 'BRASA10', 'discountPercent': 10, 'description': '10% de desconto no pedido'},
  ],
};
