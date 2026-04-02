#version 420

// original https://www.shadertoy.com/view/4tlfzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float impulse(float k, float x) {
    float h = k * x;
    return h * exp(1.0 - h);
}

//made with Inigo Quilez's heart formulanimation tutorial: https://www.youtube.com/watch?v=aNR4n0i2ZlM&list=PL0Epi
void main(void)
{
    vec2 st = gl_FragCoord.xy/resolution.xy;
    st.x = (st.x - 0.5) * resolution.x / resolution.y + 0.5;
    
    st.y -= abs(st.x-0.5) * (5.0 - abs(st.x-0.5)) / 8.0; //aply heart transform
    st.y = (st.y - 0.5) * 1.15 + 0.5; //shrink heart's height
    
    float t = impulse(2.0, 0.1+mod(1.5*time, 1.5) + 2.0*(st.y-0.5)/3.0);
    float radius = 0.5 * t;
    float smoothing = 0.01;
    
    vec3 material = mix(vec3(0.6, 0.0, 0.0), vec3(1.0, 0.0, 0.0), t);
    vec3 color = material * (1.0 - smoothstep(radius-smoothing, radius+smoothing, 
                              2.0*distance(st, vec2(0.5))));

    glFragColor = vec4(color,1.);
}
