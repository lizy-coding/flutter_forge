uniform GuideInfo {
  vec4 viewport;
  vec4 plot;
  vec4 grid_origin;
  vec4 origin;
  vec4 head;
  vec4 grid_color;
  vec4 origin_color;
  vec4 origin_dot;
  vec4 head_color;
  vec4 glow_color;
} guide;
in vec2 screen;
out vec4 frag_color;
float coverage(float distance,float radius) {
  float aa=0.75/guide.viewport.z;
  return 1.0-smoothstep(max(radius-aa,0.0),radius+aa,distance);
}
vec4 colored(vec4 color,float c) { float alpha=color.a*c;return vec4(color.rgb*alpha,alpha); }
vec4 over(vec4 top,vec4 bottom) {return top+bottom*(1.0-top.a);}
void main() {
  if(guide.viewport.w<0.5) {
    if(screen.x<guide.plot.x || screen.y<guide.plot.y || screen.x>guide.plot.z || screen.y>guide.plot.w) discard;
    vec2 cell=mod(screen-guide.grid_origin.xy+10.0,20.0)-10.0;
    frag_color=colored(guide.grid_color,coverage(min(abs(cell.x),abs(cell.y)),guide.grid_origin.z*0.5));
  } else {
    vec4 result=vec4(0.0);
    if(guide.origin.w>0.5) {
      float d=length(screen-guide.head.xy);
      result=colored(guide.glow_color,coverage(d,guide.head.w));
      result=over(colored(guide.head_color,coverage(d,guide.head.z)),result);
    }
    vec2 p=abs(screen-guide.origin.xy);
    float crossDistance=min(length(vec2(max(p.x-6.0,0.0),p.y)),length(vec2(p.x,max(p.y-6.0,0.0))));
    result=over(colored(guide.origin_color,coverage(crossDistance,guide.origin.z*0.5)),result);
    result=over(colored(guide.origin_dot,coverage(length(p),2.0)),result);
    frag_color=result;
  }
}
