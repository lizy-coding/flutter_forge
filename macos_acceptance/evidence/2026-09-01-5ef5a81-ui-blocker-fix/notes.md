# macOS UI blocker fix

Added AppDelegate handling that keeps the process alive after the last window closes and reactivates the main window when a child category window closes or the app becomes active.

Fresh Release build and quality gate passed. A cold-start desktop check opened the Isolate category, sent the native close action successfully, and confirmed the Release process remained alive. The final post-close accessibility read was not repeated in this bounded run, so the full macOS interaction gate remains HOLD until a clean session proves the main-window accessibility tree after close.
