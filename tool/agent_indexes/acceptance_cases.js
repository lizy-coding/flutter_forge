// Only visual expectations that cannot be recovered from an automated assertion
// are authored here. Platform applicability comes from the derived policy.
const { visualFlow } = require('./visual_flows');

function acceptanceCases(module) {
  const open = module.excludedPlatforms.length < 5;
  const cases = [{
    id: 'entry_navigation', platforms: 'all',
    preconditions: '使用本次构建的应用；记录平台、设备、窗口尺寸及文字缩放。',
    steps: `从目录进入「${module.title}」，再通过稳定路径 ${module.route} 进入；返回目录并再次进入。`,
    expected: open
      ? '开放平台进入教学页面；关闭平台展示统一不可用说明。返回与重进正确，无残留弹窗或错误页面。'
      : '目录保留模块，稳定路径展示统一不可用说明，不进入业务流程。',
    evidence: '目录、页面或不可用说明截图；操作记录。',
  }];
  if (!open) return cases;
  cases.push({
    id: 'layout_and_readability', platforms: 'open',
    preconditions: '移动或紧凑窗口使用 360dp；桌面另测宽窗口；使用系统大字体。',
    steps: '进入页面，滚动到末尾；展开页面已有说明、菜单或弹窗；调整窗口宽度后重复。',
    expected: '文字与关键控件可读可操作；无溢出、遮挡或截断；滚动及关闭弹窗正常。',
    evidence: '紧凑、大字体与宽窗口截图；异常时附尺寸与复现步骤。',
  });
  const core = visualFlow(module);
  if (core) cases.push(core);
  if (module.platformPolicy.required_capabilities.includes('scene_render')) {
    cases.push({
      id: 'scene_first_frame', platforms: 'open',
      preconditions: '真实 GPU 主机或 Android 设备；使用本次构建；允许自动巡展。',
      steps: '进入 3D 页面，等待场景首帧，连续观察自动巡展，再返回并重新进入。',
      expected: '场景实际可见，无持续黑屏、加载或初始化错误；巡展连续，重进不残留旧场景。',
      evidence: '首帧截图与巡展录屏；设备/GPU/构建模式；初始化日志。',
    }, {
      id: 'scene_controls', feature: 'scene_controls', platforms: 'feature',
      preconditions: '桌面真实窗口；鼠标、键盘可用；另测系统减少动态效果。',
      steps: '暂停巡展；拖拽环绕、滚轮缩放、方向键操控；点击缩略图复位；选取部件、聚焦、清除；切换减少动态效果。',
      expected: '直接操控停止巡展；缩放和环绕有边界；拖拽不误选；高亮与聚焦对象一致；复位正确；减少动态效果不主动持续运动。',
      evidence: '操控、选取和聚焦录屏；高 DPI 截图；键盘与减少动态效果记录。',
    }, {
      id: 'scene_view_only', feature: 'scene_controls', platforms: 'without_feature',
      preconditions: 'Android 真实设备，确认首帧已经出现。',
      steps: '观察自动巡展；点击和拖拽场景，检查页面是否出现操控、选取、聚焦或缩略图入口。',
      expected: '保持只读观看；不出现桌面操控入口，也不触发选取或聚焦。',
      evidence: '完整页面截图与点击、拖拽录屏。',
    });
  }
  const requirements = [...module.platformPolicy.required_capabilities, ...module.platformPolicy.optional_capabilities];
  if (requirements.includes('font_file_import')) {
    cases.push({
      id: 'font_web_boundary', platforms: 'without_feature', feature: 'font_preview',
      preconditions: '使用 Web 构建，在浏览器进入字体学习页面。',
      steps: '阅读平台说明，检查是否出现原生字体预览及本地文件加载入口。',
      expected: '显示 Web 字体学习说明，不出现尚未接入的本地字体加载入口。',
      evidence: '完整页面截图与浏览器版本。',
    });
  }
  if (requirements.includes('file_selection') || requirements.includes('font_file_import')) {
    cases.push({
      id: 'file_provider_pick_cancel', feature: requirements.includes('font_file_import') ? 'font_file_import' : 'file_selection', platforms: 'capability',
      preconditions: '真实系统文件提供器或浏览器；准备模块能消费的合法样本；允许文件访问。',
      steps: '触发文件选择；选择合法样本并观察结果；重新打开选择器后取消；返回页面后再次选择。',
      expected: '结果符合页面实际用途；取消不误报选择成功，不崩溃且页面可再次操作；Web 不承诺本地绝对路径。',
      evidence: '系统选择器与结果截图；取消后的状态与再次选择记录。',
    });
  }
  if (module.platformPolicy.required_capabilities.includes('ble_central')) {
    cases.push({
      id: 'ble_scan_stop_retry', platforms: 'open',
      preconditions: '授权扫描权限、蓝牙开启；附近有 BLE 广播设备；另测拒绝权限及关闭蓝牙。',
      steps: '开始扫描；等待设备；停止并等待后端确认；再次扫描；拒绝权限或关闭蓝牙后重试；离开页面。',
      expected: '扫描、停止和重试状态清楚；未确认停止时不允许连接；设备记录稳定；拒绝与关闭状态可恢复；离开页面释放扫描。',
      evidence: '流程录屏、权限/开关状态、扫描与停止日志；实际外设型号。',
    }, {
      id: 'ble_gatt_lifecycle', platforms: 'open',
      preconditions: '可连接、读取并通知的真实 GATT 外设；扫描已确认停止。',
      steps: '连接、发现服务、读取、订阅通知；断开；重新连接后再离开页面。',
      expected: '真实读取和通知对应外设值；断开后无迟到数据回填；重连正常；页面退出后释放连接与订阅。',
      evidence: '外设型号与服务/特征值；读回值、通知记录和连接日志。',
    });
  }
  return cases;
}

function casePlatforms(module, item, targets) {
  const open = targets.filter((host) => !module.excludedPlatforms.includes(host));
  const feature = module.platformPolicy.features[item.feature]?.platforms ?? [];
  if (item.platforms === 'all') return targets;
  if (item.platforms === 'feature') return feature;
  if (item.platforms === 'without_feature') return open.filter((host) => !feature.includes(host));
  if (item.platforms === 'capability') {
    return module.platformPolicy.features[item.feature]?.platforms ?? open;
  }
  return open;
}

module.exports = { acceptanceCases, casePlatforms };
