#version 420

// original https://www.shadertoy.com/view/lldcRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//by greenbird
#define S(a, b, c) smoothstep(a,b,c)

float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}
vec2 random2(vec2 st){
    st = vec2( dot(st,vec2(127.1,311.7)),
              dot(st,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}

// Value Noise by Inigo Quilez - iq/2013
// https://www.shadertoy.com/view/lsf3WH
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( random2(i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ),
                dot( random2(i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
            mix( dot( random2(i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ),
                dot( random2(i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}

float fbm(vec2 n) {
    float total = 0.0, amplitude = 1.0;
    for (int i = 0; i < 5; i++) 
    {
        total += noise(n) * amplitude; 
        n += n;
        amplitude *= 0.5; 
    }
    return total;
} 

float dis(vec2 a){
    return sqrt(a.x * a.x + a.y * a.y);
}

void main(void)
{
    vec2 st = gl_FragCoord.xy/resolution.xy;
    st -= 0.5;
    st.x *= resolution.x/resolution.y;

    vec2 _st = st*4. - floor(st*4.);
    
    float u_time = time;
    
    
    float shaft = mix(0., 1., fbm(vec2(st.x*10.+u_time/5., st.y/4.)));
    shaft = mix(shaft, 1., fbm(vec2(st.x*10.+100.-u_time/5., st.y/4.)));
    shaft = mix(shaft, 1., fbm(vec2(st.x*3., st.y/4.)));
    shaft = mix(shaft, 1., fbm(vec2(st.x*3.+10., st.y/4.)));

    
    glFragColor = vec4(
        vec3(shaft)
        , 
        1.0); 

}
