import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sweet_manager/monitoring/services/room_service.dart';
import 'package:sweet_manager/OrganizationalManagement/models/hotel.dart';
import 'package:sweet_manager/OrganizationalManagement/models/multimedia.dart';
import 'package:sweet_manager/OrganizationalManagement/services/hotel_service.dart';
import 'package:sweet_manager/OrganizationalManagement/views/hotel_detail.dart';
import 'package:sweet_manager/OrganizationalManagement/widgets/search_bar.dart';
import 'package:sweet_manager/OrganizationalManagement/widgets/category_tabs.dart';
import 'package:sweet_manager/OrganizationalManagement/widgets/hotel_card.dart';
import 'package:sweet_manager/shared/widgets/base_layout.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HotelService _hotelService = HotelService();
  final RoomService _roomService = RoomService(); // Add room service
  final TextEditingController _searchController = TextEditingController();

  // State variables
  int _selectedCategoryIndex = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  // Data
  List<Hotel> _hotels = [];
  List<Hotel> _filteredHotels = [];
  Map<int, Multimedia> _multimediaList = {};
  Map<int, Multimedia> _logoList = {};
  Map<int, List<Multimedia>> _multimediaDetailList = {};
  Map<int, double> _hotelMinimumPrices = {}; // Add minimum prices map

  // Categories configuration
  final List<CategoryTab> _categories = [
    CategoryTab(
        icon: SvgPicture.asset('assets/icons/trophy_icon.svg', width: 24, height: 24),
        label: 'Featured'
    ),
    CategoryTab(
        icon: SvgPicture.asset('assets/icons/lake_icon.svg', width: 24, height: 24),
        label: 'Near a lake'
    ),
    CategoryTab(
        icon: SvgPicture.asset('assets/icons/pool_icon.svg', width: 24, height: 24),
        label: 'With pool'
    ),
    CategoryTab(
        icon: SvgPicture.asset('assets/icons/beach_icon.svg', width: 24, height: 24),
        label: 'Near the beach'
    ),
    CategoryTab(
        icon: SvgPicture.asset('assets/icons/rural_icon.svg', width: 24, height: 24),
        label: 'Rural Hotel'
    ),
    CategoryTab(
        icon: SvgPicture.asset('assets/icons/bed_icon.svg', width: 24, height: 24),
        label: 'Master Bedroom'
    ),
  ];

  final List<String> _categoryValues = [
    'FEATURED',
    'NEAR_THE_LAKE',
    'WITH_A_POOL',
    'NEAR_THE_BEACH',
    'RURAL_HOTEL',
    'SUITE'
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      await _loadHotelsData();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing data: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadHotelsData() async {
    try {
      print('Loading hotels data...');

      // Load hotels based on selected category
      if (_selectedCategoryIndex == 0) {
        _hotels = await _hotelService.getHotels();
        print('Loaded ${_hotels.length} featured hotels');
      } else {
        String selectedCategory = _categoryValues[_selectedCategoryIndex];
        print('Loading hotels for category: $selectedCategory');
        _hotels = await _hotelService.getHotelByCategory(selectedCategory);
        print('Loaded ${_hotels.length} hotels in category $selectedCategory');
      }

      // Clear previous multimedia data
      _multimediaList.clear();
      _logoList.clear();
      _multimediaDetailList.clear();
      _hotelMinimumPrices.clear(); // Clear previous prices

      // Load multimedia and prices for each hotel
      await _loadMultimediaForHotels();
      await _loadMinimumPricesForHotels(); // Load minimum prices

      // Apply current search filter
      _applySearchFilter(_searchController.text);

      print('Hotels data loaded successfully');
    } catch (e) {
      print('Error loading hotels data: $e');
      throw Exception('Failed to load hotels: $e');
    }
  }

  Future<void> _loadMultimediaForHotels() async {
    print('Loading multimedia for ${_hotels.length} hotels...');

    for (var hotel in _hotels) {
      try {
        // Load multimedia concurrently for better performance
        final futures = await Future.wait([
          _hotelService.getMainHotelMultimedia(hotel.id),
          _hotelService.getHotelLogoMultimedia(hotel.id),
          _hotelService.getHotelDetailMultimedia(hotel.id),
        ]);

        final multimediaMain = futures[0] as Multimedia?;
        final logo = futures[1] as Multimedia?;
        final multimediaDetails = futures[2] as List<Multimedia>;

        if (multimediaMain != null) {
          _multimediaList[hotel.id] = multimediaMain;
          print('Loaded main image for hotel ${hotel.name}: ${multimediaMain.url}');
        } else {
          print('No main image found for hotel ${hotel.name}');
        }

        if (logo != null) {
          _logoList[hotel.id] = logo;
          print('Loaded logo for hotel ${hotel.name}: ${logo.url}');
        } else {
          print('No logo found for hotel ${hotel.name}');
        }

        _multimediaDetailList[hotel.id] = multimediaDetails;
        print('Loaded ${multimediaDetails.length} detail images for hotel ${hotel.name}');

      } catch (e) {
        print('Error loading multimedia for hotel ${hotel.name}: $e');
        // Continue with other hotels even if one fails
        _multimediaDetailList[hotel.id] = [];
      }
    }

    print('Multimedia loading completed');
  }

  Future<void> _loadMinimumPricesForHotels() async {
    print('Loading minimum prices for ${_hotels.length} hotels...');

    for (var hotel in _hotels) {
      try {
        final minimumPrice = await _roomService.getMinimumPriceRoomByHotelId(hotel.id);
        _hotelMinimumPrices[hotel.id] = minimumPrice;
        print('Loaded minimum price for hotel ${hotel.name}: S/ $minimumPrice');
      } catch (e) {
        print('Error loading minimum price for hotel ${hotel.name}: $e');
        // Set default price if loading fails
        _hotelMinimumPrices[hotel.id] = 0;
      }
    }

    print('Minimum prices loading completed');
  }

  void _applySearchFilter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredHotels = List.from(_hotels);
      } else {
        _filteredHotels = _hotels.where((hotel) {
          return hotel.name.toLowerCase().contains(query.toLowerCase()) ||
              hotel.address.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });

    print('Applied search filter: "${query}" - Found ${_filteredHotels.length} hotels');
  }

  Future<void> _onCategorySelected(int index) async {
    if (_selectedCategoryIndex == index) return; // No change needed

    try {
      setState(() {
        _selectedCategoryIndex = index;
        _isLoading = true;
        _hasError = false;
      });

      await _loadHotelsData();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error changing category: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _onHotelTap(Hotel hotel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HotelDetailScreen(
          hotel: hotel,
          multimediaMain: _multimediaList[hotel.id],
          multimediaLogo: _logoList[hotel.id],
          multimediaDetails: _multimediaDetailList[hotel.id],
          minimumPrice: _hotelMinimumPrices[hotel.id] ?? 0.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      role: 'ROLE_GUEST',
      childScreen: Column(
        children: [
          // Search Bar
          CustomSearchBar(
            hintText: 'What will be your next destination?',
            controller: _searchController,
            onSearch: _applySearchFilter,
          ),

          // Category Tabs
          CategoryTabs(
            tabs: _categories,
            selectedIndex: _selectedCategoryIndex,
            onTabSelected: _onCategorySelected,
          ),

          // Content Area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading hotels...'),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load hotels',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredHotels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.hotel_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No hotels found for "${_searchController.text}"'
                  : 'No hotels available',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your search or category filter',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _initializeData,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: _filteredHotels.length,
        itemBuilder: (context, index) {
          final hotel = _filteredHotels[index];
          return HotelCard(
            hotel: hotel,
            multimedia: _multimediaList[hotel.id],
            logo: _logoList[hotel.id],
            minimumPrice: _hotelMinimumPrices[hotel.id] ?? 0, // Pass minimum price
            onTap: () => _onHotelTap(hotel),
          );
        },
      ),
    );
  }
}