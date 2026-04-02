#version 420

// original https://www.shadertoy.com/view/XssXWr
 
// Created by Vinicius Graciano Santos - vgs/2014
// Based on the following websites:
// http://www.josleys.com/article_show.php?id=82
// http://iquilezles.org/www/articles/distancefractals/distancefractals.htm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ITER 256
#define R1 0.3
#define R2 2.0
#define TAU 6.28318530718

vec2 droste(in vec2 uv) {
    float alpha = -atan(log(R2/R1)/TAU); // try alpha = 0.0
    vec2 rot = vec2(cos(alpha), sin(alpha));
    uv = vec2(log(length(uv)), atan(uv.y, uv.x));
    uv = vec2(uv.x*rot.x - uv.y*rot.y, uv.x*rot.y + uv.y*rot.x)/rot.x;
    uv.x = mod(uv.x, log(R2/R1));
    return R1*exp(uv.x)*vec2(cos(uv.y), sin(uv.y));
}

void main(void)
{
    float t = exp(-mod(1.5*time, 20.855)); // discontinuity :(
    vec2 z = vec2(0.0), dz = vec2(0.0);
    vec2 uv = droste(t*(-resolution.xy+2.0*gl_FragCoord.xy)/resolution.y);
    vec2 c = uv - vec2(0.4, 0.0);
    
    for (int i = 0; i < ITER; ++i) {
        if (dot(z, z) > 32.0) continue;
        dz = 2.0*vec2(z.x*dz.x - z.y*dz.y, z.x*dz.y + z.y*dz.x) + vec2(1.0, 0.0);
        z = vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + c;        
    }
    float d = abs(length(uv) - R2);
    d *= dot(z, z) <= 32.0 ? 0.0 : 0.5*sqrt(dot(z,z)/dot(dz,dz))*log(dot(z,z));
    vec3 tex = vec3(1.0,1.0,1.0); 
    tex = 0.2+0.7*tex*tex*(3.0-2.0*tex);
    glFragColor = vec4(tex*vec3(pow(d, 0.18)),1.0);
}
