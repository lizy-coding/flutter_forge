import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/drawing_element.dart';

class DrawingState extends ChangeNotifier {
  final List<DrawingElement> _elements = [];
  DrawingElement? _selectedElement;
  bool _isDragging = false;
  Offset? _dragOffset;
  final List<String> _logs = [];
  static const dragUpdateInterval = Duration(milliseconds: 16);
  final Stopwatch _dragUpdateClock = Stopwatch();
  bool _hasProcessedDragUpdate = false;
  int _elementsVersion = 0;

  List<DrawingElement> get elements => List.unmodifiable(_elements);
  DrawingElement? get selectedElement => _selectedElement;
  bool get isDragging => _isDragging;
  List<String> get logs => List.unmodifiable(_logs);
  int get elementsVersion => _elementsVersion;

  void _addLog(String message) {
    _logs.add(message);
    notifyListeners();
  }

  void addElement(DrawingElement element) {
    _elements.add(element);
    _elementsVersion++;
    _addLog('添加了 ${element.type.name} 元素 (${_elements.length})');
  }

  void removeElement(String elementId) {
    final removed = _elements.firstWhere(
      (e) => e.id == elementId,
      orElse: () => const DrawingElement(
        id: '',
        position: Offset.zero,
        size: Size.zero,
        type: ElementType.rectangle,
      ),
    );
    _elements.removeWhere((element) => element.id == elementId);
    if (removed.id == elementId) _elementsVersion++;
    if (_selectedElement?.id == elementId) {
      _selectedElement = null;
    }
    _addLog('删除了 ${removed.type.name} 元素');
  }

  void updateElement(DrawingElement updatedElement) {
    final index = _elements.indexWhere(
      (element) => element.id == updatedElement.id,
    );
    if (index != -1) {
      _elements[index] = updatedElement;
      _elementsVersion++;
      if (_selectedElement?.id == updatedElement.id) {
        _selectedElement = updatedElement;
      }
      notifyListeners();
    }
  }

  void selectElement(String? elementId) {
    _selectedElement = elementId != null
        ? _elements.firstWhere((element) => element.id == elementId)
        : null;
    if (_selectedElement != null) {
      _addLog('选中了 ${_selectedElement!.type.name} 元素');
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedElement = null;
    _addLog('取消选中');
    notifyListeners();
  }

  void startDrag(Offset position) {
    _isDragging = true;
    _dragOffset = position;
    _dragUpdateClock
      ..reset()
      ..start();
    _hasProcessedDragUpdate = false;
    notifyListeners();
  }

  void updateDrag(Offset position, {bool force = false}) {
    if (_isDragging && _selectedElement != null && _dragOffset != null) {
      if (!force &&
          _hasProcessedDragUpdate &&
          _dragUpdateClock.elapsed < dragUpdateInterval) {
        return;
      }
      final delta = position - _dragOffset!;
      final newPosition = _selectedElement!.position + delta;

      final updatedElement = _selectedElement!.copyWith(position: newPosition);
      updateElement(updatedElement);

      _dragOffset = position;
      _hasProcessedDragUpdate = true;
      _dragUpdateClock.reset();
    }
  }

  void endDrag() {
    _isDragging = false;
    _dragOffset = null;
    _dragUpdateClock.stop();
    _hasProcessedDragUpdate = false;
    notifyListeners();
  }

  DrawingElement? findElementAt(Offset position) {
    for (int i = _elements.length - 1; i >= 0; i--) {
      if (_elements[i].containsPoint(position)) {
        return _elements[i];
      }
    }
    return null;
  }

  void clear() {
    _elements.clear();
    _elementsVersion++;
    _selectedElement = null;
    _isDragging = false;
    _dragOffset = null;
    _addLog('清空画板');
  }

  /// 删除选中的元素
  void deleteSelectedElement() {
    if (_selectedElement != null) {
      _addLog('删除了选中的 ${_selectedElement!.type.name} 元素');
      removeElement(_selectedElement!.id);
    }
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  /// 处理键盘事件
  bool handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.delete ||
          event.logicalKey == LogicalKeyboardKey.backspace) {
        deleteSelectedElement();
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        clearSelection();
        return true;
      }
    }
    return false;
  }
}
