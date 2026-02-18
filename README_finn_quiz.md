# finn_quiz.rb

A tiny command-line Finnish vocabulary quizzer that reads words from a YAML file and quizzes you in either:

- **typing mode** (you type the Finnish word), or
- **match-game mode** (you choose from a small set of options, but still type the Finnish word).

It tracks how many you got correct on the **1st** vs **2nd** try, and writes a “missed words” YAML file **only if you missed something**.

---

## Requirements

- **Ruby**: works with modern Ruby. Ruby 3.x+ should also be fine.
- **No external gems required** — it uses only Ruby standard library:
  - `yaml`
  - `time`
  - `optparse`

---

## Install / Run

From the directory containing `finn_quiz.rb`:

```bash
ruby finn_quiz.rb path/to/words.yaml
```

You can also run a subset of words or all words:

```bash
ruby finn_quiz.rb path/to/words.yaml 10
ruby finn_quiz.rb path/to/words.yaml all
```

---

## Modes

### Typing mode (default)

You see English, you type Finnish:

```bash
ruby finn_quiz.rb words.yaml
```

### Match-game mode

Shows a few options (1 correct + distractors), but you still **type** the correct Finnish word:

```bash
ruby finn_quiz.rb words.yaml --match-game
```

---

## Options

### `--lenient-umlauts`

Allows `a` for `ä` and `o` for `ö` (useful early on). If you use the lenient spelling, you still get credit, but it reminds you that umlauts matter.

```bash
ruby finn_quiz.rb words.yaml --lenient-umlauts
```

### `--match-game`

Enables match-game mode:

```bash
ruby finn_quiz.rb words.yaml --match-game
```

You can combine options:

```bash
ruby finn_quiz.rb words.yaml 15 --match-game --lenient-umlauts
```

---

## How many attempts?

The script currently allows **2 attempts per word**:

- “Correct 1st” means you got it on attempt 1
- “Correct 2nd” means you got it on attempt 2
- If you miss both attempts, it’s counted as **Failed** and recorded to the missed list

> If you ever want to change this later, look for the loop:
> `1.upto(2) do |attempt|`

---

## YAML format

The script supports **two** YAML shapes:

1) **Mapping (Hash)** form (recommended)
2) **List (Array)** form

Both must provide at least:

- English: `en` (or the hash key if using mapping form)
- Finnish: `fi`
- Optional: `phon` (phonetic hint)

### 1) Mapping (Hash) form (recommended)

Keys are English words/phrases. Values are objects with `fi` and optionally `phon`.

```yaml
Monday:
  fi: maanantai
  phon: MAAN-AHN-TAI

Tuesday:
  fi: tiistai
  phon: TEES-TAI

Weekend:
  fi: viikonloppu
  phon: VEE-KON-LOP-PU
```

### 2) List (Array) form

Each entry is an object with `en`, `fi`, and optionally `phon`.

```yaml
- en: Monday
  fi: maanantai
  phon: MAAN-AHN-TAI

- en: Tuesday
  fi: tiistai
  phon: TEES-TAI
```

### Notes / gotchas

- `en` and `fi` are required (in mapping form, `en` is the key).
- `phon` is optional; if omitted or empty, it just won’t print phonetics.
- Duplicate Finnish words are fine, but in match-game mode the distractors are drawn from the pool; you need enough unique Finnish words to generate distractors.

---

## Output files (missed words)

If you miss at least one word, the script writes a YAML file like:

```
<base>_missed_YYYYMMDD_HHMMSS.yaml
```

Example:

```
finnish_days_of_week_missed_20260218_082428.yaml
```

If you miss **nothing**, it prints:

```
😊 Ei virheitä — hienoa työtä!
```

…and **no file is written**.

The missed file contains:

- `meta` (timestamp, source file path, flags used)
- `stats` (counts)
- `missed` (the missed word entries)

---

## Example session

```text
Finnish Quiz — 8 word(s) (mode: match-game)
--------------------------------------------------
[1/8] English: Thursday
Options:
  - keskiviikko
  - viikonloppu
  - torstai
Type the Finnish word: torstai
✅ Oikein!
   (phonetic: TORS-TAI)
...
--------------------------------------------------
Results
Total: 8
Correct 1st: 6 (75.0%)
Correct 2nd: 2 (25.0%)
Failed: 0 (0.0%)

😊 Ei virheitä — hienoa työtä!
```

---

## Troubleshooting

### “Not enough distractors.”

In match-game mode, the script needs enough **unique** Finnish words in the YAML pool to generate distractors.

Fix: add more vocabulary, or run match-game only on a larger YAML set.

### “Unsupported YAML structure.”

Your YAML must be either:

- a mapping (Hash) of `English -> {fi:, phon:}`
- or a list (Array) of `{en:, fi:, phon:}` objects

---

## License / Notes

Personal utility script. Adjust as you like. Kiitos & have fun learning 🇫🇮
