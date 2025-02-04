
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart' as crypto;
import '../../../../common/const/utils/aesManager.dart';
import '../../../../common/const/utils/userHelper.dart';
import '../../../../common/provider/login_provider.dart';

import '../common/const/constants.dart';
import '../common/const/utils/appVersionHelper.dart';
import '../common/const/utils/convertHelper.dart';

//////////////////////////////////////////////////////////////////////////
//
//  LARBA Api Methods
//


class ApiService {
  static final ApiService _singleton = ApiService._internal();
  factory ApiService() {
    return _singleton;
  }
  ApiService._internal();

  var httpUrl = IS_DEV_MODE ? API_HOST_DEV : API_HOST;

  final RESPONSE_SUCCESS = 200;
  final RESPONSE_SUCCESS_EX = 201;

  isSuccess(statusCode) {
    return INT(statusCode) == RESPONSE_SUCCESS ||
           INT(statusCode) == RESPONSE_SUCCESS_EX;
  }

  //////////////////////////////////////////////////////////////////////////
  //
  //  Email 중복 체크
  //  /users/email/{email}/dup
  //

  Future<bool> checkEmail(String email) async {
    try {
      LOG('--> API checkEmail : $email');
      final response = await http.get(
        Uri.parse(httpUrl + '/users/email/${email}/dup'),
      );
      LOG('--> API checkEmail response : ${response.statusCode} / ${response.body}');
      if (isSuccess(response.statusCode)) {
        return BOL(jsonDecode(response.body)['result']);
      }
    } catch (e) {
      LOG('--> API checkEmail error : $e');
    }
    return false;
  }

  //////////////////////////////////////////////////////////////////////////
  //
  //  Email 인증코드 전송
  //  /users/email/vfcode
  //

  Future<bool> sendEmailVfCode(String email, String vfCode) async {
    try {
      LOG('--> API sendEmailVfCode : $email / $vfCode');
      final response = await http.post(
        Uri.parse(httpUrl + '/users/email/vfcode'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'vfCode': vfCode
        })
      );
      LOG('--> API sendEmailVfCode response : ${response.statusCode} / ${response.body}');
      if (isSuccess(response.statusCode)) {
        return true;
      }
    } catch (e) {
      LOG('--> API sendEmailVfCode error : $e');
    }
    return false;
  }

  //////////////////////////////////////////////////////////////////////////
  //
  //  Email 인증링크 클릭
  //  /users/email/vflink/{vfLinkID}
  //

  sendEmailVfCodeLink(String sha256Token) async {
    try {
      LOG('--> API sendEmailVfCodeLink : $sha256Token');
      final response = await http.get(
          Uri.parse(httpUrl + '/users/email/vflink/{$sha256Token}'),
      );
      LOG('--> API sendEmailVfCodeLink response : ${response.statusCode} / ${response.body}');
      if (isSuccess(response.statusCode)) {
        var result = jsonDecode(response.body)['result'];
        return result;
      }
    } catch (e) {
      LOG('--> API sendEmailVfCodeLink error : $e');
    }
    return null;
  }

  //////////////////////////////////////////////////////////////////////////
  //
  //  Email 인증 완료 여부
  //  /users/email/{email}/dup
  //

  Future<bool?> checkEmailVfComplete(String vfCode) async {
    try {
      LOG('--> API checkEmailVfComplete : $vfCode');
      final response = await http.get(
        Uri.parse(httpUrl + '/users/email/vfcode/${vfCode}'),
      );
      LOG('--> API checkEmailVfComplete response : ${response.statusCode} / ${response.body}');
      if (isSuccess(response.statusCode)) {
        var json = jsonDecode(response.body);
        var result = json['result'] != null ? STR(json['result']['email']) : '';
        LOG('--> API checkEmailVfComplete result : ${json['result']}');
        return result.isNotEmpty;
      }
    } catch (e) {
      LOG('--> API checkEmailVfComplete error : $e');
    }
    return null;
  }

  //////////////////////////////////////////////////////////////////////////
  //
  //  Nick 중복 체크
  //  /nick/{nickId}/dup
  //

  checkNickname(String nickId) async {
    try {
      LOG('--> API checkNickname : $nickId');
      final response = await http.get(
        Uri.parse(httpUrl + '/users/nick/$nickId/dup'),
      );
      LOG('--> API checkNickname response : ${response.statusCode} / ${response.body}');
      if (isSuccess(response.statusCode)) {
        var result = BOL(jsonDecode(response.body)['result']);
        return !result;
      }
    } catch (e) {
      LOG('--> API checkNickname error : $e');
    }
    return null;
  }

  //////////////////////////////////////////////////////////////////////////
  //
  //  유저 생성
  //  /user
  //

  Future<bool> createUser(
    String name,
    String socialNo,
    String email,
    String nickId,
    String subTitle,
    String desc,
    String address,
    String sig,
    String type,
    String authToken,
    {
      Function(LoginErrorType, String?)? onError,
    }
  ) async {
    try {
      LOG('--> API createUser : $name, $socialNo, $email, $nickId, '
          '$subTitle, $desc, $address, $sig, $type, $authToken');
      final response = await http.post(
          Uri.parse(httpUrl + '/users/createUser'),
          headers: {
            'accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'name':         name,
            'socialNo':     socialNo,
            'email':        email,
            'nickId':       nickId,
            'subTitle':     subTitle,
            'description':  desc,
            'address':      address,
            'sig':          sig,
            'type':         type,
            'authToken':    authToken,
          })
      );
      LOG('--> API createUser response : ${response.statusCode} / ${response.body}');
      if (isSuccess(response.statusCode)) {
        return true; // null is success
      } else {
        var resultJson = jsonDecode(response.body);
        var errorCode  = STR(resultJson['err' ]?['code']);
        LOG('--> API createUser error : $errorCode');
        if (onError != null) onError(LoginErrorType.code, errorCode);
      }
    } catch (e) {
      LOG('--> API createUser error : $e');
    }
    return false;
  }


  //////////////////////////////////////////////////////////////////////////
  //
  //  유저 로그인 Secret Key
  //  /auth/nick/{email}/secret-key
  //

  Future<String?> getSecretKey(
      String nickId,
      String email,
      String publicKey,
      {
        Function(LoginErrorType, String?)? onError,
      }
    ) async {
    try {
      LOG('--> API getSecretKey : $nickId / $email / $publicKey');
      final response = await http.post(
        Uri.parse(httpUrl + '/auth/nick/$email/secret-key'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pubKey': publicKey,
          'nickId': nickId
        })
      );
      LOG('--> API getSecretKey response : ${response.statusCode} / ${response.body}');
      var resultJson = jsonDecode(response.body);
      if (isSuccess(response.statusCode)) {
        if (resultJson['result'] != null) {
          var serverKey = STR(resultJson['result']['pubKey']);
          return serverKey;
        }
      } else {
        var errorCode = STR(resultJson['err' ]?['code']);
        LOG('--> API loginUser error : $errorCode');
        if (onError != null) onError(LoginErrorType.code, errorCode);
      }
    } catch (e) {
      LOG('--> API getSecretKey error : $e');
    }
    return null;
  }


  //////////////////////////////////////////////////////////////////////////
  //
  //  유저 로그인
  //  /auth/sign-in/{email}
  //

  Future<bool> loginUser(
      String nickId,
      String type,
      String email,
      String authToken, // or Sig (for email)
      {
        Function(LoginErrorType, String?)? onError,
      }
    ) async {
    try {
      LOG('------> API loginUser [$email] : $nickId, $type, $authToken');
      final response = await http.post(
        Uri.parse(httpUrl + '/auth/sign-in/$email'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'type': type,
          'nickId': nickId,
          'authToken': authToken,
        })
      );
      LOG('--> API loginUser response :'
        ' ${response.statusCode} / ${response.body}');
      var resultJson = jsonDecode(response.body);
      if (isSuccess(response.statusCode)) {
        if (resultJson['result'] != null) {
          var jwt = STR(resultJson['result']['jwt']);
          var uid = STR(resultJson['result']['uid']);
          await UserHelper().setUser(uid: uid);
          await UserHelper().setJwt(jwt);
          LOG('--> API loginUser success [$type] : $jwt');
          return true;
        }
      } else {
        var errorCode = STR(resultJson['err' ]?['code']);
        LOG('--> API loginUser error : $errorCode');
        if (onError != null) onError(LoginErrorType.code, errorCode);
      }
    } catch (e) {
      LOG('--> API loginUser error : $e');
    }
    return false;
  }

  //////////////////////////////////////////////////////////////////////////
  //
  //  유저 Nick 추가 (JWT)
  //  /users/nick/{newNickId}
  //

  Future<bool> addAccount(
      String nickId,
      String address,
      String sig,
    {
      String? subTitle,
      String? desc,
      Function(LoginErrorType, String?)? onError,
    }
  ) async {
    var jwt = await AesManager().localJwt;
    if (jwt == null) {
      return false;
    }
    LOG('--> API addAccount : $nickId (${Uri.encodeFull(nickId)}), $address, $sig / $subTitle, $desc - $jwt');
    if (STR(jwt).isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse(httpUrl + '/users/nick/${nickId}'),
          headers: {
            'accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwt',
          },
          body: jsonEncode({
            'sig'         : sig,
            'address'     : address,
            'subTitle'    : subTitle ?? '',
            'description' : desc ?? '',
          })
        );
        LOG('--> API addAddress response : ${response.statusCode} / ${response
            .body}');
        var resultJson = jsonDecode(response.body);
        if (isSuccess(response.statusCode)) {
          return STR(resultJson['result']['address']).isNotEmpty;
        } else {
          var errorCode = STR(resultJson['err' ]?['code']);
          LOG('--> API addAccount error : $errorCode');
          if (onError != null) onError(LoginErrorType.code, errorCode);
        }
      } catch (e) {
        LOG('--> API addAddress error : $e');
      }
    }
    return false;
  }


  //////////////////////////////////////////////////////////////////////////
  //
  //  유저 정보 조회 (JWT)
  //  /users/{uid}
  //

  Future<JSON?> getUserInfo({
      Function(LoginErrorType, String?)? onError,
    }) async {
    try {
      var jwt = await AesManager().localJwt;
      if (jwt == null) {
        return null;
      }
      LOG('--> API getUserInfo : $jwt');
      final response = await http.get(
        Uri.parse(httpUrl + '/users/info'),
        headers: {
          'Authorization': 'Bearer $jwt',
        },
      );
      LOG('--> API getUserInfo response : ${response.statusCode} / ${response.body}');
      var resultJson = jsonDecode(response.body);
      if (isSuccess(response.statusCode)) {
        return resultJson['result'];
      } else {
        var errorCode = STR(resultJson['err' ]?['code']);
        LOG('--> API getUserInfo fail : $errorCode');
        if (onError != null) onError(LoginErrorType.code, errorCode);
      }
    } catch (e) {
      LOG('--> API getUserInfo error : $e');
    }
    return null;
  }

  //////////////////////////////////////////////////////////////////////////
  //
  //  유저 정보 변경 (JWT)
  //  /users/info
  //

  Future<bool?> setUserInfo(
    String address,
    String sig,
  {
    String? subTitle,
    String? desc,
    String? imageUrl,
    Function(LoginErrorType, String?)? onError,
  }) async {
    try {
      var jwt = await AesManager().localJwt;
      if (jwt == null) {
        return null;
      }
      LOG('--> API setUserInfo : $address / $sig / $subTitle / $desc');
      final response = await http.post(
        Uri.parse(httpUrl + '/users/info'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({
          'sig'         : sig,
          'address'     : address,
          'subTitle'    : subTitle ?? '',
          'description' : desc ?? '',
          'image'       : imageUrl ?? '',
        })
      );
      LOG('--> API setUserInfo response : ${response.statusCode} / ${response.body}');
      var resultJson = jsonDecode(response.body);
      if (isSuccess(response.statusCode)) {
        return true;
      } else {
        var errorCode = STR(resultJson['err' ]?['code']);
        LOG('--> API getUserInfo error : $errorCode');
        if (onError != null) onError(LoginErrorType.code, errorCode);
      }
      return false;
    } catch (e) {
      LOG('--> API setUserInfo error : $e');
    }
    return null;
  }

  //////////////////////////////////////////////////////////////////////////
  //
  //  유저 탈퇴 신청 (JWT)
  //  POST: /auth/withdraw
  //

  Future<String?> setWithdrawUser(
    {
      Function(LoginErrorType, String?)? onError,
    }) async {
    try {
      var jwt = await AesManager().localJwt;
      if (jwt == null) {
        return null;
      }
      final response = await http.post(
          Uri.parse(httpUrl + '/auth/withdraw'),
          headers: {
            'accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwt',
          },
      );
      LOG('--> API setWithdrawUser response : ${response.statusCode} '
          '/ ${response.body}');
      var resultJson = jsonDecode(response.body);
      if (isSuccess(response.statusCode)) {
        return resultJson['result'];
      } else {
        var errorCode = STR(resultJson['err' ]?['code']);
        LOG('--> API setWithdrawUser server error : $errorCode');
        if (onError != null) onError(LoginErrorType.code, errorCode);
      }
    } catch (e) {
      LOG('--> API setWithdrawUser error : $e');
    }
    return null;
  }

  //////////////////////////////////////////////////////////////////////////
  //
  //  유저 탈퇴 취소 (JWT)
  //  PUT: /auth/withdraw
  //

  Future<bool?> cancelWithdrawUser(
    {
      Function(LoginErrorType, String?)? onError,
    }) async {
    try {
      var jwt = await AesManager().localJwt;
      if (jwt == null) {
        return null;
      }
      final response = await http.put(
        Uri.parse(httpUrl + '/auth/withdraw'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
      );
      LOG('--> API cancelWithdrawUser response : ${response.statusCode} / ${response.body}');
      var resultJson = jsonDecode(response.body);
      if (isSuccess(response.statusCode)) {
        return true;
      } else {
        var errorCode = STR(resultJson['err' ]?['code']);
        LOG('--> API cancelWithdrawUser server error : $errorCode');
        if (onError != null) onError(LoginErrorType.code, errorCode);
      }
      return false;
    } catch (e) {
      LOG('--> API cancelWithdrawUser error : $e');
    }
    return null;
  }

  //////////////////////////////////////////////////////////////////////////
  //
  //  본인 인증 저장
  //  POST: /auth/cert
  //

  Future<bool?> setIdentity(
    String impUID, {Function(String)? onError}) async {
    LOG('--> API setIdentity : $impUID');
    try {
      var jwt = await AesManager().localJwt;
      if (jwt == null) {
        return false;
      }
      final response = await http.put(
          Uri.parse(httpUrl + '/auth/cert'),
          headers: {
            'accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwt',
          },
          body: jsonEncode({
            'imp_uid'  : impUID,
          })
      );
      LOG('--> API setIdentity response : ${response.statusCode} / ${response.body}');
      var resultJson = jsonDecode(response.body);
      if (isSuccess(response.statusCode)) {
        return BOL(resultJson['result']);
      } else {
        var err = resultJson['err'];
        if (err != null && onError != null) {
          onError(STR(err['code']));
          return null;
        }
      }
    } catch (e) {
      LOG('--> API setIdentity error : $e');
    }
    return false;
  }

  //////////////////////////////////////////////////////////////////////////
  //
  //  유저 보유 상품 조회 (JWT)
  //  GET: /items/owner
  //

  Future<JSON?> getUserItemList(String ownerAddr) async {
    try {
      var jwt = await AesManager().localJwt;
      if (jwt == null) {
        return null;
      }
      LOG('--> API getUserItemList : $ownerAddr');
      final response = await http.get(
        Uri.parse(httpUrl + '/items/owner?ownerAddr=$ownerAddr'),
        headers: {
          'Authorization': 'Bearer $jwt',
        },
      );
      LOG('--> API getUserItemList response : ${response.statusCode} / ${response.body}');
      if (isSuccess(response.statusCode)) {
        var resultJson = jsonDecode(response.body);
        if (resultJson['result'] != null) {
          return resultJson['result'];
        }
      }
    } catch (e) {
      LOG('--> API getUserItemList error : $e');
    }
    return null;
  }

  //////////////////////////////////////////////////////////////////////////
  //
  //  Seller 정보 조회
  //  /users/seller
  //

  Future<JSON?> getSellerInfo(String address) async {
    try {
      LOG('--> API getSellerInfo : $address');
      final response = await http.get(
        Uri.parse(httpUrl + '/users/seller?address=$address'),
      );
      LOG('--> API getSellerInfo response : ${response.statusCode} / ${response.body}');
      var resultJson = jsonDecode(response.body);
      if (isSuccess(response.statusCode)) {
        return resultJson['result'];
      }
    } catch (e) {
      LOG('--> API getSellerInfo error : $e');
    }
    return null;
  }

  //////////////////////////////////////////////////////////////////////////
  //
  //  상품 카테고리 리스트
  //  /tags
  //

  Future<List?> getCategory() async {
    try {
      LOG('--> API getCategory');
      final response = await http.get(
        Uri.parse(
            httpUrl + '/tags'),
      );
      LOG('--> API getCategory response : ${response.statusCode} / '
          '${response.body}');
      if (isSuccess(response.statusCode)) {
        var resultJson = jsonDecode(response.body);
        return resultJson['result'];
      }
    } catch (e) {
      LOG('--> API getCategory error : $e');
    }
    return null;
  }

  //////////////////////////////////////////////////////////////////////////
  //
  //  상품 리스트
  //  /prods?tagId=&lastId=&pageCnt=
  //

  Future<JSON?> getProductList(
    {String? ownerAddr, int tagId = 0, int lastId = -1, int pageCnt = MARKET_PAGE_COUNT_MAX}) async {
    try {
      var urlStr = httpUrl + '/prods?tagId=$tagId&pageCnt=$pageCnt';
      if (STR(ownerAddr).isNotEmpty) {
        urlStr += '&ownerAddr=$ownerAddr';
      }
      if (lastId >= 0) {
        urlStr += '&lastId=$lastId';
      }
      LOG('--> API getProductList : $ownerAddr / $tagId / $lastId / $pageCnt => $urlStr');
      final response = await http.get(Uri.parse(urlStr));
      LOG('--> API getProductList response : ${response.statusCode} / ${response.body}');
      if (isSuccess(response.statusCode)) {
        var resultJson = jsonDecode(response.body);
        if (resultJson['result'] != null) {
          return resultJson['result'];
        }
      }
    } catch (e) {
      LOG('--> API getProductList error : $e');
    }
    return null;
  }

  //////////////////////////////////////////////////////////////////////////
  //
  //  상품 상세정보
  //   /prods/{prodSaleId}
  //

  Future<JSON?> getProductDetail(String prodSaleId) async {
    try {
      LOG('--> API getProductDetail : $prodSaleId');
      final response = await http.get(
        Uri.parse(httpUrl + '/prods/$prodSaleId'),
      );
      LOG('--> API getProductDetail response : ${response.statusCode} / ${response.body}');
      if (isSuccess(response.statusCode)) {
        var resultJson = jsonDecode(response.body);
        if (resultJson['result'] != null) {
          return resultJson['result'];
        }
      }
    } catch (e) {
      LOG('--> API getProductDetail error : $e');
    }
    return null;
  }

  //////////////////////////////////////////////////////////////////////////
  //
  //  상품 옵션 리스트
  //  /items
  //

  Future<JSON?> getProductItems(String prodSaleId,
    {int type = 1, int lastId = -1, int pageCnt = PAGE_COUNT_MAX}) async {
    try {
      final lastStr = lastId >= 0 ? '&lastId=$lastId' : '';
      LOG('--> API getProductItems : $prodSaleId / $lastStr');
      final response = await http.get(
        Uri.parse(httpUrl + '/items?prodSaleId=$prodSaleId&type=$type&pageCnt=$pageCnt$lastStr'),
      );
      LOG('--> API getProductItems response : ${response.statusCode} / ${response.body}');
      if (isSuccess(response.statusCode)) {
        var resultJson = jsonDecode(response.body);
        if (resultJson['result'] != null) {
          return resultJson['result'];
        }
      }
    } catch (e) {
      LOG('--> API getProductItems error : $e');
    }
    return null;
  }


  //////////////////////////////////////////////////////////////////////////
  //
  //  상품 이미지 옵션 리스트
  //  /prods/{prodSaleId}/imgs
  //

  Future<JSON?> getProductImageItems(String prodSaleId,
    {int lastId = -1, int pageCnt = PAGE_COUNT_MAX}) async {
    try {
      final lastStr = lastId >= 0 ? '&lastId=$lastId' : '';
      LOG('--> API getProductImageItems : $prodSaleId / $lastStr');
      final response = await http.get(
        Uri.parse(httpUrl + '/prods/${prodSaleId}/imgs?pageCnt=$pageCnt$lastStr'),
      );
      LOG('--> API getProductImageItems response : ${response.statusCode} / ${response.body}');
      if (isSuccess(response.statusCode)) {
        var resultJson = jsonDecode(response.body);
        if (resultJson['result'] != null) {
          return resultJson['result'];
        }
      }
    } catch (e) {
      LOG('--> API getProductImageItems error : $e');
    }
    return null;
  }

  //////////////////////////////////////////////////////////////////////////
  //
  //  구매 내역 조회 (JWT)
  //  GET: /purchases/{buyerAddr}
  //

  Future<JSON?> getPurchasesList(
    String buyerAddr, String? startDate, String? endDate,
    {int lastId = -1, int pageCnt = PAGE_COUNT_FULL_MAX}) async {
    try {
      var jwt = await AesManager().localJwt;
      if (jwt == null) {
        return null;
      }
      var urlStr = '/purchases/${buyerAddr}?pageCnt=$pageCnt';
      if (STR(endDate).isNotEmpty) {
        if (STR(startDate).isEmpty) {
          startDate = endDate;
        }
        urlStr += '&startDate=$startDate&endDate=$endDate';
      }
      if (lastId >= 0) {
        urlStr += '&lastId=$lastId';
      }
      LOG('--> API getPurchasesList : $urlStr');
      final response = await http.get(
          Uri.parse(httpUrl + urlStr),
          headers: {
            'Authorization': 'Bearer $jwt',
          },
      );
      LOG('--> API getPurchasesList response : ${response.statusCode} / ${response.body}');
      if (isSuccess(response.statusCode)) {
        var resultJson = jsonDecode(response.body);
        if (resultJson['result'] != null) {
          return resultJson['result'];
        }
      }
    } catch (e) {
      LOG('--> API getPurchasesList error : $e');
    }
    return null;
  }

  //////////////////////////////////////////////////////////////////////////
  //
  //  구매 요청 (JWT)
  //  POST: /purchases/{prodSaleId}
  //

  Future<JSON?> requestPurchase(
    String prodSaleId, String? itemId, String? imgId) async {
    try {
      var jwt = await AesManager().localJwt;
      if (jwt == null) {
        return null;
      }
      var urlStr = '/purchases/$prodSaleId';
      LOG('--> API requestPurchase : $urlStr / $imgId');
      final response = await http.post(
        Uri.parse(httpUrl + urlStr),
          headers: {
            'accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwt',
          },
          body: jsonEncode({
            'itemId' : itemId,
            'imgId'  : imgId,
          })
      );
      LOG('--> API requestPurchase response : ${response.statusCode} / ${response.body}');
      var resultJson = jsonDecode(response.body);
      if (isSuccess(response.statusCode)) {
        if (resultJson['result'] != null) {
          return resultJson['result'];
        }
      } else {
        return resultJson;
      }
    } catch (e) {
      LOG('--> API requestPurchase error : $e');
    }
    return null;
  }

  //////////////////////////////////////////////////////////////////////////
  //
  //  구매 확인 (JWT)
  //  PUT: /purchases/payment/info
  //

  testCheck() async {
    return await checkPurchase('imp_547454147757');
  }

  Future<JSON?> checkPurchase(String purchaseId) async {
    LOG('--> API checkPurchase : $purchaseId');
    try {
      var jwt = await AesManager().localJwt;
      if (jwt == null) {
        return null;
      }
      var urlStr = '/purchases/payment/info?purchaseId=$purchaseId';
      final response = await http.get(
        Uri.parse(httpUrl + urlStr),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
      );
      LOG('--> API checkPurchase response : ${response.statusCode} / ${response.body}');
      if (isSuccess(response.statusCode)) {
        var resultJson = jsonDecode(response.body);
        return resultJson['result'];
      }
    } catch (e) {
      LOG('--> API checkPurchase error : $e');
    }
    return null;
  }

}