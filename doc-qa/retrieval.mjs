// Shared by the browser and offline regression runner. No model or network dependency.
const stop = new Set("a an and are as at be by do does for from how i in is it of on or that the this to what when which with can could should would please help treat treatment manage".split(" "));
export const words = text => (text.toLowerCase().match(/[a-z]{3,}/g) ?? [])
  .filter(word => !stop.has(word))
  .map(word => word.length > 4 ? word.replace(/(?:ing|ed|s)$/, "") : word);

export function sourcePassages({ pdf, text, mode }) {
  const passages = [];
  for (const [pageIndex, pageText] of text.replace(/^(#SOURCE [^\n]*\n)+/, "").split("\f").entries()) {
    for (let start = 0; start < pageText.length; start += 900) {
      const raw = pageText.slice(start, start + 1200);
      const excerpt = raw.replace(/\s+/g, " ").trim();
      if (!excerpt) continue;
      const tokens = words(excerpt);
      const counts = new Map();
      for (const token of tokens) counts.set(token, (counts.get(token) ?? 0) + 1);
      // Short standalone topic headings distinguish general care from incidental mentions.
      const headings = raw.split("\n").map(line => line.trim()).filter(line =>
        /^[A-Za-z][A-Za-z -]*$/.test(line) && words(line).length <= 3);
      // Contents and indexes have repeated trailing page references, unlike prose.
      const references = raw.split("\n").filter(line => /\S\s+(?:\d+-)?\d+\s*$/.test(line)).length;
      passages.push({
        pdf, page: mode === "pages" ? pageIndex + 1 : 0, text: excerpt,
        counts, length: tokens.length, headings: headings.map(words), contents: references >= 4
      });
    }
  }
  return passages;
}

export function selectPassages(passages, query) {
  const terms = [...new Set(words(query))];
  if (!terms.length || !passages.length) return [];
  const average = passages.reduce((sum, p) => sum + p.length, 0) / passages.length;
  const frequency = new Map(terms.map(term => [term, passages.filter(p => p.counts.has(term)).length]));
  const ranked = passages.map(p => {
    const score = terms.reduce((sum, term) => {
      const count = p.counts.get(term) ?? 0;
      const found = frequency.get(term);
      const idf = Math.log(1 + (passages.length - found + 0.5) / (found + 0.5));
      return sum + idf * count * 2.2 / (count + 1.2 * (0.25 + 0.75 * p.length / average));
    }, 0);
    // Multi-term queries need specific prose, not a matching introductory heading.
    const heading = terms.length === 1 ? Math.max(0, ...p.headings.map(title =>
      terms.every(term => title.includes(term)) ? terms.length / title.length : 0)) : 0;
    return { passage: p, score: (score + (score > 0 ? 4 * heading : 0)) * (p.contents ? 0.1 : 1) };
  }).filter(p => p.score > 0).sort((a, b) => b.score - a.score);
  const selected = [];
  for (const { passage } of ranked) {
    // Overlapping chunks must not spend the small model's context twice.
    if (selected.some(p => p.pdf === passage.pdf && p.text.includes(passage.text.slice(0, 250)))) continue;
    selected.push(passage);
    if (selected.length === 3) break;
  }
  return selected;
}
