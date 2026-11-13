import io
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch, Mock
from windows_ui_acceptance import CASES, DEFAULT_CASES, Session, Blocked, run_case, validate_application_log, manual_start_menu_pid, activation_evidence, wait_for_start_menu_acknowledgement, configure_diagnostics


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


class CaptionAndEventTest(unittest.TestCase):
    def test_maximized_client_point_is_not_clicked(self):
        from windows_ui_acceptance import caption_target
        target, probes = caption_target((0, -10, 300, 200), (150, 0, 300, 38),
            'maximize_restore', lambda x, y: 9 if 200 < x < 250 and 12 < y < 29 else 1)
        self.assertEqual(probes[0]['hitTest'], 1)
        self.assertIsNotNone(target)
        self.assertGreater(target[1], 12)

    def test_no_button_hit_returns_diagnostics_instead_of_fallback(self):
        from windows_ui_acceptance import caption_target
        target, probes = caption_target((-1000, 0, -700, 200), (150, 0, 300, 38),
            'maximize_restore', lambda x, y: 1)
        self.assertIsNone(target)
        self.assertEqual(len(probes), 15)
        self.assertTrue(all(p['point'][0] < 0 for p in probes))

    def test_events_use_read_only_command_and_preserve_query_errors(self):
        from windows_ui_acceptance import crash_events
        with patch('windows_ui_acceptance.subprocess.run') as run:
            run.return_value = SimpleNamespace(returncode=0, stdout='{"matches":[]}', stderr='')
            self.assertEqual(crash_events(Path('app.exe'), '2026-11-02T10:00:00+08:00', [123]), {'matches': []})
            args, kwargs = run.call_args
            self.assertIn('-Command', args[0])
            self.assertNotIn('-File', args[0])
            self.assertNotIn('-ExecutionPolicy', args[0])
            self.assertEqual(kwargs['env']['FORGE_EVENT_PIDS'], '123')
            run.return_value = SimpleNamespace(returncode=1, stderr='Access denied')
            with self.assertRaisesRegex(RuntimeError, 'Access denied'):
                crash_events(Path('app.exe'), '2026-11-02', [123])
            run.return_value = SimpleNamespace(returncode=0, stdout='{}')
            with self.assertRaises(ValueError):
                crash_events(Path('app.exe'), '2026-11-02', [123])


class DesktopObservationTest(unittest.TestCase):
    def test_capture_failure_is_a_tool_blocker(self):
        session = Session.__new__(Session)
        session.focus = Mock()
        window = Mock()
        window.capture_as_image.side_effect = RuntimeError('capture timed out')
        with self.assertRaisesRegex(Blocked, 'capture timed out'):
            session.picture(window, 'home')

    def test_focus_does_not_invalidate_fresh_button_before_click(self):
        session = Session.__new__(Session)
        events = []
        session.focus = lambda _: events.append('focus')
        control = Mock()
        control.window_text.return_value = '基础机制'
        control.click_input.side_effect = lambda: events.append('click')
        window = Mock()
        window.descendants.side_effect = lambda **_: events.append('query') or [control]
        session.button(window, '基础机制')
        self.assertEqual(events, ['focus', 'query', 'click'])


    def test_duplicate_semantic_label_is_accepted_only_if_unique(self):
        session = Session.__new__(Session)
        session.focus = Mock()
        candidate = Mock()
        candidate.window_text.return_value = '基础机制. 基础机制'
        window = Mock()
        window.descendants.return_value = [candidate]
        session.button(window, '基础机制')
        candidate.click_input.assert_called_once()

    def test_ambiguous_and_absent_buttons_block_without_clicking(self):
        session = Session.__new__(Session)
        session.focus = Mock()
        with tempfile.TemporaryDirectory() as temporary:
            session.output = Path(temporary)
            first, second = Mock(), Mock()
            first.window_text.return_value = '基础机制'
            second.window_text.return_value = '基础机制. 基础机制'
            window = Mock()
            window.descendants.return_value = [first, second]
            with self.assertRaisesRegex(Blocked, 'Ambiguous'):
                session.button(window, '基础机制')
            first.click_input.assert_not_called()
            second.click_input.assert_not_called()
            window.descendants.return_value = []
            with patch('windows_ui_acceptance.wait', side_effect=TimeoutError('not found')):
                with self.assertRaisesRegex(Blocked, 'unavailable'):
                    session.button(window, '基础机制')

    def test_physical_input_failure_is_a_blocker_without_retry(self):
        session = Session.__new__(Session)
        session.focus = Mock()
        control = Mock()
        control.window_text.return_value = '基础机制'
        control.click_input.side_effect = RuntimeError('coordinate input geometry unavailable')
        window = Mock()
        window.descendants.return_value = [control]
        with self.assertRaisesRegex(Blocked, 'Physical UIA click unavailable'):
            session.button(window, '基础机制')
        control.click_input.assert_called_once()

    def test_configure_warning_is_observed_without_claiming_window_damage(self):
        warning = 'MissingPluginException(No implementation found for method configure on channel flutter_forge/desktop_host)'
        self.assertEqual(configure_diagnostics(warning)['status'], 'OBSERVED_NEEDS_REVIEW')
        self.assertEqual(configure_diagnostics('')['status'], 'NOT_CAPTURED')
        result = configure_diagnostics('[desktop_host] registered hwnd=1\n[desktop_host] first configure received hwnd=1')
        self.assertEqual(result['status'], 'NOT_OBSERVED')
        self.assertEqual((result['registered'], result['firstConfigure']), (1, 1))


class ScenariosTest(unittest.TestCase):
    def test_observation_captures_same_main_window_three_times_before_interaction(self):
        self.assertNotIn('observation', DEFAULT_CASES)
        session = FakeSession()
        session.picture = Mock()
        result = run_case(session, 'observation')
        self.assertEqual([call.args[0] for call in session.picture.call_args_list], [session.main] * 3)
        self.assertEqual(result['captionObservations'][0]['continuousCaptures'], 3)
        self.assertIn(('interaction', 2), session.actions)

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
