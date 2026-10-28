"""Interactive Windows-only acceptance; never substitutes posted close messages.

Exit 0: covered checks passed (screenshots still require visual review).
Exit 1: failure. Exit 2: blocked desktop/UIA/tool capability. No global process kills.
"""
import argparse
import ctypes
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
import traceback


class Blocked(RuntimeError):
    pass


def wait(predicate, timeout=20):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        result = predicate()
        if result:
            return result
        time.sleep(.1)
    raise TimeoutError('Timed out waiting for an observed window state')


def validate_application_log(text):
    errors = {
        'window lifecycle': r'Invalid engine handle|Communicating on a dead channel|c0000005',
        'window startup': r'MissingPluginException[^\r\n]*(?:getWindowDefinition|mixin\.one/desktop_multi_window)|getWindowDefinition[^\r\n]*MissingPluginException|(?:startup barrier|启动屏障)[^\r\n]*(?:timed? ?out|timeout|超时)',
        'window readiness': r'Window did not become ready|No native first frame|Native window definition was not registered|startup_failed',
        'accessibility tree': r'Failed to update ui::AXTree',
    }
    for category, pattern in errors.items():
        if re.search(pattern, text, re.I):
            raise AssertionError(f'{category} error in captured application log')


class Session:
    def __init__(self, exe, output, procdump=None):
        from pywinauto import Desktop, keyboard, mouse
        self.desktop, self.keyboard, self.mouse = Desktop(backend='uia'), keyboard, mouse
        self.output, self.monitor = output, None
        self.log = (output / 'application.log').open('w', encoding='utf-8')
        self.process = subprocess.Popen([str(exe)], cwd=exe.parent,
                                        stdout=self.log, stderr=subprocess.STDOUT)
        self.pid = self.process.pid
        self.windows_seen = []
        self.procdump = procdump

    def windows(self):
        return self.desktop.windows(process=self.pid, top_level_only=True, visible_only=False)

    def window(self, title):
        return wait(lambda: next((w for w in self.windows()
                                 if w.window_text() == title and w.is_visible()), None))

    def focus(self, window):
        try:
            window.set_focus()
            wait(lambda: ctypes.windll.user32.GetForegroundWindow() == window.handle, 3)
        except Exception as error:
            raise Blocked('Cannot activate target; unlock the interactive desktop/RDP session') from error

    def button(self, window, name):
        self.focus(window)
        try:
            control = wait(lambda: next((c for c in window.descendants(control_type='Button')
                if c.window_text().strip() == name and c.is_visible() and c.is_enabled()), None), 10)
        except Exception as error:
            (self.output / 'uia.txt').write_text(str(window.descendants()), encoding='utf-8')
            raise Blocked(f'UIA button unavailable: {name}; inspect uia.txt') from error
        self.focus(window)
        control.click_input()  # physical input, not InvokePattern or WM_COMMAND

    def picture(self, window, name):
        self.focus(window)
        image = window.capture_as_image()
        if image is None:
            raise Blocked('Window screenshot unavailable')
        image.save(self.output / f'{name}.png')
        # A uniform Flutter body is not valid first-frame evidence. This is only
        # a blank-surface guard; screenshots must still be reviewed by a human.
        body = image.crop((0, min(80, image.height // 3), image.width, image.height))
        colors = body.resize((64, 48)).convert('RGB').getcolors(3072)
        if colors is not None and len(colors) < 4:
            raise AssertionError('Uniform/blank client surface')

    def open_category(self, main, title, ready=True):
        self.button(main, title)
        self.button(main, '在新窗口打开')
        return self.window(title) if ready else None

    def interactive_child(self, child, name):
        self.picture(child, name + '-category')
        self.button(child, '三棵树与生命周期')
        wait(lambda: any('Flutter 三棵树' in c.window_text() for c in child.descendants()))
        self.picture(child, name + '-teaching')

    def caption_close(self, window):
        from ctypes import wintypes
        self.focus(window)
        bounds, frame = wintypes.RECT(), wintypes.RECT()
        hwnd = wintypes.HWND(window.handle)
        if ctypes.windll.dwmapi.DwmGetWindowAttribute(hwnd, 5, ctypes.byref(bounds), ctypes.sizeof(bounds)) != 0:
            raise Blocked('Native caption bounds unavailable')
        ctypes.windll.user32.GetWindowRect(hwnd, ctypes.byref(frame))
        if bounds.right <= bounds.left or bounds.bottom <= bounds.top:
            raise Blocked('Native caption bounds invalid')
        x = frame.left + bounds.right - (bounds.right - bounds.left) // 6
        y = frame.top + (bounds.top + bounds.bottom) // 2
        self.mouse.click(coords=(x, y))

    def alt_f4(self, window):
        self.focus(window)
        self.keyboard.send_keys('%{F4}', pause=.1)

    def attach_monitor(self):
        if not self.procdump:
            return
        import winreg
        try:
            with winreg.OpenKey(winreg.HKEY_CURRENT_USER, r'Software\Sysinternals\ProcDump') as key:
                accepted = winreg.QueryValueEx(key, 'EulaAccepted')[0]
            if accepted != 1:
                raise ValueError()
        except Exception as error:
            raise Blocked('Run ProcDump manually and accept its EULA before using --procdump') from error
        self.monitor_log = (self.output / 'procdump.log').open('w', encoding='utf-8')
        self.monitor = subprocess.Popen([str(self.procdump), '-e', '1', '-f', 'C0000005',
            '-ma', '-n', '1', str(self.pid), str(self.output)],
            stdout=self.monitor_log, stderr=subprocess.STDOUT)
        def attached():
            if self.monitor.poll() is not None:
                raise Blocked('ProcDump exited before monitoring was ready')
            text = (self.output / 'procdump.log').read_text(errors='replace')
            return 'Exception monitoring enabled' in text or 'Press Ctrl-C' in text
        wait(attached, 15)

    def finish(self, main, close=True):
        if close and self.process.poll() is None:
            self.caption_close(main)
        code = self.process.wait(timeout=15)
        if code != 0:
            raise AssertionError(f'Application exit code {code}')
        if self.windows():
            raise AssertionError('Owned HWND remains after process exit')
        if self.monitor:
            if self.monitor.wait(timeout=15) != 0:
                raise AssertionError('ProcDump did not exit normally')
            if list(self.output.glob('*.dmp')):
                raise AssertionError('Filtered first-chance dump produced')
        self.log.flush()
        text = (self.output / 'application.log').read_text(encoding='utf-8', errors='replace')
        validate_application_log(text)
        return {'pid': self.pid, 'exitCode': code, 'applicationLogCaptured': bool(text.strip()),
                'firstChance': 'PASS' if self.monitor else 'NOT_RUN'}

    def cleanup(self):
        if self.process.poll() is None:
            self.process.terminate()  # Only this harness's own failed test process.
            self.process.wait(timeout=10)
        if self.monitor and self.monitor.poll() is None:
            self.monitor.terminate()
            self.monitor.wait(timeout=10)
        self.log.close()
        if hasattr(self, 'monitor_log'):
            self.monitor_log.close()


CASES = ['caption', 'alt_f4_main', 'alt_f4_child', 'main_with_child', 'reopen', 'reuse', 'rapid_categories']


def run_case(session, case):
    main = session.window('Flutter Forge')
    session.focus(main)
    session.attach_monitor()
    handles = []
    if case == 'caption':
        session.caption_close(main)
    elif case == 'alt_f4_main':
        session.alt_f4(main)
    elif case == 'rapid_categories':
        titles = ['基础机制', '异步并发', '架构与状态']
        for title in titles:
            session.open_category(main, title, ready=False)
        children = [session.window(title) for title in titles]
        handles = [w.handle for w in children]
        if len(set(handles)) != 3:
            raise AssertionError('Three categories did not produce distinct HWNDs')
        for i, child in enumerate(children):
            session.picture(child, f'category-{i}')
        session.interactive_child(children[0], 'basic')
    else:
        child = session.open_category(main, '基础机制')
        handles.append(child.handle)
        session.interactive_child(child, 'first')
        if case in ('alt_f4_child', 'reopen'):
            closed_handle = child.handle
            if case == 'alt_f4_child':
                session.alt_f4(child)
            else:
                session.caption_close(child)
            wait(lambda: all(w.handle != closed_handle for w in session.windows()))
            if session.process.poll() is not None:
                raise AssertionError('Closing child exited the main process')
            if case == 'reopen':
                reopened = session.open_category(main, '基础机制')
                handles.append(reopened.handle)
                session.interactive_child(reopened, 'reopened')
        elif case == 'reuse':
            same = session.open_category(main, '基础机制')
            if same.handle != child.handle:
                raise AssertionError('Same-category window was not reused')
            if len([w for w in session.windows() if w.window_text() == '基础机制']) != 1:
                raise AssertionError('Duplicate category window')
            wait(lambda: any('Flutter 三棵树' in c.window_text() for c in same.descendants()))
    return {**session.finish(main, close=case not in ('caption','alt_f4_main')), 'nativeHwnds': handles}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--iterations', type=int, default=10)
    parser.add_argument('--cases', nargs='+', choices=CASES, default=CASES)
    parser.add_argument('--procdump', type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    report = {'status': 'RUNNING', 'runs': [], 'screenshotsReview': 'PENDING',
              'engineDestruction': 'UNVERIFIED', 'windowIdKind': 'native HWND, not Dart controller UUID'}
    exit_code = 1
    started = time.strftime('%Y-%m-%dT%H:%M:%S')
    try:
        if sys.platform != 'win32':
            raise Blocked('Requires Windows with an unlocked interactive desktop')
        if args.iterations < 1:
            raise ValueError('iterations must be positive')
        try:
            ctypes.windll.user32.SetProcessDpiAwarenessContext(ctypes.c_void_p(-4))
            ctypes.windll.user32.GetForegroundWindow.restype = ctypes.c_void_p
            import pywinauto  # noqa: F401
        except ImportError as error:
            raise Blocked('Install tool/windows_acceptance_requirements.txt') from error
        exe = args.exe.resolve(strict=True)
        report.update(executable=str(exe), sha256=hashlib.sha256(exe.read_bytes()).hexdigest())
        for case in args.cases:
            for iteration in range(args.iterations):
                output = args.output / f'{case}-{iteration:02d}'
                output.mkdir()
                session = Session(exe, output, args.procdump.resolve() if args.procdump else None)
                report['activeCase'] = {'case': case, 'iteration': iteration, 'pid': session.pid}
                try:
                    result = run_case(session, case)
                    report['runs'].append({'case': case, 'iteration': iteration, **result})
                    print(f'PASS {case} {iteration + 1}/{args.iterations}', flush=True)
                finally:
                    session.cleanup()
        # Event access errors are failures, not an empty event list.
        event_script = Path(__file__).with_name('windows_crash_events.ps1')
        result = subprocess.run(['powershell.exe', '-NoProfile', '-File', str(event_script),
            '-Executable', str(exe), '-StartedAt', started,
            '-ProcessIds', ','.join(str(r['pid']) for r in report['runs'])],
            capture_output=True, text=True, check=True)
        report['events'] = json.loads(result.stdout.lstrip('\ufeff'))
        if report['events']['matches']:
            raise AssertionError('Application Error 1000 recorded for tested PID/path')
        report['status'], exit_code = 'PASS', 0
        report.pop('activeCase', None)
    except Blocked as error:
        report.update(status='BLOCKED', error=str(error))
        exit_code = 2
    except Exception as error:
        report.update(status='FAIL', error=str(error), traceback=traceback.format_exc())
    finally:
        (args.output / 'result.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({'status': report['status'], 'report': str(args.output / 'result.json')}, ensure_ascii=False))
    return exit_code


if __name__ == '__main__':
    raise SystemExit(main())
