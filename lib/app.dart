
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurapp/common/routes/router.dart';
import 'package:restaurapp/common/settings/routes_names.dart';
import 'package:restaurapp/common/theme/Theme_colors.dart';
import 'package:restaurapp/page/categoria/listarcategoria/category_list_controller.dart';
import 'package:restaurapp/page/menu/listarmenu/listar_controller.dart';
import 'package:restaurapp/page/orders/crear/crear_orden_controller.dart';
import 'package:restaurapp/page/orders/orders_controller.dart';
import 'package:restaurapp/page/table/table_controller.dart';

import 'package:flutter_localizations/flutter_localizations.dart'; // AGREGAR ESTA IMPORTACIÓN

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp( locale: const Locale('es', 'ES'),
      supportedLocales: [
        const Locale('es', 'ES'),
      ], localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: AdminColors.themeData, 
      initialBinding: BindingsBuilder(() {
        Get.lazyPut(() => CategoryListController(), fenix: true);
        Get.lazyPut(() => ListarMenuController(), fenix: true);
        Get.lazyPut(() => CreateOrderController(), fenix: true);
        Get.lazyPut(() => TablesController(), fenix: true);
        Get.lazyPut(() => OrdersController(), fenix: true);
      }),
      
      getPages: AppPages.routes, 
      unknownRoute: AppPages.unknownRoute, 
    );
  }
}