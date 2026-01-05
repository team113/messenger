// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
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

import '/util/new_type.dart';

/// Price of something.
class Price {
  const Price({required this.sum, required this.currency});

  /// [Price] with value of zero with a `G` currency.
  static const zero = Price(sum: Sum(0), currency: Currency('G'));

  /// Constructs a [Price] with `G` currency of the provided [amount].
  Price.g(double amount) : sum = Sum(amount), currency = Currency('G');

  /// Constructs a [Price] with `USDT` currency of the provided [amount].
  Price.usdt(double amount) : sum = Sum(amount), currency = Currency('USDT');

  /// Constructs a [Price] with `USD` currency of the provided [amount].
  Price.usd(double amount) : sum = Sum(amount), currency = Currency('USD');

  /// Constructs a [Price] with `EUR` currency of the provided [amount].
  Price.eur(double amount) : sum = Sum(amount), currency = Currency('EUR');

  /// [Sum] of this [Price].
  final Sum sum;

  /// [Currency] of this [Price].
  final Currency currency;
}

/// Sum of money.
class Sum extends NewType<double> implements Comparable<Sum> {
  const Sum(super.val);

  /// Parses the provided [val] as a [Sum].
  static Sum parse(String val) => Sum(double.parse(val));

  @override
  int compareTo(Sum other) => val.compareTo(other.val);

  @override
  bool operator ==(Object other) {
    return other is Sum && other.val == val;
  }

  @override
  int get hashCode => val.hashCode;
}

/// Currency as alphabetic code in [ISO 4217] format.
///
/// [ISO 4217]: https://iso.org/iso-4217-currency-codes.html
class Currency extends NewType<String> {
  const Currency(super.val);
}
