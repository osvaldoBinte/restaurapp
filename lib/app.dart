
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurapp/common/routes/router.dart';
import 'package:restaurapp/common/settings/routes_names.dart';
import 'package:restaurapp/common/theme/Theme_colors.dart';


class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AdminColors.themeData, 
      initialBinding: BindingsBuilder(() {
       
      }),
      
      getPages: AppPages.routes, 
      unknownRoute: AppPages.unknownRoute, 
    );
  }
}