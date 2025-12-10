// Copyright © 2025 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '/domain/model/country.dart';
import '/domain/model/native_file.dart';
import '/domain/model/session.dart';
import '/domain/service/session.dart';
import '/l10n/l10n.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';

/// Controller for the [Routes.withdraw] page.
class WithdrawController extends GetxController {
  WithdrawController(this._sessionService);

  /// [IsoCode] of the country selected for withdrawal.
  final Rx<IsoCode?> country = Rx(null);

  /// Currently selected [WithdrawalOption].
  final Rx<WithdrawalOption?> option = Rx(null);

  /// Selected [UsdtNetwork] for [WithdrawalOption.usdt] option selected.
  final Rx<UsdtNetwork?> usdtNetwork = Rx(null);

  /// [TextFieldState] for withdrawal amount input.
  final TextFieldState amountToWithdraw = TextFieldState();

  /// [TextFieldState] for displaying the amount to be sent.
  ///
  /// Intended to be strongly tied to the [amountToWithdraw] changes.
  final TextFieldState amountToSend = TextFieldState(editable: false);

  /// [TextFieldState] for inputting a [WithdrawalOption.usdt] wallet number.
  final TextFieldState usdtWallet = TextFieldState();

  /// [TextFieldState] for inputting a [WithdrawalOption.usdt] memo/tag/etc.
  final TextFieldState usdtMemo = TextFieldState();

  /// [TextFieldState] for inputting a [WithdrawalOption.usdt] crypto platform.
  final TextFieldState usdtPlatform = TextFieldState();

  /// [TextFieldState] for inputting a [WithdrawalOption.paypal] e-mail.
  final TextFieldState payPalEmail = TextFieldState();

  /// [TextFieldState] for inputting a [WithdrawalOption.monobank] account.
  final TextFieldState monobankAccount = TextFieldState();

  /// [TextFieldState] for inputting a [WithdrawalOption.monobank] bank SWIFT
  /// code.
  final TextFieldState monobankSwiftCode = TextFieldState(text: 'CLJUGB21');

  /// [TextFieldState] for inputting a [WithdrawalOption.monobank] bank name.
  final TextFieldState monobankBankName = TextFieldState(
    text: 'Clear Junction Limited',
  );

  /// [TextFieldState] for inputting a [WithdrawalOption.monobank] bank address.
  final TextFieldState monobankBankAddress = TextFieldState(
    text: '15 Kingsway, Longon WC2B 6UN, UK',
  );

  /// [TextFieldState] for inputting a [WithdrawalOption.sepa] account.
  final TextFieldState sepaAccount = TextFieldState();

  /// [TextFieldState] for inputting a [WithdrawalOption.sepa] bank SWIFT code.
  final TextFieldState sepaSwiftCode = TextFieldState();

  /// [TextFieldState] for inputting a [WithdrawalOption.sepa] bank name.
  final TextFieldState sepaBankName = TextFieldState();

  /// [TextFieldState] for inputting a [WithdrawalOption.sepa] bank address.
  final TextFieldState sepaBankAddress = TextFieldState();

  /// [NativeFile] of the currently selected passport file.
  final Rx<NativeFile?> passport = Rx(null);

  /// Indicator whether the [passport] should be blurred or not.
  final RxBool showPassport = RxBool(false);

  /// [TextFieldState] for inputting a expiry date of the [passport].
  final TextFieldState passportExpiry = TextFieldState();

  /// [TextFieldState] for inputting a beneficiary billing name.
  final TextFieldState billingName = TextFieldState();

  /// [TextFieldState] for inputting a beneficiary birthday.
  final TextFieldState billingBirth = TextFieldState();

  /// [TextFieldState] for inputting a beneficiary billing address.
  final TextFieldState billingAddress = TextFieldState();

  /// [TextFieldState] for inputting a beneficiary billing ZIP.
  final TextFieldState billingZip = TextFieldState();

  /// [TextFieldState] for inputting a beneficiary billing e-mail.
  final TextFieldState billingEmail = TextFieldState();

  /// [TextFieldState] for inputting a beneficiary billing phone number.
  final TextFieldState billingPhone = TextFieldState();

  /// Indicator whether all the conditions were approved by the user.
  final RxBool confirmed = RxBool(false);

  /// [SessionService] used for [IpGeoLocation] retrieving.
  final SessionService _sessionService;

  @override
  void onInit() {
    _fetchIp();
    super.onInit();
  }

  /// Sets the [country] to be the provided [code].
  void selectCountry(IsoCode? code) {
    country.value = code;
    option.value ??= WithdrawalOption.values.firstOrNull;
  }

  /// Selects a [passport] file.
  Future<void> pickPassport() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      withData: true,
      lockParentWindow: true,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.isNotEmpty) {
      passport.value = NativeFile.fromPlatformFile(result.files.first);
      showPassport.value = false;
    }
  }

  /// Fetches the current [IpGeoLocation] to update [IsoCode].
  Future<void> _fetchIp() async {
    final IpGeoLocation ip = await _sessionService.fetch();
    selectCountry(IsoCode.fromJson(ip.countryCode));
  }
}

/// Available withdrawal options.
enum WithdrawalOption {
  usdt,
  paypal,
  monobank,
  sepa;

  /// Returns a [l10n] key label associated with this [WithdrawalOption].
  String get l10n => switch (this) {
    .usdt => 'label_usdt'.l10n,
    .paypal => 'label_paypal'.l10n,
    .monobank => 'label_monobank'.l10n,
    .sepa => 'label_sepa_transfer'.l10n,
  };

  /// Returns a [l10n] key label associated with this [WithdrawalOption].
  SvgData get icon => switch (this) {
    .usdt => SvgIcons.withdrawUsdt,
    .paypal => SvgIcons.withdrawPayPal,
    .monobank => SvgIcons.withdrawMonobank,
    .sepa => SvgIcons.withdrawSepa,
  };

  /// Returns whether this [WithdrawalOption] is available in the [IsoCode].
  bool available(IsoCode? code) => switch (this) {
    .usdt => IsoCode.values.toSet(),
    .paypal => {
      IsoCode.DZ,
      IsoCode.AO,
      IsoCode.BJ,
      IsoCode.BW,
      IsoCode.BF,
      IsoCode.BI,
      IsoCode.ET,
      IsoCode.CI,
      IsoCode.CM,
      IsoCode.KE,
      IsoCode.MR,
      IsoCode.MU,
      IsoCode.CV,
      IsoCode.TD,
      IsoCode.KM,
      IsoCode.CD,
      IsoCode.DJ,
      IsoCode.EG,
      IsoCode.ER,
      IsoCode.GA,
      IsoCode.GM,
      IsoCode.GN,
      IsoCode.GW,
      IsoCode.LS,
      IsoCode.MG,
      IsoCode.MW,
      IsoCode.ML,
      IsoCode.YT,
      IsoCode.MA,
      IsoCode.MZ,
      IsoCode.NA,
      IsoCode.NE,
      IsoCode.NG,
      IsoCode.CG,
      IsoCode.RE,
      IsoCode.SH,
      IsoCode.ST,
      IsoCode.SN,
      IsoCode.SC,
      IsoCode.SL,
      IsoCode.SO,
      IsoCode.ZA,
      IsoCode.SZ,
      IsoCode.TZ,
      IsoCode.TG,
      IsoCode.TN,
      IsoCode.UG,
      IsoCode.ZM,
      IsoCode.ZW,
      IsoCode.AI,
      IsoCode.AG,
      IsoCode.AR,
      IsoCode.AW,
      IsoCode.BS,
      IsoCode.BB,
      IsoCode.BZ,
      IsoCode.BM,
      IsoCode.BO,
      IsoCode.BR,
      IsoCode.VG,
      IsoCode.CA,
      IsoCode.KY,
      IsoCode.CL,
      IsoCode.CO,
      IsoCode.CR,
      IsoCode.DM,
      IsoCode.DO,
      IsoCode.EC,
      IsoCode.SV,
      IsoCode.FK,
      IsoCode.GF,
      IsoCode.GL,
      IsoCode.GD,
      IsoCode.GP,
      IsoCode.GT,
      IsoCode.GY,
      IsoCode.HN,
      IsoCode.JM,
      IsoCode.MQ,
      IsoCode.MX,
      IsoCode.MS,
      IsoCode.NI,
      IsoCode.PA,
      IsoCode.PY,
      IsoCode.PE,
      IsoCode.KN,
      IsoCode.LC,
      IsoCode.PM,
      IsoCode.VC,
      IsoCode.SR,
      IsoCode.TT,
      IsoCode.TC,
      IsoCode.US,
      IsoCode.UY,
      IsoCode.VE,
      IsoCode.AM,
      IsoCode.AU,
      IsoCode.BH,
      IsoCode.BT,
      IsoCode.BN,
      IsoCode.KH,
      IsoCode.CN,
      IsoCode.CK,
      IsoCode.FJ,
      IsoCode.PF,
      IsoCode.IN,
      IsoCode.ID,
      IsoCode.IL,
      IsoCode.JP,
      IsoCode.JO,
      IsoCode.KZ,
      IsoCode.KI,
      IsoCode.KW,
      IsoCode.KG,
      IsoCode.LA,
      IsoCode.MY,
      IsoCode.MV,
      IsoCode.MH,
      IsoCode.FM,
      IsoCode.MN,
      IsoCode.NR,
      IsoCode.NP,
      IsoCode.NC,
      IsoCode.NZ,
      IsoCode.NU,
      IsoCode.NF,
      IsoCode.OM,
      IsoCode.PW,
      IsoCode.PG,
      IsoCode.PH,
      IsoCode.QA,
      IsoCode.WS,
      IsoCode.SA,
      IsoCode.SG,
      IsoCode.SB,
      IsoCode.KR,
      IsoCode.LK,
      IsoCode.TW,
      IsoCode.TJ,
      IsoCode.TH,
      IsoCode.TO,
      IsoCode.TM,
      IsoCode.TV,
      IsoCode.AE,
      IsoCode.VU,
      IsoCode.VN,
      IsoCode.WF,
      IsoCode.YE,
      IsoCode.AL,
      IsoCode.AD,
      IsoCode.AT,
      IsoCode.AZ,
      IsoCode.BE,
      IsoCode.BA,
      IsoCode.BG,
      IsoCode.HR,
      IsoCode.CY,
      IsoCode.CZ,
      IsoCode.DK,
      IsoCode.EE,
      IsoCode.FO,
      IsoCode.FI,
      IsoCode.FR,
      IsoCode.GE,
      IsoCode.DE,
      IsoCode.GR,
      IsoCode.HU,
      IsoCode.IS,
      IsoCode.IE,
      IsoCode.IT,
      IsoCode.LV,
      IsoCode.LI,
      IsoCode.LT,
      IsoCode.LU,
      IsoCode.MK,
      IsoCode.MT,
      IsoCode.MD,
      IsoCode.MC,
      IsoCode.ME,
      IsoCode.NL,
      IsoCode.NO,
      IsoCode.PL,
      IsoCode.PT,
      IsoCode.RO,
      IsoCode.SM,
      IsoCode.RS,
      IsoCode.SK,
      IsoCode.SI,
      IsoCode.ES,
      IsoCode.SJ,
      IsoCode.SE,
      IsoCode.CH,
      IsoCode.UA,
      IsoCode.GB,
      IsoCode.VA,
      IsoCode.RW,
      IsoCode.RU,
      IsoCode.BY,
    },
    .monobank => {IsoCode.UA},
    .sepa => {
      IsoCode.AD,
      IsoCode.AL,
      IsoCode.AT,
      IsoCode.BE,
      IsoCode.BG,
      IsoCode.CH,
      IsoCode.CY,
      IsoCode.CZ,
      IsoCode.DE,
      IsoCode.DK,
      IsoCode.EE,
      IsoCode.ES,
      IsoCode.FI,
      IsoCode.FO,
      IsoCode.FR,
      IsoCode.GB,
      IsoCode.GF,
      IsoCode.GP,
      IsoCode.GR,
      IsoCode.GS,
      IsoCode.HU,
      IsoCode.IC,
      IsoCode.IE,
      IsoCode.IM,
      IsoCode.IS,
      IsoCode.IT,
      IsoCode.JE,
      IsoCode.LI,
      IsoCode.LT,
      IsoCode.LU,
      IsoCode.LV,
      IsoCode.MC,
      IsoCode.MD,
      IsoCode.ME,
      IsoCode.MK,
      IsoCode.MT,
      IsoCode.NL,
      IsoCode.NO,
      IsoCode.PL,
      IsoCode.PT,
      IsoCode.RO,
      IsoCode.RS,
      IsoCode.SE,
      IsoCode.SI,
      IsoCode.SK,
      IsoCode.SM,
      IsoCode.VA,
    },
  }.contains(code);
}

/// Available [WithdrawalOption.usdt] network withdrawal options.
enum UsdtNetwork {
  arbitrumOne,
  optimism,
  plasma,
  polygon,
  solana,
  ton,
  tron;

  /// Returns a [l10n] key label associated with this [UsdtNetwork].
  String get l10n => switch (this) {
    .arbitrumOne => 'label_arbitrum_one'.l10n,
    .optimism => 'label_optimism_op_mainnet'.l10n,
    .plasma => 'label_plasma'.l10n,
    .polygon => 'label_polygon'.l10n,
    .solana => 'label_solana'.l10n,
    .ton => 'label_ton'.l10n,
    .tron => 'label_tron_trc20'.l10n,
  };

  /// Returns a [l10n] key label associated with this [UsdtNetwork].
  SvgData get icon => switch (this) {
    .arbitrumOne => SvgIcons.usdtNetworkArbitrumIcon,
    .optimism => SvgIcons.usdtNetworkOptimismIcon,
    .plasma => SvgIcons.usdtNetworkPlasmaIcon,
    .polygon => SvgIcons.usdtNetworkPolygonIcon,
    .solana => SvgIcons.usdtNetworkSolanaIcon,
    .ton => SvgIcons.usdtNetworkTonIcon,
    .tron => SvgIcons.usdtNetworkTronIcon,
  };
}
