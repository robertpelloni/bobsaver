#version 420

// original https://www.shadertoy.com/view/WtfyzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 p = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0.);
    float t = .005;
    float k = 3.;
    float d = 0.;
    for(int i = -80; i <= 70; ++i)
    {
      float f = float(i)/120.;
      float x = p.x + cos(f*9.)*.25;
      x = x*k;
      float y = p.y + f;
      y += -cos(x+f*18.+ time*.5)*smoothstep(1.,.0,abs(x))*.1;
      float m = smoothstep(t,-t,y);
      d = mix(d,m,m);
    }
    
    col += d;

    glFragColor = vec4(col,1.0);
}
