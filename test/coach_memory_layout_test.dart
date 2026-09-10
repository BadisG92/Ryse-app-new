import 'package:flutter_test/flutter_test.dart';

/// Ce que Ryze retient s'affichait avec ses étoiles et ses tirets.
///
/// L'onboarding écrit ses lignes en Markdown — « - **Objectif**: perdre du
/// gras » — et la feuille les posait telles quelles dans un `Text`. Ces lignes
/// ne sont pas de la prose : ce sont des couples intitulé/valeur.
final _line = RegExp(r'^\s*[-*]?\s*\*\*(.+?)\*\*\s*:?\s*(.*)$');

({String label, String value}) parse(String raw) {
  final line = raw.trim();
  final m = _line.firstMatch(line);
  if (m == null) return (label: '', value: line.replaceFirst(RegExp(r'^[-*]\s*'), ''));
  return (label: m.group(1)!.trim(), value: m.group(2)!.trim());
}

void main() {
  test('une ligne de l’onboarding se sépare en intitulé et valeur', () {
    final r = parse('- **Objectif concret**: Perdre du gras (79 kg → 71 kg)');
    expect(r.label, 'Objectif concret');
    expect(r.value, 'Perdre du gras (79 kg → 71 kg)');
    expect(r.value, isNot(contains('*')));
  });

  test('les deux-points collés ou espacés donnent le même résultat', () {
    expect(parse('- **Ton**:Taquin').value, 'Taquin');
    expect(parse('- **Ton** : Taquin').value, 'Taquin');
  });

  test('une citation dans la valeur survit', () {
    final r = parse('- **Motivation**: Retrouver de l’énergie ("j’en ai marre d’être fatigué")');
    expect(r.value, contains('j’en ai marre'));
  });

  test('une ligne sans intitulé s’affiche quand même, sans son tiret', () {
    final r = parse('- Rien de particulier');
    expect(r.label, '');
    expect(r.value, 'Rien de particulier');
  });

  test('une ligne libre passe telle quelle', () {
    expect(parse('Note du coach').value, 'Note du coach');
  });
}
