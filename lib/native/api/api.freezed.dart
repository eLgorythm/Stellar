// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StellarStatus {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StellarStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StellarStatus()';
}


}

/// @nodoc
class $StellarStatusCopyWith<$Res>  {
$StellarStatusCopyWith(StellarStatus _, $Res Function(StellarStatus) __);
}


/// Adds pattern-matching-related methods to [StellarStatus].
extension StellarStatusPatterns on StellarStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StellarStatus_Idle value)?  idle,TResult Function( StellarStatus_Pairing value)?  pairing,TResult Function( StellarStatus_Paired value)?  paired,TResult Function( StellarStatus_Connecting value)?  connecting,TResult Function( StellarStatus_Connected value)?  connected,TResult Function( StellarStatus_Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StellarStatus_Idle() when idle != null:
return idle(_that);case StellarStatus_Pairing() when pairing != null:
return pairing(_that);case StellarStatus_Paired() when paired != null:
return paired(_that);case StellarStatus_Connecting() when connecting != null:
return connecting(_that);case StellarStatus_Connected() when connected != null:
return connected(_that);case StellarStatus_Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StellarStatus_Idle value)  idle,required TResult Function( StellarStatus_Pairing value)  pairing,required TResult Function( StellarStatus_Paired value)  paired,required TResult Function( StellarStatus_Connecting value)  connecting,required TResult Function( StellarStatus_Connected value)  connected,required TResult Function( StellarStatus_Error value)  error,}){
final _that = this;
switch (_that) {
case StellarStatus_Idle():
return idle(_that);case StellarStatus_Pairing():
return pairing(_that);case StellarStatus_Paired():
return paired(_that);case StellarStatus_Connecting():
return connecting(_that);case StellarStatus_Connected():
return connected(_that);case StellarStatus_Error():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StellarStatus_Idle value)?  idle,TResult? Function( StellarStatus_Pairing value)?  pairing,TResult? Function( StellarStatus_Paired value)?  paired,TResult? Function( StellarStatus_Connecting value)?  connecting,TResult? Function( StellarStatus_Connected value)?  connected,TResult? Function( StellarStatus_Error value)?  error,}){
final _that = this;
switch (_that) {
case StellarStatus_Idle() when idle != null:
return idle(_that);case StellarStatus_Pairing() when pairing != null:
return pairing(_that);case StellarStatus_Paired() when paired != null:
return paired(_that);case StellarStatus_Connecting() when connecting != null:
return connecting(_that);case StellarStatus_Connected() when connected != null:
return connected(_that);case StellarStatus_Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  pairing,TResult Function()?  paired,TResult Function()?  connecting,TResult Function()?  connected,TResult Function( String field0)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StellarStatus_Idle() when idle != null:
return idle();case StellarStatus_Pairing() when pairing != null:
return pairing();case StellarStatus_Paired() when paired != null:
return paired();case StellarStatus_Connecting() when connecting != null:
return connecting();case StellarStatus_Connected() when connected != null:
return connected();case StellarStatus_Error() when error != null:
return error(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  pairing,required TResult Function()  paired,required TResult Function()  connecting,required TResult Function()  connected,required TResult Function( String field0)  error,}) {final _that = this;
switch (_that) {
case StellarStatus_Idle():
return idle();case StellarStatus_Pairing():
return pairing();case StellarStatus_Paired():
return paired();case StellarStatus_Connecting():
return connecting();case StellarStatus_Connected():
return connected();case StellarStatus_Error():
return error(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  pairing,TResult? Function()?  paired,TResult? Function()?  connecting,TResult? Function()?  connected,TResult? Function( String field0)?  error,}) {final _that = this;
switch (_that) {
case StellarStatus_Idle() when idle != null:
return idle();case StellarStatus_Pairing() when pairing != null:
return pairing();case StellarStatus_Paired() when paired != null:
return paired();case StellarStatus_Connecting() when connecting != null:
return connecting();case StellarStatus_Connected() when connected != null:
return connected();case StellarStatus_Error() when error != null:
return error(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class StellarStatus_Idle extends StellarStatus {
  const StellarStatus_Idle(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StellarStatus_Idle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StellarStatus.idle()';
}


}




/// @nodoc


class StellarStatus_Pairing extends StellarStatus {
  const StellarStatus_Pairing(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StellarStatus_Pairing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StellarStatus.pairing()';
}


}




/// @nodoc


class StellarStatus_Paired extends StellarStatus {
  const StellarStatus_Paired(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StellarStatus_Paired);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StellarStatus.paired()';
}


}




/// @nodoc


class StellarStatus_Connecting extends StellarStatus {
  const StellarStatus_Connecting(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StellarStatus_Connecting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StellarStatus.connecting()';
}


}




/// @nodoc


class StellarStatus_Connected extends StellarStatus {
  const StellarStatus_Connected(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StellarStatus_Connected);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StellarStatus.connected()';
}


}




/// @nodoc


class StellarStatus_Error extends StellarStatus {
  const StellarStatus_Error(this.field0): super._();
  

 final  String field0;

/// Create a copy of StellarStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StellarStatus_ErrorCopyWith<StellarStatus_Error> get copyWith => _$StellarStatus_ErrorCopyWithImpl<StellarStatus_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StellarStatus_Error&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'StellarStatus.error(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $StellarStatus_ErrorCopyWith<$Res> implements $StellarStatusCopyWith<$Res> {
  factory $StellarStatus_ErrorCopyWith(StellarStatus_Error value, $Res Function(StellarStatus_Error) _then) = _$StellarStatus_ErrorCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$StellarStatus_ErrorCopyWithImpl<$Res>
    implements $StellarStatus_ErrorCopyWith<$Res> {
  _$StellarStatus_ErrorCopyWithImpl(this._self, this._then);

  final StellarStatus_Error _self;
  final $Res Function(StellarStatus_Error) _then;

/// Create a copy of StellarStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(StellarStatus_Error(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
