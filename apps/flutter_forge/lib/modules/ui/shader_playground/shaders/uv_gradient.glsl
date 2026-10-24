uniform vec2 uSize;
uniform float uVertical;
uniform float uShowUv;
uniform float uOffset;
uniform vec4 uStartColor;
uniform vec4 uEndColor;
uniform float uEffect;
uniform float uPhase;
uniform float uBandWidth;
uniform float uSoftness;

out vec4 fragColor;

void main() {
  vec2 uv = clamp(FlutterFragCoord().xy / uSize, 0.0, 1.0);
  float axis = mix(uv.x, uv.y, uVertical);
  float progress = clamp(axis + uOffset, 0.0, 1.0);
  if (uEffect < 0.5) {
    progress = 0.0;
  } else if (uEffect < 1.5) {
    progress = uv.x < 0.5 ? 0.0 : 1.0;
  } else if (uEffect > 2.5) {
    float center = mix(-uBandWidth, 1.0 + uBandWidth, uPhase);
    float distance = abs(uv.x - center);
    progress = 1.0 - smoothstep(uBandWidth * (1.0 - uSoftness), uBandWidth, distance);
  }
  vec4 gradient = mix(uStartColor, uEndColor, progress);
  vec4 coordinates = vec4(uv.x, uv.y, 0.0, 1.0);
  fragColor = mix(gradient, coordinates, uShowUv);
}
