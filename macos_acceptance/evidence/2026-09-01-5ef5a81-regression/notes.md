# 5ef5a81 macOS UI regression

The current HEAD is `5ef5a81` (`fix(ui): repair compact layouts for issue 18`) and a fresh macOS Release build completed successfully.

Real desktop interaction passed for the changed `microtask` and `isolate_basic` pages. The microtask page switched from two columns to a compact single-column layout at 360dp. The Isolate page rendered its interactive demo and controls.

When closing the Isolate category window, the Release process exited. The next desktop query failed with `procNotFound`, so the main directory could not be restored and `adsorption_line` could not be opened. This is a lifecycle regression and keeps `MACOS_GATE=HOLD`; Windows self-test remains not started.
