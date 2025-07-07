import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class FtlLabelsCollector extends RecursiveAstVisitor {
  static final foundings = <String>{};
  int count = 0;

  /// Collects all matches (including dynamic, not strings, etc...)
  static final allProperties = <PropertyAccess>{};

  /// Collects only pure strings.
  static final pureStringsProperties = <PropertyAccess>{};

  static final methods = <MethodInvocation>{};

  /// Collects all caught nodes and returns their labels.
  Set<String> getAllLabels() {
    final caughtLabels = <String>{};

    // Collect properties.
    for (var node in allProperties) {
      final labelName = node.target.toString();
      caughtLabels.add(labelName);
    }

    // Collect methods.
    for (var node in methods) {
      final labelName = node.target.toString();
      caughtLabels.add(labelName);
    }

    return caughtLabels;
  }

  /// Collects methods invocations in file.
  ///
  /// Will be able to catch `l10nfmt({})`.
  @override
  visitMethodInvocation(MethodInvocation node) {
    // final labelName = node.target;
    final methodName = node.methodName.name;

    if (methodName == 'l10nfmt') {
      count++;
      methods.add(node);
      // print('target: $labelName, name: $methodName');
    }

    return super.visitMethodInvocation(node);
  }

  @override
  visitPropertyAccess(PropertyAccess node) {
    final labelName = node.target;
    final propertyName = node.propertyName.name;

    final isL10n = propertyName == 'l10n';

    if (isL10n) {
      count++;
      allProperties.add(node);
      // print(labelName);

      // We collect pure strings to make a difference with all properties
      // which might be useful to track unusual cases.
      if (labelName is StringLiteral) {
        pureStringsProperties.add(node);
      }
    }

    return super.visitPropertyAccess(node);
  }
}
