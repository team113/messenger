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

import '/domain/model/country.dart';
import '/domain/model/operation.dart';
import '/domain/model/price.dart';
import '/domain/model/promo_share.dart';
import '/store/model/operation.dart';

// ignore: todo
// TODO: Change List<Object?> to List<String>.
// Needs https://github.com/google/json_serializable.dart/issues/806

// Sum

Sum fromGraphQLSumToDartSum(String v) => Sum.parse(v);
String fromDartSumToGraphQLSum(Sum v) => v.val.toString();
List<Sum> fromGraphQLListSumToDartListSum(List<Object?> v) =>
    v.map((e) => fromGraphQLSumToDartSum(e as String)).toList();
List<String> fromDartListSumToGraphQLListSum(List<Sum> v) =>
    v.map((e) => fromDartSumToGraphQLSum(e)).toList();
List<Sum>? fromGraphQLListNullableSumToDartListNullableSum(List<Object?>? v) =>
    v?.map((e) => fromGraphQLSumToDartSum(e as String)).toList();
List<String>? fromDartListNullableSumToGraphQLListNullableSum(List<Sum>? v) =>
    v?.map((e) => fromDartSumToGraphQLSum(e)).toList();

Sum? fromGraphQLSumNullableToDartSumNullable(String? v) =>
    v == null ? null : Sum.parse(v);
String? fromDartSumNullableToGraphQLSumNullable(Sum? v) => v?.val.toString();
List<Sum?> fromGraphQLListSumNullableToDartListSumNullable(List<Object?> v) => v
    .map((e) => fromGraphQLSumNullableToDartSumNullable(e as String?))
    .toList();
List<String?> fromDartListSumNullableToGraphQLListSumNullable(List<Sum?> v) =>
    v.map((e) => fromDartSumNullableToGraphQLSumNullable(e)).toList();
List<Sum?>? fromGraphQLListNullableSumNullableToDartListNullableSumNullable(
  List<Object?>? v,
) => v
    ?.map((e) => fromGraphQLSumNullableToDartSumNullable(e as String?))
    .toList();
List<String?>? fromDartListNullableSumNullableToGraphQLListNullableSumNullable(
  List<Sum?>? v,
) => v?.map((e) => fromDartSumNullableToGraphQLSumNullable(e)).toList();

// Currency

Currency fromGraphQLCurrencyToDartCurrency(String v) => Currency(v);
String fromDartCurrencyToGraphQLCurrency(Currency v) => v.val;
List<Currency> fromGraphQLListCurrencyToDartListCurrency(List<Object?> v) =>
    v.map((e) => fromGraphQLCurrencyToDartCurrency(e as String)).toList();
List<String> fromDartListCurrencyToGraphQLListCurrency(List<Currency> v) =>
    v.map((e) => fromDartCurrencyToGraphQLCurrency(e)).toList();
List<Currency>? fromGraphQLListNullableCurrencyToDartListNullableCurrency(
  List<Object?>? v,
) => v?.map((e) => fromGraphQLCurrencyToDartCurrency(e as String)).toList();
List<String>? fromDartListNullableCurrencyToGraphQLListNullableCurrency(
  List<Currency>? v,
) => v?.map((e) => fromDartCurrencyToGraphQLCurrency(e)).toList();

Currency? fromGraphQLCurrencyNullableToDartCurrencyNullable(String? v) =>
    v == null ? null : Currency(v);
String? fromDartCurrencyNullableToGraphQLCurrencyNullable(Currency? v) =>
    v?.val;
List<Currency?> fromGraphQLListCurrencyNullableToDartListCurrencyNullable(
  List<Object?> v,
) => v
    .map((e) => fromGraphQLCurrencyNullableToDartCurrencyNullable(e as String?))
    .toList();
List<String?> fromDartListCurrencyNullableToGraphQLListCurrencyNullable(
  List<Currency?> v,
) =>
    v.map((e) => fromDartCurrencyNullableToGraphQLCurrencyNullable(e)).toList();
List<Currency?>?
fromGraphQLListNullableCurrencyNullableToDartListNullableCurrencyNullable(
  List<Object?>? v,
) => v
    ?.map(
      (e) => fromGraphQLCurrencyNullableToDartCurrencyNullable(e as String?),
    )
    .toList();
List<String?>?
fromDartListNullableCurrencyNullableToGraphQLListNullableCurrencyNullable(
  List<Currency?>? v,
) => v
    ?.map((e) => fromDartCurrencyNullableToGraphQLCurrencyNullable(e))
    .toList();

// OperationId

OperationId fromGraphQLOperationIdToDartOperationId(String v) => OperationId(v);
String fromDartOperationIdToGraphQLOperationId(OperationId v) => v.val;
List<OperationId> fromGraphQLListOperationIdToDartListOperationId(
  List<Object?> v,
) =>
    v.map((e) => fromGraphQLOperationIdToDartOperationId(e as String)).toList();
List<String> fromDartListOperationIdToGraphQLListOperationId(
  List<OperationId> v,
) => v.map((e) => fromDartOperationIdToGraphQLOperationId(e)).toList();
List<OperationId>?
fromGraphQLListNullableOperationIdToDartListNullableOperationId(
  List<Object?>? v,
) => v
    ?.map((e) => fromGraphQLOperationIdToDartOperationId(e as String))
    .toList();
List<String>? fromDartListNullableOperationIdToGraphQLListNullableOperationId(
  List<OperationId>? v,
) => v?.map((e) => fromDartOperationIdToGraphQLOperationId(e)).toList();

OperationId? fromGraphQLOperationIdNullableToDartOperationIdNullable(
  String? v,
) => v == null ? null : OperationId(v);
String? fromDartOperationIdNullableToGraphQLOperationIdNullable(
  OperationId? v,
) => v?.val;
List<OperationId?>
fromGraphQLListOperationIdNullableToDartListOperationIdNullable(
  List<Object?> v,
) => v
    .map(
      (e) =>
          fromGraphQLOperationIdNullableToDartOperationIdNullable(e as String?),
    )
    .toList();
List<String?> fromDartListOperationIdNullableToGraphQLListOperationIdNullable(
  List<OperationId?> v,
) => v
    .map((e) => fromDartOperationIdNullableToGraphQLOperationIdNullable(e))
    .toList();
List<OperationId?>?
fromGraphQLListNullableOperationIdNullableToDartListNullableOperationIdNullable(
  List<Object?>? v,
) => v
    ?.map(
      (e) =>
          fromGraphQLOperationIdNullableToDartOperationIdNullable(e as String?),
    )
    .toList();
List<String?>?
fromDartListNullableOperationIdNullableToGraphQLListNullableOperationIdNullable(
  List<OperationId?>? v,
) => v
    ?.map((e) => fromDartOperationIdNullableToGraphQLOperationIdNullable(e))
    .toList();

// OperationNum

OperationNum fromGraphQLOperationNumToDartOperationNum(String v) =>
    OperationNum(v);
String fromDartOperationNumToGraphQLOperationNum(OperationNum v) => v.val;
List<OperationNum> fromGraphQLListOperationNumToDartListOperationNum(
  List<Object?> v,
) => v
    .map((e) => fromGraphQLOperationNumToDartOperationNum(e as String))
    .toList();
List<String> fromDartListOperationNumToGraphQLListOperationNum(
  List<OperationNum> v,
) => v.map((e) => fromDartOperationNumToGraphQLOperationNum(e)).toList();
List<OperationNum>?
fromGraphQLListNullableOperationNumToDartListNullableOperationNum(
  List<Object?>? v,
) => v
    ?.map((e) => fromGraphQLOperationNumToDartOperationNum(e as String))
    .toList();
List<String>? fromDartListNullableOperationNumToGraphQLListNullableOperationNum(
  List<OperationNum>? v,
) => v?.map((e) => fromDartOperationNumToGraphQLOperationNum(e)).toList();

OperationNum? fromGraphQLOperationNumNullableToDartOperationNumNullable(
  String? v,
) => v == null ? null : OperationNum(v);
String? fromDartOperationNumNullableToGraphQLOperationNumNullable(
  OperationNum? v,
) => v?.val;
List<OperationNum?>
fromGraphQLListOperationNumNullableToDartListOperationNumNullable(
  List<Object?> v,
) => v
    .map(
      (e) => fromGraphQLOperationNumNullableToDartOperationNumNullable(
        e as String?,
      ),
    )
    .toList();
List<String?> fromDartListOperationNumNullableToGraphQLListOperationNumNullable(
  List<OperationNum?> v,
) => v
    .map((e) => fromDartOperationNumNullableToGraphQLOperationNumNullable(e))
    .toList();
List<OperationNum?>?
fromGraphQLListNullableOperationNumNullableToDartListNullableOperationNumNullable(
  List<Object?>? v,
) => v
    ?.map(
      (e) => fromGraphQLOperationNumNullableToDartOperationNumNullable(
        e as String?,
      ),
    )
    .toList();
List<String?>?
fromDartListNullableOperationNumNullableToGraphQLListNullableOperationNumNullable(
  List<OperationNum?>? v,
) => v
    ?.map((e) => fromDartOperationNumNullableToGraphQLOperationNumNullable(e))
    .toList();

// OperationVersion

OperationVersion fromGraphQLOperationVersionToDartOperationVersion(String v) =>
    OperationVersion(v);
String fromDartOperationVersionToGraphQLOperationVersion(OperationVersion v) =>
    v.toString();
List<OperationVersion>
fromGraphQLListOperationVersionToDartListOperationVersion(List<Object?> v) => v
    .map((e) => fromGraphQLOperationVersionToDartOperationVersion(e as String))
    .toList();
List<String> fromDartListOperationVersionToGraphQLListOperationVersion(
  List<OperationVersion> v,
) =>
    v.map((e) => fromDartOperationVersionToGraphQLOperationVersion(e)).toList();
List<OperationVersion>?
fromGraphQLListNullableOperationVersionToDartListNullableOperationVersion(
  List<Object?>? v,
) => v
    ?.map((e) => fromGraphQLOperationVersionToDartOperationVersion(e as String))
    .toList();
List<String>?
fromDartListNullableOperationVersionToGraphQLListNullableOperationVersion(
  List<OperationVersion>? v,
) => v
    ?.map((e) => fromDartOperationVersionToGraphQLOperationVersion(e))
    .toList();

OperationVersion?
fromGraphQLOperationVersionNullableToDartOperationVersionNullable(String? v) =>
    v == null ? null : OperationVersion(v);
String? fromDartOperationVersionNullableToGraphQLOperationVersionNullable(
  OperationVersion? v,
) => v?.toString();
List<OperationVersion?>
fromGraphQLListOperationVersionNullableToDartListOperationVersionNullable(
  List<Object?> v,
) => v
    .map(
      (e) => fromGraphQLOperationVersionNullableToDartOperationVersionNullable(
        e as String?,
      ),
    )
    .toList();
List<String?>
fromDartListOperationVersionNullableToGraphQLListOperationVersionNullable(
  List<OperationVersion?> v,
) => v
    .map(
      (e) =>
          fromDartOperationVersionNullableToGraphQLOperationVersionNullable(e),
    )
    .toList();
List<OperationVersion?>?
fromGraphQLListNullableOperationVersionNullableToDartListNullableOperationVersionNullable(
  List<Object?>? v,
) => v
    ?.map(
      (e) => fromGraphQLOperationVersionNullableToDartOperationVersionNullable(
        e as String?,
      ),
    )
    .toList();
List<String?>?
fromDartListNullableOperationVersionNullableToGraphQLListNullableOperationVersionNullable(
  List<OperationVersion?>? v,
) => v
    ?.map(
      (e) =>
          fromDartOperationVersionNullableToGraphQLOperationVersionNullable(e),
    )
    .toList();

// CountryCode

CountryCode fromGraphQLCountryCodeToDartCountryCode(String v) => CountryCode(v);
String fromDartCountryCodeToGraphQLCountryCode(CountryCode v) => v.val;
List<CountryCode> fromGraphQLListCountryCodeToDartListCountryCode(
  List<Object?> v,
) =>
    v.map((e) => fromGraphQLCountryCodeToDartCountryCode(e as String)).toList();
List<String> fromDartListCountryCodeToGraphQLListCountryCode(
  List<CountryCode> v,
) => v.map((e) => fromDartCountryCodeToGraphQLCountryCode(e)).toList();
List<CountryCode>?
fromGraphQLListNullableCountryCodeToDartListNullableCountryCode(
  List<Object?>? v,
) => v
    ?.map((e) => fromGraphQLCountryCodeToDartCountryCode(e as String))
    .toList();
List<String>? fromDartListNullableCountryCodeToGraphQLListNullableCountryCode(
  List<CountryCode>? v,
) => v?.map((e) => fromDartCountryCodeToGraphQLCountryCode(e)).toList();

CountryCode? fromGraphQLCountryCodeNullableToDartCountryCodeNullable(
  String? v,
) => v == null ? null : CountryCode(v);
String? fromDartCountryCodeNullableToGraphQLCountryCodeNullable(
  CountryCode? v,
) => v?.val;
List<CountryCode?>
fromGraphQLListCountryCodeNullableToDartListCountryCodeNullable(
  List<Object?> v,
) => v
    .map(
      (e) =>
          fromGraphQLCountryCodeNullableToDartCountryCodeNullable(e as String?),
    )
    .toList();
List<String?> fromDartListCountryCodeNullableToGraphQLListCountryCodeNullable(
  List<CountryCode?> v,
) => v
    .map((e) => fromDartCountryCodeNullableToGraphQLCountryCodeNullable(e))
    .toList();
List<CountryCode?>?
fromGraphQLListNullableCountryCodeNullableToDartListNullableCountryCodeNullable(
  List<Object?>? v,
) => v
    ?.map(
      (e) =>
          fromGraphQLCountryCodeNullableToDartCountryCodeNullable(e as String?),
    )
    .toList();
List<String?>?
fromDartListNullableCountryCodeNullableToGraphQLListNullableCountryCodeNullable(
  List<CountryCode?>? v,
) => v
    ?.map((e) => fromDartCountryCodeNullableToGraphQLCountryCodeNullable(e))
    .toList();

// Invoice

Invoice fromGraphQLInvoiceToDartInvoice(String v) => Invoice(v);
String fromDartInvoiceToGraphQLInvoice(Invoice v) => v.val;
List<Invoice> fromGraphQLListInvoiceToDartListInvoice(List<Object?> v) =>
    v.map((e) => fromGraphQLInvoiceToDartInvoice(e as String)).toList();
List<String> fromDartListInvoiceToGraphQLListInvoice(List<Invoice> v) =>
    v.map((e) => fromDartInvoiceToGraphQLInvoice(e)).toList();
List<Invoice>? fromGraphQLListNullableInvoiceToDartListNullableInvoice(
  List<Object?>? v,
) => v?.map((e) => fromGraphQLInvoiceToDartInvoice(e as String)).toList();
List<String>? fromDartListNullableInvoiceToGraphQLListNullableInvoice(
  List<Invoice>? v,
) => v?.map((e) => fromDartInvoiceToGraphQLInvoice(e)).toList();

Invoice? fromGraphQLInvoiceNullableToDartInvoiceNullable(String? v) =>
    v == null ? null : Invoice(v);
String? fromDartInvoiceNullableToGraphQLInvoiceNullable(Invoice? v) => v?.val;
List<Invoice?> fromGraphQLListInvoiceNullableToDartListInvoiceNullable(
  List<Object?> v,
) => v
    .map((e) => fromGraphQLInvoiceNullableToDartInvoiceNullable(e as String?))
    .toList();
List<String?> fromDartListInvoiceNullableToGraphQLListInvoiceNullable(
  List<Invoice?> v,
) => v.map((e) => fromDartInvoiceNullableToGraphQLInvoiceNullable(e)).toList();
List<Invoice?>?
fromGraphQLListNullableInvoiceNullableToDartListNullableInvoiceNullable(
  List<Object?>? v,
) => v
    ?.map((e) => fromGraphQLInvoiceNullableToDartInvoiceNullable(e as String?))
    .toList();
List<String?>?
fromDartListNullableInvoiceNullableToGraphQLListNullableInvoiceNullable(
  List<Invoice?>? v,
) => v?.map((e) => fromDartInvoiceNullableToGraphQLInvoiceNullable(e)).toList();

// OperationsCursor

OperationsCursor fromGraphQLOperationsCursorToDartOperationsCursor(String v) =>
    OperationsCursor(v);
String fromDartOperationsCursorToGraphQLOperationsCursor(OperationsCursor v) =>
    v.val;
List<OperationsCursor>
fromGraphQLListOperationsCursorToDartListOperationsCursor(List<Object?> v) => v
    .map((e) => fromGraphQLOperationsCursorToDartOperationsCursor(e as String))
    .toList();
List<String> fromDartListOperationsCursorToGraphQLListOperationsCursor(
  List<OperationsCursor> v,
) =>
    v.map((e) => fromDartOperationsCursorToGraphQLOperationsCursor(e)).toList();
List<OperationsCursor>?
fromGraphQLListNullableOperationsCursorToDartListNullableOperationsCursor(
  List<Object?>? v,
) => v
    ?.map((e) => fromGraphQLOperationsCursorToDartOperationsCursor(e as String))
    .toList();
List<String>?
fromDartListNullableOperationsCursorToGraphQLListNullableOperationsCursor(
  List<OperationsCursor>? v,
) => v
    ?.map((e) => fromDartOperationsCursorToGraphQLOperationsCursor(e))
    .toList();

OperationsCursor?
fromGraphQLOperationsCursorNullableToDartOperationsCursorNullable(String? v) =>
    v == null ? null : OperationsCursor(v);
String? fromDartOperationsCursorNullableToGraphQLOperationsCursorNullable(
  OperationsCursor? v,
) => v?.val;
List<OperationsCursor?>
fromGraphQLListOperationsCursorNullableToDartListOperationsCursorNullable(
  List<Object?> v,
) => v
    .map(
      (e) => fromGraphQLOperationsCursorNullableToDartOperationsCursorNullable(
        e as String?,
      ),
    )
    .toList();
List<String?>
fromDartListOperationsCursorNullableToGraphQLListOperationsCursorNullable(
  List<OperationsCursor?> v,
) => v
    .map(
      (e) =>
          fromDartOperationsCursorNullableToGraphQLOperationsCursorNullable(e),
    )
    .toList();
List<OperationsCursor?>?
fromGraphQLListNullableOperationsCursorNullableToDartListNullableOperationsCursorNullable(
  List<Object?>? v,
) => v
    ?.map(
      (e) => fromGraphQLOperationsCursorNullableToDartOperationsCursorNullable(
        e as String?,
      ),
    )
    .toList();
List<String?>?
fromDartListNullableOperationsCursorNullableToGraphQLListNullableOperationsCursorNullable(
  List<OperationsCursor?>? v,
) => v
    ?.map(
      (e) =>
          fromDartOperationsCursorNullableToGraphQLOperationsCursorNullable(e),
    )
    .toList();

// Percentage

Percentage fromGraphQLPercentageToDartPercentage(String v) => Percentage(v);
String fromDartPercentageToGraphQLPercentage(Percentage v) => v.val;
List<Percentage> fromGraphQLListPercentageToDartListPercentage(
  List<Object?> v,
) => v.map((e) => fromGraphQLPercentageToDartPercentage(e as String)).toList();
List<String> fromDartListPercentageToGraphQLListPercentage(
  List<Percentage> v,
) => v.map((e) => fromDartPercentageToGraphQLPercentage(e)).toList();
List<Percentage>? fromGraphQLListNullablePercentageToDartListNullablePercentage(
  List<Object?>? v,
) => v?.map((e) => fromGraphQLPercentageToDartPercentage(e as String)).toList();
List<String>? fromDartListNullablePercentageToGraphQLListNullablePercentage(
  List<Percentage>? v,
) => v?.map((e) => fromDartPercentageToGraphQLPercentage(e)).toList();

Percentage? fromGraphQLPercentageNullableToDartPercentageNullable(String? v) =>
    v == null ? null : Percentage(v);
String? fromDartPercentageNullableToGraphQLPercentageNullable(Percentage? v) =>
    v?.val;
List<Percentage?> fromGraphQLListPercentageNullableToDartListPercentageNullable(
  List<Object?> v,
) => v
    .map(
      (e) =>
          fromGraphQLPercentageNullableToDartPercentageNullable(e as String?),
    )
    .toList();
List<String?> fromDartListPercentageNullableToGraphQLListPercentageNullable(
  List<Percentage?> v,
) => v
    .map((e) => fromDartPercentageNullableToGraphQLPercentageNullable(e))
    .toList();
List<Percentage?>?
fromGraphQLListNullablePercentageNullableToDartListNullablePercentageNullable(
  List<Object?>? v,
) => v
    ?.map(
      (e) =>
          fromGraphQLPercentageNullableToDartPercentageNullable(e as String?),
    )
    .toList();
List<String?>?
fromDartListNullablePercentageNullableToGraphQLListNullablePercentageNullable(
  List<Percentage?>? v,
) => v
    ?.map((e) => fromDartPercentageNullableToGraphQLPercentageNullable(e))
    .toList();
