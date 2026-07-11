import { AnimatePresence, motion, useReducedMotion } from "motion/react";
import { useEffect, useState } from "react";

const PHRASES = [
  { latin: "privet", cyrillic: "привет" },
  { latin: "konnichiwa", cyrillic: "こんにちは" },
  { latin: "annyeong", cyrillic: "안녕" },
  { latin: "spasibo", cyrillic: "спасибо" },
] as const;

const CHIPS = ["sh → ш", "chi → ち", "nyeo → 녀", "shch → щ"] as const;

/** Looping type-along demo: Latin keystrokes becoming Cyrillic in real time. */
export function PhoneticDemo() {
  const prefersReduced = useReducedMotion();
  const [phrase, setPhrase] = useState(0);
  const [typed, setTyped] = useState(PHRASES[0].latin.length);

  useEffect(() => {
    if (prefersReduced) return;
    const { latin } = PHRASES[phrase];
    const timer = setInterval(() => {
      setTyped((n) => {
        if (n < latin.length) return n + 1;
        clearInterval(timer);
        setTimeout(() => {
          setPhrase((p) => (p + 1) % PHRASES.length);
          setTyped(0);
        }, 1600);
        return n;
      });
    }, 180);
    return () => clearInterval(timer);
  }, [phrase, prefersReduced]);

  const { latin, cyrillic } = PHRASES[phrase];
  const shown = prefersReduced ? latin.length : typed;
  const cyrShown = Math.round((shown / latin.length) * cyrillic.length);

  return (
    <div className="phonetic-demo">
      <div className="phonetic-line">
        <span className="phonetic-latin">
          {latin.slice(0, shown)}
          <span className="phonetic-caret" aria-hidden="true" />
        </span>
        <span className="phonetic-arrow" aria-hidden="true">→</span>
        <AnimatePresence mode="popLayout" initial={false}>
          <motion.span
            key={`${phrase}-${cyrShown}`}
            className="phonetic-cyrillic"
            initial={{ opacity: 0.4, y: 3 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.15 }}
          >
            {cyrillic.slice(0, cyrShown) || " "}
          </motion.span>
        </AnimatePresence>
      </div>
      <div className="phonetic-chips" aria-hidden="true">
        {CHIPS.map((chip) => (
          <span key={chip}>{chip}</span>
        ))}
      </div>
    </div>
  );
}
