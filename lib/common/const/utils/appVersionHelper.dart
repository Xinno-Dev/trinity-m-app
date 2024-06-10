import 'dart:io';

import 'package:client_information/client_information.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../../common/common_package.dart';
import '../../../common/provider/language_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart' as provider;
import 'package:store_redirect/store_redirect.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/model/app_start_model.dart';
import '../../provider/firebase_provider.dart';
import '../constants.dart';
import 'convertHelper.dart';
import 'dialogHelper.dart';
import 'languageHelper.dart';
import 'localStorageHelper.dart';

bool isUpdateCheckDone = false;

Future<bool> checkAppUpdate(BuildContext context, {var isForceCheck = false}) async {
  if (isUpdateCheckDone) return true;
  isUpdateCheckDone = true;
  LOG('--> checkAppUpdate start');
  var startInfo = await provider.Provider.of<FirebaseProvider>(context,
      listen: false).getAppStartInfo();
  if (startInfo == null) return false;
  // check version from server..
  final versionLocal  = await LocalStorageManager.readData(APP_VERSION_KEY);
  AppVersionData? versionServer = startInfo.versionInfo[Platform.isAndroid ? 'android' : 'ios'];
  final packageInfo   = await PackageInfo.fromPlatform();
  final versionApp    = packageInfo.version;
  if (versionServer != null) {
    final isForceUpdate = versionServer.force_update;
    // final version = ''; // for Dev..
    LOG('--> checkAppUpdate : $versionApp / $versionLocal / ${versionServer.version} [$isForceUpdate]');
    if (checkVersionString(versionApp, versionServer.version, versionLocal ?? '')) {
      if (versionServer.message != null) {
        final dlgMessage = STR(versionServer.message?.text_us);
        var dlgResult = await showAppUpdateDialog(context,
          dlgMessage.isNotEmpty ? dlgMessage : '새버전이 마켓에 출시되었습니다.',
          '${TR('현재 버전')} $versionApp\n${TR('새 버전')} ${versionServer.version}',
          isForceUpdate: isForceUpdate,
        );
        LOG('----> showAppUpdateDialog result : $dlgResult');
        switch (dlgResult) {
          case 1: // move market..
            if (Platform.isAndroid || Platform.isIOS) {
              Future.delayed(Duration(milliseconds: 300)).then((_) {
                StoreRedirect.redirect(
                  androidAppId: "com.xinno.trinity_m_00",
                  iOSAppId: "6503721909"
                );
              });
            }
            return !isForceUpdate;
          case 2: // never show again..
            LocalStorageManager.saveData(APP_VERSION_KEY, versionServer.version);
            break;
        }
      }
    } else {
      if (startInfo.notice_message != null) {
        final noticeMessage = startInfo.notice_message!.message.getText(context);
        final isImageReady = startInfo.notice_message?.image != null &&
            startInfo.notice_message!.image!.url.isNotEmpty;
        if (startInfo.notice_message!.show && (noticeMessage.isNotEmpty || isImageReady)) {
          final infoLocal = await LocalStorageManager.readData(APP_NOTICE_KEY);
          LOG('----> notice check : $infoLocal / ${startInfo.notice_message!.id}');
          if (infoLocal != startInfo.notice_message!.id) {
            Widget? imageWidget;
            if (isImageReady) {
              imageWidget = CachedNetworkImage(
                imageUrl: startInfo.notice_message!.image!.url,
                progressIndicatorBuilder: (context, widget, _) =>
                  SizedBox(
                    height: 150.h,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                errorWidget: (context, error, stackTrace) =>
                const Icon(Icons.error),
              );
            }
            showAppNoticeDialog(context,
                noticeMessage, imageWidget: imageWidget).then((dlgResult) {
              switch (dlgResult) {
                case 2: // never show again..
                  LocalStorageManager.saveData(
                      APP_NOTICE_KEY,
                      startInfo.notice_message!.id);
                  break;
              }
            });
          }
        }
      } else if (isForceCheck) {
        showAppUpdateDialog(context,
          TR('현재 최신 버전입니다.'),
          '${TR('현재 버전')} $versionApp',
          title: TR('앱 버전정보'),
          isForceCheck: true).then((result) {
            if (result == 1) {
              // move to market..
              if (Platform.isAndroid || Platform.isIOS) {
                final appId = Platform.isAndroid ?
                  'com.xinno.trinity_m_00' :
                  'com.xinno.trinity_m_00';
                final url = Uri.parse(
                  Platform.isAndroid
                    ? "market://details?id=$appId"
                    : "https://apps.apple.com/app/id$appId",
                );
                launchUrl(
                  url,
                  mode: LaunchMode.externalApplication,
                );
              }
            }
        });
      }
    }
  }
  return true;
}

checkVersionString(String source, String target, String local) {
  try {
    var source2 = getNumberFromVersion(source);
    var target2 = getNumberFromVersion(target);
    LOG('--> checkVersionString : $source2 / $target2 - $source / $target / $local');
    return local != target && source2 < target2;
  } catch (e) {
    LOG('--> error : $e');
  }
  return false;
}

getNumberFromVersion(String version) {
  var offsetN = [10000, 100, 1];
  var result = 0;
  var arr = version.split('.');
  for (var i=0; i<arr.length; i++) {
    try {
      var value = int.parse(arr[i]);
      result += value * offsetN[i];
      // LOG('--> [$i] : $value * ${offsetN[i]}');
    } catch (e) {
      LOG('--> getNumberFromVersion error : $e');
    }
  }
  return result;
}

Future<String> getDeviceId() async {
  ClientInformation info = await ClientInformation.fetch();
  return info.deviceId;
}

Future<String> getDeviceName() async {
  ClientInformation info = await ClientInformation.fetch();
  return info.osName;
}

