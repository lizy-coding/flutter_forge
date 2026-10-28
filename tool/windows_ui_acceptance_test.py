import io
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from windows_ui_acceptance import CASES, Session, run_case, validate_application_log


class Window:
    def __init__(self, title, handle):
        self.title, self.handle = title, handle

    def window_text(self):
        return self.title

    def descendants(self):
        return [Window('Flutter 三棵树', 0)]


class FakeSession:
    def __init__(self):
        self.main = Window('Flutter Forge', 1)
        self.live = [self.main]
        self.actions = []
        self.sequence = 1

    def window(self, title):
        return next(w for w in self.live if w.title == title)

    def windows(self):
        return self.live

    def focus(self, window):
        pass

    def attach_monitor(self):
        pass

    def open_category(self, main, title, ready=True):
        found = next((w for w in self.live if w.title == title), None)
        if not found:
            self.sequence += 1
            found = Window(title, self.sequence)
            self.live.append(found)
        return found if ready else None

    def interactive_child(self, child, name):
        self.actions.append(('interaction', child.handle))

    def picture(self, child, name):
        pass

    def close(self, window, action):
        self.actions.append((action,window.handle))
        self.live = [] if window is self.main else [w for w in self.live if w is not window]

    def caption_close(self, window):
        self.close(window,'caption')

    def alt_f4(self, window):
        self.close(window,'alt_f4')

    @property
    def process(self):
        class Process:
            def poll(inner):
                return None if self.main in self.live else 0
        return Process()

    def finish(self, main, close=True):
        self.finish_close = close
        if close and main in self.live:
            self.caption_close(main)
        return {'exitCode':0}


class ScenariosTest(unittest.TestCase):
    def test_all_scenarios_finish_owned_process(self):
        for case in CASES:
            with self.subTest(case=case):
                session=FakeSession()
                self.assertEqual(run_case(session,case)['exitCode'],0)
                self.assertEqual(session.live,[])

    def test_child_alt_f4_precedes_main_caption(self):
        session=FakeSession()
        run_case(session,'alt_f4_child')
        self.assertIn(('alt_f4',2),session.actions)
        self.assertEqual(session.actions[-1],('caption',1))

    def test_main_close_is_not_sent_twice_while_waiting_for_exit(self):
        for case in ['caption','alt_f4_main']:
            session=FakeSession()
            run_case(session,case)
            self.assertFalse(session.finish_close)

    def test_reopen_has_a_new_generation_and_real_caption_path(self):
        session=FakeSession()
        self.assertEqual(run_case(session,'reopen')['nativeHwnds'],[2,3])
        self.assertIn(('caption',2),session.actions)


class ApplicationLogTest(unittest.TestCase):
    def test_clean_shutdown_log_is_accepted(self):
        validate_application_log('first frame ready\nwindow closed\nexit code 0')

    def test_issue33_and_lifecycle_errors_fail_even_with_a_clean_exit(self):
        messages = [
            'MissingPluginException(No implementation found for method getWindowDefinition on channel mixin.one/desktop_multi_window)',
            'startup barrier timeout after 15s',
            '启动屏障超时',
            'TimeoutException: Window did not become ready',
            'TimeoutException: No native first frame',
            'operation=startup_failed',
            'Failed to update ui::AXTree, error: 6 will not be in the tree',
            'Invalid engine handle',
            'Communicating on a dead channel',
            'Exception code: C0000005',
        ]
        for message in messages:
            with self.subTest(message=message):
                with self.assertRaises(AssertionError):
                    validate_application_log(message + '\nexit code 0')

    def test_session_finish_rejects_ax_errors_after_zero_exit(self):
        with tempfile.TemporaryDirectory() as directory:
            session = Session.__new__(Session)
            session.output = Path(directory)
            session.pid = 42
            session.process = SimpleNamespace(wait=lambda timeout: 0)
            session.windows = lambda: []
            session.monitor = None
            session.log = io.StringIO()
            for message, category in [
                ('Failed to update ui::AXTree', 'accessibility tree'),
                ('启动屏障超时', 'window startup'),
            ]:
                with self.subTest(message=message):
                    (session.output / 'application.log').write_text(
                        message + '\nexit code 0', encoding='utf-8')
                    with self.assertRaisesRegex(AssertionError, category):
                        session.finish(None, close=False)
            session.log.close()



if __name__ == '__main__':
    unittest.main()
