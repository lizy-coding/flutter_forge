uniform PaintInfo {
  vec4 progress_layer;
  vec4 rapid_color;
  vec4 linear_color;
  vec4 rapid_background;
  vec4 linear_background;
  vec4 widths;
} paint;
in vec4 path_info;
in float path_rapid;
out vec4 frag_color;
void main() {
  bool rapid = path_rapid > 0.5;
  bool foreground = paint.progress_layer.y > 0.5;
  float fraction = foreground ? clamp(paint.progress_layer.x - path_info.w, 0.0, 1.0) : 1.0;
  if (fraction <= 0.0) discard;
  float extent = path_info.z * fraction;
  float along = path_info.x;
  float across = path_info.y;
  float width = foreground ? (rapid ? paint.widths.x : paint.widths.y)
                           : (rapid ? paint.widths.z : paint.widths.w);
  float start = 0.0;
  float end = extent;
  if (rapid) {
    // Match the existing 7 logical pixel dash / 5 logical pixel gap.
    start = floor(max(along, 0.0) / 12.0) * 12.0;
    end = min(start + 7.0, extent);
    if (start > extent) discard;
  }
  float distance = length(vec2(max(max(start - along, along - end), 0.0), across));
  float aa = 0.75 / paint.progress_layer.z;
  float coverage = 1.0 - smoothstep(max(width * 0.5 - aa, 0.0), width * 0.5 + aa, distance);
  vec4 color = foreground ? (rapid ? paint.rapid_color : paint.linear_color)
                          : (rapid ? paint.rapid_background : paint.linear_background);
  float alpha = color.a * coverage;
  frag_color = vec4(color.rgb * alpha, alpha);
}
