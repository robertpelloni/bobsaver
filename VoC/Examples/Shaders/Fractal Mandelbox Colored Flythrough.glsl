#version 420

// original https://www.shadertoy.com/view/3sj3RK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
  vec3 r=normalize(vec3(gl_FragCoord.xy/500.-vec2(.5),1.)),p=vec3(-.44,.11,-10.+time/2.);
  for(float i=.0;i<99.;i++){
    vec4 o=vec4(p,1),q=o;
    for(float i=0.;i<9.;i++){
      o.xyz=clamp(o.xyz,-1.,1.)*2.-o.xyz;
      o=o*clamp(max(.25/dot(o.xyz,o.xyz),.25),0.,1.)*vec4(11.2)+q;
    }
    float d=(length(o.xyz)-1.)/o.w-5e-4;
    if(d<5e-4){break;}
    p+=r*d;
    glFragColor.rgb=vec3(1.-i/50.-normalize(o.xyz)*.25);
  }
}
