import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme.dart';
import '../models/project_state.dart';

class Toolbar extends StatelessWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final project = context.read<ProjectState>();

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: EditorColors.secondary,
        border: Border(
          bottom: BorderSide(color: EditorColors.borderSubtle),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _ToolbarGroup(children: [
            _ToolbarButton(
              icon: Icons.folder_open_outlined,
              tooltip: 'Import Media',
              onTap: () => project.importMedia(),
            ),
            _ToolbarButton(icon: Icons.save_outlined, tooltip: 'Save'),
            _ToolbarButton(icon: Icons.file_download_outlined, tooltip: 'Export'),
          ]),
          const _ToolbarDivider(),
          _ToolbarGroup(children: [
            _ToolbarButton(icon: Icons.undo, tooltip: 'Undo'),
            _ToolbarButton(icon: Icons.redo, tooltip: 'Redo'),
          ]),
          const _ToolbarDivider(),
          _ToolbarGroup(children: [
            _ToolbarButton(icon: Icons.content_cut, tooltip: 'Cut', shortcut: 'C'),
            _ToolbarButton(icon: Icons.straighten, tooltip: 'Trim', shortcut: 'T'),
            _ToolbarButton(icon: Icons.flip, tooltip: 'Split', shortcut: 'S'),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: EditorColors.accentPurpleBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'My Project',
              style: EditorTextStyles.small.copyWith(
                color: EditorColors.accentPurple,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _ToolbarGroup(children: [
            _ToolbarButton(icon: Icons.zoom_out, tooltip: 'Zoom Out'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('100%', style: EditorTextStyles.tiny),
            ),
            _ToolbarButton(icon: Icons.zoom_in, tooltip: 'Zoom In'),
          ]),
        ],
      ),
    );
  }
}

class _ToolbarGroup extends StatelessWidget {
  final List<Widget> children;
  const _ToolbarGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: EditorColors.borderSubtle,
    );
  }
}

class _ToolbarButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final String? shortcut;
  final VoidCallback? onTap;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    this.shortcut,
    this.onTap,
  });

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.shortcut != null
          ? '${widget.tooltip} (${widget.shortcut})'
          : widget.tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap ?? () {},
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _hovered ? EditorColors.cardHover : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: _hovered
                  ? EditorColors.textPrimary
                  : EditorColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
