import { AnimatePresence, motion, useReducedMotion } from "motion/react";
import { useEffect, useState } from "react";

type Scenario = {
  from: { flag: string; code: string };
  to: { flag: string; code: string };
  query: string;
  /** Native text built live while typing (phonetic mode). */
  phonetic?: string;
  placeholder: string;
  primary: string;
  alts: { text: string; sub?: string }[];
};

// Translations and alternatives are verbatim from Reverso's API for these
// exact queries; if the demo and Reverso disagree, Reverso wins.
const SCENARIOS: Scenario[] = [
  {
    from: { flag: "gb", code: "EN" },
    to: { flag: "ru", code: "RU" },
    query: "hello",
    placeholder: "Translate English…",
    primary: "привет",
    alts: [
      { text: "здравствуйте", sub: "zdravstvuyte" },
      { text: "алло", sub: "allo" },
    ],
  },
  {
    from: { flag: "ru", code: "RU" },
    to: { flag: "gb", code: "EN" },
    query: "spasibo",
    phonetic: "спасибо",
    placeholder: "privet → привет…",
    primary: "thank you",
    alts: [{ text: "thanks" }, { text: "thankfully" }],
  },
  {
    from: { flag: "gb", code: "EN" },
    to: { flag: "sa", code: "AR" },
    query: "hello",
    placeholder: "Translate English…",
    primary: "مرحبا",
    alts: [
      { text: "أهلا", sub: "ʾahlan" },
      { text: "تحية", sub: "taHiyya" },
    ],
  },
  {
    from: { flag: "gb", code: "EN" },
    to: { flag: "jp", code: "JA" },
    query: "hello",
    placeholder: "Translate English…",
    primary: "こんにちは",
    alts: [
      { text: "ハロー", sub: "harō" },
      { text: "もしもし", sub: "moshimoshi" },
    ],
  },
  {
    from: { flag: "gb", code: "EN" },
    to: { flag: "it", code: "IT" },
    query: "hello",
    placeholder: "Translate English…",
    primary: "ciao",
    alts: [{ text: "pronto" }, { text: "salve" }],
  },
];

const TYPE_MS = 130;
const HOLD_MS = 2600;

/** Auto-playing, art-directed recreation of the popover: type, translate, cycle. */
export function PopoverDemo() {
  const prefersReduced = useReducedMotion();
  const [scenario, setScenario] = useState(0);
  const [typed, setTyped] = useState(prefersReduced ? SCENARIOS[0].query.length : 0);

  const s = SCENARIOS[scenario];
  const doneTyping = typed >= s.query.length;

  useEffect(() => {
    if (prefersReduced) return;
    if (!doneTyping) {
      const t = setTimeout(() => setTyped((n) => n + 1), TYPE_MS);
      return () => clearTimeout(t);
    }
    const t = setTimeout(() => {
      setScenario((p) => (p + 1) % SCENARIOS.length);
      setTyped(0);
    }, HOLD_MS);
    return () => clearTimeout(t);
  }, [typed, doneTyping, prefersReduced]);

  const shownQuery = s.query.slice(0, typed);
  const shownPhonetic = s.phonetic
    ? s.phonetic.slice(0, Math.round((typed / s.query.length) * s.phonetic.length))
    : "";

  return (
    <div className="demo" aria-hidden="true">
      <div className="demo-header">
        <span className="demo-pill">
          <img src={`/flags/${s.from.flag}.png`} alt="" width="20" height="15" />
          {s.from.code}
        </span>
        <span className="demo-swap">⇄</span>
        <span className="demo-pill">
          <img src={`/flags/${s.to.flag}.png`} alt="" width="20" height="15" />
          {s.to.code}
        </span>
        {s.phonetic && <span className="demo-mode">⌨ Phonetic</span>}
      </div>

      <div className="demo-field">
        <span className="demo-search" aria-hidden="true">⌕</span>
        {shownQuery ? (
          <span className="demo-query">
            {shownQuery}
            <span className="demo-caret" />
          </span>
        ) : (
          <span className="demo-placeholder">{s.placeholder}</span>
        )}
      </div>

      {s.phonetic && shownPhonetic && (
        <div className="demo-phonetic">
          → <strong>{shownPhonetic}</strong>
        </div>
      )}

      <div className="demo-results">
        <AnimatePresence mode="wait">
          {doneTyping && (
            <motion.div
              key={scenario}
              initial={prefersReduced ? false : "hidden"}
              animate="show"
              exit={{ opacity: 0, transition: { duration: 0.15 } }}
              variants={{
                show: { transition: { staggerChildren: 0.1, delayChildren: 0.15 } },
              }}
            >
              <motion.div
                className="demo-primary"
                variants={{
                  hidden: { opacity: 0, y: 14 },
                  show: { opacity: 1, y: 0, transition: { type: "spring", visualDuration: 0.45, bounce: 0.2 } },
                }}
              >
                <span dir="auto">{s.primary}</span>
                <span className="demo-actions">★ ▶ ⧉</span>
              </motion.div>
              <motion.p
                className="demo-label"
                variants={{ hidden: { opacity: 0 }, show: { opacity: 1 } }}
              >
                OTHER TRANSLATIONS
              </motion.p>
              {s.alts.map((alt) => (
                <motion.div
                  className="demo-alt"
                  key={alt.text}
                  variants={{
                    hidden: { opacity: 0, y: 10 },
                    show: { opacity: 1, y: 0, transition: { type: "spring", visualDuration: 0.4, bounce: 0.15 } },
                  }}
                >
                  <span className="demo-alt-text" dir="auto">{alt.text}</span>
                  {alt.sub && <span className="demo-alt-sub">{alt.sub}</span>}
                </motion.div>
              ))}
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      <div className="demo-footer">
        <span><i>↩</i> copy</span>
        <span><i>esc</i> close</span>
        <span className="demo-footer-right"><i>⌥</i><i>space</i> anywhere</span>
      </div>
    </div>
  );
}
