import 'package:calculator2/app/app.dart';
import 'package:calculator2/domain/model/workspace.dart';
import 'package:calculator2/state/document_controller.dart';
import 'package:calculator2/state/settings_controller.dart';
import 'package:calculator2/data/repository/workspace_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory repository so widget tests don't touch real storage.
class _MemoryRepository implements WorkspaceRepository {
  Workspace? _saved;
  @override
  Future<Workspace?> load() async => _saved;
  @override
  Future<void> save(Workspace workspace) async => _saved = workspace;
}

Future<Widget> _buildApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final repo = _MemoryRepository();
  final initial = await DocumentController.bootstrap(repo);
  return ProviderScope(
    overrides: [
      workspaceRepositoryProvider.overrideWithValue(repo),
      documentControllerProvider.overrideWith(
        (ref) => DocumentController(repo, initial),
      ),
      settingsControllerProvider.overrideWith(
        (ref) => SettingsController(prefs),
      ),
    ],
    child: const Calculator2App(),
  );
}

void main() {
  testWidgets('renders the seed canvas with live, linked results', (
    tester,
  ) async {
    await tester.pumpWidget(await _buildApp(tester));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Calculator 2.0'), findsOneWidget);
    // 120 * 3 = 360, and the linked equation @a + 50 = 410.
    expect(find.text('360'), findsOneWidget);
    expect(find.text('410'), findsOneWidget);
    expect(find.byTooltip('Dark mode'), findsOneWidget);
    expect(find.byTooltip('Export to Excel'), findsOneWidget);
  });

  testWidgets('editing a source equation cascades to its dependent', (
    tester,
  ) async {
    await tester.pumpWidget(await _buildApp(tester));
    await tester.pumpAndSettle();

    final field = find.widgetWithText(TextField, '120 * 3');
    expect(field, findsOneWidget);
    await tester.enterText(field, '120 * 4');
    await tester.pumpAndSettle();

    expect(find.text('480'), findsOneWidget);
    expect(find.text('530'), findsOneWidget);
  });

  testWidgets('adding a canvas tab creates and switches to it', (tester) async {
    await tester.pumpWidget(await _buildApp(tester));
    await tester.pumpAndSettle();

    expect(find.text('Canvas 1'), findsWidgets);
    await tester.tap(find.byTooltip('Add canvas'));
    await tester.pumpAndSettle();

    // The new tab exists and the seed content is gone (we're on a blank tab).
    expect(find.text('Canvas 2'), findsWidgets);
    expect(find.text('Welcome to Calculator 2.0'), findsNothing);
  });

  testWidgets('About dialog credits the developer as Gastronaut', (
    tester,
  ) async {
    await tester.pumpWidget(await _buildApp(tester));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('About'));
    await tester.pumpAndSettle();

    expect(find.text('Developed by Gastronaut'), findsWidgets);
  });
}
