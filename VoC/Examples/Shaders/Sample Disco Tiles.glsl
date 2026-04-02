#version 420

// original https://www.shadertoy.com/view/wltyWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 st = vec2(gl_FragCoord.xy / resolution.xy);
    st.x *= resolution.x/resolution.y;

    float pattern1 = sin((st.x ) * 100.0);
    float pattern2 = cos((1.0 - st.y) * 100.0);

    vec3 col1 = 0.5 + 0.2 * cos(time + st.xyx + vec3(0,2,4));
    vec3 col2 = 0.2 + 0.5 * cos(time + st.xyx + vec3(0,2,4));

    vec3 a = (pattern1 * pattern2) * col1;
    vec3 b = (pattern1 + pattern2) * col2;

    vec3 finalColor = a + b;
    glFragColor = vec4(finalColor, 1.0);
}
