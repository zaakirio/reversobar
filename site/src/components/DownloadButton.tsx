import { motion, useMotionValue, useReducedMotion, useSpring } from "motion/react";
import type { PointerEvent } from "react";
import { DOWNLOAD_URL, VERSION } from "../constants";

/** Primary CTA: safety-yellow signage button with a subtle magnetic pull. */
export function DownloadButton({ align = "start" }: { align?: "start" | "center" }) {
  const prefersReduced = useReducedMotion();
  const x = useMotionValue(0);
  const y = useMotionValue(0);
  const sx = useSpring(x, { stiffness: 320, damping: 22 });
  const sy = useSpring(y, { stiffness: 320, damping: 22 });

  function onPointerMove(e: PointerEvent<HTMLAnchorElement>) {
    if (prefersReduced) return;
    const rect = e.currentTarget.getBoundingClientRect();
    x.set((e.clientX - rect.left - rect.width / 2) * 0.12);
    y.set((e.clientY - rect.top - rect.height / 2) * 0.2);
  }

  function onPointerLeave() {
    x.set(0);
    y.set(0);
  }

  return (
    <div className="download" data-align={align}>
      <motion.a
        className="btn-download"
        href={DOWNLOAD_URL}
        style={{ x: sx, y: sy }}
        onPointerMove={onPointerMove}
        onPointerLeave={onPointerLeave}
        whileTap={{ scale: 0.97 }}
      >
        Download for macOS
        <svg viewBox="0 0 20 20" width="20" height="20" fill="currentColor" aria-hidden="true">
          <path d="M10 2a1 1 0 0 1 1 1v8.09l2.79-2.8a1 1 0 1 1 1.42 1.42l-4.5 4.5a1 1 0 0 1-1.42 0l-4.5-4.5A1 1 0 0 1 6.2 8.3L9 11.08V3a1 1 0 0 1 1-1Zm-6 13a1 1 0 0 1 1 1v1h10v-1a1 1 0 1 1 2 0v2a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1v-2a1 1 0 0 1 1-1Z" />
        </svg>
      </motion.a>
      <p className="download-meta">v{VERSION} · macOS 14+ · Universal · free, notarized</p>
    </div>
  );
}
