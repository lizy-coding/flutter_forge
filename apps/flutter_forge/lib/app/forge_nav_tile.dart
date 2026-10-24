import 'package:flutter/material.dart';

import 'theme/forge_interaction_tokens.dart';

/// Unified navigation/list row for shells across materials and platforms.
///
/// Owns hover, selection, the keyboard-cursor ring, truncation tooltip and
/// selection semantics so every shell surface presents identical feedback;
/// colors come from [ForgeInteractionTokens], never from a specific material.
class ForgeNavTile extends StatefulWidget {
  const ForgeNavTile({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.selected = false,
    this.keyboardActive = false,
    this.trailing,
    this.indent = 0,
    this.enabled = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  /// Route-backed selection; [keyboardActive] is the transient keyboard
  /// cursor rendered as a focus ring and never set together with a tap.
  final bool selected;
  final bool keyboardActive;
  final Widget? trailing;
  final double indent;
  final bool enabled;

  @override
  State<ForgeNavTile> createState() => _ForgeNavTileState();
}

class _ForgeNavTileState extends State<ForgeNavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = context.forgeInteraction;
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.highContrastOf(context);
    final foreground = widget.selected
        ? colors.onSurface
        : colors.onSurfaceVariant;
    return Semantics(
      selected: widget.selected,
      button: widget.onTap != null,
      enabled: widget.enabled,
      child: Tooltip(
        // Sidebar labels truncate long module titles; the tooltip is the only
        // place the full title remains reachable.
        message: widget.label,
        waitDuration: const Duration(milliseconds: 600),
        child: MouseRegion(
          cursor: widget.enabled && widget.onTap != null
              ? SystemMouseCursors.click
              : MouseCursor.defer,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: InkWell(
            onTap: widget.enabled ? widget.onTap : null,
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: reduced ? Duration.zero : tokens.hoverDuration,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                // Constant border width keeps the ring from shifting layout.
                border: Border.all(
                  color: widget.keyboardActive
                      ? tokens.focusColor
                      : Colors.transparent,
                ),
                color: widget.selected
                    ? tokens.selectedColor
                    : _hovered
                    ? tokens.hoverOverlayColor
                    : null,
              ),
              padding: EdgeInsetsDirectional.fromSTEB(
                widget.indent + 8,
                7,
                8,
                7,
              ),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 18,
                      color: widget.selected ? colors.primary : foreground,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: foreground,
                        fontWeight: widget.selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (widget.trailing != null) widget.trailing!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
