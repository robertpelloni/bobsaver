#version 420

#define PI 3.14159265359

uniform vec2 resolution;
uniform vec2 mouse;
uniform float time;

out vec4 glFragColor;

float rand(float x){
  return fract(sin(x)*1.);
}

float random(vec2 st){
    return fract(sin(dot(st.xy, vec2(12.9898,78.233)))*43758.5453123);
}

vec2 random2D(vec2 st){
    st = vec2(dot(st,vec2(127.1,311.7)), dot(st,vec2(269.5,183.3)));

    return 2.0*fract(sin(st)*43758.5453123) - 1.0;
}

float noise(in vec2 st){
    vec2 i = floor(st * 20.);
    vec2 f = fract(st * 20.);

    vec2 u = f*f*(3.0-2.0*f);

    return mix(
        mix(
            dot(random2D(i + vec2(0.0,0.0)), f - vec2(0.0,0.0)),
            dot(random2D(i + vec2(1.0,0.0)), f - vec2(1.0,0.0)),
            u.x
        ),
        mix(
            dot(random2D(i + vec2(0.0,1.0)), f - vec2(0.0,1.0)),
            dot(random2D(i + vec2(1.0,1.0)), f - vec2(1.0,1.0)),
            u.x
        ),
        u.y
    );

}

vec2 rotate(in vec2 st, float angle){
    return st * mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

void main(){
    vec2 st = (gl_FragCoord.xy * 2. - resolution.xy) / min(resolution.x, resolution.y);

    float l = length(st);
    float f = smoothstep(l - 0.03, l + 0.03 , 0.85);

    float n = 0.;
    for(int i = 0; i < 5; i++){
        n += noise(rotate(st , noise(st * noise(vec2(time * 0.0006))))) + float(i) * 0.05;
    }

    f *= n;

    glFragColor = vec4(f * vec3(0.9529, 0.5843, 0.1647), 1.);
}
