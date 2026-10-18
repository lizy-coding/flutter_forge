uniform vec2 uSize;
uniform float uVertical;
uniform float uShowUv;
uniform float uOffset;
uniform vec4 uStartColor;
uniform vec4 uEndColor;

out vec4 fragColor;

void main() {
  vec2 uv = clamp(FlutterFragCoord().xy / uSize, 0.0, 1.0);
  float axis = mix(uv.x, uv.y, uVertical);
  float progress = clamp(axis + uOffset, 0.0, 1.0);
  vec4 gradient = mix(uStartColor, uEndColor, progress);
  vec4 coordinates = vec4(uv.x, uv.y, 0.0, 1.0);
  fragColor = mix(gradient, coordinates, uShowUv);
}
