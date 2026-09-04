# Current macOS rerun

The fresh Release opened the correct asynchronous category window and rendered its first frame. Two complete close cycles were executed with the native close button; after each close the main Flutter Forge window remained readable through the accessibility tree.

The third cycle was blocked by the verification procedure retaining the previous main-window route, so the fixed coordinate no longer targeted the category entry. This is not counted as a product PASS or FAIL. `adsorption_line` was not reached. Keep the macOS gate HOLD and Windows readiness false.
