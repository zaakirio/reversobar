import { useEffect, useRef } from "react";
import { useReducedMotion } from "motion/react";

const FRAG = `
precision mediump float;
uniform vec2 u_res;
uniform float u_time;

// Field and dot colors (sRGB, matches --field / --field-line tokens).
const vec3 FIELD = vec3(0.102, 0.278, 0.847);
const vec3 DOT = vec3(0.235, 0.412, 0.949);

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
  float cell = 26.0;
  vec2 grid = gl_FragCoord.xy / cell;
  vec2 id = floor(grid);
  vec2 f = fract(grid) - 0.5;

  // Each LED breathes on its own slow phase; a diagonal wave sweeps the board.
  float phase = hash(id) * 6.2831;
  float wave = sin(u_time * 0.5 + (id.x + id.y) * 0.18 + phase);
  float lit = smoothstep(-1.0, 1.0, wave);

  float radius = 0.08 + 0.1 * lit;
  float dot = 1.0 - smoothstep(radius - 0.05, radius + 0.05, length(f));

  // Fade the matrix toward the top so the headline sits on calm color.
  float falloff = smoothstep(1.0, 0.25, gl_FragCoord.y / u_res.y);

  vec3 color = mix(FIELD, DOT, dot * lit * falloff * 0.85);
  gl_FragColor = vec4(color, 1.0);
}
`;

const VERT = `
attribute vec2 a_pos;
void main() { gl_Position = vec4(a_pos, 0.0, 1.0); }
`;

/** Animated LED-matrix texture over the signal-blue field, WebGL, zero deps.
    Falls back to the flat CSS field when WebGL is unavailable; renders a
    single static frame under prefers-reduced-motion. */
export function DotField() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const prefersReduced = useReducedMotion();

  useEffect(() => {
    const canvas = canvasRef.current!;
    const gl = canvas.getContext("webgl", { antialias: false });
    if (!gl) return;

    function compile(type: number, src: string) {
      const s = gl!.createShader(type)!;
      gl!.shaderSource(s, src);
      gl!.compileShader(s);
      return s;
    }
    const program = gl.createProgram()!;
    gl.attachShader(program, compile(gl.VERTEX_SHADER, VERT));
    gl.attachShader(program, compile(gl.FRAGMENT_SHADER, FRAG));
    gl.linkProgram(program);
    gl.useProgram(program);

    const buf = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buf);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 3, -1, -1, 3]), gl.STATIC_DRAW);
    const loc = gl.getAttribLocation(program, "a_pos");
    gl.enableVertexAttribArray(loc);
    gl.vertexAttribPointer(loc, 2, gl.FLOAT, false, 0, 0);

    const uRes = gl.getUniformLocation(program, "u_res");
    const uTime = gl.getUniformLocation(program, "u_time");

    function resize() {
      const dpr = Math.min(window.devicePixelRatio, 2);
      canvas.width = canvas.clientWidth * dpr;
      canvas.height = canvas.clientHeight * dpr;
      gl!.viewport(0, 0, canvas.width, canvas.height);
      gl!.uniform2f(uRes, canvas.width, canvas.height);
    }
    resize();
    const ro = new ResizeObserver(resize);
    ro.observe(canvas);

    let raf = 0;
    function frame(t: number) {
      gl!.uniform1f(uTime, t / 1000);
      gl!.drawArrays(gl!.TRIANGLES, 0, 3);
      if (!prefersReduced) raf = requestAnimationFrame(frame);
    }
    raf = requestAnimationFrame(frame);

    return () => {
      cancelAnimationFrame(raf);
      ro.disconnect();
    };
  }, [prefersReduced]);

  return <canvas ref={canvasRef} className="dot-field" aria-hidden="true" />;
}
