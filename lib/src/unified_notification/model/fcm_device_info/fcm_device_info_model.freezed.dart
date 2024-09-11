// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fcm_device_info_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$FcmDeviceInfoModel {
  String get fcmToken => throw _privateConstructorUsedError;
  AndroidDeviceInfo? get androidDeviceInfo =>
      throw _privateConstructorUsedError;
  IosDeviceInfo? get iosDeviceInfo => throw _privateConstructorUsedError;

  /// Create a copy of FcmDeviceInfoModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FcmDeviceInfoModelCopyWith<FcmDeviceInfoModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FcmDeviceInfoModelCopyWith<$Res> {
  factory $FcmDeviceInfoModelCopyWith(
          FcmDeviceInfoModel value, $Res Function(FcmDeviceInfoModel) then) =
      _$FcmDeviceInfoModelCopyWithImpl<$Res, FcmDeviceInfoModel>;
  @useResult
  $Res call(
      {String fcmToken,
      AndroidDeviceInfo? androidDeviceInfo,
      IosDeviceInfo? iosDeviceInfo});
}

/// @nodoc
class _$FcmDeviceInfoModelCopyWithImpl<$Res, $Val extends FcmDeviceInfoModel>
    implements $FcmDeviceInfoModelCopyWith<$Res> {
  _$FcmDeviceInfoModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FcmDeviceInfoModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fcmToken = null,
    Object? androidDeviceInfo = freezed,
    Object? iosDeviceInfo = freezed,
  }) {
    return _then(_value.copyWith(
      fcmToken: null == fcmToken
          ? _value.fcmToken
          : fcmToken // ignore: cast_nullable_to_non_nullable
              as String,
      androidDeviceInfo: freezed == androidDeviceInfo
          ? _value.androidDeviceInfo
          : androidDeviceInfo // ignore: cast_nullable_to_non_nullable
              as AndroidDeviceInfo?,
      iosDeviceInfo: freezed == iosDeviceInfo
          ? _value.iosDeviceInfo
          : iosDeviceInfo // ignore: cast_nullable_to_non_nullable
              as IosDeviceInfo?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FcmDeviceInfoModelImplCopyWith<$Res>
    implements $FcmDeviceInfoModelCopyWith<$Res> {
  factory _$$FcmDeviceInfoModelImplCopyWith(_$FcmDeviceInfoModelImpl value,
          $Res Function(_$FcmDeviceInfoModelImpl) then) =
      __$$FcmDeviceInfoModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String fcmToken,
      AndroidDeviceInfo? androidDeviceInfo,
      IosDeviceInfo? iosDeviceInfo});
}

/// @nodoc
class __$$FcmDeviceInfoModelImplCopyWithImpl<$Res>
    extends _$FcmDeviceInfoModelCopyWithImpl<$Res, _$FcmDeviceInfoModelImpl>
    implements _$$FcmDeviceInfoModelImplCopyWith<$Res> {
  __$$FcmDeviceInfoModelImplCopyWithImpl(_$FcmDeviceInfoModelImpl _value,
      $Res Function(_$FcmDeviceInfoModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of FcmDeviceInfoModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fcmToken = null,
    Object? androidDeviceInfo = freezed,
    Object? iosDeviceInfo = freezed,
  }) {
    return _then(_$FcmDeviceInfoModelImpl(
      fcmToken: null == fcmToken
          ? _value.fcmToken
          : fcmToken // ignore: cast_nullable_to_non_nullable
              as String,
      androidDeviceInfo: freezed == androidDeviceInfo
          ? _value.androidDeviceInfo
          : androidDeviceInfo // ignore: cast_nullable_to_non_nullable
              as AndroidDeviceInfo?,
      iosDeviceInfo: freezed == iosDeviceInfo
          ? _value.iosDeviceInfo
          : iosDeviceInfo // ignore: cast_nullable_to_non_nullable
              as IosDeviceInfo?,
    ));
  }
}

/// @nodoc

class _$FcmDeviceInfoModelImpl implements _FcmDeviceInfoModel {
  _$FcmDeviceInfoModelImpl(
      {required this.fcmToken,
      this.androidDeviceInfo = null,
      this.iosDeviceInfo = null});

  @override
  final String fcmToken;
  @override
  @JsonKey()
  final AndroidDeviceInfo? androidDeviceInfo;
  @override
  @JsonKey()
  final IosDeviceInfo? iosDeviceInfo;

  @override
  String toString() {
    return 'FcmDeviceInfoModel(fcmToken: $fcmToken, androidDeviceInfo: $androidDeviceInfo, iosDeviceInfo: $iosDeviceInfo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FcmDeviceInfoModelImpl &&
            (identical(other.fcmToken, fcmToken) ||
                other.fcmToken == fcmToken) &&
            (identical(other.androidDeviceInfo, androidDeviceInfo) ||
                other.androidDeviceInfo == androidDeviceInfo) &&
            (identical(other.iosDeviceInfo, iosDeviceInfo) ||
                other.iosDeviceInfo == iosDeviceInfo));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, fcmToken, androidDeviceInfo, iosDeviceInfo);

  /// Create a copy of FcmDeviceInfoModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FcmDeviceInfoModelImplCopyWith<_$FcmDeviceInfoModelImpl> get copyWith =>
      __$$FcmDeviceInfoModelImplCopyWithImpl<_$FcmDeviceInfoModelImpl>(
          this, _$identity);
}

abstract class _FcmDeviceInfoModel implements FcmDeviceInfoModel {
  factory _FcmDeviceInfoModel(
      {required final String fcmToken,
      final AndroidDeviceInfo? androidDeviceInfo,
      final IosDeviceInfo? iosDeviceInfo}) = _$FcmDeviceInfoModelImpl;

  @override
  String get fcmToken;
  @override
  AndroidDeviceInfo? get androidDeviceInfo;
  @override
  IosDeviceInfo? get iosDeviceInfo;

  /// Create a copy of FcmDeviceInfoModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FcmDeviceInfoModelImplCopyWith<_$FcmDeviceInfoModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
