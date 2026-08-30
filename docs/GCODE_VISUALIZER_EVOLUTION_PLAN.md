# G-code Visualizer Evolution Plan

## CURRENT_BASELINE

```text
module = lib/gcode_visualizer
route = /gcode-visualizer
homepage_title = G-code 解析与轨迹动画
status = v1 quality-closed
validation =
  dart format .
  flutter analyze => No issues found
  flutter test => 18 tests passed
```

Implemented:

```text
G0/G00 rapid movement
G1/G01 linear movement
X/Y absolute coordinates
F feed rate stored
semicolon comments
parentheses comments
parser error collection
toolpath segment building
CustomPaint path drawing
play/pause/reset/seek/speed controls
current command highlight
parse error row display
parser tests
toolpath builder tests
```

Known deferred scope:

```text
G2/G3 arc interpolation
G20/G21 unit switching
G90/G91 absolute/relative mode
Z axis
real feed-rate timing
large file isolate parsing
file import/export
3D visualization
```

## HARD_RULES_FOR_NEXT_AGENT

```text
MUST read:
  AGENTS.md
  AI_PROJECT_CONTEXT.md
  lib/gcode_visualizer/AI_ANALYSIS.md
  lib/gcode_visualizer/parser/gcode_parser.dart
  lib/gcode_visualizer/services/toolpath_builder.dart
  lib/gcode_visualizer/state/gcode_player_controller.dart
  lib/gcode_visualizer/widgets/gcode_canvas.dart

MUST keep parser pure Dart.
MUST keep geometry building outside widgets.
MUST keep animation progress independent from parsed segment data.
MUST update lib/gcode_visualizer/AI_ANALYSIS.md after behavior changes.
MUST add or update tests for parser/geometry behavior changes.
MUST run:
  dart format .
  flutter analyze
  flutter test

DO_NOT add external G-code parser package.
DO_NOT implement full CNC standard in one pass.
DO_NOT move module under another demo.
DO_NOT weaken existing tests.
DO_NOT make parse errors silent.
```

## P1_TARGET

Goal:

```text
improve learning clarity without expanding G-code grammar much
```

Tasks:

```text
P1.1 add current segment inspector
P1.2 add canvas legend
P1.3 add widget smoke test for module page
P1.4 improve empty/error states
P1.5 update AI_ANALYSIS.md
```

### P1.1 Current Segment Inspector

Create:

```text
lib/gcode_visualizer/widgets/current_segment_inspector.dart
```

Display:

```text
current line number
raw command
segment type: rapid/linear
start position: x/y
end position: x/y
feedRate
progress in current segment
```

Controller support:

```text
GcodePlayerController getters:
  ToolpathSegment? currentSegment
  double currentSegmentProgress
```

Acceptance:

```text
while playback running, inspector updates with highlighted command
at progress 0, inspector shows first segment or waiting state
at progress 1, inspector shows last segment completed
no crash when segments empty
```

Tests:

```text
add controller test only if test harness can provide vsync cleanly
otherwise cover segment progress with pure helper extracted from controller
```

### P1.2 Canvas Legend

Modify:

```text
lib/gcode_visualizer/widgets/gcode_canvas.dart
```

Add small legend inside canvas container or below canvas:

```text
blue = G0 快速移动
green = G1 线性移动
red dot = 当前刀头
orange cross = 原点
```

Acceptance:

```text
legend visible on desktop and mobile
legend does not cover the path
legend text does not overflow
```

### P1.3 Widget Smoke Test

Create:

```text
test/gcode_visualizer/gcode_visualizer_page_test.dart
```

Minimum assertions:

```text
pump MaterialApp(home: GcodeVisualizerPage())
find title: G-code 解析与轨迹动画
find editor label: G-code 编辑器
find controls: play, stop or progress slider
find teaching text: 学习目标
```

Avoid:

```text
do not assert exact rendering pixels
do not depend on animation timing for first smoke test
```

### P1.4 Empty/Error States

Improve:

```text
editor parse result summary:
  valid command count
  error count
  segment count

canvas empty state:
  no commands
  commands with no movement
  parse errors but partial valid path exists
```

Acceptance:

```text
G1 F1200 => no movement state, not generic blank state
G2 X10 Y10 => error state visible in timeline
G1 X10 Y10 + bad line => valid partial path still visible and error visible
```

## P2_TARGET

Goal:

```text
extend G-code semantics while keeping beginner-friendly explanations
```

Recommended order:

```text
P2.1 support G90/G91 absolute/relative mode
P2.2 support G20/G21 unit switching
P2.3 support G2/G3 arc interpolation by polyline approximation
```

### P2.1 G90/G91

Model changes:

```text
add modal state in ToolpathBuilder:
  coordinateMode = absolute | relative

G90 command:
  update mode
  no segment

G91 command:
  update mode
  no segment
```

Parser changes:

```text
support codes:
  G90
  G91
allow commands with no X/Y/F params
```

Tests:

```text
G90 then G1 X10 Y10 => end 10,10
G91 then G1 X10 Y10 twice => end 20,20
mode changes do not create segments
mixed G90/G91 sequence
```

Teaching updates:

```text
add ConceptChip: G90/G91
add CodeSnippetCard explaining absolute vs relative
add CommonPitfall: relative mode accumulates movement
```

### P2.2 G20/G21

Model changes:

```text
unitMode = millimeter | inch
G21 => millimeter
G20 => inch
internal coordinates remain millimeter
inch input conversion: value * 25.4
```

Tests:

```text
G21 G1 X10 => end.x 10
G20 G1 X1 => end.x 25.4
unit change does not create segment
F conversion decision documented
```

Decision:

```text
first implementation may store F as raw value
if converting F, document unit/minute behavior in AI_ANALYSIS.md
```

### P2.3 G2/G3 Arc Interpolation

Scope:

```text
support XY plane only
support I/J center offset mode first
do not support R radius mode in first arc pass
approximate arc into line segments
```

Model changes:

```text
GcodeSegmentType:
  rapid
  linear
  arcClockwise
  arcCounterClockwise

ToolpathSegment may need:
  source command
  start
  end
  optional center
  optional generated points
```

Algorithm:

```text
start = current position
end = command X/Y with current coordinate mode
center = start + I/J
radius = distance(start, center)
startAngle = atan2(start.y - center.y, start.x - center.x)
endAngle = atan2(end.y - center.y, end.x - center.x)
direction:
  G2 clockwise
  G3 counterclockwise
generate 24..96 points depending on sweep angle
```

Tests:

```text
parse G2/G3 with I/J
reject G2/G3 missing X/Y/I/J
build arc segment or generated polyline
clockwise/counterclockwise direction differs
canvas can draw arc-generated points
```

Teaching updates:

```text
add arc explanation after linear movement
show I/J center offset visually if possible
common pitfall: arc center is offset from start, not absolute center
```

## P3_TARGET

Goal:

```text
make module robust for larger examples and more realistic workflows
```

Tasks:

```text
P3.1 isolate parsing/building for large source
P3.2 add sample library
P3.3 optional file import/export
P3.4 performance budget and repaint review
```

### P3.1 Isolate Parsing

Trigger:

```text
source line count > 1000
or source length > 100KB
```

Implementation:

```text
extract pure function:
  GcodeBuildOutput parseAndBuildToolpath(String source)

use compute() if payload remains simple
otherwise Isolate.run if available in project SDK
```

Acceptance:

```text
small examples still parse synchronously
large examples show parsing state
UI remains responsive
errors preserved with line numbers
tests cover pure parseAndBuildToolpath
```

### P3.2 Sample Library

Create:

```text
lib/gcode_visualizer/data/gcode_samples.dart
```

Samples:

```text
rectangle
zigzag
rapid-vs-linear
relative-mode-demo after P2.1
arc-demo after P2.3
invalid-code-demo
```

UI:

```text
sample selector dropdown/menu
load selected sample
short sample description
```

### P3.3 File Import/Export

Only after sample library is stable.

Constraints:

```text
avoid platform-specific code unless project already has dependency
if adding file_picker/share dependency, document reason in pubspec change
keep feature optional
```

## QUALITY_GATES

For every phase:

```bash
dart format .
flutter analyze
flutter test
```

Minimum test growth:

```text
P1:
  + widget smoke test

P2.1:
  + G90/G91 parser tests
  + G90/G91 builder tests

P2.2:
  + G20/G21 parser tests
  + unit conversion builder tests

P2.3:
  + G2/G3 parser tests
  + arc geometry tests

P3:
  + pure parse/build integration tests
```

Manual acceptance:

```text
run app
open /gcode-visualizer from homepage
verify no overflow on narrow width
edit sample and parse
play, pause, resume, seek, reset
introduce bad line and verify timeline error
```

## RECOMMENDED_NEXT_PROMPT

Use this for next coding agent:

```text
Read AGENTS.md, AI_PROJECT_CONTEXT.md, GCODE_VISUALIZER_EVOLUTION_PLAN.md, and lib/gcode_visualizer/AI_ANALYSIS.md.

Execute P1 only.

Implement:
1. current segment inspector widget
2. canvas legend
3. widget smoke test for GcodeVisualizerPage
4. improved no-movement / partial-error UI states
5. update lib/gcode_visualizer/AI_ANALYSIS.md

Do not implement G90/G91, G20/G21, G2/G3 yet.

Run:
dart format .
flutter analyze
flutter test

Return changed files and validation result.
```
