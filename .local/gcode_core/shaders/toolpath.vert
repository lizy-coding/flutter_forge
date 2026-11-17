uniform FrameInfo { vec4 viewport; } frame;
in vec2 position;
in vec4 info;
in float rapid;
out vec4 path_info;
out float path_rapid;
void main() {
  gl_Position = vec4(position.x / frame.viewport.x * 2.0 - 1.0,
                     1.0 - position.y / frame.viewport.y * 2.0, 0.0, 1.0);
  path_info = info;
  path_rapid = rapid;
}
