import unittest
from windows_ui_acceptance import CASES, run_case


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


if __name__ == '__main__':
    unittest.main()
