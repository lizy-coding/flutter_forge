import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;

import '../core/gcode_bounds.dart';
import '../core/gcode_style.dart';
import '../models/toolpath_segment.dart';
import 'toolpath_geometry.dart';
import 'toolpath_viewport.dart';

/// Optional counters of renderer work submitted by the CPU.
///
/// These counters do not measure GPU time or native memory reclamation. Keep
/// one instance for the lifetime of a canvas to compare loading and playback.
class GcodeRenderStats {
  int _geometryBuilds = 0;
  int _vertexUploadBytes = 0;
  int _compositedFrames = 0;
  int _surfaceCreations = 0;
  int _surfaceResizes = 0;
  int _resourceSetsCreated = 0;
  int _resourceSetsCleared = 0;

  int get geometryBuilds => _geometryBuilds;
  int get vertexUploadBytes => _vertexUploadBytes;
  int get compositedFrames => _compositedFrames;
  int get surfaceCreations => _surfaceCreations;
  int get surfaceResizes => _surfaceResizes;
  int get resourceSetsCreated => _resourceSetsCreated;
  int get resourceSetsCleared => _resourceSetsCleared;
  int get activeResourceSets => _resourceSetsCreated - _resourceSetsCleared;
}

/// GPU scene: paths, grid, origin and moving markers share one surface.
class GpuToolpathLayer extends StatefulWidget {
  const GpuToolpathLayer(
      {super.key,
      required this.segments,
      required this.bounds,
      required this.progress,
      required this.style,
      this.onReady,
      this.onError,
      this.stats});
  final List<ToolpathSegment> segments;
  final GcodeBounds? bounds;
  final double progress;
  final GcodeStyle style;
  final VoidCallback? onReady;
  final ValueChanged<Object>? onError;
  final GcodeRenderStats? stats;
  @override
  State<GpuToolpathLayer> createState() => _GpuToolpathLayerState();
}

class _GpuToolpathLayerState extends State<GpuToolpathLayer> {
  _GpuResources? resources;
  Object? error;
  bool _presented = false;
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant GpuToolpathLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.segments, widget.segments)) _presented = false;
  }

  Future<void> _initialize() async {
    try {
      final library = await gpu.ShaderLibrary.fromAsset(
          'packages/gcode_core/shaders/toolpath.shaderbundle');
      if (library == null) throw StateError('Invalid toolpath shader bundle');
      final pipeline = gpu.gpuContext.createRenderPipeline(
          library['ToolpathVertex']!, library['ToolpathFragment']!);
      final guides = gpu.gpuContext.createRenderPipeline(
          library['GuidesVertex']!, library['GuidesFragment']!);
      if (mounted)
        setState(
            () => resources = _GpuResources(pipeline, guides, widget.stats));
    } catch (e) {
      debugPrint('GCODE_GPU_INIT_FAILED $e');
      if (mounted) {
        setState(() => error = e);
        widget.onError?.call(e);
      }
    }
  }

  void _failed(Object failure) {
    if (error != null) return;
    debugPrint('GCODE_GPU_RENDER_FAILED $failure');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        resources?.clear();
        setState(() {
          resources = null;
          error = failure;
        });
        widget.onError?.call(failure);
      }
    });
  }

  void _ready() {
    if (_presented || error != null) return;
    _presented = true;
    final presentedSegments = widget.segments;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          error == null &&
          identical(presentedSegments, widget.segments)) {
        widget.onReady?.call();
      }
    });
  }

  @override
  void dispose() {
    resources?.clear();
    resources = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
          child: Text('GPU 绘制不可用\n$error', textAlign: TextAlign.center));
    }
    if (resources == null)
      return const Center(child: CircularProgressIndicator());
    return CustomPaint(
        painter: _GpuImageCompositor(resources!, widget,
            MediaQuery.devicePixelRatioOf(context), _failed, _ready));
  }
}

class _GpuResources {
  _GpuResources(this.pipeline, this.guides, this.stats) {
    stats?._resourceSetsCreated++;
    final data = Float32List.fromList([0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1]);
    quad = gpu.BufferView(
        gpu.gpuContext.createDeviceBufferWithCopy(ByteData.sublistView(data)),
        offsetInBytes: 0,
        lengthInBytes: data.lengthInBytes);
    // Five small uniforms per frame; four rotating blocks are enough.
    host = gpu.gpuContext.createHostBuffer(blockLengthInBytes: 16 * 1024);
  }
  final GcodeRenderStats? stats;
  bool _cleared = false;
  final gpu.RenderPipeline pipeline;
  final gpu.RenderPipeline guides;
  late final gpu.BufferView quad;
  late final gpu.HostBuffer host;
  ToolpathViewport? viewport;
  GcodeBounds? suppliedBounds;
  gpu.GpuImageSurface? surface;
  gpu.BufferView? vertices;
  List<ToolpathSegment>? segments;
  GcodeBounds? bounds;
  Size? size;
  double? width;
  int vertexCount = 0;
  List<int> prefixVertexCounts = const [0];
  void clear() {
    if (_cleared) return;
    _cleared = true;
    stats?._resourceSetsCleared++;
    surface = null;
    vertices = null;
    segments = null;
    viewport = null;
    suppliedBounds = null;
    bounds = null;
    size = null;
    width = null;
    vertexCount = 0;
    prefixVertexCounts = const [0];
  }

  void prepare(GpuToolpathLayer input, Size newSize, double dpr) {
    final maxWidth = [
      input.style.rapidMove.width,
      input.style.linearMove.width,
      input.style.rapidBackground.width,
      input.style.linearBackground.width
    ].reduce(math.max);
    final changed = !identical(segments, input.segments) ||
        suppliedBounds?.minX != input.bounds?.minX ||
        suppliedBounds?.minY != input.bounds?.minY ||
        suppliedBounds?.maxX != input.bounds?.maxX ||
        suppliedBounds?.maxY != input.bounds?.maxY;
    if (changed || bounds == null) {
      bounds = input.bounds ?? ToolpathViewport.measure(input.segments);
      suppliedBounds = input.bounds;
    }
    if (changed || size != newSize || width != maxWidth) {
      viewport = ToolpathViewport(bounds!, newSize);
      final nextGeometry =
          ToolpathGeometry.build(input.segments, bounds!, newSize, maxWidth);
      stats?._geometryBuilds++;
      stats?._vertexUploadBytes += nextGeometry.vertices.lengthInBytes;
      vertexCount = nextGeometry.vertexCount;
      vertices = vertexCount == 0
          ? null
          : gpu.BufferView(
              gpu.gpuContext.createDeviceBufferWithCopy(
                  ByteData.sublistView(nextGeometry.vertices)),
              offsetInBytes: 0,
              lengthInBytes: nextGeometry.vertices.lengthInBytes);
      prefixVertexCounts = nextGeometry.prefixVertexCounts;
      segments = input.segments;
      size = newSize;
      width = maxWidth;
    }
    final w = math.max(1, (newSize.width * dpr).ceil());
    final h = math.max(1, (newSize.height * dpr).ceil());
    if (surface == null) {
      surface = gpu.gpuContext
          .createImageSurface(w, h, format: gpu.PixelFormat.r8g8b8a8UNormInt);
      stats?._surfaceCreations++;
    }
    if (surface!.width != w || surface!.height != h) {
      surface!.resize(w, h);
      stats?._surfaceResizes++;
    }
  }
}

class _GpuImageCompositor extends CustomPainter {
  _GpuImageCompositor(
      this.resources, this.input, this.dpr, this.failed, this.ready);
  final _GpuResources resources;
  final GpuToolpathLayer input;
  final double dpr;
  final void Function(Object) failed;
  final VoidCallback ready;

  gpu.BufferView _uniform(gpu.HostBuffer host, gpu.UniformSlot slot,
      Map<String, List<double>> values) {
    final data = ByteData(slot.sizeInBytes!);
    for (final entry in values.entries) {
      final offset = slot.getMemberOffsetInBytes(entry.key)!;
      for (var i = 0; i < entry.value.length; i++) {
        data.setFloat32(offset + i * 4, entry.value[i], Endian.host);
      }
    }
    return host.emplace(data);
  }

  List<double> _color(Color c) => [c.r, c.g, c.b, c.a];
  void _drawGuides(
      gpu.RenderPass pass, gpu.HostBuffer host, Size size, double layer) {
    final viewport = resources.viewport!;
    final plot = viewport.plot;
    final grid = viewport.gridOrigin;
    final origin = viewport.project(0, 0);
    final head = viewport.toolHead(input.segments, input.progress);
    final style = input.style;
    pass.clearBindings();
    pass.bindPipeline(resources.guides);
    pass.bindVertexBuffer(resources.quad);
    final vertex = resources.guides.vertexShader.getUniformSlot('GuideFrame');
    pass.bindUniform(
        vertex,
        _uniform(host, vertex, {
          'viewport': [size.width, size.height, 0, 0]
        }));
    final fragment =
        resources.guides.fragmentShader.getUniformSlot('GuideInfo');
    pass.bindUniform(
        fragment,
        _uniform(host, fragment, {
          'viewport': [size.width, size.height, dpr, layer],
          'plot': [plot.left, plot.top, plot.right, plot.bottom],
          'grid_origin': [grid.dx, grid.dy, style.grid.width, 0],
          'origin': [
            origin.dx,
            origin.dy,
            style.origin.width,
            input.progress > 0 ? 1.0 : 0.0
          ],
          'head': [head.dx, head.dy, 5, 10],
          'grid_color': _color(style.grid.color),
          'origin_color': _color(style.origin.color),
          'origin_dot': _color(style.originDotColor),
          'head_color': _color(style.toolHeadColor),
          'glow_color': _color(style.toolHeadGlowColor),
        }));
    pass.draw(6);
  }

  // Canvas only composites the finished GPU image; it draws no scene geometry.
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 60 || size.height <= 60) return;
    gpu.GpuImageSurfaceFrame? frame;
    try {
      resources.prepare(input, size, dpr);
      frame = resources.surface!.acquireNextFrame();
      final command = gpu.gpuContext.createCommandBuffer();
      final pass = command.createRenderPass(gpu.RenderTarget.singleColor(
          gpu.ColorAttachment(texture: frame.colorTexture)));
      pass.setColorBlendEnable(true);
      pass.setColorBlendEquation(gpu.ColorBlendEquation());
      final host = resources.host..reset();
      _drawGuides(pass, host, size, 0);
      if (resources.vertexCount > 0) {
        pass.clearBindings();
        pass.bindPipeline(resources.pipeline);
        pass.bindVertexBuffer(resources.vertices!);
        final vertexSlot =
            resources.pipeline.vertexShader.getUniformSlot('FrameInfo');
        pass.bindUniform(
            vertexSlot,
            _uniform(host, vertexSlot, {
              'viewport': [size.width, size.height, 0, 0]
            }));
        final fragmentSlot =
            resources.pipeline.fragmentShader.getUniformSlot('PaintInfo');
        final style = input.style;
        for (final layer in [0.0, 1.0]) {
          final drawCount = layer == 0.0
              ? resources.vertexCount
              : ToolpathGeometry.foregroundVertexCount(
                  resources.prefixVertexCounts, input.progress);
          if (drawCount == 0) continue;
          pass.bindUniform(
              fragmentSlot,
              _uniform(host, fragmentSlot, {
                'progress_layer': [
                  input.progress.clamp(0.0, 1.0).toDouble() *
                      input.segments.length,
                  layer,
                  dpr,
                  0
                ],
                'rapid_color': _color(style.rapidMove.color),
                'linear_color': _color(style.linearMove.color),
                'rapid_background': _color(style.rapidBackground.color),
                'linear_background': _color(style.linearBackground.color),
                'widths': [
                  style.rapidMove.width,
                  style.linearMove.width,
                  style.rapidBackground.width,
                  style.linearBackground.width
                ],
              }));
          pass.draw(drawCount);
        }
      }
      _drawGuides(pass, host, size, 1);
      frame.present(command);
      command.submit();
      final ui.Image image = resources.surface!.currentImage!;
      try {
        canvas.drawImageRect(
            image,
            Rect.fromLTWH(
                0, 0, image.width.toDouble(), image.height.toDouble()),
            Offset.zero & size,
            Paint());
      } finally {
        image.dispose();
      }
      resources.stats?._compositedFrames++;
      ready();
    } catch (e) {
      frame?.discard();
      failed(e);
    }
  }

  @override
  bool shouldRepaint(covariant _GpuImageCompositor oldDelegate) {
    return !identical(resources, oldDelegate.resources) ||
        !identical(input.segments, oldDelegate.input.segments) ||
        input.bounds != oldDelegate.input.bounds ||
        input.progress != oldDelegate.input.progress ||
        input.style != oldDelegate.input.style ||
        dpr != oldDelegate.dpr;
  }
}
