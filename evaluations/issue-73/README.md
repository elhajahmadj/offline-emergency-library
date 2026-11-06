# Interpreter temperature comparison

Issue #73 asks whether the translator should keep `--temp 0.2` or use `0`.
This replay compares only that setting. It does not change the model, prompt,
context size or sampling seed between arms.

## Replay

```text
uv run evaluations/issue-73/measure.py <llama-server executable> <Qwen_Qwen3-4B-Instruct-2507-Q4_K_M.gguf> <new output directory>
```

Requires Python 3.11 or later and uv. The script declares its pinned scorer
dependency. Supply the kit's CPU engine and the translator GGUF downloaded by
`-Translate` / `--translate`. It runs locally on loopback, with GPU offload
disabled and six CPU threads. No inference API or data upload is used.

The runner extracts the interpreter system prompt from the PowerShell installer,
uses context 4096, and runs temperature 0 followed by 0.2, with seed 1 and a
150-token reply limit. Each language pair starts a fresh conversation. The
model's actual setup reply and all earlier replies in that session remain in
history. Prompt caching is disabled. Empty or truncated replies are retained and
counted as failed translations, so a failing arm still has complete evidence.
The server is owned by the runner and terminated in `finally`.

`cases.json` preserves the inputs and ordering of the original #21 interpreter
test: language setup messages are excluded from the translation score. References
were written and frozen before either arm ran. These are author-provided smoke
references, not an independently reviewed multilingual benchmark. They are
provided in full so a reviewer can challenge or replace them explicitly.

The score is corpus chrF++ from SacreBLEU 2.5.1, with word order 2 and its other
defaults. Both arms use the same fixed references. Read the complete replies
alongside the score: lexical overlap cannot establish semantic accuracy,
especially for low-resource languages. Direction, verbatim source echoes,
setup compliance and repeated replies must be reported separately.

Selection rule fixed before inference: prefer fewer wrong-direction or echoed
turns only when chrF++ does not decrease. If neither arm dominates, preserve
the existing 0.2 setting and disclose the trade-off instead of claiming a winner.
One seed and a short, previously used smoke set do not establish a general
temperature optimum or clinical translation reliability.

## Evidence format

`results/manifest.json` records hashes of the executable, GGUF and cases, the
extracted prompt, CPU settings and scorer version. The temperature files contain
every setup and translation response with HTTP status, headers and response
body. The response's local model path is reduced to its filename; answer text
is unchanged. `cleanup.json` records termination of the owned server.
Server logs and personal absolute paths are kept out of the published evidence.
