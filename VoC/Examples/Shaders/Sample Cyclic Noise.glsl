#version 420

// original https://www.shadertoy.com/view/Wl3BR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159265
#define iterations 13

vec3 function(vec3 x){
    vec3 ca = vec3(0.420,0.827,1.000)*cos(x.xxx)+vec3(1.000,0.902,0.859)*cos(x.yyy);
    vec3 cb = vec3(0.898,1.000,0.922)*cos(x.zzz*1.5);
    return ca*cb-cb;
}

mat2 ROT(float ang)
{
    return mat2(cos(ang), sin(ang), -sin(ang), cos(ang));
}

#define SCALE 1.5
#define SHIFT vec3(2.3, -5.2, 1.0)

vec3 fractal(vec3 x){
    x *= pi;
    vec3 v = vec3(0.0);
    float a = 0.5;
    mat2 rmZ = SCALE*ROT(0.35);
    mat2 rmX = SCALE*ROT(0.46);
    for (int i = 0; i < iterations; i++){
        vec3 F =function(x); 
        v += a*F;
        x.xy = rmZ*x.xy;
        x += 0.3*F;
        x.yz = rmX*x.yz;
        x += SHIFT;
        a /= 1.1*SCALE;
    }
    return v;
}

void main(void) {
    vec2 uv = 1.5*(gl_FragCoord.xy-0.5*resolution.xy)/max(resolution.x, resolution.y);
    vec3 color = 0.8*fractal(vec3(uv, 0.05*time))+0.4;
    glFragColor = vec4(tanh(pow(color, vec3(1.4))), 1.0);
}
