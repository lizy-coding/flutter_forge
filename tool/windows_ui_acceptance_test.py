import io
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch, Mock
from windows_ui_acceptance import CASES, DEFAULT_CASES, Session, Blocked, run_case, validate_application_log, manual_start_menu_pid, activation_evidence, wait_for_start_menu_acknowledgement


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

    def caption_controls(self, window, name):
        self.actions.append(('caption-controls', window.handle))
        return {'hwnd': window.handle, 'maximizeRestore': 'PASS', 'captionVisualReview': 'PENDING'}

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
    def test_caption_case_is_explicit_and_covers_both_windows(self):
        self.assertNotIn('caption_controls', DEFAULT_CASES)
        session = FakeSession()
        result = run_case(session, 'caption_controls')
        self.assertIn(('caption-controls', 1), session.actions)
        self.assertIn(('caption-controls', 2), session.actions)
        self.assertEqual(len(result['captionObservations']), 2)
        self.assertTrue(all(r['captionVisualReview'] == 'PENDING' for r in result['captionObservations']))

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


class StartMenuObservationTest(unittest.TestCase):
    def test_activation_collection_does_not_turn_missing_logs_into_pass(self):
        with patch('windows_ui_acceptance.subprocess.run', return_value=SimpleNamespace(stdout='[{"status":"DISABLED","events":[]}]')):
            result = activation_evidence(Path('app.exe'), '2026-10-29T12:00:00+08:00')
            self.assertEqual(result['interpretation'], 'REQUIRES_REVIEW')
            self.assertEqual(result['channels'][0]['status'], 'DISABLED')
        with patch('windows_ui_acceptance.subprocess.run', side_effect=OSError('Access denied')):
            self.assertEqual(activation_evidence(Path('app.exe'), 'start')['status'], 'UNAVAILABLE')

    def test_attach_only_after_manual_acknowledgement_and_unique_new_process(self):
        with patch('windows_ui_acceptance.process_ids_for_executable', side_effect=[[], [42]]), \
                patch('windows_ui_acceptance.wait_for_start_menu_acknowledgement') as prompt, patch('windows_ui_acceptance.subprocess.Popen') as launch:
            self.assertEqual(manual_start_menu_pid(Path('app.exe')), 42)
            prompt.assert_called_once()
            launch.assert_not_called()

    def test_existing_or_missing_process_and_missing_console_cannot_pass(self):
        for inventories in ([[99]], [[], []], [[], [41, 42]]):
            with self.subTest(inventories=inventories), \
                    patch('windows_ui_acceptance.process_ids_for_executable', side_effect=inventories), \
                    patch('windows_ui_acceptance.wait_for_start_menu_acknowledgement'), self.assertRaises(Blocked):
                manual_start_menu_pid(Path('app.exe'))
        with patch('windows_ui_acceptance.process_ids_for_executable', return_value=[]), \
                patch('windows_ui_acceptance.wait_for_start_menu_acknowledgement', side_effect=Blocked('No console')), self.assertRaises(Blocked):
            manual_start_menu_pid(Path('app.exe'))

    def test_manual_acknowledgement_is_bounded_and_requires_console(self):
        with patch('sys.stdin.isatty', return_value=False), self.assertRaises(Blocked):
            wait_for_start_menu_acknowledgement()
        keyboard = SimpleNamespace(kbhit=lambda: False)
        with patch('sys.stdin.isatty', return_value=True), patch.dict('sys.modules', {'msvcrt': keyboard}), \
                patch('windows_ui_acceptance.time.monotonic', side_effect=[0, 181]), self.assertRaisesRegex(Blocked, 'Timed out'):
            wait_for_start_menu_acknowledgement()

    def test_manual_session_never_spawns_or_terminates_user_process(self):
        with tempfile.TemporaryDirectory() as directory, \
                patch.dict('sys.modules', {'pywinauto': SimpleNamespace(Desktop=Mock(), keyboard=Mock(), mouse=Mock())}), \
                patch('windows_ui_acceptance.manual_start_menu_pid', return_value=42), \
                patch('windows_ui_acceptance.AttachedProcess') as attached, \
                patch('windows_ui_acceptance.subprocess.Popen') as launch:
            attached.return_value.pid = 42
            session = Session(Path('app.exe'), Path(directory), launch_mode='manual-start-menu')
            session.cleanup()
            launch.assert_not_called()
            attached.return_value.terminate.assert_not_called()
            attached.return_value.close.assert_called_once()



if __name__ == '__main__':
    unittest.main()
