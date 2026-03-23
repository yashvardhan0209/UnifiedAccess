// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fcm_device_info_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FcmDeviceInfoModel {

 String get fcmToken; AndroidDeviceInfo? get androidDeviceInfo; IosDeviceInfo? get iosDeviceInfo;
/// Create a copy of FcmDeviceInfoModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FcmDeviceInfoModelCopyWith<FcmDeviceInfoModel> get copyWith => _$FcmDeviceInfoModelCopyWithImpl<FcmDeviceInfoModel>(this as FcmDeviceInfoModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FcmDeviceInfoModel&&(identical(other.fcmToken, fcmToken) || other.fcmToken == fcmToken)&&(identical(other.androidDeviceInfo, androidDeviceInfo) || other.androidDeviceInfo == androidDeviceInfo)&&(identical(other.iosDeviceInfo, iosDeviceInfo) || other.iosDeviceInfo == iosDeviceInfo));
}


@override
int get hashCode => Object.hash(runtimeType,fcmToken,androidDeviceInfo,iosDeviceInfo);

@override
String toString() {
  return 'FcmDeviceInfoModel(fcmToken: $fcmToken, androidDeviceInfo: $androidDeviceInfo, iosDeviceInfo: $iosDeviceInfo)';
}


}

/// @nodoc
abstract mixin class $FcmDeviceInfoModelCopyWith<$Res>  {
  factory $FcmDeviceInfoModelCopyWith(FcmDeviceInfoModel value, $Res Function(FcmDeviceInfoModel) _then) = _$FcmDeviceInfoModelCopyWithImpl;
@useResult
$Res call({
 String fcmToken, AndroidDeviceInfo? androidDeviceInfo, IosDeviceInfo? iosDeviceInfo
});




}
/// @nodoc
class _$FcmDeviceInfoModelCopyWithImpl<$Res>
    implements $FcmDeviceInfoModelCopyWith<$Res> {
  _$FcmDeviceInfoModelCopyWithImpl(this._self, this._then);

  final FcmDeviceInfoModel _self;
  final $Res Function(FcmDeviceInfoModel) _then;

/// Create a copy of FcmDeviceInfoModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fcmToken = null,Object? androidDeviceInfo = freezed,Object? iosDeviceInfo = freezed,}) {
  return _then(_self.copyWith(
fcmToken: null == fcmToken ? _self.fcmToken : fcmToken // ignore: cast_nullable_to_non_nullable
as String,androidDeviceInfo: freezed == androidDeviceInfo ? _self.androidDeviceInfo : androidDeviceInfo // ignore: cast_nullable_to_non_nullable
as AndroidDeviceInfo?,iosDeviceInfo: freezed == iosDeviceInfo ? _self.iosDeviceInfo : iosDeviceInfo // ignore: cast_nullable_to_non_nullable
as IosDeviceInfo?,
  ));
}

}


/// Adds pattern-matching-related methods to [FcmDeviceInfoModel].
extension FcmDeviceInfoModelPatterns on FcmDeviceInfoModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FcmDeviceInfoModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FcmDeviceInfoModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FcmDeviceInfoModel value)  $default,){
final _that = this;
switch (_that) {
case _FcmDeviceInfoModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FcmDeviceInfoModel value)?  $default,){
final _that = this;
switch (_that) {
case _FcmDeviceInfoModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fcmToken,  AndroidDeviceInfo? androidDeviceInfo,  IosDeviceInfo? iosDeviceInfo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FcmDeviceInfoModel() when $default != null:
return $default(_that.fcmToken,_that.androidDeviceInfo,_that.iosDeviceInfo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fcmToken,  AndroidDeviceInfo? androidDeviceInfo,  IosDeviceInfo? iosDeviceInfo)  $default,) {final _that = this;
switch (_that) {
case _FcmDeviceInfoModel():
return $default(_that.fcmToken,_that.androidDeviceInfo,_that.iosDeviceInfo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fcmToken,  AndroidDeviceInfo? androidDeviceInfo,  IosDeviceInfo? iosDeviceInfo)?  $default,) {final _that = this;
switch (_that) {
case _FcmDeviceInfoModel() when $default != null:
return $default(_that.fcmToken,_that.androidDeviceInfo,_that.iosDeviceInfo);case _:
  return null;

}
}

}

/// @nodoc


class _FcmDeviceInfoModel implements FcmDeviceInfoModel {
   _FcmDeviceInfoModel({required this.fcmToken, this.androidDeviceInfo = null, this.iosDeviceInfo = null});
  

@override final  String fcmToken;
@override@JsonKey() final  AndroidDeviceInfo? androidDeviceInfo;
@override@JsonKey() final  IosDeviceInfo? iosDeviceInfo;

/// Create a copy of FcmDeviceInfoModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FcmDeviceInfoModelCopyWith<_FcmDeviceInfoModel> get copyWith => __$FcmDeviceInfoModelCopyWithImpl<_FcmDeviceInfoModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FcmDeviceInfoModel&&(identical(other.fcmToken, fcmToken) || other.fcmToken == fcmToken)&&(identical(other.androidDeviceInfo, androidDeviceInfo) || other.androidDeviceInfo == androidDeviceInfo)&&(identical(other.iosDeviceInfo, iosDeviceInfo) || other.iosDeviceInfo == iosDeviceInfo));
}


@override
int get hashCode => Object.hash(runtimeType,fcmToken,androidDeviceInfo,iosDeviceInfo);

@override
String toString() {
  return 'FcmDeviceInfoModel(fcmToken: $fcmToken, androidDeviceInfo: $androidDeviceInfo, iosDeviceInfo: $iosDeviceInfo)';
}


}

/// @nodoc
abstract mixin class _$FcmDeviceInfoModelCopyWith<$Res> implements $FcmDeviceInfoModelCopyWith<$Res> {
  factory _$FcmDeviceInfoModelCopyWith(_FcmDeviceInfoModel value, $Res Function(_FcmDeviceInfoModel) _then) = __$FcmDeviceInfoModelCopyWithImpl;
@override @useResult
$Res call({
 String fcmToken, AndroidDeviceInfo? androidDeviceInfo, IosDeviceInfo? iosDeviceInfo
});




}
/// @nodoc
class __$FcmDeviceInfoModelCopyWithImpl<$Res>
    implements _$FcmDeviceInfoModelCopyWith<$Res> {
  __$FcmDeviceInfoModelCopyWithImpl(this._self, this._then);

  final _FcmDeviceInfoModel _self;
  final $Res Function(_FcmDeviceInfoModel) _then;

/// Create a copy of FcmDeviceInfoModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fcmToken = null,Object? androidDeviceInfo = freezed,Object? iosDeviceInfo = freezed,}) {
  return _then(_FcmDeviceInfoModel(
fcmToken: null == fcmToken ? _self.fcmToken : fcmToken // ignore: cast_nullable_to_non_nullable
as String,androidDeviceInfo: freezed == androidDeviceInfo ? _self.androidDeviceInfo : androidDeviceInfo // ignore: cast_nullable_to_non_nullable
as AndroidDeviceInfo?,iosDeviceInfo: freezed == iosDeviceInfo ? _self.iosDeviceInfo : iosDeviceInfo // ignore: cast_nullable_to_non_nullable
as IosDeviceInfo?,
  ));
}


}

// dart format on
