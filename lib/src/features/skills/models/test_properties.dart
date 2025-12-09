enum TestState { initial, loading, test, results }

// Keep legacy 'band_*' identifiers but add CEFR-style values used by speaking features.
enum Difficulty {
  a1,
  a2,
  b1,
  b2,
  c1,
  c2,
  adaptive,
}

enum TestType { reading, speaking, listening, writing }

enum ReadingModuleType { inference, keywords, scanning, skimming }

// Add common speaking module identifiers (part_1, part_2, part_3)
enum SpeakingModuleType {
  fluency_drills,
  intonation,
  structuring_responses,
  part_1,
  part_2,
  part_3,
}

enum ListeningModuleType {
  gist_listening,
  note_taking,
  detail_listening,
  inference,
}

enum WritingModuleType { coherence_and_cohesion, paraphrasing, task_response }
