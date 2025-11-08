import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PetAdoptionHomeScreen extends StatefulWidget {
  const PetAdoptionHomeScreen({super.key});

  @override
  State<PetAdoptionHomeScreen> createState() => _PetAdoptionHomeScreenState();
}

class _PetAdoptionHomeScreenState extends State<PetAdoptionHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _selectedCategory = 0;
  String _searchQuery = '';
  bool _isGridView = true;

  final List<String> _categories = [
    'All Pets',
    'Dogs',
    'Cats',
    'Birds',
    'Others'
  ];
  final List<Pet> _featuredPets = [
    Pet(
      id: '1',
      name: 'Buddy',
      breed: 'Golden Retriever',
      age: '2 years',
      location: 'New York',
      imageUrl:
          'https://images.unsplash.com/photo-1552053831-71594a27632d?w=400',
      type: 'Dog',
      description: 'Friendly and energetic dog looking for a loving family.',
      isVaccinated: true,
      isNeutered: true,
      price: 'Free',
    ),
    Pet(
      id: '2',
      name: 'Luna',
      breed: 'Persian Cat',
      age: '1 year',
      location: 'Los Angeles',
      imageUrl:
          'https://images.unsplash.com/photo-1574158622682-e40e69881006?w=400',
      type: 'Cat',
      description: 'Calm and affectionate cat, perfect for apartments.',
      isVaccinated: true,
      isNeutered: false,
      price: '\$150',
    ),
    Pet(
      id: '3',
      name: 'Charlie',
      breed: 'Labrador Mix',
      age: '3 years',
      location: 'Chicago',
      imageUrl:
          'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=400',
      type: 'Dog',
      description: 'Great with kids and other pets.',
      isVaccinated: true,
      isNeutered: true,
      price: 'Free',
    ),
    Pet(
      id: '4',
      name: 'Whiskers',
      breed: 'Maine Coon',
      age: '4 years',
      location: 'Seattle',
      imageUrl:
          'https://images.unsplash.com/photo-1592194996308-7b43878e84a6?w=400',
      type: 'Cat',
      description: 'Majestic and gentle giant cat.',
      isVaccinated: true,
      isNeutered: true,
      price: '\$200',
    ),
    Pet(
      id: '5',
      name: 'Rocky',
      breed: 'German Shepherd',
      age: '5 years',
      location: 'Denver',
      imageUrl:
          'https://images.unsplash.com/photo-1589941013453-ec89f33b5e95?w=400',
      type: 'Dog',
      description: 'Loyal and protective, great guard dog.',
      isVaccinated: true,
      isNeutered: true,
      price: 'Free',
    ),
    Pet(
      id: '6',
      name: 'Bella',
      breed: 'Siamese Cat',
      age: '2 years',
      location: 'Miami',
      imageUrl:
          'https://images.unsplash.com/photo-1513245543132-31f507417b26?w=400',
      type: 'Cat',
      description: 'Vocal and intelligent cat with beautiful blue eyes.',
      isVaccinated: true,
      isNeutered: false,
      price: '\$100',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  List<Pet> get _filteredPets {
    List<Pet> filtered = _featuredPets;

    if (_selectedCategory > 0) {
      String category = _categories[_selectedCategory];
      if (category != 'All Pets') {
        filtered = filtered
            .where(
                (pet) => pet.type == category.substring(0, category.length - 1))
            .toList();
      }
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((pet) =>
              pet.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              pet.breed.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              pet.location.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Row(
            children: [
              // Sidebar
              _buildSidebar(),
              // Main Content
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeroSection(),
                            const SizedBox(height: 40),
                            _buildStatsSection(),
                            const SizedBox(height: 40),
                            _buildFeaturedPetsSection(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF6C63FF),
            const Color(0xFF4ECDC4),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Logo
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.pets,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'PetAdopt',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Navigation Menu
          _buildMenuItem(Icons.home, 'Home', true),
          _buildMenuItem(Icons.search, 'Browse Pets', false),
          _buildMenuItem(Icons.favorite, 'Favorites', false),
          _buildMenuItem(Icons.chat, 'Messages', false),
          _buildMenuItem(Icons.event, 'Appointments', false),
          _buildMenuItem(Icons.volunteer_activism, 'Donate', false),
          _buildMenuItem(Icons.info, 'About Us', false),
          const Spacer(),
          // User Profile
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'John Doe',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Pet Lover',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            flex: 2,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search for pets, breeds, locations...',
                  prefixIcon: Icon(Icons.search, color: Color(0xFF6C757D)),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Category Filter
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedCategory,
                dropdownColor: const Color(0xFF6C63FF),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                items: _categories.asMap().entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // View Toggle
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE9ECEF)),
            ),
            child: Row(
              children: [
                _buildViewToggle(Icons.grid_view, true),
                _buildViewToggle(Icons.list, false),
              ],
            ),
          ),
          const Spacer(),
          // Notifications
          IconButton(
            onPressed: () {},
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, size: 24),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B6B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Profile
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF6C63FF),
            child: const Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(IconData icon, bool isGrid) {
    final isSelected = _isGridView == isGrid;
    return InkWell(
      onTap: () {
        setState(() {
          _isGridView = isGrid;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.white : const Color(0xFF6C757D),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.8),
            const Color(0xFF4ECDC4).withOpacity(0.8),
          ],
        ),
        image: const DecorationImage(
          image: NetworkImage(
              'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=1200'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Color(0x66000000),
            BlendMode.overlay,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Find Your Perfect',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Furry Friend',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Give a loving home to pets in need. Browse through our\ncollection of adorable pets waiting for adoption.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6C63FF),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Adopt Now',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Learn More',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        _buildStatCard(
            '1,247', 'Pets Adopted', Icons.pets, const Color(0xFF4ECDC4)),
        const SizedBox(width: 24),
        _buildStatCard(
            '156', 'Available Pets', Icons.home, const Color(0xFF6C63FF)),
        const SizedBox(width: 24),
        _buildStatCard('89', 'Happy Families', Icons.family_restroom,
            const Color(0xFFFF6B6B)),
        const SizedBox(width: 24),
        _buildStatCard(
            '23', 'Rescue Centers', Icons.location_on, const Color(0xFFFFD93D)),
      ],
    );
  }

  Widget _buildStatCard(
      String number, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              number,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6C757D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedPetsSection() {
    final filteredPets = _filteredPets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Featured Pets',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _isGridView
            ? GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                ),
                itemCount: filteredPets.length,
                itemBuilder: (context, index) {
                  return _buildPetCard(filteredPets[index]);
                },
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredPets.length,
                itemBuilder: (context, index) {
                  return _buildPetListTile(filteredPets[index]);
                },
              ),
      ],
    );
  }

  Widget _buildPetCard(Pet pet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pet Image
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                image: DecorationImage(
                  image: NetworkImage(pet.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        color: Color(0xFF6C63FF),
                        size: 20,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: pet.price == 'Free'
                            ? const Color(0xFF4ECDC4)
                            : const Color(0xFF6C63FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        pet.price,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Pet Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pet.breed,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6C757D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Color(0xFF6C757D)),
                      const SizedBox(width: 4),
                      Text(
                        pet.location,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6C757D),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        pet.age,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (pet.isVaccinated)
                        _buildBadge('Vaccinated', const Color(0xFF4ECDC4)),
                      const SizedBox(width: 4),
                      if (pet.isNeutered)
                        _buildBadge('Neutered', const Color(0xFF6C63FF)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetListTile(Pet pet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pet Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(pet.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Pet Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pet.breed} • ${pet.age}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6C757D),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: Color(0xFF6C757D)),
                    const SizedBox(width: 4),
                    Text(
                      pet.location,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6C757D),
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (pet.isVaccinated)
                      _buildBadge('Vaccinated', const Color(0xFF4ECDC4)),
                    const SizedBox(width: 4),
                    if (pet.isNeutered)
                      _buildBadge('Neutered', const Color(0xFF6C63FF)),
                  ],
                ),
              ],
            ),
          ),
          // Price and Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                pet.price,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: pet.price == 'Free'
                      ? const Color(0xFF4ECDC4)
                      : const Color(0xFF6C63FF),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Adopt'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// Pet Model
class Pet {
  final String id;
  final String name;
  final String breed;
  final String age;
  final String location;
  final String imageUrl;
  final String type;
  final String description;
  final bool isVaccinated;
  final bool isNeutered;
  final String price;

  Pet({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
    required this.location,
    required this.imageUrl,
    required this.type,
    required this.description,
    required this.isVaccinated,
    required this.isNeutered,
    required this.price,
  });
}
