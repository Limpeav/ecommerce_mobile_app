import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/bloc/locale_cubit.dart';
import '../theme/bloc/theme_cubit.dart';
import '../network/api_client.dart';
import '../models/user_profile.dart';
import '../services/push_notification_service.dart';
import '../services/search_history_service.dart';
import '../services/settings_service.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/cart/presentation/bloc/cart_event.dart';
import '../../features/notifications/presentation/bloc/notification_cubit.dart';
import '../../features/orders/presentation/bloc/order_bloc.dart';
import '../../features/orders/presentation/bloc/order_event.dart';
import '../../features/products/data/datasources/product_remote_datasource.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/repositories/product_repository.dart';
import '../../features/products/domain/usecases/get_products_usecase.dart';
import '../../features/products/presentation/bloc/product_bloc.dart';
import '../../features/profile/presentation/bloc/address_cubit.dart';
import '../../features/wishlist/presentation/bloc/wishlist_bloc.dart';
import '../../features/wishlist/presentation/bloc/wishlist_event.dart';

class ServiceLocator {
  static final ServiceLocator instance = ServiceLocator._internal();

  ServiceLocator._internal();

  bool _isInitialized = false;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<void>? _sessionSubscription;

  late ApiClient apiClient;
  late ProductRemoteDataSource productRemoteDataSource;
  late ProductRepository productRepository;
  late GetProductsUseCase getProductsUseCase;

  late AuthLocalDataSource authLocalDataSource;
  late AuthRemoteDataSource authRemoteDataSource;
  late AuthRepository authRepository;

  late ThemeCubit themeCubit;
  late LocaleCubit localeCubit;
  late AuthBloc authBloc;
  late ProductBloc productBloc;
  late CartBloc cartBloc;
  late WishlistBloc wishlistBloc;
  late OrderBloc orderBloc;
  late AddressCubit addressCubit;
  late NotificationCubit notificationCubit;
  late SearchHistoryService searchHistoryService;
  late UserProfile userProfile;

  Future<void> init({SharedPreferences? preferences, bool force = false}) async {
    if (_isInitialized && !force) return;

    final prefs = preferences ?? await SharedPreferences.getInstance();
    authLocalDataSource = AuthLocalDataSourceImpl(sharedPreferences: prefs);

    // 1. Core Network & Data Sources
    apiClient = ApiClient(
      onRefreshToken: () => authRepository.refreshToken(),
      onSessionExpired: () {
        if (authRepository is AuthRepositoryImpl) {
          (authRepository as AuthRepositoryImpl).notifySessionExpired();
        }
      },
    );

    productRemoteDataSource = ProductRemoteDataSourceImpl(apiClient: apiClient);
    productRepository = ProductRepositoryImpl(remoteDataSource: productRemoteDataSource);

    authRemoteDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);
    authRepository = AuthRepositoryImpl(
      remoteDataSource: authRemoteDataSource,
      localDataSource: authLocalDataSource,
    );

    // 3. Domain Use Cases
    getProductsUseCase = GetProductsUseCase(productRepository);

    // 4. BLoCs / Cubits
    themeCubit = ThemeCubit(preferences: prefs);
    localeCubit = LocaleCubit(preferences: prefs);
    authBloc = AuthBloc(authRepository: authRepository);
    productBloc = ProductBloc(
      getProductsUseCase: getProductsUseCase,
      productRepository: productRepository,
    );
    cartBloc = CartBloc(preferences: prefs);
    wishlistBloc = WishlistBloc(preferences: prefs);
    orderBloc = OrderBloc(preferences: prefs);
    addressCubit = AddressCubit(preferences: prefs);
    notificationCubit = NotificationCubit(preferences: prefs);
    PushNotificationService.instance.init(notificationCubit: notificationCubit);
    searchHistoryService = SearchHistoryService(preferences: prefs);
    userProfile = UserProfile.defaultUser;

    _isInitialized = true;

    // Listen to session expiry to automatically log out
    _sessionSubscription?.cancel();
    _sessionSubscription = authRepository.sessionExpiredStream.listen((_) {
      authBloc.add(const AuthLogoutRequested());
    });

    // Fetch admin-configured financial settings and apply to CartBloc
    SettingsService.fetchFinancialSettings().then((settings) {
      cartBloc.add(CartFinancialSettingsUpdated(
        shippingFee: settings.shippingFee,
        taxRate: settings.taxRate,
        freeShippingThreshold: settings.freeShippingThreshold,
      ));
    });

    // Automatically resync orders, cart, and wishlist whenever user logs in or logs out
    _authSubscription?.cancel();
    _authSubscription = authBloc.stream.listen((authState) {
      final token = authState.user?.token;
      if (token != null && token.isNotEmpty) {
        orderBloc.add(OrderFetchRequested(authToken: token));
        cartBloc.add(CartRemoteFetchRequested(authToken: token));
        wishlistBloc.add(WishlistRemoteFetchRequested(authToken: token));
      } else if (authState.status == AuthStatus.unauthenticated) {
        orderBloc.add(const OrderCleared());
      }
    });

    // Fetch user orders, cart & wishlist if initial cached token exists
    final cachedToken = authBloc.state.user?.token;
    if (cachedToken != null && cachedToken.isNotEmpty) {
      orderBloc.add(OrderFetchRequested(authToken: cachedToken));
      cartBloc.add(CartRemoteFetchRequested(authToken: cachedToken));
      wishlistBloc.add(WishlistRemoteFetchRequested(authToken: cachedToken));
    }
  }

  void reset() {
    _isInitialized = false;
    init(force: true);
  }

  void dispose() {
    _authSubscription?.cancel();
    _sessionSubscription?.cancel();
    themeCubit.close();
    localeCubit.close();
    authBloc.close();
    productBloc.close();
    cartBloc.close();
    wishlistBloc.close();
    orderBloc.close();
    addressCubit.close();
    notificationCubit.close();
    _isInitialized = false;
  }
}
