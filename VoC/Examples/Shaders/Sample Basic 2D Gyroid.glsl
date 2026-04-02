#version 420

// original https://www.shadertoy.com/view/3sSSRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 cgyroid(vec3 p)
{
   
  float g = (cos(p.x) * sin(p.y) + cos(p.y) * sin(p.z) + cos(p.z) * sin(p.x));
    return vec3(g);
 // return vec3(g+p.x,g+p.y,g+p.z) * cos(atan(p.x,p.y));
  //  return vec3(g+p.x,g+p.y,g+p.z) * cos(length(p));
    
    
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = 2.0*gl_FragCoord.xy/resolution.xy;
    float aspect = resolution.x/resolution.y;
    uv.x *= aspect;
    vec2 dc = uv -.5;
    dc *= 8.0;

    vec3 col = cgyroid(vec3(dc.x,dc.y,cos(time)*5.0));
    col += vec3(sin(time), sin(time * 0.5), sin(time*0.15));
    glFragColor = vec4(col,1.0);
}

