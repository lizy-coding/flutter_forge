import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drawing_element.dart';
import '../state/drawing_state.dart';
import '../services/adsorption_manager.dart';
import 'drawing_canvas.dart';

/// 画板主界面
class DrawingBoard extends StatefulWidget {
  final bool embedInScaffold;

  const DrawingBoard({super.key, this.embedInScaffold = true});

  @override
  State<DrawingBoard> createState() => _DrawingBoardState();
}

class _DrawingBoardState extends State<DrawingBoard> {
  ElementType _selectedTool = ElementType.rectangle;
  Color _selectedColor = Colors.blue;
  double _strokeWidth = 2.0;
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _keyboardFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    AdsorptionManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (!widget.embedInScaffold) return body;
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      onKeyEvent: (event) {
        context.read<DrawingState>().handleKeyEvent(event);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('吸附线画板'),
          backgroundColor: Colors.grey[100],
          elevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                context.read<DrawingState>().clear();
              },
              tooltip: '清空画板',
            ),
            Consumer<DrawingState>(
              builder: (context, drawingState, child) {
                return IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: drawingState.selectedElement != null
                      ? () => drawingState.deleteSelectedElement()
                      : null,
                  tooltip: '删除选中元素',
                );
              },
            ),
          ],
        ),
        body: body,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: Container(
            width: double.infinity,
            color: Colors.white,
            child: Consumer<DrawingState>(
              builder: (context, drawingState, child) {
                return DrawingCanvas(
                  elements: drawingState.elements,
                  elementsVersion: drawingState.elementsVersion,
                  selectedElement: drawingState.selectedElement,
                  onTap: _handleCanvasTap,
                  onPanStart: _handlePanStart,
                  onPanUpdate: _handlePanUpdate,
                  onPanEnd: _handlePanEnd,
                );
              },
            ),
          ),
        ),
        _buildStatusBar(),
      ],
    );
  }

  /// 构建工具栏
  Widget _buildToolbar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 工具选择
            _buildToolButton(
              icon: Icons.crop_square,
              tool: ElementType.rectangle,
              tooltip: '矩形',
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              icon: Icons.circle_outlined,
              tool: ElementType.circle,
              tooltip: '圆形',
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              icon: Icons.remove,
              tool: ElementType.line,
              tooltip: '直线',
            ),
            const SizedBox(width: 16),
            // 分隔线
            Container(width: 1, height: 30, color: Colors.grey[300]),
            const SizedBox(width: 16),
            // 颜色选择
            const Text('颜色: '),
            const SizedBox(width: 8),
            _buildColorButton(Colors.blue),
            const SizedBox(width: 4),
            _buildColorButton(Colors.red),
            const SizedBox(width: 4),
            _buildColorButton(Colors.green),
            const SizedBox(width: 4),
            _buildColorButton(Colors.orange),
            const SizedBox(width: 4),
            _buildColorButton(Colors.purple),
            const SizedBox(width: 16),
            // 线宽选择
            const Text('线宽: '),
            SizedBox(
              width: 100,
              child: Slider(
                value: _strokeWidth,
                min: 1.0,
                max: 10.0,
                divisions: 9,
                label: _strokeWidth.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _strokeWidth = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建工具按钮
  Widget _buildToolButton({
    required IconData icon,
    required ElementType tool,
    required String tooltip,
  }) {
    final isSelected = _selectedTool == tool;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTool = tool;
          });
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[100] : Colors.transparent,
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, color: isSelected ? Colors.blue : Colors.grey[600]),
        ),
      ),
    );
  }

  /// 构建颜色按钮
  Widget _buildColorButton(Color color) {
    final isSelected = _selectedColor == color;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
      ),
    );
  }

  /// 构建状态栏
  Widget _buildStatusBar() {
    return Consumer<DrawingState>(
      builder: (context, drawingState, child) {
        return Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Text(
                '元素数量: ${drawingState.elements.length}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              if (drawingState.selectedElement != null)
                Text(
                  '已选择: ${drawingState.selectedElement!.type.name}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 处理画布点击
  void _handleCanvasTap(Offset position) {
    final drawingState = context.read<DrawingState>();

    // 检查是否点击了现有元素
    final clickedElement = drawingState.findElementAt(position);

    if (clickedElement != null) {
      // 选择元素
      drawingState.selectElement(clickedElement.id);
    } else {
      // 创建新元素
      _createElementAt(position);
      drawingState.clearSelection();
    }
  }

  /// 在指定位置创建元素
  void _createElementAt(Offset position) {
    final drawingState = context.read<DrawingState>();

    // 默认尺寸
    Size defaultSize;
    switch (_selectedTool) {
      case ElementType.rectangle:
        defaultSize = const Size(80, 60);
        break;
      case ElementType.circle:
        defaultSize = const Size(60, 60);
        break;
      case ElementType.line:
        defaultSize = const Size(100, 0);
        break;
    }

    final element = DrawingElement(
      id: DrawingElement.generateId(),
      position: Offset(
        position.dx - defaultSize.width / 2,
        position.dy - defaultSize.height / 2,
      ),
      size: defaultSize,
      type: _selectedTool,
      color: _selectedColor,
      strokeWidth: _strokeWidth,
    );

    drawingState.addElement(element);
  }

  /// 处理拖拽开始
  void _handlePanStart(Offset position) {
    final drawingState = context.read<DrawingState>();
    final element = drawingState.findElementAt(position);

    if (element != null) {
      drawingState.selectElement(element.id);
      drawingState.startDrag(position);
    }
  }

  /// 处理拖拽更新
  void _handlePanUpdate(Offset position) {
    final drawingState = context.read<DrawingState>();

    if (drawingState.isDragging && drawingState.selectedElement != null) {
      // 应用磁吸效果的拖拽逻辑
      final magneticPosition = AdsorptionManager.applyMagneticEffect(
        position,
        drawingState.elements,
        drawingState.selectedElement!,
      );

      drawingState.updateDrag(magneticPosition);
    }
  }

  /// 处理拖拽结束
  void _handlePanEnd() {
    final drawingState = context.read<DrawingState>();

    // 在拖拽结束时应用最终的磁吸效果
    if (drawingState.selectedElement != null) {
      AdsorptionManager.applyMagneticEffect(
        drawingState.selectedElement!.position,
        drawingState.elements,
        drawingState.selectedElement!,
        onElementSnapped: (snappedElement) {
          // 更新元素的最终坐标
          drawingState.updateElement(snappedElement);
        },
      );
    }

    drawingState.endDrag();
  }
}
