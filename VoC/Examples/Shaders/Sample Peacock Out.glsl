#version 420

// original https://www.shadertoy.com/view/Wdd3Wr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 plas(vec2 v,float time)
{
  float c=.5+sin(v.x*110.)+cos(sin(time/4.+v.y)*20.);
  return vec4(sin(c*.92+cos(time/2.)),c*.015,cos(c*.91+time/2.4)*.25,1.);
}
void main(void)
{
  vec2 uv=vec2(gl_FragCoord.x/resolution.x,gl_FragCoord.y/resolution.y);
  uv-=.5;
  uv/=vec2(resolution.y/resolution.x,1);

  vec2 origuv = uv; 
  float time = (time/20.);
  uv.y += (sin(uv.x*15.+time))/10.-(uv.x);
  origuv.x += time/110.;
  vec4 theNoise= vec4(0.0);//texture(iChannel0,origuv);
  uv.y += (theNoise.r)/1115.;
  uv.x = abs(uv.x);
  uv.y = abs(uv.y);
  vec2 m;
  m.x = atan(uv.x / uv.y) / 3.14;
  m.y = 1. / length(uv) * .2;
  m.y += time + (time/110.);
  m.x += ((time/130.)*sin(m.y/100.));
  float d = m.y;
 float ratio = (sin((m.x*150.)+time*(-10.))/sin(m.y*5.))*500.;
//  out_color = theNoise;
//out_color = vec4(ratio);
// out_color = f + t;
  //float f = texture( iChannel0, d ).r * 100.;
  m.x += sin( time ) * .001;
  m.y += time * .0011;

  vec4 t = plas( m * 3.14, time ) / d;
  t = clamp( t, 0.0, 1.0 );
  vec4 out_color=vec4(1.);
 //out_color = f + t;
 out_color=(t*ratio);
 glFragColor=vec4(out_color);
}
