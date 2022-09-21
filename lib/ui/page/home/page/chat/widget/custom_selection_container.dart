// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../controller.dart';

/// [CustomSelectionContainer] manages selected text.
///
///
/// Responsible for creating [_SelectableRegionContainerDelegate] and [SelectionData].
/// Get selected text with [_SelectableRegionContainerDelegate].
/// Writes selected text to [SelectionData].
class CustomSelectionContainer extends StatefulWidget {
  const CustomSelectionContainer({
    super.key,
    required this.selections,
    required this.position,
    required this.type,
    required this.animation,
    required this.child,
  });

  /// Storage [SelectionData].
  final Map<int, List<SelectionData>> selections;

  /// Message position index.
  final int position;

  /// Selected text type.
  final SelectionItem type;

  /// Optional animation that controls a [SwipeableStatus].
  final AnimationController? animation;

  /// Widget in which there will be text to selection.
  final Widget child;

  @override
  State<StatefulWidget> createState() => _CustomSelectionContainerState();
}

/// State of an [CustomSelectionContainer] controls selected text.
class _CustomSelectionContainerState extends State<CustomSelectionContainer> {
  /// Selectable content delegate.
  late final _SelectableRegionContainerDelegate delegate;

  /// Selectable text storage.
  late final SelectionData selectionData;

  /// [GestureRecognizer] recognizes double and triple tap gestures.
  ///
  /// Double-tap selects a word, triple-tap selects all text.
  final Map<Type, GestureRecognizerFactory> _gestureRecognizers =
      <Type, GestureRecognizerFactory>{};

  @override
  void initState() {
    super.initState();
    delegate = _SelectableRegionContainerDelegate();
    delegate.addListener(_selectionChange);

    _gestureRecognizers[SerialTapGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<SerialTapGestureRecognizer>(
      () => SerialTapGestureRecognizer(),
      (SerialTapGestureRecognizer instance) {
        instance.onSerialTapUp = (SerialTapUpDetails details) {
          if (details.count == 2) {
            delegate.handleSelectWord(
              SelectWordSelectionEvent(globalPosition: details.globalPosition),
            );
          }
          if (details.count == 3) {
            delegate.handleSelectAll(const SelectAllSelectionEvent());
          }
          _selectionChange();
        };
      },
    );

    selectionData = SelectionData(widget.type);
    if (widget.selections[widget.position] == null) {
      widget.selections[widget.position] = [selectionData];
    } else {
      widget.selections[widget.position]?.add(selectionData);
    }
  }

  @override
  void dispose() {
    selectionData.data.close();
    widget.selections.remove(widget.position);
    delegate.removeListener(_selectionChange);
    delegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: _gestureRecognizers,
      child: SelectionContainer(
        delegate: delegate,
        child: widget.child,
      ),
    );
  }

  /// Writes data to [selectionData.data].
  void _selectionChange() {
    if (widget.animation == null || widget.animation?.isCompleted == true) {
      final String? oldText = selectionData.data.value;
      final String? newText = delegate.getSelectedContent()?.plainText;
      if (oldText != newText) {
        selectionData.data.value = newText;
      }
    }
  }
}

/// Delegate for [SelectionEvent]s.
///
/// Taken from Flutter framework.
class _SelectableRegionContainerDelegate
    extends MultiSelectableSelectionContainerDelegate {
  /// Storage of [Selectable]s on [SelectionEventType.startEdgeUpdate].
  final Set<Selectable> _hasReceivedStartEvent = <Selectable>{};

  /// Storage of [Selectable]s on [SelectionEventType.endEdgeUpdate].
  final Set<Selectable> _hasReceivedEndEvent = <Selectable>{};

  /// Global position of start of selection.
  Offset? _lastStartEdgeUpdateGlobalPosition;

  /// Global position of end of selection.
  Offset? _lastEndEdgeUpdateGlobalPosition;

  @override
  void remove(Selectable selectable) {
    _hasReceivedStartEvent.remove(selectable);
    _hasReceivedEndEvent.remove(selectable);
    super.remove(selectable);
  }

  /// Get updated selection coordinates.
  void _updateLastEdgeEventsFromGeometries() {
    if (currentSelectionStartIndex != -1) {
      final Selectable start = selectables[currentSelectionStartIndex];
      final Offset localStartEdge =
          start.value.startSelectionPoint!.localPosition +
              Offset(0, -start.value.startSelectionPoint!.lineHeight / 2);
      _lastStartEdgeUpdateGlobalPosition = MatrixUtils.transformPoint(
          start.getTransformTo(null), localStartEdge);
    }
    if (currentSelectionEndIndex != -1) {
      final Selectable end = selectables[currentSelectionEndIndex];
      final Offset localEndEdge = end.value.endSelectionPoint!.localPosition +
          Offset(0, -end.value.endSelectionPoint!.lineHeight / 2);
      _lastEndEdgeUpdateGlobalPosition =
          MatrixUtils.transformPoint(end.getTransformTo(null), localEndEdge);
    }
  }

  @override
  SelectionResult handleSelectAll(SelectAllSelectionEvent event) {
    final SelectionResult result = super.handleSelectAll(event);
    for (final Selectable selectable in selectables) {
      _hasReceivedStartEvent.add(selectable);
      _hasReceivedEndEvent.add(selectable);
    }
    // Synthesize last update event so the edge updates continue to work.
    _updateLastEdgeEventsFromGeometries();
    return result;
  }

  /// Selects a word in a selectable at the location
  /// [SelectWordSelectionEvent.globalPosition].
  @override
  SelectionResult handleSelectWord(SelectWordSelectionEvent event) {
    final SelectionResult result = super.handleSelectWord(event);
    if (currentSelectionStartIndex != -1) {
      _hasReceivedStartEvent.add(selectables[currentSelectionStartIndex]);
    }
    if (currentSelectionEndIndex != -1) {
      _hasReceivedEndEvent.add(selectables[currentSelectionEndIndex]);
    }
    _updateLastEdgeEventsFromGeometries();
    return result;
  }

  @override
  SelectionResult handleClearSelection(ClearSelectionEvent event) {
    final SelectionResult result = super.handleClearSelection(event);
    _hasReceivedStartEvent.clear();
    _hasReceivedEndEvent.clear();
    _lastStartEdgeUpdateGlobalPosition = null;
    _lastEndEdgeUpdateGlobalPosition = null;
    return result;
  }

  @override
  SelectionResult handleSelectionEdgeUpdate(SelectionEdgeUpdateEvent event) {
    if (event.type == SelectionEventType.endEdgeUpdate) {
      _lastEndEdgeUpdateGlobalPosition = event.globalPosition;
    } else {
      _lastStartEdgeUpdateGlobalPosition = event.globalPosition;
    }
    return super.handleSelectionEdgeUpdate(event);
  }

  @override
  void dispose() {
    _hasReceivedStartEvent.clear();
    _hasReceivedEndEvent.clear();
    super.dispose();
  }

  @override
  SelectionResult dispatchSelectionEventToChild(
      Selectable selectable, SelectionEvent event) {
    switch (event.type) {
      case SelectionEventType.startEdgeUpdate:
        _hasReceivedStartEvent.add(selectable);
        ensureChildUpdated(selectable);
        break;
      case SelectionEventType.endEdgeUpdate:
        _hasReceivedEndEvent.add(selectable);
        ensureChildUpdated(selectable);
        break;
      case SelectionEventType.clear:
        _hasReceivedStartEvent.remove(selectable);
        _hasReceivedEndEvent.remove(selectable);
        break;
      case SelectionEventType.selectAll:
      case SelectionEventType.selectWord:
        break;
    }
    return super.dispatchSelectionEventToChild(selectable, event);
  }

  @override
  void ensureChildUpdated(Selectable selectable) {
    if (_lastEndEdgeUpdateGlobalPosition != null &&
        _hasReceivedEndEvent.add(selectable)) {
      final SelectionEdgeUpdateEvent synthesizedEvent =
          SelectionEdgeUpdateEvent.forEnd(
        globalPosition: _lastEndEdgeUpdateGlobalPosition!,
      );
      if (currentSelectionEndIndex == -1) {
        handleSelectionEdgeUpdate(synthesizedEvent);
      }
      selectable.dispatchSelectionEvent(synthesizedEvent);
    }
    if (_lastStartEdgeUpdateGlobalPosition != null &&
        _hasReceivedStartEvent.add(selectable)) {
      final SelectionEdgeUpdateEvent synthesizedEvent =
          SelectionEdgeUpdateEvent.forStart(
        globalPosition: _lastStartEdgeUpdateGlobalPosition!,
      );
      if (currentSelectionStartIndex == -1) {
        handleSelectionEdgeUpdate(synthesizedEvent);
      }
      selectable.dispatchSelectionEvent(synthesizedEvent);
    }
  }

  @override
  void didChangeSelectables() {
    if (_lastEndEdgeUpdateGlobalPosition != null) {
      handleSelectionEdgeUpdate(
        SelectionEdgeUpdateEvent.forEnd(
          globalPosition: _lastEndEdgeUpdateGlobalPosition!,
        ),
      );
    }
    if (_lastStartEdgeUpdateGlobalPosition != null) {
      handleSelectionEdgeUpdate(
        SelectionEdgeUpdateEvent.forStart(
          globalPosition: _lastStartEdgeUpdateGlobalPosition!,
        ),
      );
    }
    final Set<Selectable> selectableSet = selectables.toSet();
    _hasReceivedEndEvent.removeWhere(
        (Selectable selectable) => !selectableSet.contains(selectable));
    _hasReceivedStartEvent.removeWhere(
        (Selectable selectable) => !selectableSet.contains(selectable));
    super.didChangeSelectables();
  }
}
