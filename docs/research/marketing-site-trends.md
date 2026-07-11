# Marketing site design and animation research for Reversobar (2025-2026)

Researched 2026-07-11 against primary sources (official docs, repos, npm registry, first-party sites).
Versions below were verified directly via `npm view <pkg> version` on 2026-07-11.

## 1. WebGL on marketing sites

### Library landscape and current versions (verified via npm registry)

- `three` 0.185.1 (r185) - https://github.com/mrdoob/three.js/releases
- `@react-three/fiber` 9.6.1 - https://github.com/pmndrs/react-three-fiber
- `@react-three/drei` 10.7.7 - https://github.com/pmndrs/drei
- `ogl` 1.0.11 - https://github.com/oframe/ogl
- `@paper-design/shaders` / `@paper-design/shaders-react` - https://github.com/paper-design/shaders

### React 19 compatibility

react-three-fiber v9 is the React 19 compatibility release; `@react-three/fiber@9` pairs with `react@19` and supports React 19.0 through 19.2 (https://r3f.docs.pmnd.rs/tutorials/v9-migration-guide).
R3F v9 bundles its own copy of the React reconciler because React 19.2 bumped the internal reconciler incompatibly with 19.1 (https://github.com/pmndrs/react-three-fiber/releases).
drei v10 added R3F v9 / React 19 support (https://github.com/pmndrs/drei/pull/2284).

### Choosing for a lightweight hero effect

OGL is the light option: 29 kb minzipped total (core 8 kb, math 6 kb, extras 15 kb), zero dependencies, ES modules, tree-shakes smaller; it does "the minimum abstraction necessary" over raw WebGL, so it fits a single custom fullscreen shader (https://github.com/oframe/ogl).
Three.js + R3F + drei is the full-featured option; expect a materially larger bundle since three.js itself is the dependency, so reserve it for scenes with real 3D content rather than a flat gradient.
Paper Shaders is a purpose-built middle path for exactly this use case: zero-dependency canvas shaders with prebuilt `MeshGradient`, `DotOrbit`, and other effects, a dedicated `@paper-design/shaders-react` package, and props like `colors`, `distortion`, `swirl`, `speed` (https://github.com/paper-design/shaders, examples at https://shaders.paper.design).
Recommendation for Reversobar: an animated gradient-mesh or noise hero via `@paper-design/shaders-react` (or a single hand-written OGL fullscreen shader) rather than pulling in three.js.

### drei helpers if a real 3D scene is wanted

drei (`@react-three/drei`) ships ready-made abstractions useful for hero visuals: `Sparkles` (particles), `Float` (idle floating motion), `MeshDistortMaterial`, `MeshTransmissionMaterial` (glass), `GradientTexture`, `shaderMaterial` (custom GLSL), and `Environment` (https://drei.docs.pmnd.rs/getting-started/introduction).

### Official performance guidance (R3F scaling-performance docs)

Source: https://r3f.docs.pmnd.rs/advanced/scaling-performance

- Use `<Canvas frameloop="demand">` so frames render only when needed; call `invalidate()` to request a frame after out-of-band mutations (it requests, not forces, a render).
- Reuse geometries and materials globally across meshes; `useLoader` caches assets automatically.
- Use `InstancedMesh` to keep draw calls low, and drei `<Detailed />` for LOD.
- Use drei `PerformanceMonitor` to adaptively lower dpr/quality on weak devices, and movement regression to drop pixel ratio during interaction.
- Base per-frame movement on the `delta` argument of `useFrame`, not fixed increments.

### Reduced motion and fallbacks

Motion's `MotionConfig reducedMotion="user"` automatically disables transform and layout animations while preserving opacity-type animations when the visitor has Reduced Motion enabled (https://motion.dev/docs/react-accessibility).
The `useReducedMotion()` hook returns a boolean for manual control; the docs specifically recommend using it to disable parallax and autoplaying video (https://motion.dev/docs/react-accessibility).
Apply the same boolean to the WebGL canvas: render a static gradient (CSS or a single non-animated frame) when reduced motion is on, and also as the no-WebGL fallback behind the canvas so the page never depends on GL.

## 2. Motion (formerly Framer Motion)

### Package and version

The package is now `motion`, installed with `npm install motion` and imported from `"motion/react"` (https://motion.dev/docs/react).
Verified on npm: `motion` 12.42.2 (the legacy `framer-motion` package is republished at the same version but the docs treat `motion` as current).
The upgrade guide says migration is uninstall `framer-motion`, install `motion`, change imports from `"framer-motion"` to `"motion/react"`, with no breaking API changes in v12 (https://motion.dev/docs/react-upgrade-guide).
React 18 is the minimum supported version, so React 19 works (https://motion.dev/docs/react-upgrade-guide).
The library is fully tree-shakable, so bundle cost tracks what you import (https://motion.dev/docs/react).

### Scroll APIs

Source: https://motion.dev/docs/react-scroll-animations

In-view reveals use the `whileInView` prop:

```jsx
<motion.div
  initial={{ opacity: 0, y: 24 }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, amount: 0.4 }}
/>
```

`viewport={{ once: true }}` plays the reveal only on first entry; `root` targets a custom scroll container; there is also a `useInView` hook for state-based logic.
Scroll-linked animation uses `useScroll`, which returns `scrollY`/`scrollX` (pixels) and `scrollYProgress`/`scrollXProgress` (0-1) motion values.
Track a specific element with `useScroll({ target: ref, offset: ["start end", "end start"] })`.
Map progress to any value with `useTransform`, and smooth it with `useSpring` (the documented parallax and progress-bar patterns).
Motion uses the browser-native `ScrollTimeline` API for hardware-accelerated scroll animation where available and falls back to JS otherwise.

### Springs and transitions

Source: https://motion.dev/docs/react-transitions

Spring options: `type: "spring"` with either physics (`stiffness`, `damping`, `mass`) or perceptual settings (`bounce`, default 0.25, plus `duration`).
`visualDuration` sets the time the animation appears to take to reach its target, which is the easiest way to tune a spring to match a design.
Named eases include `"linear"`, `"easeIn/Out/InOut"`, `"circIn/Out/InOut"`, `"backIn/Out/InOut"`, `"anticipate"`, plus cubic-bezier arrays.
Site-wide default transitions can be set once via `MotionConfig transition={...}`.

### Layout animations

Source: https://motion.dev/docs/react-layout-animations

The `layout` prop animates any size/position change caused by a React render automatically.
`layoutId` creates shared-element transitions between components (the classic animated tab underline / expanding card).
`LayoutGroup` coordinates layout animation across components that do not re-render together.
Use `layout="position"` on distortion-prone children such as images, and configure the animation via `transition={{ layout: { ... } }}`.

## 3. Landing-page trends verified on first-party sites

Observations below come from fetching the live sites on 2026-07-11, not trend listicles.

Raycast (https://www.raycast.com): dark theme, very large sans-serif display type, glass-effect backdrops, a bento grid of feature modules, 3D accent graphics; primary CTA is plain-text "Download for Mac" with no version subtext in the hero.
Linear (https://linear.app): dark theme, high contrast, bento-grid feature modules, subtle gradient overlays separating sections, glassmorphic semi-transparent UI overlays, embedded product screenshots, progressive reveal structure.
CleanShot X (https://cleanshot.com): the counter-example - light, minimal, blue accent, bento grid of features, demo GIFs; hero carries the compatibility line "Apple Silicon & macOS Tahoe ready!" and trust markers ("30-Day Money-Back Guarantee").
Vercel (https://vercel.com/home): dual dark/light theming with theme-swapped assets, gradient background glows tuned per theme, large hierarchical display type, full-width narrative sections.

Practical takeaways for Reversobar:

- Dark-first with a real light theme is the norm among dev-tool/macOS-app sites; CleanShot shows light-first also works for a consumer utility.
- The consistent structural pattern is: oversized display headline, one short subline, a single primary CTA, then a bento grid of feature cards with real product UI (screenshots or a live demo of the menu-bar popover).
- Motion is subtle everywhere: gradient glows, glass panels, staggered in-view reveals; nobody autoplays aggressive animation in the hero.
- Show the actual product early; Raycast/Linear/CleanShot all put a rendered app window or screenshot in or directly under the hero.
- Implement reveals with `whileInView` + `viewport={{ once: true }}` and sticky scroll sections with `useScroll({ target })` + `useTransform`, per the Motion docs above.

## 4. "Download for Mac" button conventions

### Apple's rules (primary sources)

Apple's third-party trademark guidelines prohibit using the Apple logo (the  glyph) on websites, products, or packaging without express written permission from Apple, so a third-party download button must not carry the Apple logo (https://www.apple.com/legal/intellectual-property/guidelinesfor3rdparties.html).
Referential use of word marks is allowed: phrases like "for Mac", "compatible with", "runs on" are fine provided the Apple term is not part of the product name, is less prominent than the product name, the claim is true, and no endorsement is implied (same source).
"Reversobar for Mac" as a tagline pattern is explicitly the acceptable form; "MacReversobar" or a standalone styled "Mac" wordmark is not (same source).
The "Download on the Mac App Store" badge is licensed only for apps actually distributed on the App Store, must use Apple's unmodified artwork (black preferred), minimum 40 px height onscreen, clear space of one quarter badge height, no color/animation/translation changes (https://developer.apple.com/app-store/marketing/guidelines/).
Reversobar is direct-download, so the App Store badge and the Apple logo are both off the table; use a plain-text button.

### Observed direct-download patterns

Raycast uses a text button reading "Download for Mac", with an alternate "Install via homebrew" link (https://www.raycast.com).
CleanShot places compatibility as hero subtext, "Apple Silicon & macOS Tahoe ready!", rather than on the button (https://cleanshot.com).
Recommended pattern for Reversobar: primary button "Download for macOS", with one line of small subtext under it such as "v1.x - macOS 14+ - Apple Silicon and Intel" (adjust to the app's real minimum target and architectures), plus an optional secondary "brew install --cask reversobar" line if a cask ships later.

## 5. Static site stack

Verified current versions via npm: `vite` 8.1.4, `astro` 7.0.7, `react` 19.2.7.
Recommendation: Vite 8 + React 19 + `motion` (+ `@paper-design/shaders-react` for the hero), because the page is a single animation-heavy screen where everything above the fold is interactive anyway, and this keeps one mental model (React components + Motion APIs documented above).
Astro 7 with a React island is the better pick only if the site grows real content pages (docs, changelog, blog) where its zero-JS-by-default output pays off; plain Vite + vanilla TS is viable but you give up Motion's React APIs (`whileInView`, `useScroll`, layout animations) that this page will lean on.
