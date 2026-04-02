#version 420

// original https://www.shadertoy.com/view/tsGBRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float time_scale=.5;
float angle_div=0.6;
#define TAU 6.28318530718
float box(vec2 center, vec2 uv, vec2 R){
    float d = length(max(abs(center+uv)-R,0.));
    return d;
}
mat2 rotate2d(float angle){
    return mat2(cos(angle),-sin(angle),
                sin(angle),cos(angle));
}
float t;
vec3 color = vec3(0.2549, 0.0157, 0.2549);
vec3 color2 = vec3(0.0, 0.9333, 1.0);
float makeThing(vec2 uv){
    float r = 0.;
    float N = 30.;
    float s=.70;
    for(float i=0.;i<N;i++){    
        float n = i/N;
        float anim=2.+sin(t+n*6.);
        float b = box(vec2(0.,0.), uv*rotate2d(float(i)*TAU*angle_div), vec2(s-n*s*anim,s-n*s*anim));
        b=smoothstep(3./resolution.y,.0,b);
        r = max(b*n,r);
    }
    return r;
}
void main(void) {
    vec2 R = resolution.xy;
    vec2 uv = (2.*gl_FragCoord.xy-R)/R.y;
    t = time*TAU*time_scale;
    float d=makeThing(uv);
    vec3 col = mix(color,color2,d);
    glFragColor = vec4(col,1);
}
