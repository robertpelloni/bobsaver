#version 420

// original https://www.shadertoy.com/view/wlXXRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define BLACK_COL vec3(24,32,38)/255.
#define WHITE_COL vec3(245,248,250)/255.

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy * 0.5) / resolution.y;

    vec2 st = vec2(atan(uv.x, uv.y), length(uv));
        
    st.x += time*.1 + floor(st.y * 3. + time*.2)*0.3925;
    
    float g = st.x * 3.82 * 2.;
    float b1 = fract(g);
    float b2 = sin(st.y*50. - time * 10.) * .25 + .5;
    
    float gf = floor(mod(g, 2.)) * .6;
    float m = step(.125 - st.y*.25 * gf, abs(b2 - b1) );        
    
    m = (1.-m) * abs(1. - gf + .1);  
    
    vec3 col = mix(BLACK_COL, WHITE_COL, m);

    glFragColor = vec4(col, 1.0);
}
