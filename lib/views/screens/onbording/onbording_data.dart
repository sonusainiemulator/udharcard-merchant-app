import '../../../utils/app_constants.dart';

class OnBordingData {
  String imagePath;
  String title;
  String description;

  OnBordingData(
      {required this.imagePath,
      required this.title,
      required this.description});
}

List<OnBordingData> onBordingDataList = [
  OnBordingData(
      imagePath: "$rootImageDir/onbording_1.png",
      title: "Manage Your Store",
      description:
          "Easily configure business details, services, and preferences from merchant settings."),
  OnBordingData(
      imagePath: "$rootImageDir/onbording_2.png",
      title: "Track Payments Easily",
      description:
          "Monitor payment requests, history, and charges from one simple, secure dashboard."),
  OnBordingData(
      imagePath: "$rootImageDir/onbording_3.png",
      title: "QR Scan & Pay",
      description:
          "Accept fast, secure payments with QR codes — just scan and confirm."),
];
