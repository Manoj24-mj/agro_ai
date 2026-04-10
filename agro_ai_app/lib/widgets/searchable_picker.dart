import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchablePicker extends StatefulWidget {
  final List<String> items;
  final String title;
  final String selectedItem;
  final ValueChanged<String> onSelected;

  const SearchablePicker({
    super.key,
    required this.items,
    required this.title,
    required this.selectedItem,
    required this.onSelected,
  });

  @override
  State<SearchablePicker> createState() => _SearchablePickerState();

  static void show(BuildContext context, {
    required List<String> items,
    required String title,
    required String selectedItem,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchablePicker(
        items: items,
        title: title,
        selectedItem: selectedItem,
        onSelected: onSelected,
      ),
    );
  }
}

class _SearchablePickerState extends State<SearchablePicker> {
  late List<String> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 1. Sort Alphabetically
    _filteredItems = List<String>.from(widget.items)..sort();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items
          .where((item) => item.toLowerCase().contains(query))
          .toList()
        ..sort(); // Always keep sorted
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(widget.title, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[800])),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search ${widget.title.toLowerCase()}...",
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                final isSelected = item == widget.selectedItem;

                return InkWell(
                  onTap: () {
                    widget.onSelected(item);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green[50] : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      border: isSelected ? Border.all(color: Colors.green.shade200) : null,
                    ),
                    child: Row(
                      children: [
                        Text(
                          item, 
                          style: GoogleFonts.inter(
                            fontSize: 16, 
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.green[800] : Colors.black87,
                          )
                        ),
                        const Spacer(),
                        if (isSelected) const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
