import 'package:calculator2/app/app.dart';
import 'package:calculator2/data/repository/document_repository.dart';
import 'package:calculator2/domain/model/project.dart';
import 'package:calculator2/state/document_controller.dart';
import 'package:calculator2/state/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory repository so widget tests don't touch real storage.
class _MemoryRepository implements DocumentRepository {
  Project? _saved;
  @override
  Future<Project?> load() async => _saved;
  @override
  Future<void> save(Project project) async => _saved = project;
}

void main() {
  testWidgets('renders the seed canvas with live, linked results', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = _MemoryRepository();
    final initial = await DocumentController.bootstrap(repo);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentRepositoryProvider.overrideWithValue(repo),
          documentControllerProvider
              .overrideWith((ref) => DocumentController(repo, initial)),
          settingsControllerProvider
              .overrideWith((ref) => SettingsController(prefs)),
        ],
        child: const Calculator2App(),
      ),
    );
    await tester.pumpAndSettle();

    // Seed title note is present.
    expect(find.text('Welcome to Calculator 2.0'), findsOneWidget);
    // 120 * 3 = 360, and the linked equation @a + 50 = 410.
    expect(find.text('360'), findsOneWidget);
    expect(find.text('410'), findsOneWidget);
    // Dark-mode toggle is available.
    expect(find.byTooltip('Dark mode'), findsOneWidget);
  });

  testWidgets('editing a source equation cascades to its dependent',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = _MemoryRepository();
    final initial = await DocumentController.bootstrap(repo);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentRepositoryProvider.overrideWithValue(repo),
          documentControllerProvider
              .overrideWith((ref) => DocumentController(repo, initial)),
          settingsControllerProvider
              .overrideWith((ref) => SettingsController(prefs)),
        ],
        child: const Calculator2App(),
      ),
    );
    await tester.pumpAndSettle();

    // Change the source equation "120 * 3" -> "120 * 4" (=480), dependent ->530.
    final field = find.widgetWithText(TextField, '120 * 3');
    expect(field, findsOneWidget);
    await tester.enterText(field, '120 * 4');
    await tester.pumpAndSettle();

    expect(find.text('480'), findsOneWidget);
    expect(find.text('530'), findsOneWidget);
  });
}
