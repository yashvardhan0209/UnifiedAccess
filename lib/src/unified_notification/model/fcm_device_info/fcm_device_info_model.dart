// ignore_for_file: public_member_api_docs

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:unified_access/unified_access.dart';

part 'fcm_device_info_model.freezed.dart';

@freezed
abstract class FcmDeviceInfoModel with _$FcmDeviceInfoModel {
  factory FcmDeviceInfoModel({
    required String fcmToken,
    @Default(null) AndroidDeviceInfo? androidDeviceInfo,
    @Default(null) IosDeviceInfo? iosDeviceInfo,
  }) = _FcmDeviceInfoModel;
}
