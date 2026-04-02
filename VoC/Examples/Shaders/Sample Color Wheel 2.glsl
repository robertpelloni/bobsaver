#version 420

// original https://www.shadertoy.com/view/lt2GD1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

vec3 hsb2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0, 
                     0.0, 
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

float hypot(in vec2 p) {
    return sqrt(pow(p.x, 2.0) + pow(p.y, 2.0));   
}

float plot(vec2 st, float pct){
  return  smoothstep(pct-0.02, pct, st.y) - 
          smoothstep(pct, pct+0.02, st.y);
}

float impulse(float x, float at){
  return  step(at-0.02, x) - 
          step(at+0.02, x);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.x;
    vec2 cuv = uv - vec2(0.5, 0.5*resolution.y / resolution.x);
    float angle = (atan(cuv.y, cuv.x)/PI + 1.0) / 2.0 + time * 3.0;
    float dist = hypot(cuv);
    //float intens = impulse(dist, 0.2);
    vec3 hsbOut = vec3(angle, dist*2.0, clamp(2.0*sin(time*2.0), 0.0, 1.3));
    glFragColor = vec4(hsb2rgb(hsbOut), 1.0);
}
