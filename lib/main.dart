import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/bloc/locale_cubit.dart';
import 'core/theme/bloc/theme_cubit.dart';
import 'core/theme/bloc/theme_state.dart';
import 'l10n/app_localizations.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';
import 'features/notifications/presentation/bloc/notification_cubit.dart';
import 'features/orders/presentation/bloc/order_bloc.dart';
import 'features/products/presentation/bloc/product_bloc.dart';
import 'features/profile/presentation/bloc/address_cubit.dart';
import 'features/wishlist/presentation/bloc/wishlist_bloc.dart';
import 'features/splash/presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('⚠️ SharedPreferences notice: $e');
  }
  await ServiceLocator.instance.init(preferences: prefs);
  runApp(const EcommerceApp());
}

class EcommerceApp extends StatelessWidget {
  const EcommerceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final sl = ServiceLocator.instance;

    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: sl.themeCubit),
        BlocProvider<LocaleCubit>.value(value: sl.localeCubit),
        BlocProvider<AuthBloc>.value(value: sl.authBloc),
        BlocProvider<ProductBloc>.value(value: sl.productBloc),
        BlocProvider<CartBloc>.value(value: sl.cartBloc),
        BlocProvider<WishlistBloc>.value(value: sl.wishlistBloc),
        BlocProvider<OrderBloc>.value(value: sl.orderBloc),
        BlocProvider<AddressCubit>.value(value: sl.addressCubit),
        BlocProvider<NotificationCubit>.value(value: sl.notificationCubit),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) {
              return MaterialApp(
                title: 'Cherish Baby Store - Premium Baby & Kids Essentials',
                debugShowCheckedModeBanner: false,
                themeMode: themeState.themeMode,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const SplashPage(),
              );
            },
          );
        },
      ),
    );
  }
}
