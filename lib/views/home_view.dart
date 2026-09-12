import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/services/amman_boundary_service.dart';
import 'package:ghasele/models/delivery_slot.dart';
import 'package:ghasele/services/api_service.dart';
import 'package:ghasele/services/notification_service.dart';
import 'package:ghasele/theme/app_theme.dart';
import 'package:ghasele/utils/jordan_phone.dart';
import 'package:ghasele/utils/jordan_time.dart';
import 'package:ghasele/widgets/custom_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeView extends StatefulWidget {
  /// False while another tab is showing. The map is a platform view: kept
  /// alive by the IndexedStack it stays full-screen in the *native* view
  /// hierarchy on every tab and swallows drag gestures, which is what stopped
  /// the account page from scrolling. Unmounting it while it is off-screen
  /// hands those gestures back to Flutter.
  final bool isActive;

  const HomeView({super.key, this.isActive = true});

  @override
  State<HomeView> createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  /// Hoisted out of build(): the map style is fixed, so rebuilding this JSON
  /// alongside the GoogleMap widget was pure overhead.
  static const String _mapStyle = '''
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
''';

  GoogleMapController? _mapController;
  LatLng _selectedPosition = AmmanBoundaryService.ammanCenter;
  String _selectedAddress = '';

  /// Set while we animate the camera back inside Amman. The correction itself
  /// fires onCameraIdle again, so without this the handler re-enters and the
  /// user gets a stutter of repeated nudges and toasts.
  bool _isCorrectingCamera = false;
  bool _showWelcomeDialog = true;
  bool _isLoading = false;
  bool _hasPendingOrder = false;
  String? _activeOrderRef;
  String? _activeOrderStatus;

  /// Pins for every order that has not been delivered or cancelled. Kept as its own field so a
  /// refresh that changes nothing can skip setState entirely - see [checkPendingOrder].
  Set<Marker> _orderMarkers = const <Marker>{};

  /// Id of the order marker the user last tapped, or null. Drives the marker's highlight colour
  /// so it is obvious which pin the shown details belong to.
  String? _selectedOrderId;

  /// Statuses that mean the order is finished and should not appear on the map.
  /// Mirrors OrderStatus in the backend (PendingCollection, Assigned, Collected, Cleaning,
  /// Ready, OutForDelivery, Delivered, Cancelled); everything not listed here is still active.
  /// 'Completed' is not in that enum but is kept as a defensive alias.
  static const Set<String> _finishedStatuses = {
    'Delivered',
    'Cancelled',
    'Completed',
  };
  List<dynamic> _userLocations = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _marketingController = TextEditingController();

  /// Owned by the State rather than created per call in [_saveLocation]. A
  /// per-call controller cannot be released safely: showDialog's future
  /// completes while the dialog's TextField is still mounted, so disposing it
  /// there left the field reading a dead controller and took down the tree.
  final TextEditingController _locationNameController = TextEditingController();
  Timer? _refreshTimer;

  /// Whether the app is being used without an account.
  ///
  /// Starts true so the save-location button is never shown in the moment before the
  /// session has been read - offering it and then taking it away reads worse than it
  /// appearing a beat later.
  bool _isGuest = true;

  /// How far ahead the customer may book: today and tomorrow.
  ///
  /// Asked of the server rather than trimmed after the fact, so the horizon lives in one
  /// place and the app never holds slots it will not offer. Late in the day today
  /// contributes nothing and the list is tomorrow's windows alone - which is the intent,
  /// not an empty state.
  static const int _scheduleHorizonDays = 2;

  /// Collection times from the operator's trip schedule, and the one the customer picked.
  /// Kept on the state rather than in the sheet so reopening it remembers the choice.
  List<DeliverySlot> _slots = <DeliverySlot>[];
  DeliverySlot? _selectedSlot;

  /// Null while the schedule is still loading, so the sheet can show a spinner rather
  /// than an empty schedule the operator has not actually left empty.
  bool _slotsLoading = true;

  /// True when the last schedule fetch failed outright - offline, unreachable server,
  /// an error response.
  ///
  /// Kept apart from an empty [_slots] because the two mean opposite things to the
  /// customer: "we could not reach the server, retry" versus "the operator has published
  /// no windows". Collapsing them told customers there were no collection times while
  /// the operator was looking at a full schedule in the dashboard.
  bool _slotsFailed = false;

  /// The checkout sheet's own setState, held while it is open.
  ///
  /// The sheet is a separate route, so this widget's setState does not repaint it. The
  /// schedule refresh fires as the sheet opens and lands after it is on screen, and
  /// without this the customer would sit looking at a spinner that never resolves.
  StateSetter? _sheetSetState;

  /// The delivery fee from the admin panel's settings row. Null until the fetch lands
  /// (or if it fails) - the sheet then omits the price rather than inventing a number.
  double? _normalDeliveryPrice;

  @override
  void initState() {
    super.initState();
    // Don't fetch location immediately if we are showing dialog
    // _getCurrentLocation();
    checkPendingOrder();
    _fetchUserLocations();
    _fetchDeliveryPricing();
    _fetchDeliverySlots();

    // Set up periodic refresh
    _startRefreshTimer();
  }

  /// Pulls the operator's configured delivery fee so the checkout sheet can show it.
  /// Failures are swallowed: the sheet still works without a price, and blocking
  /// checkout on a settings read would be worse than omitting the figure.
  Future<void> _fetchDeliveryPricing() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      if (token == null) return;

      final result = await ApiService.getDeliveryPricing(token);
      if (!mounted || result['success'] != true) return;

      final data = result['data'] as Map<String, dynamic>;
      setState(() {
        _normalDeliveryPrice = (data['normalDeliveryPrice'] as num?)
            ?.toDouble();
      });
    } catch (e) {
      debugPrint('Error fetching delivery pricing: $e');
    }
  }

  /// Loads the operator's trip schedule - the only collection times the customer may
  /// choose from.
  ///
  /// Refetched each time the checkout sheet opens, not just at startup: slots fill up
  /// and pass, and a sheet opened twenty minutes later would otherwise offer a time
  /// the server is about to reject.
  Future<void> _fetchDeliverySlots() async {
    try {
      final result = await ApiService.getDeliverySlots(days: _scheduleHorizonDays);
      if (!mounted) return;

      if (result['success'] != true) {
        debugPrint('Delivery slots request failed: ${result['message']}');
        setState(() {
          _slotsLoading = false;
          _slotsFailed = true;
        });
        _sheetSetState?.call(() {});
        return;
      }

      final slots = (result['data'] as List<dynamic>)
          .map((e) => DeliverySlot.fromJson(e as Map<String, dynamic>))
          .toList();

      void apply() {
        _slots = slots;
        _slotsLoading = false;
        _slotsFailed = false;

        // Drop a selection the refresh has invalidated - the window may have been
        // deactivated, filled, or simply started since the customer picked it.
        final stillOffered = slots.where(
          (s) => s.windowId == _selectedSlot?.windowId &&
              s.dateKey == _selectedSlot?.dateKey &&
              s.isAvailable,
        );
        _selectedSlot = stillOffered.isEmpty ? null : stillOffered.first;
      }

      setState(apply);
      // Repaint the sheet too, if it is the thing currently on screen.
      _sheetSetState?.call(() {});
    } catch (e) {
      debugPrint('Error fetching delivery slots: $e');
      if (mounted) {
        setState(() {
          _slotsLoading = false;
          _slotsFailed = true;
        });
        _sheetSetState?.call(() {});
      }
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      // widget.isActive: while another tab is showing there is nothing on screen to refresh,
      // and the setState would rebuild this subtree underneath whatever the user is actually
      // looking at - which is how a background poll ends up interrupting another page.
      if (mounted && widget.isActive && !_isLoading) {
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
    // Deliberately does NOT raise _isLoading. That flag draws a full-screen scrim over the
    // Stack, and because the scrim is painted it swallows every touch - so blocking on the GPS
    // fix left the map unpannable for as long as the fix took, and indefinitely when no fix
    // ever arrived. The map is usable straight away centred on Amman; the location simply
    // recentres it when it lands, and the address line shows "Loading..." meanwhile.
    setState(() {
      _showWelcomeDialog = false;
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
  void didUpdateWidget(HomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      // The GoogleMap is about to leave the tree and its controller dies with
      // it - calling animateCamera on a dead controller throws.
      _mapController?.dispose();
      _mapController = null;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    _searchController.dispose();
    _marketingController.dispose();
    _locationNameController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // Get current position
      // Fall back to the last known fix first so the map can render
      // immediately instead of waiting on the GPS.
      final Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        final seed = LatLng(lastKnown.latitude, lastKnown.longitude);
        // Where to *open* the map, not where the user may order. Ordering is now
        // unrestricted, but a stale fix from another country is still a poor starting
        // view, so seed from it only when it is actually in Amman.
        if (AmmanBoundaryService.isWithinPolygon(seed)) {
          setState(() {
            _selectedPosition = seed;
          });
        }
      }

      // timeLimit matters: without it this future never completes when the
      // device cannot get a fix, leaving the screen stuck on its spinner.
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final gpsPosition = LatLng(position.latitude, position.longitude);

      // Opening view only. A device reporting a fix far from Amman - travelling, or an
      // emulator defaulting to Google HQ - would otherwise drop the user on the wrong
      // continent. They can still pan anywhere from here; this only picks the start.
      final bool startNearAmman = AmmanBoundaryService.isWithinPolygon(
        gpsPosition,
      );
      final newPosition = startNearAmman
          ? gpsPosition
          : AmmanBoundaryService.ammanCenter;

      setState(() {
        _selectedPosition = newPosition;
      });

      // Animate camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newPosition, AmmanBoundaryService.focusZoom),
      );

      // Get address
      _getAddressFromLatLng(newPosition);
    } catch (e) {
      // A missing fix is not fatal: the map stays on its current centre and remains usable.
      debugPrint('Error getting location: $e');
    }
  }

  /// Turns active orders into map pins.
  ///
  /// Orders without usable coordinates are skipped rather than defaulted: a pin at (0,0) sits in
  /// the Atlantic and is worse than no pin. Orders are keyed by id so a refresh cannot produce
  /// two markers for the same order.
  Set<Marker> _buildOrderMarkers(
    List<Map<String, dynamic>> orders,
    AppLocalizations l10n,
  ) {
    final Map<String, Marker> byId = {};

    // Tracks how many pins already sit on each rounded coordinate, so orders sharing an address
    // can be fanned out instead of stacking into one untappable pin.
    final Map<String, int> occupancy = {};

    for (final order in orders) {
      final String? id = order['id']?.toString();
      if (id == null || id.isEmpty || byId.containsKey(id)) continue;

      final LatLng? position = _readLatLng(order['lat'], order['long']);
      if (position == null) continue;

      // ~5 decimal places is roughly a metre; anything closer is visually one point.
      final String cell =
          '${position.latitude.toStringAsFixed(5)},'
          '${position.longitude.toStringAsFixed(5)}';
      final int stackIndex = occupancy[cell] ?? 0;
      occupancy[cell] = stackIndex + 1;

      final LatLng resolved = stackIndex == 0
          ? position
          : _spreadDuplicate(position, stackIndex);

      final String reference =
          order['referenceNumber']?.toString() ?? '#${id.substring(0, 8)}';
      final String status = order['status']?.toString() ?? '';
      final bool isSelected = id == _selectedOrderId;

      byId[id] = Marker(
        markerId: MarkerId('order_$id'),
        position: resolved,
        // Selected pin turns green to match the app's accent; the rest stay amber like the
        // active-order banner, so the two read as the same concept.
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected
              ? BitmapDescriptor.hueGreen
              : BitmapDescriptor.hueOrange,
        ),
        infoWindow: InfoWindow(
          title: reference,
          snippet: _localizedOrderStatus(l10n, status),
        ),
        onTap: () => _onOrderMarkerTapped(id, resolved, reference, status),
      );
    }

    return byId.values.toSet();
  }

  /// Parses a coordinate pair from the API, rejecting anything unusable.
  ///
  /// Covers null, non-numeric strings, NaN/infinity, out-of-range values and the (0,0) placeholder
  /// the API uses when an order has no location.
  LatLng? _readLatLng(dynamic rawLat, dynamic rawLng) {
    final double? lat = rawLat is num
        ? rawLat.toDouble()
        : double.tryParse(rawLat?.toString() ?? '');
    final double? lng = rawLng is num
        ? rawLng.toDouble()
        : double.tryParse(rawLng?.toString() ?? '');

    if (lat == null || lng == null) return null;
    if (!lat.isFinite || !lng.isFinite) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    if (lat == 0 && lng == 0) return null;

    return LatLng(lat, lng);
  }

  /// Nudges the nth pin on a shared coordinate onto a small circle around it, so overlapping
  /// orders stay individually tappable. ~8m radius: separated at street zoom, still clearly the
  /// same address.
  LatLng _spreadDuplicate(LatLng origin, int index) {
    const double radiusDegrees = 0.00007;
    final double angle = (index * 2 * math.pi) / 8;

    return LatLng(
      origin.latitude + radiusDegrees * math.sin(angle),
      origin.longitude + radiusDegrees * math.cos(angle),
    );
  }

  /// Selects the tapped order: moves the pin selection, centres the map on it and refreshes the
  /// address line, reusing the same _selectedPosition/_selectedAddress the rest of the screen
  /// already reads rather than introducing a parallel notion of "selected".
  void _onOrderMarkerTapped(
    String id,
    LatLng position,
    String reference,
    String status,
  ) {
    _selectedPosition = position;

    setState(() {
      _selectedOrderId = id;
      _activeOrderRef = reference;
      _activeOrderStatus = status;
      // Rebuild so the tapped pin picks up the selected colour.
      _orderMarkers = _recolourForSelection(_orderMarkers, id);
    });

    // animateCamera only from an explicit user action - never from onCameraMove/onCameraIdle,
    // which would fight the user's own panning.
    _mapController?.animateCamera(CameraUpdate.newLatLng(position));

    _getAddressFromLatLng(position);
  }

  /// Re-tints existing markers for a new selection without rebuilding them from the API.
  Set<Marker> _recolourForSelection(Set<Marker> markers, String? selectedId) {
    return markers
        .map(
          (m) => m.copyWith(
            iconParam: BitmapDescriptor.defaultMarkerWithHue(
              m.markerId.value == 'order_$selectedId'
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueOrange,
            ),
          ),
        )
        .toSet();
  }

  /// True when both sets describe the same orders at the same points, so a refresh that changed
  /// nothing does not trigger a rebuild.
  bool _sameMarkerIds(Set<Marker> a, Set<Marker> b) {
    if (a.length != b.length) return false;

    final Map<String, LatLng> positions = {
      for (final m in b) m.markerId.value: m.position,
    };

    for (final m in a) {
      final LatLng? previous = positions[m.markerId.value];
      if (previous == null) return false;
      if (previous.latitude != m.position.latitude ||
          previous.longitude != m.position.longitude) {
        return false;
      }
    }

    return true;
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

        // An order that has not been delivered or cancelled yet is still "active".
        final List<Map<String, dynamic>> activeOrders = [
          for (final o in orders)
            if (o is Map<String, dynamic> &&
                !_finishedStatuses.contains(o['status']?.toString()))
              o,
        ];

        final Map<String, dynamic>? active = activeOrders.isEmpty
            ? null
            : activeOrders.first;

        // Reads context, so re-check mounted after the await above before touching it.
        if (!mounted) return;
        final Set<Marker> markers = _buildOrderMarkers(
          activeOrders,
          AppLocalizations.of(context)!,
        );

        // Only rebuild when something actually differs. This runs on a 60s timer, and an
        // unconditional setState re-ran build() - and with it the GoogleMap - forever, which
        // is what made the map feel like it was fighting the user's finger.
        final bool changed =
            _hasPendingOrder != (active != null) ||
            _activeOrderRef != active?['referenceNumber']?.toString() ||
            _activeOrderStatus != active?['status']?.toString() ||
            !_sameMarkerIds(markers, _orderMarkers);

        if (mounted && changed) {
          setState(() {
            _hasPendingOrder = active != null;
            _activeOrderRef = active?['referenceNumber']?.toString();
            _activeOrderStatus = active?['status']?.toString();
            _orderMarkers = markers;
          });
        }
      }
    } catch (e) {
      // Background poll: a failure must not touch the blocking scrim, which belongs to the
      // explicit save/checkout actions only.
      debugPrint('Error checking pending order: $e');
    }
  }

  Future<void> _fetchUserLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String? userId = prefs.getString('user_id');

      // Doubles as the session check for the save-location affordance: this already
      // runs on init and after every save, so there is no second place reading the
      // session and no window where the two disagree.
      final bool guest =
          token == null || token.isEmpty || userId == null || userId.isEmpty;
      if (mounted) setState(() => _isGuest = guest);

      if (guest) return;

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
    _locationNameController.clear();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.saveLocation),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _locationNameController,
              decoration: InputDecoration(
                labelText: l10n.locationNameHint,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedAddress,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final String name = _locationNameController.text.trim();
              if (name.isEmpty) return;

              // The only path that persists coordinates without a service-area
              // check. The camera correction usually gets here first, but a
              // position seeded from GPS or a saved address can still reach
              // this dialog uncorrected, and a stored out-of-area address then
              // fails much later, at order time.
              if (!AmmanBoundaryService.isLocationInsideAmman(
                _selectedPosition,
              )) {
                Navigator.of(dialogContext).pop();
                // Say why. Closing the dialog on its own looked like the name
                // had been rejected, so the customer retyped it instead of
                // moving the pin.
                CustomToast.show(
                  context,
                  message: l10n.locationOutsideAmman,
                  type: ToastType.error,
                );
                return;
              }

              Navigator.of(dialogContext).pop();

              setState(() => _isLoading = true);

              try {
                final prefs = await SharedPreferences.getInstance();
                final String? token = prefs.getString('auth_token');
                final String? userId = prefs.getString('user_id');

                if (token != null && userId != null) {
                  final result = await ApiService.addUserLocation(
                    userId: userId,
                    name: name,
                    lat: _selectedPosition.latitude,
                    lng: _selectedPosition.longitude,
                    token: token,
                  );

                  // The request outlives the dialog and can outlive this tab,
                  // so every toast past here needs the map to still be on
                  // screen before it touches a context.
                  if (!mounted) return;

                  if (result['success']) {
                    CustomToast.show(
                      context,
                      message: l10n.locationSaved,
                      type: ToastType.success,
                    );
                    _fetchUserLocations();
                  } else {
                    CustomToast.show(
                      context,
                      message: 'Failed to save location',
                      type: ToastType.error,
                    );
                  }
                } else if (mounted) {
                  // A guest has no account for the location to belong to. Saying so is
                  // the whole fix: this branch used to fall through silently, so the
                  // dialog closed, nothing was saved, and the customer had no way to
                  // tell that from the name being rejected.
                  CustomToast.show(
                    context,
                    message: l10n.loginToSaveLocation,
                    type: ToastType.error,
                  );
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
                if (mounted) setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandGreen,
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
          _selectedAddress =
              '${place.street}, ${place.locality}, ${place.country}';
        });
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      setState(() {
        _selectedAddress =
            'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    try {
      // The geocoding plugin wraps the platform geocoders, which take a plain
      // string and expose no bbox/country/proximity parameters - scoping the
      // query text is the only bias available. The polygon filter below is what
      // actually enforces the restriction.
      final List<Location> locations = await locationFromAddress(
        AmmanBoundaryService.buildSearchQuery(query),
      );

      // A scoped query still returns matches elsewhere in Jordan when the name
      // is ambiguous, so keep only the candidates that land inside Amman.
      Location? match;
      for (final Location location in locations) {
        if (AmmanBoundaryService.isLocationInsideAmman(
          LatLng(location.latitude, location.longitude),
        )) {
          match = location;
          break;
        }
      }

      if (!mounted) return;

      if (match == null) {
        // "Not found" still gets a toast - that's a real error about the
        // search itself. A match that simply lands outside Amman is silent:
        // Irbid and Zarqa geocode perfectly well, they are just not served,
        // and that case isn't shown to the user at all.
        if (locations.isEmpty) {
          CustomToast.show(
            context,
            message:
                '${AppLocalizations.of(context)!.locationNotFound}: $query',
            type: ToastType.error,
          );
        }
        return;
      }

      final newPosition = LatLng(match.latitude, match.longitude);

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newPosition, AmmanBoundaryService.focusZoom),
      );

      setState(() {
        _selectedPosition = newPosition;
      });

      _getAddressFromLatLng(newPosition);
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
    // Deliberately not setState: this fires on every camera frame while the
    // user pans, and nothing in build() reads _selectedPosition. Rebuilding
    // here re-created the whole map screen ~60 times a second. The visible
    // address is refreshed from onCameraIdle instead.
    _selectedPosition = position.target;
  }

  void _onCameraIdle() {
    // cameraTargetBounds keeps the pin inside the bounding box, but the box has
    // corners the polygon does not cover, so the gap is closed once panning
    // settles. Correcting here rather than in onCameraMove is what keeps the
    // map from fighting the finger mid-drag.
    if (_isCorrectingCamera) {
      _isCorrectingCamera = false;
      _getAddressFromLatLng(_selectedPosition);
      return;
    }

    if (!AmmanBoundaryService.isLocationInsideAmman(_selectedPosition)) {
      final LatLng corrected = AmmanBoundaryService.nearestPointInside(
        _selectedPosition,
      );

      // Corrects the pin silently - no warning shown, the map just settles
      // back inside the service area on its own.
      _isCorrectingCamera = true;
      _selectedPosition = corrected;
      _mapController?.animateCamera(CameraUpdate.newLatLng(corrected));
      return;
    }

    _getAddressFromLatLng(_selectedPosition);
  }

  /// Guarantees the account has a contact number before an order is placed.
  ///
  /// Returns true when a number is already on file or the user supplies one; false when they
  /// decline or saving fails, in which case the caller must abandon the order. The number is
  /// written to the user record rather than the order, so it is asked for once rather than at
  /// every checkout.
  Future<bool> _ensureContactNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final String existing = prefs.getString('user_phone')?.trim() ?? '';
    if (existing.isNotEmpty) return true;

    if (!mounted) return false;
    final String? entered = await _askForContactNumber();
    if (entered == null || !mounted) return false;

    final String? token = prefs.getString('auth_token');
    final String? userId = prefs.getString('user_id');
    if (token == null || userId == null) return false;

    setState(() => _isLoading = true);
    try {
      final result = await ApiService.updateUserPhoneNumber(
        userId: userId,
        phoneNumber: entered,
        // Resent unchanged: the endpoint replaces the whole row.
        fullName: prefs.getString('user_fullname') ?? '',
        username: prefs.getString('user_username') ?? entered,
        email: prefs.getString('user_email'),
        token: token,
      );

      if (!mounted) return false;

      if (result['success'] != true) {
        CustomToast.show(
          context,
          message:
              result['message']?.toString() ??
              AppLocalizations.of(context)!.connectionError,
          type: ToastType.error,
        );
        return false;
      }

      // Mirror locally so the next checkout does not ask again.
      await prefs.setString('user_phone', entered);
      return true;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Asks for a Jordanian mobile number. Returns it in E.164 (+962...), or null if dismissed.
  Future<String?> _askForContactNumber() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      // Dismissible: cancelling is allowed, it just abandons the order rather than trapping
      // the user in a dialog they cannot leave.
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.contactNumberRequiredTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.contactNumberRequiredMessage,
                style: const TextStyle(fontSize: 13.5, height: 1.4),
              ),
              const SizedBox(height: 16),
              // Phone numbers read left-to-right in every locale, so the field is
              // pinned to LTR. Inheriting the ambient direction puts the "+962 "
              // prefix on the right in Arabic, which reads as a suffix.
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  textAlign: TextAlign.left,
                  // Same shape the signup screen accepts, so one account cannot end up with a
                  // number the rest of the app would reject.
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.phoneNumber,
                    prefixText: '+962 ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    final digits = _localJordanDigits(value ?? '');
                    return digits == null ? l10n.invalidPhoneNumber : null;
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final digits = _localJordanDigits(controller.text)!;
              Navigator.of(dialogContext).pop('+962$digits');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandGreen,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  /// Strips a leading 0 / 962 / +962 and returns the bare 9-digit local number, or null when it
  /// is not a valid Jordan mobile number. Delegates so this screen and the support form cannot
  /// drift apart on what counts as a valid number.
  String? _localJordanDigits(String raw) => localJordanDigits(raw);

  Future<void> _confirmOrder() async {
    final l10n = AppLocalizations.of(context)!;

    // Last line of defence before the coordinates leave the screen. The camera
    // and search paths already block this, but an order is the only thing that
    // is expensive to get wrong. Silent, like the other checks - just refuses
    // to proceed rather than surfacing a warning.
    if (!AmmanBoundaryService.isLocationInsideAmman(_selectedPosition)) {
      return;
    }

    // Collection is scheduled, never immediate, so there is no sensible default to fall
    // back on - an order with no slot has no time anyone has agreed to.
    final slot = _selectedSlot;
    if (slot == null) {
      CustomToast.show(
        context,
        message: l10n.selectCollectionTime,
        type: ToastType.error,
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');
    final bool isGuest = token == null || token.isEmpty;

    // A driver needs a number to call on arrival, and neither a guest nor an Apple/Google account
    // necessarily has one. Guests are asked here and the number rides on the order itself; signed-in
    // users get it saved to their profile so the next checkout does not ask again. Either way:
    // no number, no order.
    String? guestPhoneNumber;
    if (isGuest) {
      if (!mounted) return;
      guestPhoneNumber = await _askForContactNumber();
      if (guestPhoneNumber == null || !mounted) return;
    } else {
      if (!await _ensureContactNumber()) return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.createOrder(
        lat: _selectedPosition.latitude,
        lng: _selectedPosition.longitude,
        // Omitted for a guest, which is what makes the server treat this as a guest order.
        token: isGuest ? null : token,
        contactPhoneNumber: guestPhoneNumber,
        // Only a guest needs this on the order: a signed-in customer's token is already on
        // their user row. Null if Firebase has not issued one yet - the order still goes
        // through, it just cannot be pushed to.
        fcmToken: isGuest ? await NotificationService.cachedToken() : null,
        marketingCode: _marketingController.text.trim().isEmpty
            ? null
            : _marketingController.text.trim(),
        deliveryWindowId: slot.windowId,
        scheduledDate: slot.dateKey,
      );

      if (mounted) {
        if (result['success']) {
          _marketingController.clear();
          Navigator.of(context).pushNamed(
            '/order-success',
            arguments: {
              'lat': _selectedPosition.latitude,
              'lng': _selectedPosition.longitude,
              'address': _selectedAddress,
            },
          );
        } else {
          // A stale token still passes the null check above, so an expired
          // session only shows up here as a 401 with an empty body.
          if (result['statusCode'] == 401) {
            await prefs.remove('auth_token');
            await prefs.remove('user_id');
            if (!mounted) return;
            CustomToast.show(
              context,
              message: 'User session expired. Please login again.',
              type: ToastType.error,
            );
            Navigator.of(context).pushReplacementNamed('/login');
            return;
          }

          // Branch on the error code, not the message: the API localizes its
          // text to the Accept-Language we send, so matching English prose
          // never fires for an Arabic user.
          final String errorMessage =
              result['errorCode'] == 'order.pending_exists'
              ? l10n.hasPendingOrder
              : (result['message'] ?? l10n.orderFailed);

          Navigator.of(
            context,
          ).pushNamed('/order-failure', arguments: errorMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: 'Error: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// The customer's entire scheduling choice: one tap on a date-and-time option.
  ///
  /// Every option here comes from the trip schedule the operator configured - there is
  /// no free time entry and no immediate-collection option, so a customer can only ask
  /// for a slot the operation actually runs.
  ///
  /// Presented as a single vertical list rather than a day picker over a time list. The
  /// two-step version made the customer's own schedule the thing they had to navigate -
  /// and it could open on a day with nothing left on it. One list, earliest first, means
  /// the soonest collection is always the first thing on screen.
  Widget _buildScheduleSection({
    required AppLocalizations l10n,
    required VoidCallback onChanged,
  }) {
    final locale = Localizations.localeOf(context);
    final slots = DeliverySlot.bookable(_slots);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event_outlined, size: 18, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(
              l10n.collectionTime,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.neutral700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_slotsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_slotsFailed)
          // The schedule could not be fetched at all. Saying "no collection times" here
          // would blame the operator for a problem on our side, and leaves the customer
          // waiting for a schedule that is already published.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.neutral50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.collectionTimesFailed,
                  style: TextStyle(fontSize: 13, color: AppTheme.neutral600, height: 1.4),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _slotsLoading = true;
                      _slotsFailed = false;
                    });
                    onChanged();
                    _fetchDeliverySlots();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        l10n.tryAgain,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else if (slots.isEmpty)
          // The operator has published no upcoming windows. Say so plainly rather than
          // showing an empty list that reads as a broken screen.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.neutral50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.neutral200),
            ),
            child: Text(
              l10n.noCollectionTimes,
              style: TextStyle(fontSize: 13, color: AppTheme.neutral600, height: 1.4),
            ),
          )
        else
          _buildSlotList(
            slots: slots,
            locale: locale,
            l10n: l10n,
            onChanged: onChanged,
          ),
        if (_normalDeliveryPrice != null) ...[
          const SizedBox(height: 12),
          Text(
            '${l10n.deliveryFee} ${_normalDeliveryPrice!.toStringAsFixed(2)} ${l10n.jodShort}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.neutral700,
            ),
          ),
        ],
      ],
    );
  }

  /// The whole schedule as one vertical list, soonest first.
  ///
  /// [slots] arrives already ordered by date then time, so index 0 is always the earliest
  /// collection still available - which is what makes the rollover invisible to the
  /// customer: once today's windows have elapsed the list simply starts at tomorrow.
  ///
  /// The list scrolls within a bounded height rather than growing the sheet. A week of
  /// windows is far more rows than the day-picker ever showed, and letting them push the
  /// sheet taller overflows it and carries the confirm button off screen - so the schedule
  /// scrolls and the actions stay put.
  Widget _buildSlotList({
    required List<DeliverySlot> slots,
    required Locale locale,
    required AppLocalizations l10n,
    required VoidCallback onChanged,
  }) {
    // The operator's clock, not the phone's, so the boundary between "today" and
    // "tomorrow" is the same one the backend used to build this list.
    final today = JordanTime.today();

    return ConstrainedBox(
      // A fraction of the screen rather than a fixed height, so a short phone does not
      // lose the buttons and a tall one does not waste the space. Sized to cut a row in
      // half, which is what tells the customer there is more to scroll.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.30,
      ),
      child: ListView.separated(
        // Takes only the height it needs, so a schedule with two slots left does not
        // leave an empty gap above the fee line.
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: slots.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _buildSlotTile(
          slot: slots[index],
          locale: locale,
          l10n: l10n,
          today: today,
          onChanged: onChanged,
        ),
      ),
    );
  }
  /// One bookable option: the date and the time window together, so choosing a
  /// collection is a single decision rather than a day followed by a time.
  Widget _buildSlotTile({
    required DeliverySlot slot,
    required Locale locale,
    required AppLocalizations l10n,
    required DateTime today,
    required VoidCallback onChanged,
  }) {
    final selected = _selectedSlot?.windowId == slot.windowId &&
        _selectedSlot?.dateKey == slot.dateKey;
    // Full slots stay visible but unselectable: a day that is genuinely booked out
    // should read as booked out, not as a day the operator forgot to schedule.
    final available = slot.isAvailable;

    return GestureDetector(
      onTap: available
          ? () {
              setState(() => _selectedSlot = slot);
              onChanged();
            }
          : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.neutral200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 18,
              color: !available
                  ? AppTheme.neutral400
                  : (selected ? AppTheme.primary : AppTheme.neutral500),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                slot.dateTimeLabel(
                  locale,
                  today: today,
                  todayLabel: l10n.today,
                  tomorrowLabel: l10n.tomorrow,
                ),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: !available
                      ? AppTheme.neutral400
                      : (selected ? AppTheme.primary : AppTheme.neutral900),
                ),
              ),
            ),
            if (!available)
              Text(
                l10n.fullyBooked,
                style: TextStyle(fontSize: 12, color: AppTheme.neutral400),
              )
            else if (selected)
              const Icon(Icons.check_circle_rounded, size: 18, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  void _confirmLocation() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    // The schedule ages: windows fill up and start while the app sits on the map. Refetch
    // on open so the sheet offers what is bookable now, not what was bookable at launch.
    _fetchDeliverySlots();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          _sheetSetState = setModalState;
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
                    const Icon(
                      Icons.shopping_cart_checkout_rounded,
                      color: AppTheme.primary,
                      size: 28,
                    ),
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
                // The whole of the customer's scheduling choice: a date, then one of the
                // operator's windows on that date. setState stores the pick on the view (it
                // outlives the sheet); setModalState repaints the sheet.
                _buildScheduleSection(
                  l10n: l10n,
                  onChanged: () => setModalState(() {}),
                ),
                const SizedBox(height: 24),
                if (!showPromoField)
                  GestureDetector(
                    onTap: () {
                      setModalState(() {
                        // We use the controller's content to trigger visibility in this simple logic
                        _marketingController.text =
                            " "; // Dummy space to trigger if empty
                      });
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.add_circle_outline,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.addPromoCode,
                          style: const TextStyle(
                            color: AppTheme.primary,
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
                            setModalState(
                              () {},
                            ); // Refresh to potentially show button again if user clears
                          }
                        },
                        decoration: InputDecoration(
                          hintText: l10n.enterPromoCode,
                          hintStyle: TextStyle(
                            color: AppTheme.neutral400,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.sell_outlined,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.neutral200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.neutral200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.primary,
                            ),
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
                          backgroundColor: AppTheme.primary,
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
        },
      ),
      // Dropped when the sheet closes, so a late schedule refresh does not try to
      // repaint a route that is no longer on screen.
    ).whenComplete(() => _sheetSetState = null);
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
                      AppTheme.primary.withOpacity(0.08),
                      AppTheme.primary.withOpacity(0),
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
                      AppTheme.primary.withOpacity(0.05),
                      AppTheme.primary.withOpacity(0),
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
                        color: AppTheme.primary.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        size: 60,
                        color: AppTheme.primary,
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
                        backgroundColor: AppTheme.primary,
                        elevation: 4,
                        shadowColor: AppTheme.primary.withOpacity(0.3),
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
                          const Expanded(
                            child: Divider(color: AppTheme.neutral200),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              l10n.orChooseSavedLocation,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: AppTheme.neutral400,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: AppTheme.neutral200),
                          ),
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
                                    final saved = LatLng(
                                      location['lat'],
                                      location['long'],
                                    );
                                    // Addresses saved before the service area
                                    // was restricted can sit outside it, so
                                    // they are re-checked on use rather than
                                    // trusted.
                                    if (!AmmanBoundaryService.isLocationInsideAmman(
                                      saved,
                                    )) {
                                      return;
                                    }
                                    setState(() {
                                      _showWelcomeDialog = false;
                                      _selectedPosition = saved;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppTheme.neutral200,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withOpacity(
                                              0.08,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.home_work_rounded,
                                            size: 24,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                location['name'] ??
                                                    l10n.savedLocation,
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
          // Google Map - mounted only while this tab is showing, see
          // HomeView.isActive.
          if (!widget.isActive)
            const ColoredBox(
              color: AppTheme.neutral100,
              child: SizedBox.expand(),
            )
          else
            GoogleMap(
              // _selectedPosition tracks the camera as the user pans, so
              // returning to this tab restores the map where they left it.
              initialCameraPosition: CameraPosition(
                target: _selectedPosition,
                zoom: AmmanBoundaryService.focusZoom,
              ),
              // Handled by the map engine itself, so panning stops at the edge
              // instead of springing back - the polygon's concave parts are then
              // tidied up in onCameraIdle.
              cameraTargetBounds: AmmanBoundaryService.cameraTargetBounds,
              minMaxZoomPreference: AmmanBoundaryService.zoomPreference,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              markers: _orderMarkers,
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              style: _mapStyle,
            ),

          // Center Marker
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 48,
                  color: AppTheme.primary,
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
                const SizedBox(
                  height: 40,
                ), // Space to keep icon above center point
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
                if (_hasPendingOrder) _buildPendingOrderBanner(l10n),
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
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppTheme.primary,
                      ),
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
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
                      child: const Icon(
                        Icons.my_location_rounded,
                        color: AppTheme.primary,
                      ),
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
                              color: AppTheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.place_rounded,
                              color: AppTheme.primary,
                            ),
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
                          // Saved locations belong to a user row, so a guest has nowhere
                          // to keep one - hidden rather than offered and then refused.
                          if (!_isGuest)
                            IconButton(
                              onPressed: _saveLocation,
                              icon: const Icon(
                                Icons.bookmark_add_outlined,
                                color: AppTheme.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _confirmLocation,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor: AppTheme.primary,
                          disabledBackgroundColor: AppTheme.neutral300,
                          disabledForegroundColor: AppTheme.neutral500,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          l10n.setPickupLocation,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Blocking scrim. Unpositioned and painted, so it fills the Stack and absorbs every
          // touch - which is correct for the two actions that raise _isLoading (saving a
          // location, placing an order) because both must not be interrupted, and wrong for
          // anything else. Nothing background may raise this flag: an order refresh or a GPS
          // fetch that did would freeze the map for as long as it ran.
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
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9C3), // amber-100
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)), // amber-300
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _showActiveOrderInvoice,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFFB45309),
                ), // amber-700
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.activeOrderTitle,
                        style: const TextStyle(
                          color: Color(0xFF92400E), // amber-800
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _activeOrderRef != null
                            ? '${l10n.invoiceNumber}: $_activeOrderRef'
                            : l10n.activeOrderTapHint,
                        style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFB45309),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showActiveOrderInvoice() {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.receipt_long_rounded, color: AppTheme.primary),
            const SizedBox(width: 10),
            Text(l10n.activeOrderTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.invoiceNumber,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.neutral500,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              _activeOrderRef ?? '—',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppTheme.neutral900,
              ),
            ),
            if (_activeOrderStatus != null) ...[
              const SizedBox(height: 16),
              Text(
                l10n.orderStatusLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.neutral500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _localizedOrderStatus(l10n, _activeOrderStatus!),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.neutral800,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  String _localizedOrderStatus(AppLocalizations l10n, String status) {
    switch (status) {
      case 'PendingCollection':
      case 'Pending':
        return l10n.statusPendingCollection;
      case 'Assigned':
        return l10n.statusAssigned;
      case 'Collected':
        return l10n.statusCollected;
      case 'Cleaning':
        return l10n.statusCleaning;
      case 'Ready':
        return l10n.statusReady;
      case 'OutForDelivery':
        return l10n.statusOutForDelivery;
      case 'Delivered':
        return l10n.statusDelivered;
      case 'Cancelled':
        return l10n.statusCancelled;
      default:
        return status;
    }
  }
}
