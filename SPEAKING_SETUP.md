# Speaking Module Setup Instructions

## Changes Made

### 1. Updated Difficulty System ✅
- Changed from `band_1` through `band_9` to CEFR levels: `a1`, `a2`, `b1`, `b2`, `c1`, `c2`, `adaptive`
- Updated `test_properties.dart` with new Difficulty enum
- Updated `skill_settings_dialog.dart` to show A1-C2 levels with Adaptive option
- Updated `start_test.dart` to handle new difficulty format

### 2. Created Speaking Part 1 Screen ✅
- File: `lib/src/features/skills/speaking/speaking_part_1.dart`
- Features:
  - Speech-to-text recording for each question
  - 5-minute timer for Part 1
  - Real-time transcription
  - Question-by-question recording with mic button
  - Visual feedback (blue=ready, red=recording)
  - Results screen with scoring

### 3. Created Speaking Part 2 Screen ✅
- File: `lib/src/features/skills/speaking/speaking_part_2.dart`
- Features:
  - Two-phase structure (60s preparation + 120s speaking)
  - Topic card with bullet points
  - Single continuous recording
  - Phase transitions with visual indicators
  - Results screen with AI evaluation

### 4. Created Speaking Part 3 Screen ✅
- File: `lib/src/features/skills/speaking/speaking_part_3.dart`
- Features:
  - Abstract discussion questions (4-5 questions)
  - 5-minute timer for deeper discussion
  - Individual recordings per question (90s each)
  - Critical thinking and analytical responses
  - Results screen with detailed feedback

### 5. Updated Navigation ✅
- Connected Speaking home screen to all three parts
- Updated speaking index exports

## ⚠️ REQUIRED: Database Setup

You need to add prompts for all three speaking parts to your Supabase database.

### Option 1: Run SQL Scripts
1. Open Supabase Dashboard
2. Go to SQL Editor
3. Run these files in order:
   - `speaking_part_1_prompt.sql`
   - `speaking_part_2_prompt.sql`
   - `speaking_part_3_prompt.sql`

### Option 2: Manual Insert
Go to your `prompts` table and add three rows:

**Part 1:**
- **test_type**: `speaking`
- **module_type**: `part_1`
- **prompt_text**: (See speaking_part_1_prompt.sql for the full prompt)

**Part 2:**
- **test_type**: `speaking`
- **module_type**: `part_2`
- **prompt_text**: (See speaking_part_2_prompt.sql for the full prompt)

**Part 3:**
- **test_type**: `speaking`
- **module_type**: `part_3`
- **prompt_text**: (See speaking_part_3_prompt.sql for the full prompt)

## Testing

After adding all database prompts:

### Part 1 (Introduction & Interview)
1. Navigate: Skills → Speaking → Part 1
2. Select difficulty (A1-C2 or Adaptive)
3. Click "Start Test"
4. AI generates 4-5 simple interview questions
5. Tap microphone button to record each answer
6. Submit and view results

### Part 2 (Long Turn)
1. Navigate: Skills → Speaking → Part 2
2. Select difficulty
3. Click "Start Test"
4. Read the topic card during 60s preparation phase
5. Speak continuously for 120s during speaking phase
6. Submit and view results

### Part 3 (Discussion)
1. Navigate: Skills → Speaking → Part 3
2. Select difficulty
3. Click "Start Test"
4. AI generates 4-5 abstract discussion questions
5. Record each answer individually (up to 90s per question)
6. Submit and view results

## Difficulty Levels Explained

- **A1-A2**: Beginner/Elementary (simple topics, basic vocabulary)
- **B1-B2**: Intermediate/Upper-Intermediate (common topics, moderate complexity)
- **C1-C2**: Advanced/Proficiency (abstract topics, complex language)
- **Adaptive**: AI adjusts based on your past performance

## Next Steps

To complete Parts 2 and 3:
1. Create similar screens for `speaking_part_2.dart` and `speaking_part_3.dart`
2. Add corresponding prompts to database with test_type='speaking' and module_type='part_2'/'part_3'
3. Update the speaking home screen navigation

## Files Modified

1. `/lib/src/features/skills/models/test_properties.dart`
2. `/lib/src/features/skills/widgets/skill_settings_dialog.dart`
3. `/lib/src/features/skills/actions/start_test.dart`
4. `/lib/src/features/skills/speaking/speaking_part_1.dart` (NEW)
5. `/lib/src/features/skills/speaking/speaking_home_screen.dart`
6. `/lib/src/features/skills/speaking/index.dart`
7. `/speaking_part_1_prompt.sql` (NEW - Database setup)
