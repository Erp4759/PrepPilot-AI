-- SQL to insert Speaking Part 3 prompt into Supabase prompts table
-- Run this in your Supabase SQL Editor

INSERT INTO prompts (test_type, module_type, prompt_text)
VALUES (
  'speaking',
  'part_3',
  'You are a JSON generator for IELTS Speaking Part 3. Return ONLY valid JSON, no other text.

Generate 4-5 abstract discussion questions for {difficulty} level.

Rules:
- Avoid topics from: {pastTitles}
- Questions must be abstract and analytical (not personal experiences)
- Build on broader themes: society, technology, education, environment, culture, future trends
- Require critical thinking, analysis, comparison, and speculation
- Use question types: "Why do you think...?", "How has... changed?", "What are the advantages/disadvantages of...?", "Do you agree that...?", "In your opinion, will...?"
- Adjust complexity and depth for {difficulty} level
- Higher levels (B2-C2) require more sophisticated vocabulary and complex ideas

Return ONLY this JSON structure (no explanations, no markdown, no extra text):
{
  "test": {
    "title": "Part 3: Discussion on [Abstract Topic]",
    "test_description": "Discuss abstract questions about [topic]. Provide detailed answers with reasoning, examples, and analysis."
  },
  "questions": {
    "1": {
      "question_text": "First abstract/analytical question here",
      "correct_answer": "This will be evaluated by AI based on fluency, coherence, vocabulary range, grammatical accuracy, pronunciation, and ability to discuss abstract ideas",
      "points": 1
    },
    "2": {
      "question_text": "Second abstract/analytical question here",
      "correct_answer": "This will be evaluated by AI based on fluency, coherence, vocabulary range, grammatical accuracy, pronunciation, and ability to discuss abstract ideas",
      "points": 1
    },
    "3": {
      "question_text": "Third abstract/analytical question here",
      "correct_answer": "This will be evaluated by AI based on fluency, coherence, vocabulary range, grammatical accuracy, pronunciation, and ability to discuss abstract ideas",
      "points": 1
    },
    "4": {
      "question_text": "Fourth abstract/analytical question here",
      "correct_answer": "This will be evaluated by AI based on fluency, coherence, vocabulary range, grammatical accuracy, pronunciation, and ability to discuss abstract ideas",
      "points": 1
    }
  }
}

CRITICAL: Return ONLY the JSON object. Start with { and end with }. No other text, explanations, or markdown.'
);
