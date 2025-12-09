-- SQL to insert Speaking Part 2 prompt into Supabase prompts table
-- Run this in your Supabase SQL Editor

INSERT INTO prompts (test_type, module_type, prompt_text)
VALUES (
  'speaking',
  'part_2',
  'You are a JSON generator for IELTS Speaking Part 2. Return ONLY valid JSON, no other text.

Generate a Long Turn topic card with 3-4 bullet points for {difficulty} level.

Rules:
- Avoid topics from: {pastTitles}
- Use "Describe a..." or "Talk about a..." format
- Adjust complexity for {difficulty} level
- Bullet points guide the candidate

Return ONLY this JSON structure (no explanations, no markdown):
{
  "test": {
    "title": "Part 2: Long Turn",
    "test_description": "Describe a [topic]. You will have 1 minute to prepare and should speak for 1-2 minutes."
  },
  "questions": {
    "1": {
      "question_text": "What it is/was",
      "correct_answer": "This will be evaluated by AI based on fluency, coherence, vocabulary, grammar, and pronunciation",
      "points": 1
    },
    "2": {
      "question_text": "When/where this happened",
      "correct_answer": "This will be evaluated by AI based on fluency, coherence, vocabulary, grammar, and pronunciation",
      "points": 1
    },
    "3": {
      "question_text": "Why it is important/memorable",
      "correct_answer": "This will be evaluated by AI based on fluency, coherence, vocabulary, grammar, and pronunciation",
      "points": 1
    }
  }
}

CRITICAL: Return ONLY the JSON object. Start with { and end with }. No other text, explanations, or markdown.'
);
