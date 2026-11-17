uniform GuideFrame { vec4 viewport; } frame;
in vec2 position;
out vec2 screen;
void main() {
  screen=position*frame.viewport.xy;
  gl_Position=vec4(position.x*2.0-1.0,1.0-position.y*2.0,0.0,1.0);
}
