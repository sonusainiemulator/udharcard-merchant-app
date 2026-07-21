import 'dart:ui';

class AppColors {
  // Clean ledger-first palette (Khatabook-inspired, not a clone)
  static Color mainColor = Color(0xff0F5BD8);

  static Color secondaryColor = Color(0xffF2A400);

  static Color yellowColor = Color(0xffF2A400);
  static Color pendingColor = Color(0xffEF8D17);

  static Color splashGradient1 = Color(0xff0E4FB8);
  static Color splashGradient2 = Color(0xff1D75E5);

  static const Color textFieldHintColor = Color(0xff98A0AB);
  static const Color fillColorColor = Color(0xffF4F7FB);
  static const Color greyColor = Color(0xff818688);
  static const Color borderColor = Color(0xffE3E9F2);
  static const Color sliderInActiveColor = Color(0xffEAEAEA);

  static Color imageBgColor = mainColor.withValues(alpha: .2);
  static const Color bgColor = Color(0xffEAF2FF);
  static const Color scaffoldColor = Color(0xffF5F8FD);
  static const Color paragraphColor = Color(0xff666666);
  static const Color darkBgColor = Color(0xff0E1621);
  static const Color darkCardColor = Color(0xff17212B);
  static const Color darkCardColorDeep = Color(0xff25303D);

  static const Color whiteColor = Color(0xffFFFFFF);
  static Color blackColor = Color(0xff152033);
  static const Color black5 = Color(0xffF2F3F3);
  static const Color black10 = Color(0xffE6E7E7);
  static const Color black20 = Color(0xffCDCFD0);
  static const Color black30 = Color(0xffB4B6B8);
  static const Color black50 = Color(0xff818688);
  static const Color black60 = Color(0xff686E71);
  static const Color black70 = Color(0xff494D4F);
  static const Color black80 = Color(0xff363D41);
  static const Color redColor = Color(0xffE34B4B);
  static const Color greenColor = Color(0xff1F9D58);

  static const Color random1 = Color(0xffFD8D00);
  static const Color random2 = Color(0xffFD00F3);
  static const Color random3 = Color(0xff2F3C7E);
  static const Color random4 = Color(0xffF9E795);
  static const Color random5 = Color(0xffF96167);
  static const Color random6 = Color(0xff2C5F2D);
  static const Color random7 = Color(0xff408EC6);
  static const Color random8 = Color(0xffB85042);
  static const Color random9 = Color(0xff20948B);
  static const Color random10 = Color(0xffC5001A);

  static List<Color> colors = [
    random1,
    random2,
    random3,
    random4,
    random5,
    random6,
    random7,
    random8,
    random9,
    random10,
  ];

  static const Color dollerColor = random1;
  static const Color euroColor = Color(0xff0ECAF0);
  static const Color britishPoundColor = Color(0xffDEE3FB);
  static const Color nigeriaCurrencyColor = Color(0xffD9EDD7);
}
