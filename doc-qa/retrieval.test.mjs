import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { sourcePassages, selectPassages } from "./retrieval.mjs";

const source = (pdf, text, mode = "pages") => sourcePassages({ pdf, text, mode });
// Small retrieval fixtures, not medical advice. Order deliberately puts distractors first.
const corpus = [
  ...source("contents.pdf", "CONTENTS\nTreat for shock 2-44\nBurn injuries 3-12\nFirst aid for burns 3-13\nControl bleeding 4-10\nPurify water 6-3"),
  ...source("eyes.pdf", "Chemical burns of the eyes require special care. Burns of the eyes differ from general skin burns. Treat the eye burn."),
  ...source("sea.pdf", "Sunburn and sea survival. Do not treat dehydration this way. The sun can burn skin. Sharks live in the sea."),
  ...source("general.pdf", "#SOURCE Fixture attribution\nBurns\nGeneral skin burn care starts by stopping the burning process. Assess the burned area.\fControl Bleeding\nUse direct pressure to control bleeding from wounds.\fPurify Water\nBoiling is one method to purify drinking water.")
];

for (const query of ["How do I treat a burn?", "burns", "burned", "burning"]) {
  test(`issue 160: general burn care ranks before contents and eye burns: ${query}`, () => {
    const selected = selectPassages(corpus, query);
    assert.equal(selected[0].pdf, "general.pdf");
    assert.equal(selected[0].page, 1);
    assert.equal(selected.length, 3);
    assert.notEqual(selected[0].pdf, "contents.pdf");
  });
}
for (const [query, pdf, page] of [
  ["How do I control bleeding?", "general.pdf", 2],
  ["How do I purify water?", "general.pdf", 3],
  ["chemical burns eyes", "eyes.pdf", 1]
]) {
  test(`adjacent question retains its source: ${query}`, () => {
    const selected = selectPassages(corpus, query);
    assert.equal(selected[0].pdf, pdf);
    assert.equal(selected[0].page, page);
  });
}
for (const query of ["", "how do I", "zzzqxv"]) {
  test(`empty or unmatched question retrieves nothing: ${JSON.stringify(query)}`, () => {
    assert.deepEqual(selectPassages(corpus, query), []);
  });
}
test("overlapping duplicate chunks do not consume the source budget", () => {
  const passages = source("excerpt.pdf", "Burns\n" + "General burn care. ".repeat(70), "excerpts");
  const selected = selectPassages(passages, "burn");
  assert.equal(selected.length, 1);
  assert.equal(selected[0].page, 0);
});
test("issue 160: bundled manual retrieves its general burns chapter", () => {
  const text = readFileSync(new URL("./text/usuhs.txt", import.meta.url), "utf8");
  const passages = [...corpus, ...source("usuhs.pdf", text)];
  const selected = selectPassages(passages, "How do I treat a burn?");
  assert.ok(selected.some(p => p.pdf === "usuhs.pdf" && p.page === 231));
});
test("multi-term questions prefer specific instructions over an introductory heading", () => {
  const passages = [
    ...source("intro.pdf", "CONTROL BLEEDING\nYou must control bleeding immediately in a survival situation. External bleeding falls into classifications according to its source. Arteries carry blood away from the heart. Veins return blood to the heart. Capillaries connect arteries and veins. A casualty can lose a large volume of blood in a short period when a major artery is damaged."),
    ...source("procedure.pdf", "Direct Pressure\nControl external bleeding with direct pressure over the wound. Keep pressure firm to control bleeding. If bleeding continues, maintain pressure.")
  ];
  assert.equal(selectPassages(passages, "How do I control bleeding?")[0].pdf, "procedure.pdf");
});
