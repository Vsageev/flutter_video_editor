import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'models/project_state.dart';
import 'widgets/toolbar.dart';
import 'widgets/preview_panel.dart';
import 'widgets/timeline.dart';
import 'widgets/properties_panel.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final ProjectState _project = ProjectState();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _project.init().then((_) {
      setState(() => _initialized = true);
    });
  }

  @override
  void dispose() {
    _project.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BlocProvider<ProjectState>.value(
      value: _project,
      child: Scaffold(
        body: Column(
          children: [
            const Toolbar(),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  const Expanded(child: PreviewPanel()),
                  const PropertiesPanel(),
                ],
              ),
            ),
            const Expanded(
              flex: 2,
              child: Timeline(),
            ),
          ],
        ),
      ),
    );
  }
}
