import { MotionConfig, motion } from "motion/react";
import { DotField } from "./components/DotField";
import { DownloadButton } from "./components/DownloadButton";
import { PhoneticDemo } from "./components/PhoneticDemo";
import { PopoverDemo } from "./components/PopoverDemo";
import { GITHUB_URL } from "./constants";
import "./app.css";

const FLAGS = [
  ["gb", "English"], ["ru", "Russian"], ["es", "Spanish"], ["fr", "French"],
  ["de", "German"], ["it", "Italian"], ["pt", "Portuguese"], ["nl", "Dutch"],
  ["pl", "Polish"], ["ua", "Ukrainian"], ["tr", "Turkish"], ["sa", "Arabic"],
  ["il", "Hebrew"], ["jp", "Japanese"], ["kr", "Korean"], ["cn", "Chinese"],
  ["ro", "Romanian"], ["cz", "Czech"],
] as const;

const GREETINGS = [
  "HELLO", "ПРИВЕТ", "BONJOUR", "HALLO", "CIAO", "HOLA", "OLÁ",
  "CZEŚĆ", "MERHABA", "ПРИВІТ", "SALUT", "AHOJ",
];

const reveal = {
  initial: { opacity: 0, y: 24 },
  whileInView: { opacity: 1, y: 0 },
  viewport: { once: true, amount: 0.3 },
  transition: { type: "spring", visualDuration: 0.6, bounce: 0.1 },
} as const;

function Hero() {
  return (
    <header className="hero">
      <DotField />

      <nav className="nav container">
        <a className="nav-brand" href="/">
          <img src="/app-icon-256.png" alt="" width="34" height="34" />
          <span>Reversobar</span>
        </a>
        <a className="nav-github" href={GITHUB_URL} target="_blank" rel="noreferrer">
          <GitHubMark />
          <span>GitHub</span>
        </a>
      </nav>

      <div className="container hero-grid">
        <div className="hero-copy">
          <motion.div
            className="hero-route"
            initial={{ opacity: 0, y: 14 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ type: "spring", visualDuration: 0.5, bounce: 0.1 }}
          >
            <span className="route-pill">EN</span>
            <span className="route-arrow" aria-hidden="true">→</span>
            <span className="route-pill">RU</span>
            <span className="route-note">+ 16 more, from your menu bar</span>
          </motion.div>

          <motion.h1
            initial={{ opacity: 0, y: 22 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ type: "spring", visualDuration: 0.65, bounce: 0.1, delay: 0.08 }}
          >
            Translation,
            <br />
            one keystroke
            <br />
            away<span className="h1-mark" aria-hidden="true">↓</span>
          </motion.h1>

          <motion.p
            className="hero-sub"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ type: "spring", visualDuration: 0.65, bounce: 0.1, delay: 0.16 }}
          >
            Press <kbd>⌥</kbd> <kbd>space</kbd> in any app. Type. Instant
            translations across 18 languages, powered by Reverso - click to
            copy, play to hear, star to save.
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ type: "spring", visualDuration: 0.65, bounce: 0.1, delay: 0.24 }}
          >
            <DownloadButton />
          </motion.div>
        </div>

        <motion.figure
          className="hero-shot"
          initial={{ opacity: 0, y: 40 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ type: "spring", visualDuration: 0.8, bounce: 0.12, delay: 0.2 }}
        >
          <div className="menubar-mock" aria-hidden="true">
            <span className="menubar-icon">
              <img src="/app-icon-256.png" alt="" width="17" height="17" />
            </span>
            <span className="menubar-time">Fri 09:41</span>
          </div>
          <PopoverDemo />
        </motion.figure>
      </div>
    </header>
  );
}

function Ticker() {
  const line = GREETINGS.map((g) => `${g} `).join("→ ") + "→ ";
  return (
    <div className="ticker" aria-hidden="true">
      <div className="ticker-track">
        <span>{line}</span>
        <span>{line}</span>
      </div>
    </div>
  );
}

function Board() {
  return (
    <section className="board">
      <div className="container">
        <motion.h2 {...reveal}>
          Everything a translator
          <br />
          should be. Nothing more.
        </motion.h2>
        <div className="bento">
          <motion.div {...reveal} className="tile tile-languages">
            <div className="tile-languages-head">
              <span className="tile-big">18</span>
              <div>
                <h3>languages, two clicks</h3>
                <p>
                  Pick any pair from two flag dropdowns, hit ⇄ to swap. Your
                  last pair is remembered.
                </p>
              </div>
            </div>
            <div className="tile-flags" aria-hidden="true">
              {FLAGS.map(([code, name]) => (
                <img key={code} src={`/flags/${code}.png`} alt={name} title={name} loading="lazy" />
              ))}
            </div>
          </motion.div>

          <motion.div {...reveal} className="tile tile-hotkey">
            <div className="tile-keys" aria-hidden="true">
              <kbd>⌥</kbd>
              <kbd>space</kbd>
            </div>
            <h3>Summoned from anywhere</h3>
            <p>
              A global hotkey toggles the popover over any app. No Dock icon,
              no clutter - esc and it&apos;s gone.
            </p>
          </motion.div>

          <motion.div {...reveal} className="tile tile-fast">
            <span className="tile-big">5<small>µs wait</small></span>
            <h3>Instant on repeat</h3>
            <p>
              Live results as you type. Anything you&apos;ve looked up before
              loads straight from the on-device cache - even offline.
            </p>
          </motion.div>

          <motion.div {...reveal} className="tile">
            <span className="tile-glyphs" aria-hidden="true">⧉ ▶ ★</span>
            <h3>Copy · hear · save</h3>
            <p>
              Click any result to copy it, play native pronunciation, or star
              it into a phrasebook that persists across restarts.
            </p>
          </motion.div>

          <motion.div {...reveal} className="tile">
            <span className="tile-context" aria-hidden="true">
              <span className="ctx-pill">adv.</span>
              <span className="ctx-freq"><i /><i /><i /></span>
              <span className="ctx-translit">privet</span>
            </span>
            <h3>Context, not just words</h3>
            <p>
              Part of speech, usage frequency, transliteration, and real-world
              example sentences with every translation.
            </p>
          </motion.div>
        </div>
      </div>
    </section>
  );
}

function Phonetic() {
  return (
    <section className="phonetic container">
      <motion.div {...reveal} className="phonetic-head">
        <h2>
          No Cyrillic keyboard?
          <br />
          Type it as it sounds.
        </h2>
        <p>
          For Russian, Ukrainian, Japanese and Korean, flip on Phonetic mode
          and type Latin letters - Reversobar builds the native script live,
          with a per-phoneme breakdown.
        </p>
      </motion.div>
      <motion.div {...reveal}>
        <PhoneticDemo />
      </motion.div>
    </section>
  );
}

function Closing() {
  return (
    <section className="closing">
      <div className="container closing-inner">
        <motion.h2 {...reveal}>
          Speak more languages
          <br />
          by lunch.
        </motion.h2>
        <motion.div {...reveal} className="closing-actions">
          <DownloadButton align="center" />
          <a className="btn-secondary" href={GITHUB_URL} target="_blank" rel="noreferrer">
            <GitHubMark />
            View source on GitHub
          </a>
        </motion.div>
      </div>
    </section>
  );
}

function Footer() {
  return (
    <footer className="footer">
      <div className="container footer-inner">
        <div className="footer-brand">
          <img src="/app-icon-256.png" alt="" width="24" height="24" />
          <span>Reversobar</span>
        </div>
        <p>
          An independent open-source project. Not affiliated with or endorsed
          by Reverso. Mac and macOS are trademarks of Apple Inc.
        </p>
        <a href={GITHUB_URL} target="_blank" rel="noreferrer">GitHub</a>
      </div>
    </footer>
  );
}

function GitHubMark() {
  return (
    <svg viewBox="0 0 16 16" width="18" height="18" fill="currentColor" aria-hidden="true">
      <path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82a7.42 7.42 0 0 1 2-.27c.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.01 8.01 0 0 0 16 8c0-4.42-3.58-8-8-8Z" />
    </svg>
  );
}

export default function App() {
  return (
    <MotionConfig reducedMotion="user">
      <Hero />
      <Ticker />
      <main>
        <Board />
        <Phonetic />
        <Closing />
      </main>
      <Footer />
    </MotionConfig>
  );
}
