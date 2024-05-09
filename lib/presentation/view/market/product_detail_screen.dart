import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:larba_00/common/common_package.dart';
import 'package:larba_00/common/const/utils/uihelper.dart';
import 'package:larba_00/common/provider/market_provider.dart';
import 'package:larba_00/domain/model/product_model.dart';

import '../../../common/const/constants.dart';
import '../../../common/const/utils/convertHelper.dart';
import '../../../common/const/utils/languageHelper.dart';
import '../../../common/const/widget/dialog_utils.dart';
import '../../../common/const/widget/disabled_button.dart';
import '../../../common/const/widget/primary_button.dart';
import '../../../domain/viewModel/market_view_model.dart';
import 'product_buy_screen.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  ProductDetailScreen({super.key, required this.isShowSeller, required this.isCanBuy});
  static String get routeName => 'productDetailScreen';
  final bool isShowSeller;
  final bool isCanBuy;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late MarketViewModel _viewModel;

  @override
  void initState() {
    final prov = ref.read(marketProvider);
    prov.optionIndex = 0;
    _viewModel = MarketViewModel(prov);
    LOG('---> reset index to 0');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final prov = ref.watch(marketProvider);
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(TR(context, '상품 정보')),
          centerTitle: true,
          titleTextStyle: typo16bold,
          backgroundColor: Colors.white,
        ),
        backgroundColor: Colors.white,
        body: ListView(
          shrinkWrap: true,
          children: [
            _viewModel.showProductDetail(widget.isShowSeller),
            _viewModel.showProductInfo(),
          ]
        ),
        bottomNavigationBar: widget.isCanBuy ? IS_DEV_MODE ?
        OpenContainer(
          transitionType: ContainerTransitionType.fadeThrough,
          closedBuilder: (context, builder) {
            return PrimaryButton(
              text: TR(context, '구매하기'),
              round: 0,
            );
          },
          openBuilder: (context, builder) {
            return ProductBuyScreen();
          },
        ) : DisabledButton(
          text: TR(context, '구매하기'),
        ) : null
      ),
    );
  }
}
