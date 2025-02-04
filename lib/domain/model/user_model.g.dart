// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      uid: json['uid'] as String?,
      status: (json['status'] as num?)?.toInt(),
      loginType: $enumDecodeNullable(_$LoginTypeEnumMap, json['loginType']),
      bioIdentityYN: json['bioIdentityYN'] as bool?,
      mnemonic: json['mnemonic'] as String?,
      keyPair: json['keyPair'] as String?,
      socialId: json['socialId'] as String?,
      socialToken: json['socialToken'] as String?,
      userName: json['userName'] as String?,
      email: json['email'] as String?,
      mobile: json['mobile'] as String?,
      country: json['country'] as String?,
      pic: json['pic'] as String?,
      picThumb: json['picThumb'] as String?,
      deviceId: json['deviceId'] as String?,
      deviceType: json['deviceType'] as String?,
      addressList: (json['addressList'] as List<dynamic>?)
          ?.map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      certUpdt: json['certUpdt'] as String?,
      withdrawDt: json['withdrawDt'] as String?,
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('uid', instance.uid);
  writeNotNull('status', instance.status);
  writeNotNull('loginType', _$LoginTypeEnumMap[instance.loginType]);
  writeNotNull('bioIdentityYN', instance.bioIdentityYN);
  writeNotNull('mnemonic', instance.mnemonic);
  writeNotNull('keyPair', instance.keyPair);
  writeNotNull('socialId', instance.socialId);
  writeNotNull('socialToken', instance.socialToken);
  writeNotNull('userName', instance.userName);
  writeNotNull('email', instance.email);
  writeNotNull('mobile', instance.mobile);
  writeNotNull('country', instance.country);
  writeNotNull('pic', instance.pic);
  writeNotNull('picThumb', instance.picThumb);
  writeNotNull('deviceId', instance.deviceId);
  writeNotNull('deviceType', instance.deviceType);
  writeNotNull('certUpdt', instance.certUpdt);
  writeNotNull('withdrawDt', instance.withdrawDt);
  writeNotNull(
      'addressList', instance.addressList?.map((e) => e.toJson()).toList());
  return val;
}

const _$LoginTypeEnumMap = {
  LoginType.kakaotalk: 'kakaotalk',
  LoginType.naver: 'naver',
  LoginType.google: 'google',
  LoginType.apple: 'apple',
  LoginType.email: 'email',
};
