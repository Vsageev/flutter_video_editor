import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme.dart';
import '../models/project_state.dart';

class PropertiesPanel extends StatefulWidget {
  const PropertiesPanel({super.key});

  @override
  State<PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends State<PropertiesPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: EditorColors.secondary,
        border: Border(
          left: BorderSide(color: EditorColors.borderSubtle),
        ),
      ),
      child: Column(
        children: [
          _buildTabs(),
          const Divider(height: 1, color: EditorColors.borderSubtle),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const _MediaTab(),
                _EffectsTab(),
                _PropertiesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TabBar(
        controller: _tabController,
        labelColor: EditorColors.textPrimary,
        unselectedLabelColor: EditorColors.textTertiary,
        labelStyle: EditorTextStyles.small.copyWith(fontSize: 12),
        unselectedLabelStyle: EditorTextStyles.small.copyWith(fontSize: 12),
        indicatorColor: EditorColors.textPrimary,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 1.5,
        dividerHeight: 0,
        tabs: const [
          Tab(text: 'Media'),
          Tab(text: 'Effects'),
          Tab(text: 'Properties'),
        ],
      ),
    );
  }
}

class _MediaTab extends StatelessWidget {
  const _MediaTab();

  String _formatDuration(double seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toInt();
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectState, ProjectStateData>(
      buildWhen: (prev, curr) => prev.mediaFiles != curr.mediaFiles,
      builder: (context, state) {
        final media = state.mediaFiles;
        final project = context.read<ProjectState>();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: _ImportButton(onTap: () => project.importMedia()),
            ),
            if (media.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.video_library_outlined, size: 32, color: EditorColors.textTertiary),
                      const SizedBox(height: 8),
                      Text(
                        'No media imported',
                        style: EditorTextStyles.small.copyWith(
                          color: EditorColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Click Import to add videos',
                        style: EditorTextStyles.tiny,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: media.length,
                  itemBuilder: (context, index) => _MediaItemWidget(
                    media: media[index],
                    formatDuration: _formatDuration,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ImportButton extends StatefulWidget {
  final VoidCallback onTap;

  const _ImportButton({required this.onTap});

  @override
  State<_ImportButton> createState() => _ImportButtonState();
}

class _ImportButtonState extends State<_ImportButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? Colors.white : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 16, color: Colors.black),
              const SizedBox(width: 4),
              Text(
                'Import Media',
                style: EditorTextStyles.small.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaItemWidget extends StatefulWidget {
  final MediaFile media;
  final String Function(double) formatDuration;

  const _MediaItemWidget({
    required this.media,
    required this.formatDuration,
  });

  @override
  State<_MediaItemWidget> createState() => _MediaItemWidgetState();
}

class _MediaItemWidgetState extends State<_MediaItemWidget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final project = context.read<ProjectState>();
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onDoubleTap: () {
          project.addToTimeline(widget.media);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? EditorColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered ? EditorColors.borderSubtle : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 28,
                decoration: BoxDecoration(
                  color: EditorColors.accentPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.media.thumbnailPath != null &&
                        File(widget.media.thumbnailPath!).existsSync()
                    ? Image.file(
                        File(widget.media.thumbnailPath!),
                        fit: BoxFit.cover,
                      )
                    : Icon(Icons.movie_outlined, size: 14, color: EditorColors.accentPurple),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.media.name,
                      style: EditorTextStyles.small.copyWith(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.formatDuration(widget.media.duration)} · ${widget.media.width}x${widget.media.height}',
                      style: EditorTextStyles.tiny,
                    ),
                  ],
                ),
              ),
              if (_hovered)
                GestureDetector(
                  onTap: () => project.addToTimeline(widget.media),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: EditorColors.accentPurpleBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(Icons.add, size: 14, color: EditorColors.accentPurple),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EffectsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        _SectionHeader('TRANSITIONS'),
        _EffectItem('Fade', Icons.gradient_outlined),
        _EffectItem('Dissolve', Icons.blur_on_outlined),
        _EffectItem('Wipe', Icons.swipe_outlined),
        _EffectItem('Slide', Icons.arrow_forward_outlined),
        const SizedBox(height: 16),
        _SectionHeader('FILTERS'),
        _EffectItem('Brightness', Icons.brightness_6_outlined),
        _EffectItem('Contrast', Icons.contrast_outlined),
        _EffectItem('Saturation', Icons.palette_outlined),
        _EffectItem('Blur', Icons.blur_circular_outlined),
        const SizedBox(height: 16),
        _SectionHeader('TEXT'),
        _EffectItem('Title', Icons.title_outlined),
        _EffectItem('Lower Third', Icons.subtitles_outlined),
        _EffectItem('Caption', Icons.closed_caption_outlined),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(title, style: EditorTextStyles.label.copyWith(fontSize: 10)),
    );
  }
}

class _EffectItem extends StatefulWidget {
  final String name;
  final IconData icon;

  const _EffectItem(this.name, this.icon);

  @override
  State<_EffectItem> createState() => _EffectItemState();
}

class _EffectItemState extends State<_EffectItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: _hovered ? EditorColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(widget.icon, size: 15, color: EditorColors.textTertiary),
            const SizedBox(width: 8),
            Text(widget.name, style: EditorTextStyles.small.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _PropertiesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        _SectionHeader('TRANSFORM'),
        _PropertySlider('Position X', 0, -1920, 1920),
        _PropertySlider('Position Y', 0, -1080, 1080),
        _PropertySlider('Scale', 100, 0, 400),
        _PropertySlider('Rotation', 0, -360, 360),
        const SizedBox(height: 16),
        _SectionHeader('OPACITY'),
        _PropertySlider('Opacity', 100, 0, 100),
        const SizedBox(height: 16),
        _SectionHeader('SPEED'),
        _PropertySlider('Speed', 100, 10, 400),
      ],
    );
  }
}

class _PropertySlider extends StatefulWidget {
  final String label;
  final double initial;
  final double min;
  final double max;

  const _PropertySlider(this.label, this.initial, this.min, this.max);

  @override
  State<_PropertySlider> createState() => _PropertySliderState();
}

class _PropertySliderState extends State<_PropertySlider> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              widget.label,
              style: EditorTextStyles.tiny,
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: EditorColors.textSecondary,
                inactiveTrackColor: EditorColors.borderDefault,
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                trackHeight: 2,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: _value,
                min: widget.min,
                max: widget.max,
                onChanged: (v) => setState(() => _value = v),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              _value.toInt().toString(),
              style: EditorTextStyles.tiny.copyWith(
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
