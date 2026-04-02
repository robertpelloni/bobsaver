#version 420

// original https://www.shadertoy.com/view/4stBzH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    uv -= .5;
  
    //uv.x *= mouse*resolution.xy.x * .005;
    uv.x *= cos(time + uv.y  ) * 2.;
    uv.y *= sin(time + uv.x ) * 2.;
    //uv.y *= mouse*resolution.xy.y * .005;
    float d = length(uv);
    float g = length(atan( d * time) * .4);
    float o = 25.f;
  
    vec3 col = vec3(smoothstep(g, g - .1, abs(sin(g * time * o )) ), 
                    smoothstep(g, g - .1, sin(g * time * o)), 
                    smoothstep(g, g - .1, sin(g * time * o) ));

    d = smoothstep(0.04, 0.42, d);
    
    glFragColor = vec4(col * d,1.0);
}
