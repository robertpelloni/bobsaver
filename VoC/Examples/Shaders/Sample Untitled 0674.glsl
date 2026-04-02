#version 420

// original https://www.shadertoy.com/view/Ntccz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    
    vec2 U =( 2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

     float b=sqrt(length(U));
  
  float t=time*.5;U=fract(vec2(b-time,abs(atan(U.x,U.y))));
  //U = mod(U+time,256.);

  vec2 c=U*vec2(50.,25.);
  //c.x += time*100.; //makes a cool "warp speed" animation

  U=floor(mod((c),vec2(256*2)));

  float d=b*mod((U.x*U.x+U.y*U.y),U.x-U.y)/256.;

  glFragColor=vec4(fract(d*U.x),fract(d*U.y),d,1.);
    

}
