#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;

out vec4 fragColor;

float hash21(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;
  vec2 p = frag / uSize.y;
  float aspect = uSize.x / uSize.y;

  vec3 color = vec3(0.035, 0.039, 0.048);
  float topGlow = exp(-length((p - vec2(0.16, 0.03)) * vec2(0.75, 1.3)) * 2.3);
  color += vec3(0.27, 0.23, 0.20) * topGlow * 0.62;

  float cycle = uTime * 6.28318530718 / 30.0;
  float sweep = cos(cycle);
  vec2 origin = vec2(0.16, 0.02);
  vec2 beam = p - origin;
  vec2 beamDir = normalize(vec2(0.40 + sweep * 0.09, 0.92));
  float along = dot(beam, beamDir);
  float across = abs(beam.x * beamDir.y - beam.y * beamDir.x);
  float cone = 1.0 - smoothstep(0.0, 0.035 + max(along, 0.0) * 0.17, across);
  float beamFade = exp(-max(along, 0.0) * 0.9) * step(0.0, along);
  float rays = 0.88 + 0.12 * cos(atan(beam.y, beam.x) * 18.0 + sweep * 0.35);
  float beamPulse = 0.88 + 0.12 * (0.5 + 0.5 * sweep);
  color += vec3(0.48, 0.41, 0.34) * cone * beamFade * rays * beamPulse * 0.5;

  float particles = 0.0;
  for (int i = 0; i < 8; i++) {
    float id = float(i);
    float seed = hash21(vec2(id + 1.0, 2.71));
    float seed2 = hash21(vec2(id + 3.0, 8.13));
    vec2 center = vec2(seed * aspect, 0.39 + seed2 * 0.55);
    float radius = 0.004 + seed * 0.006;
    float distanceToDot = length((p - center) * vec2(1.0, 1.15));
    float dotShape = 1.0 - smoothstep(radius * 0.45, radius, distanceToDot);
    float phase = fract(uTime * (0.11 + seed2 * 0.13) + seed * 3.0);
    float appear = smoothstep(0.02, 0.18, phase) * (1.0 - smoothstep(0.48, 0.78, phase));
    particles += dotShape * appear * (0.65 + seed2 * 0.6);
  }
  float lowerBand = smoothstep(0.35, 0.72, p.y) * (1.0 - smoothstep(0.92, 1.18, p.y));
  color += vec3(0.76, 0.61, 0.40) * particles * lowerBand;

  float vignette = smoothstep(1.32, 0.15, length((uv - 0.5) * vec2(aspect, 1.0)));
  color *= 0.62 + vignette * 0.38;
  fragColor = vec4(color, 1.0);
}
