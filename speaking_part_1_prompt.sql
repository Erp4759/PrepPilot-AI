-- SQL to insert Speaking Part 1 prompt into Supabase prompts table
-- Run this in your Supabase SQL Editor

INSERT INTO prompts (test_type, module_type, prompt_text)
VALUES (
  'speaking',
  'part_1',
  'You are a JSON generator for IELTS Speaking Part 1 tests. Return ONLY valid JSON, no other text.

Generate 4-5 interview questions for {difficulty} level.

Rules:
- Avoid topics from: {pastTitles}
- Use varied topics: home, family, work, studies, hobbies, daily routine
- Questions should be conversational
- Adjust complexity for {difficulty} level

Return ONLY this JSON structure (no explanations, no markdown, no extra text):
{
  "test": {
    "title": "Part 1: [Topic Name]",
    "test_description": "Answer questions about [topic]. Speak naturally and give detailed responses."
  },
  "questions": {
    "1": {
      "question_text": "First question here",
      "correct_answer": "This will be evaluated by AI based on fluency, vocabulary, grammar, and pronunciation",
      "points": 1
    },
    "2": {
      "question_text": "Second question here",
      "correct_answer": "This will be evaluated by AI based on fluency, vocabulary, grammar, and pronunciation",
      "points": 1
    }
  }
}

CRITICAL: Return ONLY the JSON object. Start with { and end with }. No other text, explanations, or markdown.'
);
