#version 420

// original https://www.shadertoy.com/view/WdfcRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float tri(vec2 st, float pct){
  return 1.0 - smoothstep( pct, pct+0.05, st.y);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x/resolution.y;

    // Time varying pixel color
    vec3 color_a = vec3(uv.x * 0.2 + 0.8,0.2,0.0);
    vec3 color_b = vec3(0.0,0.1,uv.y * 0.5 + 0.5);
    vec3 color_c = vec3(0.6,0.5,0.0);
    float s = 10.0;
    uv *= s;
    uv.x += time;
    float y1 = mod(uv.x,1.0) + sin(uv.x / s + time * 2.0)+ sin(uv.y / s + time);
    float y2 = mod(uv.x,1.0) + sin(uv.x / s + time + 1.0 * 2.0) + sin(uv.y / s + time);
    vec3 col = color_a + vec3(tri(mod(uv,1.0), y1) * color_b + vec3(tri(mod(uv,1.0), y2)) * color_c);
    //vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
