# /// script
# requires-python = ">=3.11"
# dependencies = ["sacrebleu==2.5.1"]
# ///
"""Replay fixed interpreter conversations at both temperatures, on CPU.

Run: uv run measure.py <llama-server executable> <GGUF> <output directory>
References and cases are fixed in cases.json before inference.
"""
import hashlib
import json
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

import sacrebleu

engine, model, output = map(Path, sys.argv[1:])
here = Path(__file__).resolve().parent
cases = json.loads((here / "cases.json").read_text(encoding="utf-8"))
installer = (here.parent.parent / "Get-OfflineLibrary.ps1").read_text(encoding="utf-8")
prompt = installer.split("$TrArgs = '", 1)[1].split('-sys "', 1)[1].split('"', 1)[0]
output.mkdir(parents=True, exist_ok=False)
with socket.socket() as probe:
    probe.bind(("127.0.0.1", 0))
    port = probe.getsockname()[1]
url = f"http://127.0.0.1:{port}"
arguments = [str(engine), "-m", str(model), "-ngl", "0", "-t", "6",
             "-c", "4096", "-np", "1", "--host", "127.0.0.1", "--port", str(port)]
with engine.open("rb") as engine_file, model.open("rb") as model_file:
    engine_hash = hashlib.file_digest(engine_file, "sha256").hexdigest()
    model_hash = hashlib.file_digest(model_file, "sha256").hexdigest()
manifest = {
    "prompt": prompt, "arguments": arguments[1:], "seed": 1,
    "engine_sha256": engine_hash,
    "model_sha256": model_hash,
    "cases_sha256": hashlib.sha256((here / "cases.json").read_bytes()).hexdigest(),
    "sacrebleu_version": sacrebleu.__version__,
}
# Paths are machine-local inputs, not needed in published results.
manifest["arguments"][1] = model.name
(output / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
with (output / "server.log").open("w", encoding="utf-8") as log:
    server = subprocess.Popen(arguments, stdout=log, stderr=subprocess.STDOUT)
    try:
        for attempt in range(90):
            try:
                with urllib.request.urlopen(url + "/health", timeout=2) as response:
                    if json.load(response)["status"] == "ok":
                        break
            except (urllib.error.URLError, TimeoutError):
                if server.poll() is not None:
                    raise RuntimeError("Server exited; see server.log")
            time.sleep(2)
        else:
            raise TimeoutError("Server not ready within 3 minutes")
        for temperature in (0, 0.2):
            records = []
            for case in cases:
                messages = [{"role": "system", "content": prompt}]
                for index, turn in enumerate([{"input": case["setup"]}, *case["turns"]]):
                    messages.append({"role": "user", "content": turn["input"]})
                    payload = {"messages": messages, "temperature": temperature,
                               "seed": 1, "max_tokens": 150, "cache_prompt": False}
                    request = urllib.request.Request(
                        url + "/v1/chat/completions", json.dumps(payload).encode(),
                        {"Content-Type": "application/json"})
                    with urllib.request.urlopen(request, timeout=180) as response:
                        body = json.load(response)
                        status = response.status
                        headers = dict(response.headers)
                    body["model"] = model.name
                    answer = body["choices"][0]["message"]["content"].strip()
                    messages.append({"role": "assistant", "content": answer})
                    records.append({"setup": case["setup"], "turn": index,
                                    "input": turn["input"], "reference": turn.get("reference"),
                                    "status": status, "headers": headers, "response": body})
                    print(f"ANSWER temp={temperature} {case['setup']} turn={index}", flush=True)
            translated = [record for record in records if record["turn"]]
            hypotheses = [r["response"]["choices"][0]["message"]["content"].strip()
                          for r in translated]
            references = [r["reference"] for r in translated]
            metric = sacrebleu.CHRF(word_order=2)
            score = metric.corpus_score(hypotheses, [references]).score
            incomplete = sum(r["response"]["choices"][0]["finish_reason"] != "stop"
                             or not h for r, h in zip(translated, hypotheses))
            result = {"temperature": temperature, "chrf++": score,
                      "incomplete_translations": incomplete,
                      "metric_signature": str(metric.get_signature()), "records": records}
            (output / f"temperature-{temperature}.json").write_text(
                json.dumps(result, ensure_ascii=True, indent=2), encoding="utf-8")
            print(f"COMPLETE temp={temperature} chrF++={score:.4f}", flush=True)
    finally:
        server.terminate()
        try:
            server.wait(timeout=20)
        except subprocess.TimeoutExpired:
            server.kill()
            server.wait(timeout=10)
        (output / "cleanup.json").write_text(json.dumps({
            "owned_server_pid": server.pid, "exit_code": server.returncode,
            "terminated": server.poll() is not None}), encoding="utf-8")
