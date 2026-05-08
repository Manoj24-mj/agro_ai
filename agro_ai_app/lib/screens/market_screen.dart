import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:agro_ai_app/service/market_service.dart';
import 'package:agro_ai_app/widgets/searchable_picker.dart';
import 'package:agro_ai_app/localization.dart';
import 'package:agro_ai_app/service/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  
  String _searchQuery = "";
  String _selectedFilter = "All";

  List<Map<String, dynamic>> get _filteredProducts {
    return _products.where((p) {
       final matchesSearch = p['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
       final matchesCategory = _selectedFilter == "All" || p['cat'] == _selectedFilter;
       return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadState();
    Lang().addListener(_onLangChanged);
  }

  void _onLangChanged() { if (mounted) setState(() {}); }

  Future<void> _loadState() async {
    final cart = await MarketService.getCart();
    if (mounted) {
      setState(() {
        _cartItems = cart;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(Lang.t("market_title"), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.mic), onPressed: () {}),
          IconButton(
            icon: Badge(
              label: Text('${_cartItems.length}'),
              isLabelVisible: _cartItems.isNotEmpty,
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: () => _showCart(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                      ),
                      child: TextField(
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        onSubmitted: (val) async {
                          if (val.trim().isNotEmpty) {
                            final prefs = await SharedPreferences.getInstance();
                            final phone = prefs.getString('userPhone');
                            if (phone != null) {
                              await FirebaseService.saveSearchHistory(
                                phone: phone,
                                query: val.trim(),
                                category: "Marketplace",
                              );
                            }
                          }
                        },
                        decoration: InputDecoration(
                          icon: const Icon(Icons.search, color: Colors.green),
                          hintText: Lang.t("market_search_hint"),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // AI Recommendation Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.green.shade800, Colors.teal.shade700]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0,5))]
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.amber, size: 30),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(Lang.t("ai_suggest_title"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(Lang.t("ai_suggest_body"), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.green.shade800),
                            onPressed: () {},
                            child: Text(Lang.t("view")),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(Lang.t("categories"), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterChip("All", Icons.apps),
                          _buildFilterChip("Crops", Icons.grass),
                          _buildFilterChip("Seeds", Icons.spa),
                          _buildFilterChip("Fertilizers", Icons.science),
                          _buildFilterChip("Tools", Icons.build),
                          _buildFilterChip("Equipment", Icons.agriculture),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Nearby Shops Horizontal
                    Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text(Lang.t("nearby_shops"), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                         TextButton.icon(onPressed: (){}, icon: const Icon(Icons.map, size: 16), label: Text(Lang.t("map_view")))
                       ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildShopCard("AgroTech Store", "1.2 km", 4.9),
                          _buildShopCard("Farmers Hub", "3.0 km", 4.5),
                          _buildShopCard("Green Life Solutions", "4.5 km", 4.2),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(Lang.t("trending_products"), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            
            // Product Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: StreamBuilder<List<Map<String, dynamic>>>(
                stream: MarketService.getProductsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: Colors.green)));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return SliverToBoxAdapter(child: Center(child: Text(Lang.t("no_products"))));
                  }
                  
                  _products = snapshot.data!;
                  final filtered = _filteredProducts;

                  return SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.55,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildProductCard(filtered[index]);
                      },
                      childCount: filtered.length,
                    ),
                  );
                }
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSellProductForm(context),
        backgroundColor: Colors.orange.shade700,
        icon: const Icon(Icons.add_business, color: Colors.white),
        label: Text(Lang.t("sell_product"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    bool isActive = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.shade700 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.green.shade700 : Colors.green.shade200),
          boxShadow: isActive ? [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : Colors.green.shade800),
            const SizedBox(width: 8),
            Text(Lang.t("${label}_cat"), style: TextStyle(color: isActive ? Colors.white : Colors.green.shade900, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildShopCard(String name, String distance, double rating) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.store, color: Colors.green.shade700, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: Colors.grey),
                    Text(distance, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(rating.toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => _ProductDetailPage(product: product)));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder with Demand Badge
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Center(
                       child: Icon(
                         product["cat"] == "Seeds" || product["cat"] == "Crops" ? Icons.spa : 
                         product["cat"] == "Fertilizers" ? Icons.science : Icons.build, 
                         size: 50, color: Colors.green.shade300
                       ),
                    ),
                  ),
                  if (product["demand"] == "HIGH")
                    Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)), child: Text("🔥 ${Lang.t("high_demand")}", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)))),
                  if (product["demand"] == "TRENDING")
                    Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)), child: Text("📈 ${Lang.t("trending")}", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)))),
                  if (product["demand"] == "LOW")
                    Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(4)), child: Text("📉 ${Lang.t("low_demand")}", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product["name"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(child: Text(product["seller"], style: TextStyle(color: Colors.grey.shade600, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 4),
                      if (product["isVerified"] == true) const Icon(Icons.verified, color: Colors.blue, size: 12),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(product["rating"].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const Spacer(),
                      Text(product["distance"], style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(product["price"], style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.green.shade50,
                         foregroundColor: Colors.green.shade800,
                         elevation: 0,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      onPressed: () async {
                         await MarketService.addToCart(product);
                         _loadState(); // Refresh Cart UI Badge
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${product['name']} ${Lang.t("added_to_cart")}", style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
                      },
                      child: Text(Lang.t("add_to_cart"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.orange.shade600,
                         foregroundColor: Colors.white,
                         elevation: 2,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      onPressed: () {},
                      child: Text(Lang.t("buy_now"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showSellProductForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String selectedCategory = "Seeds";
        String qualityGrade = "A";
        bool isAnalyzingPrice = false;
        String? aiPrice;
        
        final nameCtrl = TextEditingController();
        final priceCtrl = TextEditingController();

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                   const SizedBox(height: 20),
                   Text(Lang.t("sell_form_title"), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                   const SizedBox(height: 20),
                   Expanded(
                     child: ListView(
                       physics: const BouncingScrollPhysics(),
                       children: [
                         TextField(
                           controller: nameCtrl,
                           decoration: InputDecoration(labelText: Lang.t("prod_name"), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                         ),
                         const SizedBox(height: 16),
                         InkWell(
                           onTap: () {
                               final cats = ["Crops", "Seeds", "Fertilizers", "Tools"];
                               cats.sort();
                               SearchablePicker.show(
                                 context,
                                 title: Lang.t("prod_cat"),
                                 items: cats,
                                 selectedItem: selectedCategory,
                                 onSelected: (v) => setModalState(() => selectedCategory = v),
                               );
                           },
                           child: Container(
                             padding: const EdgeInsets.all(16),
                             decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                             child: Row(
                               children: [
                                 Expanded(child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(Lang.t("prod_cat"), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                     Text(selectedCategory, style: const TextStyle(fontSize: 16)),
                                   ],
                                 )),
                                 const Icon(Icons.arrow_drop_down, color: Colors.grey),
                               ],
                             ),
                           ),
                         ),
                         
                         // Crop Selling Mode
                         if (selectedCategory == "Crops") ...[
                            const SizedBox(height: 16),
                            Container(
                               padding: const EdgeInsets.all(12),
                               decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                    Row(children: [const Icon(Icons.spa, color: Colors.green, size: 18), const SizedBox(width: 8), Text(Lang.t("crop_sell_mode"), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))]),
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      onPressed: () {}, 
                                      icon: const Icon(Icons.calendar_today, size: 16), 
                                      label: Text(Lang.t("harvest_date")),
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.green.shade800),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(Lang.t("quality_grade"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: ["A", "B", "C"].map((grade) => Expanded(
                                        child: Padding(
                                           padding: const EdgeInsets.only(right: 4),
                                           child: ChoiceChip(
                                              label: Text("Grade $grade"), 
                                              selected: qualityGrade == grade, 
                                              onSelected: (val) { if(val) setModalState(() => qualityGrade = grade); },
                                              selectedColor: Colors.green.shade200,
                                           )
                                        )
                                      )).toList()
                                    ),
                                 ]
                               )
                            )
                         ],

                         const SizedBox(height: 16),
                         Row(
                           children: [
                             Expanded(child: TextField(
                               controller: priceCtrl,
                               keyboardType: TextInputType.number,
                               onChanged: (val) {
                                 if (val.isNotEmpty && !isAnalyzingPrice && aiPrice == null) {
                                     setModalState(() => isAnalyzingPrice = true);
                                     Future.delayed(const Duration(seconds: 1), () {
                                         setModalState(() { isAnalyzingPrice = false; aiPrice = "₹" + ((int.tryParse(val) ?? 1000) * 0.9).toInt().toString(); });
                                     });
                                 }
                               },
                               decoration: InputDecoration(labelText: Lang.t("price_rs"), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                             )),
                             const SizedBox(width: 16),
                             Expanded(child: _buildTextField(Lang.t("quantity"), isNumber: true)),
                           ],
                         ),
                         // AI Price Suggestion
                         if (isAnalyzingPrice)
                            Padding(padding: const EdgeInsets.only(top: 8, left: 4), child: Text("🤖 ${Lang.t("ai_analyzing")}", style: const TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic)))
                         else if (aiPrice != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 4), 
                              child: Text("🤖 ${Lang.t("suggested_price")}: $aiPrice based on trends", style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold))
                            ),

                         const SizedBox(height: 16),
                         _buildTextField(Lang.t("description"), maxLines: 4),
                         const SizedBox(height: 16),
                         
                         // Upload Image Box
                         Container(
                           height: 100,
                           decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200, style: BorderStyle.solid)),
                           child: Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               Icon(Icons.add_a_photo, color: Colors.green.shade600, size: 30),
                               const SizedBox(height: 8),
                               Text(Lang.t("upload_images"), style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                             ],
                           ),
                         ),
                         const SizedBox(height: 16),
                         
                         SwitchListTile(
                           title: Text(Lang.t("bulk_sale")),
                           value: true,
                           onChanged: (v) {},
                           activeColor: Colors.green,
                         ),
                         SwitchListTile(
                           title: Text(Lang.t("organic_prod")),
                           subtitle: Text(Lang.t("organic_badge")),
                           value: false,
                           onChanged: (v) {},
                           activeColor: Colors.green,
                         ),
                       ],
                     )
                   ),
                   SizedBox(
                     width: double.infinity,
                     height: 55,
                     child: ElevatedButton(
                       style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                       onPressed: () async {
                         
                         // CONSTRUCT THE PRODUCT OBJECT TO SAVE TO DB
                         Map<String, dynamic> newProduct = {
                           "id": DateTime.now().millisecondsSinceEpoch.toString(),
                           "name": selectedCategory == "Crops" && qualityGrade.isNotEmpty ? "${nameCtrl.text.isEmpty ? 'New Crop' : nameCtrl.text} (Grade $qualityGrade)" : (nameCtrl.text.isEmpty ? 'New Product' : nameCtrl.text),
                           "price": "₹${priceCtrl.text.isEmpty ? '0' : priceCtrl.text}",
                           "distance": "0.0 km",
                           "rating": 5.0,
                           "reviews": 0,
                           "seller": "You (Verified)",
                           "isVerified": true,
                           "demand": "TRENDING",
                           "cat": selectedCategory
                         };
                         
                         Navigator.pop(context); // Close the bottom sheet immediately
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Lang.t("uploading_cloud"), style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.amber, duration: const Duration(seconds: 1)));
                         
                         // Simulate Backend Network Delay
                         await Future.delayed(const Duration(milliseconds: 1500));
                         
                         await MarketService.addProduct(newProduct);
                         _loadState(); // Re-trigger flutter UI state to show newly downloaded data
                         
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Lang.t("list_success")), backgroundColor: Colors.green));
                       },
                       child: Text(Lang.t("list_btn"), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                     ),
                   )
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildTextField(String label, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String deliveryOption = "Kisan Delivery";

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(Lang.t("checkout"), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                   const SizedBox(height: 20),
                   Expanded(
                     child: _cartItems.isEmpty 
                       ? Center(child: Text(Lang.t("empty_cart"), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 16)))
                       : ListView.separated(
                           physics: const BouncingScrollPhysics(),
                           itemCount: _cartItems.length,
                           separatorBuilder: (context, index) => const Divider(),
                           itemBuilder: (context, index) {
                             final item = _cartItems[index];
                             return ListTile(
                               leading: Container(
                                 width: 40, height: 40,
                                 decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                                 child: Icon(Icons.shopping_bag, color: Colors.green.shade700)
                               ),
                               title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                               subtitle: Text(item['seller'], style: const TextStyle(fontSize: 11)),
                               trailing: Text(item['price'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                               contentPadding: EdgeInsets.zero,
                             );
                           },
                         ),
                   ),
                   if (_cartItems.isNotEmpty) ...[
                     const SizedBox(height: 16),
                     Text(Lang.t("select_delivery"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                     const SizedBox(height: 12),
                     _buildDeliveryToggle("Kisan Delivery", "Local farmer network - 1 Day", Icons.agriculture, deliveryOption, (v) => setModalState(() => deliveryOption = v!)),
                     _buildDeliveryToggle("Third-Party Transport", "Standard Logistic - 3 Days", Icons.local_shipping, deliveryOption, (v) => setModalState(() => deliveryOption = v!)),
                     _buildDeliveryToggle("Self Pickup", "Pickup from seller location directly", Icons.storefront, deliveryOption, (v) => setModalState(() => deliveryOption = v!)),
                     const SizedBox(height: 16),
                     const Divider(),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text(Lang.t("total_est"), style: const TextStyle(fontSize: 16, color: Colors.grey)),
                         Text("₹${_cartItems.fold<double>(0, (sum, i) => sum + (double.tryParse(i['price'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0))}", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                       ],
                     ),
                     const SizedBox(height: 16),
                     SizedBox(
                       width: double.infinity,
                       height: 55,
                       child: ElevatedButton(
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                         onPressed: () async {
                           await MarketService.clearCart();
                           _loadState();
                           Navigator.pop(context);
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Lang.t("order_success"), style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
                         },
                         child: Text(Lang.t("proceed_pay"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                       ),
                     )
                   ]
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildDeliveryToggle(String title, String sub, IconData icon, String groupValue, ValueChanged<String?> onChanged) {
    return Card(
      elevation: 0,
      color: groupValue == title ? Colors.green.shade50 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: groupValue == title ? Colors.green : Colors.grey.shade300)),
      child: RadioListTile<String>(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: groupValue == title ? Colors.green.shade800 : Colors.black87)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        value: title,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: Colors.green,
        secondary: Icon(icon, color: groupValue == title ? Colors.green : Colors.grey),
      ),
    );
  }
}

class _ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductDetailPage({required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(Lang.t("details")),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
           IconButton(icon: const Icon(Icons.share), onPressed: (){}),
           IconButton(icon: const Icon(Icons.favorite_border), onPressed: (){}),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.orange.shade100, foregroundColor: Colors.orange.shade800, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {},
                child: Text(Lang.t("add_to_cart"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {},
                child: Text(Lang.t("buy_now"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 300, width: double.infinity, color: Colors.green.shade100, child: const Icon(Icons.inventory_2, size: 100, color: Colors.white)),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(product["cat"], style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text("${product["rating"]} (120 reviews)", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(product["name"], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Text(product["price"], style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.green.shade800)),
                  const SizedBox(height: 24),
                  
                  // Seller Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200)
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(backgroundColor: Colors.green.shade50, child: const Icon(Icons.store, color: Colors.green)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product["seller"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                  Text(product["distance"], style: const TextStyle(color: Colors.grey)),
                                ],
                              )
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(Lang.t("description"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text("High quality, premium grade product sourced directly from verified local suppliers. Certified to yield strong results in optimal weather scenarios. Supports bulk ordering upon request.", style: TextStyle(color: Colors.black87, height: 1.5)),
                  
                  const SizedBox(height: 32),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
