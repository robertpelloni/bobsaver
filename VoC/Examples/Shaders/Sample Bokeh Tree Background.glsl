#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3djfWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

precision lowp float;

#define PI 3.14159265358979
#define R 0.07
#define D 0.05

const vec3 base_colors[] = vec3[](
    vec3(1.0, 5.0, 0.0),
    vec3(2.0, 2.0, 9.0),
    vec3(5.0, 4.0, 2.0),
    vec3(4.0, 4.0, 5.0)
);

// from https://www.shadertoy.com/view/lsf3WH
float hash(vec2 p) {
    p  = 50.0*fract( p*0.3183099 + vec2(0.71,0.113));
    return fract( p.x*p.y*(p.x+p.y) );
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( hash( i + vec2(0.0, 0.0) ), 
                     hash( i + vec2(1.0, 0.0) ), u.x),
                mix( hash( i + vec2(0.0, 1.0) ), 
                     hash( i + vec2(1.0, 1.0) ), u.x), u.y);
}

// from https://www.shadertoy.com/view/MsKGWz
float hash12(vec2 p) {
    float h = dot(p,vec2(127.1, 311.7));    
    return fract(sin(h)*43758.5453123);
}

// from https://www.shadertoy.com/view/MsKGWz
float hash5(float x) {
    return fract(sin(x)*43758.5453+0.4);
}

float disc(vec2 c, vec2 pos) {
    pos -= c;
    float d = length(pos / R);
    if (d > 1.0+D) {
        return 0.0;
    }
    else {
        float a = atan(pos.y, pos.x);
        float dm = d + 0.03*(cos(a*5.0+2.5)+1.0);
        return (0.02+0.01*(
            ((dm < 1.0+D) ? smoothstep(0.0, 1.0, dm) : 0.0) -
            smoothstep(1.0, 1.0+D, dm)))*
            (0.75+0.25*noise(75.0*pos*mat2( 1.6,  1.2, -1.2,  1.6 )));
    }
}
    
    
void main(void) {
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float aspect = resolution.y/resolution.x;
    uv.y *= aspect;
    vec3 col = mix(vec3(0.02, 0.05, 0.00),
                   vec3(0.10, 0.20, 0.05),
                   dot(vec2(0.6, 0.6/aspect), uv)+
                   //0.4*noise(20.0*uv)-0.2+
                   0.2*hash12(uv)-0.1);
    
    for (float i=100.0; i>0.0; i--) {
        int m = int(i) & 3;
        float x = 1.1*hash5(2.0*i+3.0)-0.05;
        float y = 1.1*hash5(5.0*i)-0.05;
        float dx = 0.05*sin(0.3*time+0.01*i) + 0.05*sin(0.4*time+0.01*i);
        float dy = 0.03*sin(0.2*time+0.100*i) + 0.03*sin(0.3*time+0.100*i);
        float b = pow((1.0+cos(0.75*time+0.1*i)), 0.5) * (0.7+0.3*cos(0.51*time+0.03*i));
        col += (base_colors[m] + 2.0*vec3(hash5(x), hash5(y), hash5(x+y))) *
            disc(vec2(x+dx, (y+dy)*aspect), uv) * b;
    }

    // tone mapping and gamma
    glFragColor = vec4(pow(col/(col+1.0), vec3(1.0)/2.2), 1.0);
}
