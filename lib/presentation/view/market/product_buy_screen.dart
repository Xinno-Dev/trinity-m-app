import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trinity_m_00/common/provider/login_provider.dart';
import 'package:trinity_m_00/presentation/view/market/payment_done_screen.dart';
import '../../../../common/common_package.dart';
import '../../../../common/const/utils/uihelper.dart';
import '../../../../common/provider/market_provider.dart';
import '../../../../domain/model/product_model.dart';

import '../../../common/const/constants.dart';
import '../../../common/const/utils/convertHelper.dart';
import '../../../common/const/utils/languageHelper.dart';
import '../../../common/const/widget/dialog_utils.dart';
import '../../../common/const/widget/disabled_button.dart';
import '../../../common/const/widget/primary_button.dart';
import '../../../domain/viewModel/market_view_model.dart';
import '../../../domain/viewModel/profile_view_model.dart';
import '../profile/profile_Identity_screen.dart';
import 'payment_screen.dart';
import 'pg/payment_test.dart';

class ProductBuyScreen extends ConsumerStatefulWidget {
  ProductBuyScreen({super.key});
  static String get routeName => 'productBuyScreen';

  @override
  ConsumerState<ProductBuyScreen> createState() => _ProductBuyScreenState();
}

class _ProductBuyScreenState extends ConsumerState<ProductBuyScreen> {
  final controller  = ScrollController();
  late MarketViewModel _viewModel;

  _showFailMessage(BuildContext context) {
    showLoginErrorTextDialog(context, TR('결제에 실패했습니다!'));
  }

  @override
  void initState() {
    final prov = ref.read(marketProvider);
    prov.optionIndex = -1;
    _viewModel = MarketViewModel(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final prov = ref.watch(marketProvider);
    final loginProv = ref.watch(loginProvider);
    return loginProv.isScreenLocked ? lockScreen(context) :
      AnnotatedRegion<SystemUiOverlayStyle>(
        value:SystemUiOverlayStyle(
          systemNavigationBarColor: WHITE,
        ),
        child: SafeArea(
          top: false,
          child: Scaffold(
            appBar: defaultAppBar(TR('구매하기'),
              leading: IconButton(
                onPressed: context.pop,
                icon: Icon(Icons.close),
              ),
            ),
            backgroundColor: Colors.white,
            body: Column(
              children: [
                Expanded(
                  child: ListView(
                      shrinkWrap: true,
                      children: [
                        _viewModel.showBuyBox(),
                      ]
                  ),
                ),
                if (!prov.purchaseReady)
                  Padding(padding: EdgeInsets.all(10),
                    child: Text(TR('* 옵션을 선택해 주세요.'),
                      style: typo12bold.copyWith(color: Colors.red))),
              ],
            ),
            bottomNavigationBar: IS_PAYMENT_READY && prov.purchaseReady ?
            PrimaryButton(
              text: TR('결제하기'),
              round: 0,
              onTap: () {
                loginProv.disableLockScreen();
                LOG('--> userIdentityYN : ${loginProv.userIdentityYN}');
                if (loginProv.userIdentityYN) {
                  _startPurchase();
                } else {
                  // 본인인증이 안되있을경우 본인인증 부터..
                  Navigator.of(context).push(
                      createAniRoute(ProfileIdentityScreen())).then((result) {
                    if (BOL(result)) {
                      loginProv.userInfo!.certUpdt = DateTime.now().toString();
                      _startPurchase();
                    } else {
                      loginProv.enableLockScreen();
                    }
                  });
                }
              },
            ) : DisabledButton(
              text: TR('결제하기'),
            )
          )
        )
      );
  }

  _startPurchase() {
    final prov = ref.read(marketProvider);
    final loginProv = ref.read(loginProvider);
    prov.createPurchaseInfo();
    var data = prov.createPurchaseData(userInfo: loginProv.userInfo!);
    if (data != null) {
      prov.requestPurchaseWithImageId(onError: (error) {
        showLoginErrorTextDialog(context, TR(error));
      }).then((info) {
        if (info != null) {
          var pgCode = PAYMENT_PG;
          if (STR(prov.purchaseInfo?.mid).isNotEmpty) {
            pgCode += '.${STR(prov.purchaseInfo?.mid)}';
          }
          LOG('--> pgCode : $pgCode');
          data.pg = pgCode;
          Navigator.of(context).push(
            createAniRoute(PaymentScreen(PORTONE_IMP_CODE, data))).then((_) {
            loginProv.enableLockScreen();
          });
          return;
        } else if (info == null) {
          _showFailMessage(context);
        } else {
          LOG('--> purchase skip');
        }
        loginProv.enableLockScreen();
      });
    } else {
      loginProv.enableLockScreen();
    }
  }
}
