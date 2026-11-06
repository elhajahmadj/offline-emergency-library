# Results and decision

Measured on Windows 11 x64, 2026-11-06, against upstream `1212078`.
Engine: llama.cpp build 12110, commit `cd959bae9`, CPU only, six threads.
The exact GGUF and executable hashes are in `results/manifest.json`.
The model hash matches the installer-selected Bartowski Q4_K_M file:
`2fde00ce69dd4899c70d020845e2638353015bba0fdf161b3eb965f2bca4464e`.

| Observation | Temperature 0 | Temperature 0.2 |
| --- | ---: | ---: |
| chrF++ against fixed smoke references | 52.4801 | 52.7552 |
| Setup replies exactly `Ready` | 10/10 | 10/10 |
| Translations in expected language/script (manual direction check) | 21/21 | 21/21 |
| Verbatim echoes of the current input (trimmed, case-insensitive) | 0 | 0 |
| Degenerate repeated phrase, truncated at 150 tokens | 1 | 1 |
| Following reply translates an earlier question instead of the current message | 1 | 1 |

**Decision: retain `--temp 0.2` in both installers.** Neither arm reduces the
observed direction/repetition failures; 0.2 has slightly higher chrF++ on this
fixed set. Under the predeclared rule, there is no behavioral winner and no
evidence that justifies changing the shipped default to 0. This resolves the
temperature/measurement mismatch by publishing the interpreter scores at both
settings, rather than treating the earlier single-direction benchmark as proof.
The launcher arguments, model, prompt and defaults remain unchanged.

## What the aggregate hides

Both arms' English-to-Amharic replies repeat a phrase until the token limit.
The following Amharic message means "I need water", but both arms answer with
an English question about allergies. Correct output language alone therefore
overstates success. These are failed translations in both runs.

Temperature 0.2 also turns the Ukrainian allergy question into a statement
advising contact with a doctor before taking medication. This adds content
instead of translating the question. Both arms mistranslate the Swahili turns;
the fever reply adds "today" and loses the severity. These observations are
not fixed by choosing between these two temperatures.

The references were written by the contributor before inference and have not
had independent native-speaker review. The tiny score difference is descriptive,
not statistically significant evidence of better semantic accuracy. The set is
the previously used interpreter smoke set, not a held-out evaluation. One seed,
one model quantization and one CPU build do not establish broad language quality.
This does not validate the translator for medicine or safety decisions.

## QA evidence

- The runner used the shipped explicit interpreter prompt, verified identical
  in both installers. Its cases were compared with the original #21 test inputs
  and ordering before inference.
- Both arm files retain all HTTP responses, including the failing replies.
  Each contains the setup exchanges and translation turns, status 200,
  response headers, answer text, finish reasons and timings.
- `results/cleanup.json` records the owned inference server's termination.
- Both installers' actual launcher sections were executed with Translate on and
  off. Corresponding generated files were byte-identical; batch files had CRLF,
  shell files LF. Both generated translator launchers use `--temp 0.2`.
- Windows installer smoke passed, including engine acquisition, generated
  launchers, moving the folder and running from the moved path, and CHECK-DRIVE.
  That smoke used the current downloadable engine b12143; the paired inference
  used the installed b12110 engine, with the hash recorded above.
- PowerShell parser passed. Python diagnostics ran with the declared SacreBLEU
  dependency available: zero errors and warnings.
- The unmodified CI launcher parity script reports a Windows Git Bash failure:
  its CR-containing grep expression errors with "Unmatched [". Its file
  comparisons passed. Independent byte inspection passed the line-ending checks;
  the baseline failure is disclosed rather than suppressed.
- Native macOS/Linux runtime and the full upstream link check were not run
  locally. No download URL, installer code, guide or integrity-listed file changed.
