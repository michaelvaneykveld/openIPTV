// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grouped_content.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GroupedContent implements DiagnosticableTreeMixin {

 List<MainCategory> get categories;
/// Create a copy of GroupedContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupedContentCopyWith<GroupedContent> get copyWith => _$GroupedContentCopyWithImpl<GroupedContent>(this as GroupedContent, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'GroupedContent'))
    ..add(DiagnosticsProperty('categories', categories));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupedContent&&const DeepCollectionEquality().equals(other.categories, categories));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(categories));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'GroupedContent(categories: $categories)';
}


}

/// @nodoc
abstract mixin class $GroupedContentCopyWith<$Res>  {
  factory $GroupedContentCopyWith(GroupedContent value, $Res Function(GroupedContent) _then) = _$GroupedContentCopyWithImpl;
@useResult
$Res call({
 List<MainCategory> categories
});




}
/// @nodoc
class _$GroupedContentCopyWithImpl<$Res>
    implements $GroupedContentCopyWith<$Res> {
  _$GroupedContentCopyWithImpl(this._self, this._then);

  final GroupedContent _self;
  final $Res Function(GroupedContent) _then;

/// Create a copy of GroupedContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categories = null,}) {
  return _then(_self.copyWith(
categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<MainCategory>,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupedContent].
extension GroupedContentPatterns on GroupedContent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupedContent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupedContent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupedContent value)  $default,){
final _that = this;
switch (_that) {
case _GroupedContent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupedContent value)?  $default,){
final _that = this;
switch (_that) {
case _GroupedContent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MainCategory> categories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupedContent() when $default != null:
return $default(_that.categories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MainCategory> categories)  $default,) {final _that = this;
switch (_that) {
case _GroupedContent():
return $default(_that.categories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MainCategory> categories)?  $default,) {final _that = this;
switch (_that) {
case _GroupedContent() when $default != null:
return $default(_that.categories);case _:
  return null;

}
}

}

/// @nodoc


class _GroupedContent with DiagnosticableTreeMixin implements GroupedContent {
  const _GroupedContent({required final  List<MainCategory> categories}): _categories = categories;
  

 final  List<MainCategory> _categories;
@override List<MainCategory> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}


/// Create a copy of GroupedContent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupedContentCopyWith<_GroupedContent> get copyWith => __$GroupedContentCopyWithImpl<_GroupedContent>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'GroupedContent'))
    ..add(DiagnosticsProperty('categories', categories));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupedContent&&const DeepCollectionEquality().equals(other._categories, _categories));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_categories));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'GroupedContent(categories: $categories)';
}


}

/// @nodoc
abstract mixin class _$GroupedContentCopyWith<$Res> implements $GroupedContentCopyWith<$Res> {
  factory _$GroupedContentCopyWith(_GroupedContent value, $Res Function(_GroupedContent) _then) = __$GroupedContentCopyWithImpl;
@override @useResult
$Res call({
 List<MainCategory> categories
});




}
/// @nodoc
class __$GroupedContentCopyWithImpl<$Res>
    implements _$GroupedContentCopyWith<$Res> {
  __$GroupedContentCopyWithImpl(this._self, this._then);

  final _GroupedContent _self;
  final $Res Function(_GroupedContent) _then;

/// Create a copy of GroupedContent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categories = null,}) {
  return _then(_GroupedContent(
categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<MainCategory>,
  ));
}


}

/// @nodoc
mixin _$MainCategory implements DiagnosticableTreeMixin {

 String get name; List<SubCategory> get subCategories;
/// Create a copy of MainCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MainCategoryCopyWith<MainCategory> get copyWith => _$MainCategoryCopyWithImpl<MainCategory>(this as MainCategory, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'MainCategory'))
    ..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('subCategories', subCategories));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MainCategory&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.subCategories, subCategories));
}


@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(subCategories));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'MainCategory(name: $name, subCategories: $subCategories)';
}


}

/// @nodoc
abstract mixin class $MainCategoryCopyWith<$Res>  {
  factory $MainCategoryCopyWith(MainCategory value, $Res Function(MainCategory) _then) = _$MainCategoryCopyWithImpl;
@useResult
$Res call({
 String name, List<SubCategory> subCategories
});




}
/// @nodoc
class _$MainCategoryCopyWithImpl<$Res>
    implements $MainCategoryCopyWith<$Res> {
  _$MainCategoryCopyWithImpl(this._self, this._then);

  final MainCategory _self;
  final $Res Function(MainCategory) _then;

/// Create a copy of MainCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? subCategories = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,subCategories: null == subCategories ? _self.subCategories : subCategories // ignore: cast_nullable_to_non_nullable
as List<SubCategory>,
  ));
}

}


/// Adds pattern-matching-related methods to [MainCategory].
extension MainCategoryPatterns on MainCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MainCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MainCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MainCategory value)  $default,){
final _that = this;
switch (_that) {
case _MainCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MainCategory value)?  $default,){
final _that = this;
switch (_that) {
case _MainCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  List<SubCategory> subCategories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MainCategory() when $default != null:
return $default(_that.name,_that.subCategories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  List<SubCategory> subCategories)  $default,) {final _that = this;
switch (_that) {
case _MainCategory():
return $default(_that.name,_that.subCategories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  List<SubCategory> subCategories)?  $default,) {final _that = this;
switch (_that) {
case _MainCategory() when $default != null:
return $default(_that.name,_that.subCategories);case _:
  return null;

}
}

}

/// @nodoc


class _MainCategory with DiagnosticableTreeMixin implements MainCategory {
  const _MainCategory({required this.name, required final  List<SubCategory> subCategories}): _subCategories = subCategories;
  

@override final  String name;
 final  List<SubCategory> _subCategories;
@override List<SubCategory> get subCategories {
  if (_subCategories is EqualUnmodifiableListView) return _subCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subCategories);
}


/// Create a copy of MainCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MainCategoryCopyWith<_MainCategory> get copyWith => __$MainCategoryCopyWithImpl<_MainCategory>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'MainCategory'))
    ..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('subCategories', subCategories));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MainCategory&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._subCategories, _subCategories));
}


@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(_subCategories));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'MainCategory(name: $name, subCategories: $subCategories)';
}


}

/// @nodoc
abstract mixin class _$MainCategoryCopyWith<$Res> implements $MainCategoryCopyWith<$Res> {
  factory _$MainCategoryCopyWith(_MainCategory value, $Res Function(_MainCategory) _then) = __$MainCategoryCopyWithImpl;
@override @useResult
$Res call({
 String name, List<SubCategory> subCategories
});




}
/// @nodoc
class __$MainCategoryCopyWithImpl<$Res>
    implements _$MainCategoryCopyWith<$Res> {
  __$MainCategoryCopyWithImpl(this._self, this._then);

  final _MainCategory _self;
  final $Res Function(_MainCategory) _then;

/// Create a copy of MainCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? subCategories = null,}) {
  return _then(_MainCategory(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,subCategories: null == subCategories ? _self._subCategories : subCategories // ignore: cast_nullable_to_non_nullable
as List<SubCategory>,
  ));
}


}

/// @nodoc
mixin _$SubCategory implements DiagnosticableTreeMixin {

 String get name; List<PlayableItem> get items;
/// Create a copy of SubCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubCategoryCopyWith<SubCategory> get copyWith => _$SubCategoryCopyWithImpl<SubCategory>(this as SubCategory, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SubCategory'))
    ..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('items', items));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubCategory&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.items, items));
}


@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(items));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SubCategory(name: $name, items: $items)';
}


}

/// @nodoc
abstract mixin class $SubCategoryCopyWith<$Res>  {
  factory $SubCategoryCopyWith(SubCategory value, $Res Function(SubCategory) _then) = _$SubCategoryCopyWithImpl;
@useResult
$Res call({
 String name, List<PlayableItem> items
});




}
/// @nodoc
class _$SubCategoryCopyWithImpl<$Res>
    implements $SubCategoryCopyWith<$Res> {
  _$SubCategoryCopyWithImpl(this._self, this._then);

  final SubCategory _self;
  final $Res Function(SubCategory) _then;

/// Create a copy of SubCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? items = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<PlayableItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubCategory].
extension SubCategoryPatterns on SubCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubCategory value)  $default,){
final _that = this;
switch (_that) {
case _SubCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubCategory value)?  $default,){
final _that = this;
switch (_that) {
case _SubCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  List<PlayableItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubCategory() when $default != null:
return $default(_that.name,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  List<PlayableItem> items)  $default,) {final _that = this;
switch (_that) {
case _SubCategory():
return $default(_that.name,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  List<PlayableItem> items)?  $default,) {final _that = this;
switch (_that) {
case _SubCategory() when $default != null:
return $default(_that.name,_that.items);case _:
  return null;

}
}

}

/// @nodoc


class _SubCategory with DiagnosticableTreeMixin implements SubCategory {
  const _SubCategory({required this.name, required final  List<PlayableItem> items}): _items = items;
  

@override final  String name;
 final  List<PlayableItem> _items;
@override List<PlayableItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of SubCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubCategoryCopyWith<_SubCategory> get copyWith => __$SubCategoryCopyWithImpl<_SubCategory>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SubCategory'))
    ..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('items', items));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubCategory&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(_items));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SubCategory(name: $name, items: $items)';
}


}

/// @nodoc
abstract mixin class _$SubCategoryCopyWith<$Res> implements $SubCategoryCopyWith<$Res> {
  factory _$SubCategoryCopyWith(_SubCategory value, $Res Function(_SubCategory) _then) = __$SubCategoryCopyWithImpl;
@override @useResult
$Res call({
 String name, List<PlayableItem> items
});




}
/// @nodoc
class __$SubCategoryCopyWithImpl<$Res>
    implements _$SubCategoryCopyWith<$Res> {
  __$SubCategoryCopyWithImpl(this._self, this._then);

  final _SubCategory _self;
  final $Res Function(_SubCategory) _then;

/// Create a copy of SubCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? items = null,}) {
  return _then(_SubCategory(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<PlayableItem>,
  ));
}


}

/// @nodoc
mixin _$PlayableItem implements DiagnosticableTreeMixin {

 String get id; String get name; String? get logoUrl;
/// Create a copy of PlayableItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayableItemCopyWith<PlayableItem> get copyWith => _$PlayableItemCopyWithImpl<PlayableItem>(this as PlayableItem, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PlayableItem'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('logoUrl', logoUrl));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayableItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,logoUrl);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'PlayableItem(id: $id, name: $name, logoUrl: $logoUrl)';
}


}

/// @nodoc
abstract mixin class $PlayableItemCopyWith<$Res>  {
  factory $PlayableItemCopyWith(PlayableItem value, $Res Function(PlayableItem) _then) = _$PlayableItemCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? logoUrl
});




}
/// @nodoc
class _$PlayableItemCopyWithImpl<$Res>
    implements $PlayableItemCopyWith<$Res> {
  _$PlayableItemCopyWithImpl(this._self, this._then);

  final PlayableItem _self;
  final $Res Function(PlayableItem) _then;

/// Create a copy of PlayableItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? logoUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayableItem].
extension PlayableItemPatterns on PlayableItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayableItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayableItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayableItem value)  $default,){
final _that = this;
switch (_that) {
case _PlayableItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayableItem value)?  $default,){
final _that = this;
switch (_that) {
case _PlayableItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? logoUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayableItem() when $default != null:
return $default(_that.id,_that.name,_that.logoUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? logoUrl)  $default,) {final _that = this;
switch (_that) {
case _PlayableItem():
return $default(_that.id,_that.name,_that.logoUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? logoUrl)?  $default,) {final _that = this;
switch (_that) {
case _PlayableItem() when $default != null:
return $default(_that.id,_that.name,_that.logoUrl);case _:
  return null;

}
}

}

/// @nodoc


class _PlayableItem with DiagnosticableTreeMixin implements PlayableItem {
  const _PlayableItem({required this.id, required this.name, this.logoUrl});
  

@override final  String id;
@override final  String name;
@override final  String? logoUrl;

/// Create a copy of PlayableItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayableItemCopyWith<_PlayableItem> get copyWith => __$PlayableItemCopyWithImpl<_PlayableItem>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PlayableItem'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('logoUrl', logoUrl));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayableItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,logoUrl);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'PlayableItem(id: $id, name: $name, logoUrl: $logoUrl)';
}


}

/// @nodoc
abstract mixin class _$PlayableItemCopyWith<$Res> implements $PlayableItemCopyWith<$Res> {
  factory _$PlayableItemCopyWith(_PlayableItem value, $Res Function(_PlayableItem) _then) = __$PlayableItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? logoUrl
});




}
/// @nodoc
class __$PlayableItemCopyWithImpl<$Res>
    implements _$PlayableItemCopyWith<$Res> {
  __$PlayableItemCopyWithImpl(this._self, this._then);

  final _PlayableItem _self;
  final $Res Function(_PlayableItem) _then;

/// Create a copy of PlayableItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? logoUrl = freezed,}) {
  return _then(_PlayableItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
