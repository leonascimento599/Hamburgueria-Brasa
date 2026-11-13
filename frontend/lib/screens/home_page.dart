import 'dart:async';
import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/api_service.dart';

const _ink = Color(0xFF211A18);
const _ember = Color(0xFFC93425);
const _gold = Color(0xFFF6B73C);
const _muted = Color(0xFF756B64);
const _line = Color(0xFFEDE3D8);

String money(double value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  MenuCatalog? catalog;
  List<Product> get products => catalog?.products ?? const [];
  final List<CartLine> cart = [];
  final Set<String> favorites = {};
  final ScrollController _scrollController = ScrollController();
  String selectedCategory = 'Todos';
  String search = '';
  Coupon? appliedCoupon;
  bool? apiAvailable;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMenu() async {
    setState(() => apiAvailable = null);
    try {
      final loadedCatalog = await ApiService.fetchMenu();
      if (!mounted) return;
      setState(() {
        catalog = loadedCatalog;
        apiAvailable = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => apiAvailable = false);
    }
  }

  List<Product> get visibleProducts => products.where((product) {
        final matchesCategory =
            selectedCategory == 'Todos' || product.category == selectedCategory;
        final query = search.trim().toLowerCase();
        final matchesSearch = query.isEmpty ||
            product.name.toLowerCase().contains(query) ||
            product.description.toLowerCase().contains(query);
        return matchesCategory && matchesSearch;
      }).toList();

  double get subtotal => cart.fold<double>(0, (sum, item) => sum + item.total);
  double get discount =>
      (subtotal * (appliedCoupon?.discountPercent ?? 0)).round() / 100;
  double get deliveryFee => subtotal >= 65 ? 0 : 6.90;
  double get total => subtotal - discount + (cart.isEmpty ? 0 : deliveryFee);
  int get itemCount => cart.fold<int>(0, (sum, item) => sum + item.quantity);

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.fixed,
      backgroundColor: _ink,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _customize(Product product) async {
    final availableExtras = catalog!.addOns
        .where((extra) => product.allowedAddOnIds.contains(extra.id))
        .toList();
    final canRemoveIngredients =
        product.category == 'Burgers' || product.category == 'Combos';
    final chosenExtras = <Extra>{};
    final removed = <String>{};
    int quantity = 1;
    final result = await showDialog<CartLine>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) =>
          StatefulBuilder(builder: (context, setModalState) {
        final addedPrice =
            chosenExtras.fold<double>(0, (sum, extra) => sum + extra.price);
        return Dialog(
          backgroundColor: const Color(0xFFFFFCF7),
          insetPadding: const EdgeInsets.all(18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 590, maxHeight: 790),
            child: Column(children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: SizedBox(
                    height: 190,
                    width: double.infinity,
                    child: _FoodImage(
                        url: product.image,
                        icon: Icons.lunch_dining,
                        radius: 0)),
              ),
              Expanded(
                  child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
                      children: [
                    Row(children: [
                      Expanded(
                          child: Text(product.name,
                              style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                  color: _ink))),
                      IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close)),
                    ]),
                    Text(product.description,
                        style: const TextStyle(color: _muted, height: 1.45)),
                    if (availableExtras.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const _SectionLabel(
                          title: 'Adicionais',
                          subtitle: 'Escolha os adicionais que vão junto.'),
                      const SizedBox(height: 8),
                      ...availableExtras.map((extra) => CheckboxListTile(
                            value: chosenExtras.contains(extra),
                            onChanged: (checked) => setModalState(() {
                              if (checked == true) {
                                chosenExtras.add(extra);
                              } else {
                                chosenExtras.remove(extra);
                              }
                            }),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            activeColor: _ember,
                            title: Text(extra.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            secondary: Text('+ ${money(extra.price)}',
                                style: const TextStyle(
                                    color: _ember,
                                    fontWeight: FontWeight.w700)),
                            controlAffinity: ListTileControlAffinity.leading,
                          )),
                    ],
                    if (canRemoveIngredients) ...[
                      const Divider(height: 26),
                      const _SectionLabel(
                          title: 'Do seu jeito',
                          subtitle: 'Retire algum ingrediente, se preferir.'),
                      Wrap(
                          spacing: 8,
                          runSpacing: 2,
                          children: [
                            'Sem cebola',
                            'Sem picles',
                            'Sem tomate',
                            'Sem molho'
                          ]
                              .map((label) => FilterChip(
                                    label: Text(label),
                                    selected: removed.contains(label),
                                    selectedColor: const Color(0xFFFFE3D8),
                                    checkmarkColor: _ember,
                                    onSelected: (selected) => setModalState(() {
                                      selected
                                          ? removed.add(label)
                                          : removed.remove(label);
                                    }),
                                  ))
                              .toList()),
                    ],
                    const SizedBox(height: 16),
                  ])),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: _line))),
                child: Row(children: [
                  _QuantityControl(
                      value: quantity,
                      onChanged: (value) =>
                          setModalState(() => quantity = value)),
                  const SizedBox(width: 14),
                  Expanded(
                      child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: _ember,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () => Navigator.pop(
                        dialogContext,
                        CartLine(
                          product: product,
                          extras: chosenExtras.toList(),
                          quantity: quantity,
                          removedIngredients: removed.toList(),
                        )),
                    child: Text(
                        'Adicionar • ${money((product.price + addedPrice) * quantity)}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  )),
                ]),
              ),
            ]),
          ),
        );
      }),
    );
    if (result != null && mounted) {
      setState(() {
        final matching = cart.where((line) =>
            line.product.id == result.product.id &&
            line.extras
                .map((e) => e.id)
                .toSet()
                .containsAll(result.extras.map((e) => e.id)) &&
            result.extras
                .map((e) => e.id)
                .toSet()
                .containsAll(line.extras.map((e) => e.id)) &&
            line.removedIngredients
                .toSet()
                .containsAll(result.removedIngredients) &&
            result.removedIngredients
                .toSet()
                .containsAll(line.removedIngredients));
        if (matching.isNotEmpty) {
          final combined = matching.first.quantity + result.quantity;
          matching.first.quantity = combined > 20 ? 20 : combined;
        } else {
          cart.add(result);
        }
      });
      _snack('${product.name} adicionado à sacola!');
    }
  }

  void _changeQuantity(CartLine line, int delta) {
    setState(() {
      line.quantity += delta;
      if (line.quantity <= 0) cart.remove(line);
    });
  }

  Future<void> _openCart() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
          builder: (context, setSheetState) => _CartSheet(
                cart: cart,
                subtotal: subtotal,
                discount: discount,
                deliveryFee: deliveryFee,
                total: total,
                coupon: appliedCoupon,
                coupons: catalog?.coupons ?? const [],
                onQuantity: (line, delta) {
                  _changeQuantity(line, delta);
                  setSheetState(() {});
                },
                onRemove: (line) {
                  setState(() => cart.remove(line));
                  setSheetState(() {});
                },
                onCoupon: (coupon) {
                  setState(() => appliedCoupon = coupon);
                  setSheetState(() {});
                },
                onCheckout: () {
                  Navigator.pop(context);
                  _checkout();
                },
              )),
    );
  }

  Future<void> _checkout() async {
    if (cart.isEmpty) return;
    final checkout = await showDialog<_CheckoutData>(
        context: context, builder: (_) => const _CheckoutDialog());
    if (checkout == null || !mounted) return;
    try {
      final response = await ApiService.createOrder(
        customerName: checkout.name,
        address: checkout.address,
        paymentMethod: checkout.payment,
        items: List<CartLine>.from(cart),
        coupon: appliedCoupon?.code,
      );
      if (!mounted) return;
      final orderId = response['id'] as String;
      setState(() {
        cart.clear();
        appliedCoupon = null;
      });
      _snack('Pedido confirmado! Código $orderId');
      await showDialog<void>(
          context: context,
          builder: (_) => _TrackingDialog(initialId: orderId));
    } catch (error) {
      if (!mounted) return;
      _snack(
          'Não foi possível enviar o pedido. Confira se a API Dart Frog está rodando.');
    }
  }

  Future<void> _track() async {
    final id = await showDialog<String>(
        context: context, builder: (_) => const _TrackCodeDialog());
    if (id == null || !mounted) return;
    await showDialog<void>(
        context: context, builder: (_) => _TrackingDialog(initialId: id));
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 920;
    return Scaffold(
      body: CustomScrollView(controller: _scrollController, slivers: [
        SliverToBoxAdapter(
            child: _TopBar(
                onTrack: _track, onCart: _openCart, itemCount: itemCount)),
        SliverToBoxAdapter(child: _HeroBanner(onBrowse: () {
          _scrollController.animateTo(300,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOut);
        })),
        SliverToBoxAdapter(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 6),
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1250),
                  child: Row(children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: _ember, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            apiAvailable == true
                                ? 'Cardápio atualizado'
                                : 'Feito na brasa. Entregue com carinho.',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, color: _ink))),
                  ]))),
        )),
        SliverToBoxAdapter(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1250),
          child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
              child: _SearchAndCategories(
                onSearch: (value) => setState(() => search = value),
                selected: selectedCategory,
                categories: catalog?.categories ?? const [],
                onCategory: (value) => setState(() => selectedCategory = value),
              )),
        ))),
        SliverToBoxAdapter(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1250),
          child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
              child: _SectionHeading(
                title: selectedCategory == 'Todos'
                    ? 'Os queridinhos da casa'
                    : selectedCategory,
                subtitle: selectedCategory == 'Todos'
                    ? 'Clássicos, novidades e combinações para deixar o dia melhor.'
                    : 'Escolha o seu favorito e personalize do seu jeito.',
              )),
        ))),
        if (apiAvailable == null)
          const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (apiAvailable == false)
          SliverToBoxAdapter(
            child: Column(children: [
              const Text('Não foi possível carregar o cardápio.'),
              TextButton(
                  onPressed: _loadMenu, child: const Text('Tentar novamente')),
            ]),
          )
        else if (visibleProducts.isEmpty)
          const SliverToBoxAdapter(
              child: Padding(
                  padding: EdgeInsets.all(50),
                  child: Center(
                      child:
                          Text('Nenhum item encontrado. Tente outra busca.'))))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverLayoutBuilder(builder: (context, constraints) {
              return SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = visibleProducts[index];
                  return _ProductCard(
                    product: product,
                    favorite: favorites.contains(product.id),
                    onFavorite: () => setState(() =>
                        favorites.contains(product.id)
                            ? favorites.remove(product.id)
                            : favorites.add(product.id)),
                    onAdd: () => _customize(product),
                  );
                }, childCount: visibleProducts.length),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: isWide ? 310 : 360,
                  mainAxisExtent: 365,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                ),
              );
            }),
          ),
        SliverToBoxAdapter(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1250),
          child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 34, 24, 22),
              child: const _BenefitsStrip()),
        ))),
        SliverToBoxAdapter(child: const _Footer()),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ]),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _openCart,
                          style: FilledButton.styleFrom(
                              backgroundColor: _ember,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18))),
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: Text(
                              'Ver sacola ($itemCount)  •  ${money(total)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ))),
            ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar(
      {required this.onTrack, required this.onCart, required this.itemCount});
  final VoidCallback onTrack;
  final VoidCallback onCart;
  final int itemCount;
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 650;
    return SafeArea(
        child: Center(
            child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1300),
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          child: Row(children: [
            Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: _ember, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.local_fire_department_rounded,
                    color: Colors.white, size: 28)),
            const SizedBox(width: 9),
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('BRASA & PONTO',
                      style: TextStyle(
                          color: _ink,
                          fontSize: 16,
                          letterSpacing: .6,
                          fontWeight: FontWeight.w900)),
                  Text('BURGER • DELIVERY',
                      style: TextStyle(
                          color: _muted,
                          fontSize: 8,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.w700)),
                ]),
            const Spacer(),
            if (compact)
              IconButton(
                  onPressed: onTrack,
                  tooltip: 'Acompanhar pedido',
                  icon: const Icon(Icons.route_outlined, color: _ink))
            else
              TextButton.icon(
                  onPressed: onTrack,
                  icon: const Icon(Icons.route_outlined, size: 18),
                  label: const Text('Acompanhar pedido'),
                  style: TextButton.styleFrom(foregroundColor: _ink)),
            const SizedBox(width: 4),
            if (compact)
              IconButton(
                  onPressed: onCart,
                  tooltip: 'Sacola ($itemCount)',
                  icon: Badge(
                      isLabelVisible: itemCount > 0,
                      label: Text('$itemCount'),
                      child: const Icon(Icons.shopping_bag_outlined,
                          color: _ember)))
            else
              OutlinedButton.icon(
                  onPressed: onCart,
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: Text('Sacola${itemCount > 0 ? ' ($itemCount)' : ''}'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: _ember,
                      side: const BorderSide(color: _ember),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)))),
          ])),
    )));
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onBrowse});
  final VoidCallback onBrowse;
  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.sizeOf(context).width < 650;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
          child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1250),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
              height: 310,
              width: double.infinity,
              child: Stack(fit: StackFit.expand, children: [
                _FoodImage(
                    url:
                        'https://images.unsplash.com/photo-1550547660-d9450f859349?w=1800&q=90',
                    icon: Icons.lunch_dining,
                    radius: 0),
                DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                      _ink.withValues(alpha: .98),
                      _ink.withValues(alpha: .84),
                      _ink.withValues(alpha: .15)
                    ]))),
                Padding(
                    padding: const EdgeInsets.all(30),
                    child: Row(children: [
                      Expanded(
                          flex: 6,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 11, vertical: 6),
                                    decoration: BoxDecoration(
                                        color: _gold,
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: const Text('A FOME CHAMOU?',
                                        style: TextStyle(
                                            color: _ink,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.1))),
                                const SizedBox(height: 16),
                                Text('MORDIDA\nDE RESPEITO.',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isSmall ? 30 : 38,
                                        height: 1.02,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1.1)),
                                const SizedBox(height: 10),
                                const Text(
                                    'Burger de verdade, do seu jeito e na sua porta.',
                                    style: TextStyle(
                                        color: Color(0xFFE9DCD0),
                                        fontSize: 14)),
                                const SizedBox(height: 19),
                                FilledButton(
                                    onPressed: onBrowse,
                                    style: FilledButton.styleFrom(
                                        backgroundColor: _ember,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 14)),
                                    child: const Text('Explorar cardápio  →',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800))),
                              ])),
                      if (!isSmall) const Spacer(flex: 4),
                    ])),
                Positioned(
                    right: 23,
                    top: 20,
                    child: Transform.rotate(
                        angle: .08,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 9),
                            decoration: BoxDecoration(
                                color: _ember,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 12,
                                      offset: Offset(0, 4))
                                ]),
                            child: const Text('FEITO NA BRASA',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1))))),
              ])),
        ),
      )),
    );
  }
}

class _SearchAndCategories extends StatelessWidget {
  const _SearchAndCategories(
      {required this.onSearch,
      required this.selected,
      required this.categories,
      required this.onCategory});
  final ValueChanged<String> onSearch;
  final String selected;
  final List<String> categories;
  final ValueChanged<String> onCategory;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(
            onChanged: onSearch,
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, color: _ember),
                hintText: 'Encontre seu burger, combo ou sobremesa...',
                suffixIcon: Icon(Icons.tune_rounded, color: _muted))),
        const SizedBox(height: 17),
        SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
                children: categories
                    .map((category) => Padding(
                          padding: const EdgeInsets.only(right: 9),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: selected == category,
                            onSelected: (_) => onCategory(category),
                            selectedColor: _ink,
                            labelStyle: TextStyle(
                                color:
                                    selected == category ? Colors.white : _ink,
                                fontWeight: FontWeight.w700),
                            backgroundColor: Colors.white,
                            side: BorderSide(
                                color: selected == category ? _ink : _line),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                          ),
                        ))
                    .toList())),
      ]);
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: -.8)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: _muted)),
        ])),
        if (MediaQuery.sizeOf(context).width > 650)
          const Text('QUAL VAI SER HOJE?',
              style: TextStyle(
                  color: _ember,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w900)),
      ]);
}

class _ProductCard extends StatelessWidget {
  const _ProductCard(
      {required this.product,
      required this.favorite,
      required this.onFavorite,
      required this.onAdd});
  final Product product;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _line),
            boxShadow: [
              BoxShadow(
                  color: _ink.withValues(alpha: .035),
                  blurRadius: 15,
                  offset: const Offset(0, 7))
            ]),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              height: 177,
              width: double.infinity,
              child: Stack(fit: StackFit.expand, children: [
                _FoodImage(url: product.image, icon: Icons.fastfood, radius: 0),
                if (product.badge != null)
                  Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                              color: _gold,
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(product.badge!,
                              style: const TextStyle(
                                  color: _ink,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900)))),
                Positioned(
                    right: 10,
                    top: 10,
                    child: Material(
                        color: Colors.white.withValues(alpha: .93),
                        shape: const CircleBorder(),
                        child: IconButton(
                            onPressed: onFavorite,
                            icon: Icon(
                                favorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: favorite ? _ember : _ink,
                                size: 18),
                            tooltip: 'Favoritar'))),
              ])),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 13, 15, 12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: _ink)),
                        const SizedBox(height: 5),
                        Expanded(
                            child: Text(product.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: _muted,
                                    fontSize: 11.5,
                                    height: 1.35))),
                        Row(children: [
                          Expanded(
                              child: Text(money(product.price),
                                  style: const TextStyle(
                                      color: _ember,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17))),
                          FilledButton.icon(
                              onPressed: onAdd,
                              icon: const Icon(Icons.add, size: 17),
                              label: const Text('Personalizar'),
                              style: FilledButton.styleFrom(
                                  backgroundColor: _ink,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 11),
                                  textStyle: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(11)))),
                        ]),
                      ]))),
        ]),
      );
}

class _FoodImage extends StatelessWidget {
  const _FoodImage({required this.url, required this.icon, this.radius = 16});
  final String url;
  final IconData icon;
  final double radius;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            1.17,
            -0.08,
            -0.08,
            0,
            0,
            -0.04,
            1.12,
            -0.04,
            0,
            0,
            -0.07,
            -0.07,
            1.18,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: Image.network(url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFE9D9C8),
                  child: Icon(icon, size: 58, color: _ember))),
        ),
      );
}

class _BenefitsStrip extends StatelessWidget {
  const _BenefitsStrip();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 19),
        decoration: BoxDecoration(
            color: const Color(0xFFFFE9D7),
            borderRadius: BorderRadius.circular(18)),
        child: Wrap(
            alignment: WrapAlignment.spaceAround,
            runSpacing: 16,
            spacing: 22,
            children: const [
              _Benefit(
                  icon: Icons.delivery_dining,
                  title: 'Entrega acompanhada',
                  subtitle: 'Saiba onde está seu pedido'),
              _Benefit(
                  icon: Icons.tune_rounded,
                  title: 'Do seu jeito',
                  subtitle: 'Monte com seus adicionais'),
              _Benefit(
                  icon: Icons.local_offer_outlined,
                  title: 'Ofertas especiais',
                  subtitle: 'Cupons e combos da casa'),
            ]),
      );
}

class _Benefit extends StatelessWidget {
  const _Benefit(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: _ember)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: _ink, fontWeight: FontWeight.w800, fontSize: 12)),
          Text(subtitle, style: const TextStyle(color: _muted, fontSize: 10))
        ]),
      ]);
}

class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) => Container(
        color: _ink,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('BRASA & PONTO',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    fontSize: 17)),
                            SizedBox(height: 8),
                            Text('Feito na brasa. Feito para compartilhar.',
                                style: TextStyle(
                                    color: Color(0xFFCCBFB5), fontSize: 12)),
                            SizedBox(height: 20),
                            Text('© 2026 Brasa & Ponto • Projeto demonstrativo',
                                style: TextStyle(
                                    color: Color(0xFF8D8179), fontSize: 10)),
                          ])),
                      if (MediaQuery.sizeOf(context).width > 570)
                        const Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('PRECISA DE AJUDA?',
                                  style: TextStyle(
                                      color: _gold,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                      letterSpacing: 1)),
                              SizedBox(height: 9),
                              Text('Central de atendimento',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12)),
                              SizedBox(height: 6),
                              Text('Política de entrega • Privacidade',
                                  style: TextStyle(
                                      color: Color(0xFFCCBFB5), fontSize: 10)),
                            ]),
                    ]))),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w900, color: _ink, fontSize: 15)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11)),
      ]);
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: const Color(0xFFF4EDE5),
            borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove, size: 16),
              visualDensity: VisualDensity.compact),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w900)),
          IconButton(
              onPressed: value < 20 ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add, size: 16),
              visualDensity: VisualDensity.compact),
        ]),
      );
}

class _CartSheet extends StatelessWidget {
  const _CartSheet({
    required this.cart,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
    required this.coupon,
    required this.coupons,
    required this.onQuantity,
    required this.onRemove,
    required this.onCoupon,
    required this.onCheckout,
  });
  final List<CartLine> cart;
  final double subtotal, discount, deliveryFee, total;
  final Coupon? coupon;
  final List<Coupon> coupons;
  final void Function(CartLine, int) onQuantity;
  final ValueChanged<CartLine> onRemove;
  final ValueChanged<Coupon?> onCoupon;
  final VoidCallback onCheckout;
  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
        initialChildSize: .78,
        minChildSize: .55,
        maxChildSize: .95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
              color: Color(0xFFFFFCF7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
          child: Column(children: [
            const SizedBox(height: 10),
            Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                    color: _line, borderRadius: BorderRadius.circular(5))),
            Padding(
                padding: const EdgeInsets.fromLTRB(22, 17, 22, 12),
                child: Row(children: [
                  const Expanded(
                      child: Text('Sua sacola',
                          style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              color: _ink))),
                  Text('${cart.length} item(ns)',
                      style: const TextStyle(color: _muted, fontSize: 12))
                ])),
            Expanded(
                child: cart.isEmpty
                    ? const Center(child: Text('Sua sacola está vazia.'))
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                            ...cart.map((line) => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(13),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: _line),
                                      borderRadius: BorderRadius.circular(15)),
                                  child: Row(children: [
                                    ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: SizedBox(
                                            width: 68,
                                            height: 68,
                                            child: _FoodImage(
                                                url: line.product.image,
                                                icon: Icons.fastfood,
                                                radius: 0))),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(line.product.name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: _ink)),
                                          if (line.extras.isNotEmpty)
                                            Text(
                                                '+ ${line.extras.map((e) => e.name).join(', ')}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    color: _muted,
                                                    fontSize: 10)),
                                          Text(money(line.total),
                                              style: const TextStyle(
                                                  color: _ember,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 13)),
                                        ])),
                                    Column(children: [
                                      _QuantityControl(
                                          value: line.quantity,
                                          onChanged: (v) => onQuantity(
                                              line, v - line.quantity)),
                                      TextButton(
                                          onPressed: () => onRemove(line),
                                          child: const Text('Remover',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: _muted))),
                                    ]),
                                  ]),
                                )),
                          ])),
            if (cart.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
                decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: _line))),
                child: Column(children: [
                  if (coupons.isNotEmpty)
                    DropdownButton<Coupon>(
                      isExpanded: true,
                      value: coupon,
                      hint: const Text('Selecionar cupom'),
                      items: [
                        const DropdownMenuItem<Coupon>(
                            child: Text('Sem cupom')),
                        for (final option in coupons)
                          DropdownMenuItem(
                            value: option,
                            child: Text(option.description.isEmpty
                                ? option.code
                                : '${option.code} • ${option.description}'),
                          ),
                      ],
                      onChanged: onCoupon,
                    ),
                  _PriceRow(label: 'Subtotal', value: money(subtotal)),
                  if (discount > 0)
                    _PriceRow(
                        label: 'Desconto ${coupon?.code ?? ''}',
                        value: '- ${money(discount)}',
                        color: const Color(0xFF218653)),
                  _PriceRow(
                      label: 'Entrega',
                      value: deliveryFee == 0 ? 'Grátis' : money(deliveryFee)),
                  const Divider(height: 20),
                  _PriceRow(label: 'Total', value: money(total), bold: true),
                  const SizedBox(height: 13),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          onPressed: onCheckout,
                          style: FilledButton.styleFrom(
                              backgroundColor: _ember,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('Continuar para entrega',
                              style: TextStyle(fontWeight: FontWeight.w900)))),
                  const SizedBox(height: 4),
                  const Text('Frete grátis em pedidos acima de R\$ 65,00',
                      style: TextStyle(color: _muted, fontSize: 10)),
                ]),
              ),
          ]),
        ),
      );
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(
      {required this.label,
      required this.value,
      this.bold = false,
      this.color});
  final String label, value;
  final bool bold;
  final Color? color;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: TextStyle(
                    color: bold ? _ink : _muted,
                    fontWeight: bold ? FontWeight.w900 : FontWeight.w500))),
        Text(value,
            style: TextStyle(
                color: color ?? _ink,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                fontSize: bold ? 17 : 13)),
      ]));
}

class _CheckoutData {
  const _CheckoutData(this.name, this.address, this.payment);
  final String name, address, payment;
}

class _CheckoutDialog extends StatefulWidget {
  const _CheckoutDialog();
  @override
  State<_CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<_CheckoutDialog> {
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  String payment = 'Pix na entrega';
  String? error;
  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFCF7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Dados para entrega',
            style: TextStyle(fontWeight: FontWeight.w900, color: _ink)),
        content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text(
                  'Preencha os dados para registrar seu pedido e acompanhar a entrega.',
                  style: TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 16),
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: 'Seu nome',
                      prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 12),
              TextField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Endereço completo',
                      prefixIcon: Icon(Icons.location_on_outlined))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                  initialValue: payment,
                  decoration:
                      const InputDecoration(labelText: 'Forma de pagamento'),
                  items: const [
                    DropdownMenuItem(
                        value: 'Pix na entrega', child: Text('Pix na entrega')),
                    DropdownMenuItem(
                        value: 'Cartão na entrega',
                        child: Text('Cartão na entrega')),
                    DropdownMenuItem(
                        value: 'Dinheiro', child: Text('Dinheiro')),
                  ],
                  onChanged: (value) =>
                      setState(() => payment = value ?? payment)),
              if (error != null)
                Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(error!,
                        style: const TextStyle(color: _ember, fontSize: 12))),
              const SizedBox(height: 7),
              const Text(
                  'Pagamento demonstrativo: nenhum dado bancário é solicitado ou processado.',
                  style: TextStyle(color: _muted, fontSize: 10)),
            ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Voltar')),
          FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final address = addressController.text.trim();
                if (name.length < 2 || address.length < 8) {
                  setState(() =>
                      error = 'Informe seu nome e um endereço mais completo.');
                  return;
                }
                Navigator.pop(context, _CheckoutData(name, address, payment));
              },
              style: FilledButton.styleFrom(
                  backgroundColor: _ember, foregroundColor: Colors.white),
              child: const Text('Confirmar pedido')),
        ],
      );
}

class _TrackCodeDialog extends StatefulWidget {
  const _TrackCodeDialog();
  @override
  State<_TrackCodeDialog> createState() => _TrackCodeDialogState();
}

class _TrackCodeDialogState extends State<_TrackCodeDialog> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Acompanhar pedido',
            style: TextStyle(fontWeight: FontWeight.w900, color: _ink)),
        content: SizedBox(
            width: 390,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text(
                  'Digite o código que apareceu após confirmar seu pedido.',
                  style: TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 14),
              TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                      hintText: 'Ex.: BP-A1B2C3',
                      prefixIcon: Icon(Icons.receipt_long_outlined))),
            ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () {
                final value = controller.text.trim().toUpperCase();
                if (value.isNotEmpty) Navigator.pop(context, value);
              },
              style: FilledButton.styleFrom(backgroundColor: _ember),
              child:
                  const Text('Rastrear', style: TextStyle(color: Colors.white)))
        ],
      );
}

class _TrackingDialog extends StatefulWidget {
  const _TrackingDialog({required this.initialId});
  final String initialId;
  @override
  State<_TrackingDialog> createState() => _TrackingDialogState();
}

class _TrackingDialogState extends State<_TrackingDialog> {
  Map<String, dynamic>? order;
  String? error;
  bool loading = true;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    _refresh();
    timer = Timer.periodic(
        const Duration(seconds: 8), (_) => _refresh(silent: true));
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent && mounted)
      setState(() {
        loading = true;
        error = null;
      });
    try {
      final result = await ApiService.trackOrder(widget.initialId);
      if (!mounted) return;
      setState(() {
        order = result;
        loading = false;
        error = null;
      });
      if ((result['statusIndex'] as num?)?.toInt() == 3) timer?.cancel();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Pedido não encontrado. Confira o código e tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusIndex = (order?['statusIndex'] as num?)?.toInt() ?? 0;
    final address = order?['address'];
    final steps = [
      'Pedido recebido',
      'Preparando',
      'Saiu para entrega',
      'Entregue'
    ];
    return AlertDialog(
      backgroundColor: const Color(0xFFFFFCF7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(children: [
        const Expanded(
            child: Text('Rastreio do pedido',
                style: TextStyle(fontWeight: FontWeight.w900, color: _ink))),
        IconButton(
            onPressed: () => _refresh(),
            icon: const Icon(Icons.refresh, color: _ember))
      ]),
      content: SizedBox(
          width: 450,
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child:
                      Center(child: CircularProgressIndicator(color: _ember)))
              : error != null
                  ? Text(error!, style: const TextStyle(color: _ember))
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFFFE9D7),
                                  borderRadius: BorderRadius.circular(13)),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('CÓDIGO DO PEDIDO',
                                        style: TextStyle(
                                            color: _muted,
                                            fontSize: 9,
                                            letterSpacing: 1,
                                            fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 3),
                                    Text('${order!['id']}',
                                        style: const TextStyle(
                                            color: _ink,
                                            fontSize: 19,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1)),
                                    const SizedBox(height: 5),
                                    Text('${order!['status']}',
                                        style: const TextStyle(
                                            color: _ember,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800)),
                                    Text(
                                        'Previsão estimada: ${order!['etaMinutes']} min',
                                        style: const TextStyle(
                                            color: _muted, fontSize: 11)),
                                  ])),
                          const SizedBox(height: 18),
                          ...List.generate(
                              steps.length,
                              (index) => Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(children: [
                                          Container(
                                              width: 25,
                                              height: 25,
                                              decoration: BoxDecoration(
                                                  color: index <= statusIndex
                                                      ? _ember
                                                      : const Color(0xFFE9DED4),
                                                  shape: BoxShape.circle),
                                              child: Icon(
                                                  index < statusIndex
                                                      ? Icons.check
                                                      : _stepIcon(index),
                                                  size: 14,
                                                  color: index <= statusIndex
                                                      ? Colors.white
                                                      : _muted)),
                                          if (index != steps.length - 1)
                                            Container(
                                                width: 2,
                                                height: 25,
                                                color: index < statusIndex
                                                    ? _ember
                                                    : _line),
                                        ]),
                                        const SizedBox(width: 12),
                                        Padding(
                                            padding:
                                                const EdgeInsets.only(top: 3),
                                            child: Text(steps[index],
                                                style: TextStyle(
                                                    color: index <= statusIndex
                                                        ? _ink
                                                        : _muted,
                                                    fontWeight: index ==
                                                            statusIndex
                                                        ? FontWeight.w900
                                                        : FontWeight.w500))),
                                      ])),
                          const SizedBox(height: 12),
                          if (address is String && address.trim().isNotEmpty)
                            Text('Entrega em: $address',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: _muted, fontSize: 11)),
                          const SizedBox(height: 8),
                          const Text(
                              'Atualização automática a cada 8 segundos (modo demonstração).',
                              style: TextStyle(color: _muted, fontSize: 10)),
                        ])),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'))
      ],
    );
  }

  IconData _stepIcon(int index) => [
        Icons.receipt_long,
        Icons.soup_kitchen,
        Icons.delivery_dining,
        Icons.check_circle
      ][index];
}
