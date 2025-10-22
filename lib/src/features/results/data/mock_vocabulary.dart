import '../models/vocabulary_word.dart';

class MockVocabulary {
  static final List<VocabularyWord> words = [
    VocabularyWord(
      id: '1',
      word: 'Meticulous',
      definition:
          'showing great attention to detail; very careful and precise.',
    ),
    VocabularyWord(
      id: '2',
      word: 'Ubiquitous',
      definition: 'present, appearing, or found everywhere.',
    ),
    VocabularyWord(
      id: '3',
      word: 'Alleviate',
      definition:
          'to make something (a pain, suffering, or a problem) less severe.',
    ),
    VocabularyWord(
      id: '4',
      word: 'Ambivalent',
      definition:
          'having mixed feelings or contradictory ideas about something or someone.',
    ),
  ];
}
