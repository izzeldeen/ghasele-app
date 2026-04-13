import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/services/api_service.dart';
import 'package:ghasele/theme/app_theme.dart';
import 'package:ghasele/widgets/custom_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(31.9539, 35.9106); // Default: Amman, Jordan
  LatLng _selectedPosition = const LatLng(31.9539, 35.9106);
  String _selectedAddress = '';
  bool _showWelcomeDialog = true;
  bool _isLoading = false; 
  bool _hasPendingOrder = false;
  List<dynamic> _userLocations = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _marketingController = TextEditingController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Don't fetch location immediately if we are showing dialog
    // _getCurrentLocation(); 
    checkPendingOrder();
    _fetchUserLocations();
    
    // Set up periodic refresh
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted && !_isLoading) {
        checkPendingOrder();
      }
    });
  }

  void refresh() {
    checkPendingOrder();
    _fetchUserLocations();
    _startRefreshTimer(); // Reset timer
  }

  void _startMap() {
    setState(() {
      _showWelcomeDialog = false;
      _isLoading = true; // Show loading while fetching location
    });
    _getCurrentLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedAddress.isEmpty || _selectedAddress == 'Loading...') {
      _selectedAddress = AppLocalizations.of(context)!.loading;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    _searchController.dispose();
    _marketingController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final newPosition = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _currentPosition = newPosition;
        _selectedPosition = newPosition;
        _isLoading = false;
      });

      // Animate camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newPosition, 15),
      );

      // Get address
      _getAddressFromLatLng(newPosition);
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> checkPendingOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String? userId = prefs.getString('user_id');

      if (token == null || userId == null) return;

      final result = await ApiService.getUserOrders(
        userId: userId,
        token: token,
      );

      if (result['success'] && result['data'] != null) {
        final List orders = result['data'];
        final bool hasPending = orders.any((o) => 
          o['status'] == 'Pending' || 
          o['status'] == 'PendingCollection' || 
          o['status'] == 'Assigned'
        );
        if (mounted) {
          setState(() {
            _hasPendingOrder = hasPending;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking pending order: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchUserLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String? userId = prefs.getString('user_id');

      if (token == null || userId == null) return;

      final result = await ApiService.getUserLocations(
        userId: userId,
        token: token,
      );

      if (result['success'] && result['data'] != null) {
        if (mounted) {
          setState(() {
            _userLocations = result['data'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching locations: $e');
    }
  }


  Future<void> _saveLocation() async {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.saveLocation),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.locationNameHint,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(_selectedAddress, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              Navigator.of(context).pop();
              
              setState(() => _isLoading = true);
              
              try {
                final prefs = await SharedPreferences.getInstance();
                final String? token = prefs.getString('auth_token');
                final String? userId = prefs.getString('user_id');
                
                if (token != null && userId != null) {
                   final result = await ApiService.addUserLocation(
                    userId: userId,
                    name: nameController.text,
                    lat: _selectedPosition.latitude,
                    lng: _selectedPosition.longitude,
                    token: token,
                  );
                  
                  if (result['success']) {
                    CustomToast.show(context, message: l10n.locationSaved, type: ToastType.success);
                    _fetchUserLocations();
                  } else {
                    CustomToast.show(context, message: 'Failed to save location', type: ToastType.error);
                  }
                }
              } catch (e) {
                 CustomToast.show(context, message: 'Error: $e', type: ToastType.error);
              } finally {
                 if (mounted) setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF025595),
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _selectedAddress = '${place.street}, ${place.locality}, ${place.country}';
        });
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      setState(() {
        _selectedAddress = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final newPosition = LatLng(location.latitude, location.longitude);
        
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(newPosition, 15),
        );
        
        setState(() {
          _selectedPosition = newPosition;
        });
        
        _getAddressFromLatLng(newPosition);
      }
    } catch (e) {
      debugPrint('Error searching location: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        CustomToast.show(
          context,
          message: '${l10n.locationNotFound}: $query',
          type: ToastType.error,
        );
      }
    }
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _selectedPosition = position.target;
    });
  }

  void _onCameraIdle() {
    _getAddressFromLatLng(_selectedPosition);
  }

  Future<void> _confirmOrder() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String? userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        if (mounted) {
          CustomToast.show(
            context,
            message: 'User session expired. Please login again.',
            type: ToastType.error,
          );
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      final result = await ApiService.createOrder(
        lat: _selectedPosition.latitude,
        lng: _selectedPosition.longitude,
        userId: userId,
        token: token,
        marketingCode: _marketingController.text.trim().isEmpty ? null : _marketingController.text.trim(),
      );

      if (mounted) {
        if (result['success']) {
          _marketingController.clear();
          Navigator.of(context).pushNamed('/order-success', arguments: {
            'lat': _selectedPosition.latitude,
            'lng': _selectedPosition.longitude,
            'address': _selectedAddress,
          });
        } else {
          String errorMessage = result['message'] ?? l10n.orderFailed;
          if (errorMessage.contains("already have a pending order")) {
            errorMessage = l10n.hasPendingOrder;
          }
          Navigator.of(context).pushNamed(
            '/order-failure',
            arguments: errorMessage,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: 'Error: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmLocation() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          bool showPromoField = _marketingController.text.isNotEmpty;
          
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.neutral200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_checkout_rounded, color: AppTheme.primaryBlue, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      l10n.confirmOrder,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.neutral900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.minOrderWarning,
                  style: TextStyle(
                    color: AppTheme.neutral600,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                if (!showPromoField)
                  GestureDetector(
                    onTap: () {
                      setModalState(() {
                        // We use the controller's content to trigger visibility in this simple logic
                        _marketingController.text = " "; // Dummy space to trigger if empty
                      });
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.add_circle_outline, color: AppTheme.primaryBlue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          l10n.addPromoCode,
                          style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.promoCode,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neutral700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _marketingController,
                        onChanged: (val) {
                          if (val.isEmpty) {
                             setModalState(() {}); // Refresh to potentially show button again if user clears
                          }
                        },
                        decoration: InputDecoration(
                          hintText: l10n.enterPromoCode,
                          hintStyle: TextStyle(color: AppTheme.neutral400, fontSize: 14),
                          prefixIcon: const Icon(Icons.sell_outlined, color: AppTheme.primaryBlue, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.neutral200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.neutral200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryBlue),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppTheme.neutral200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: const TextStyle(
                            color: AppTheme.neutral600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _confirmOrder();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          l10n.confirm,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;

    if (_showWelcomeDialog) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Abstract background elements
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.08),
                      AppTheme.primaryBlue.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.05),
                      AppTheme.primaryBlue.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        size: 60,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      l10n.selectPickupLocationTitle,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.neutral900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.selectPickupLocationDesc,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.neutral500,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _startMap,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        backgroundColor: AppTheme.primaryBlue,
                        elevation: 4,
                        shadowColor: AppTheme.primaryBlue.withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.map_outlined, size: 20),
                          const SizedBox(width: 12),
                          Text(l10n.goToMap),
                        ],
                      ),
                    ),
                    
                    if (_userLocations.isNotEmpty) ...[
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppTheme.neutral200)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              l10n.orChooseSavedLocation,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppTheme.neutral400,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: AppTheme.neutral200)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _userLocations.length,
                          itemBuilder: (context, index) {
                            final location = _userLocations[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _showWelcomeDialog = false;
                                      _currentPosition = LatLng(location['lat'], location['long']);
                                      _selectedPosition = LatLng(location['lat'], location['long']);
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppTheme.neutral200),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryBlue.withOpacity(0.08),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.home_work_rounded,
                                            size: 24,
                                            color: AppTheme.primaryBlue,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                location['name'] ?? l10n.savedLocation,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: AppTheme.neutral800,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Jordan, Amman', // or format Lat/Lng
                                                style: TextStyle(
                                                  color: AppTheme.neutral500,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 16,
                                          color: AppTheme.neutral300,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            style: '''
[
  {
    "featureType": "poi",
    "elementType": "labels.text",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.business",
    "stylers": [{"visibility": "off"}]
  }
]
''',
          ),

          // Center Marker
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 48,
                  color: AppTheme.primaryBlue,
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40), // Space to keep icon above center point
              ],
            ),
          ),

          // Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_hasPendingOrder)
                  _buildPendingOrderBanner(l10n),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchLocation,
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue),
                      suffixIcon: _searchController.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onSubmitted: _searchLocation,
                    onChanged: (val) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Card
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Floating My Location Button
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FloatingActionButton(
                      onPressed: _getCurrentLocation,
                      backgroundColor: Colors.white,
                      elevation: 4,
                      child: const Icon(Icons.my_location_rounded, color: AppTheme.primaryBlue),
                    ),
                  ),
                ),
                
                // Address & Action Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.place_rounded, color: AppTheme.primaryBlue),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.selectedLocation,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.neutral400,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedAddress,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.neutral900,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _saveLocation,
                            icon: const Icon(Icons.bookmark_add_outlined, color: AppTheme.primaryBlue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _hasPendingOrder ? null : _confirmLocation,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor: AppTheme.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          l10n.setPickupLocation,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPendingOrderBanner(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEE2E2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.hasPendingOrder,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
