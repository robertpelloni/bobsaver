#version 420

// original https://www.shadertoy.com/view/MltXWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Original "Droste Mandelbrot" vgs/2014
// https://www.shadertoy.com/view/XssXWr

#define TAU 6.28318530718

vec2 droste(in vec2 uv) {
    float alpha = atan(log(2.0/.3)/TAU) - 0.0;
    vec2 rot = vec2(cos(alpha), sin(alpha));
    uv = vec2(log(length(uv)), atan(uv.y, uv.x));
    uv = vec2(uv.x*rot.x - uv.y*rot.y, uv.x*rot.y + uv.y*rot.x)/rot.x;
    uv.x = mod(uv.x, log(2.0/.3));
    return 0.3*exp(uv.x)*vec2(cos(uv.y-0.5*time), sin(uv.y-0.5*time)); // drehung

}

void main(void)
{
    float t = exp(-mod(0.90*time, +20.825));
    vec2 z = vec2(0.0), dz = vec2(0.0);
    vec2 uv = droste(t*(-resolution.xy+2.0*gl_FragCoord.xy)/resolution.y);
    vec2 c = uv - vec2(0.5, -0.2);
    for (int i = 0; i < 256; ++i) 
    {
        if (dot(z, z) > 40.0) continue;
        dz = 2.0*vec2(z.x*dz.x - z.y*dz.y, z.x*dz.y + z.y*dz.x) + vec2(1.0, 0.0);
        z = vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + c;        
    }
    float d = abs(length(uv) -2.0);
    d *= dot(z, z) <= 32.0 ? 0.0 : 0.5*sqrt(dot(z,z)/dot(dz,dz))*log(dot(z,z));
    float t2 = exp(-mod(0.9*time, +20.825)); 
    vec2 z2 = vec2(0.0), dz2 = vec2(0.0);
    vec2 uv2 = droste(t2*(-resolution.xy+2.01*gl_FragCoord.xy)/resolution.y);
    vec2 c2 = uv2 - vec2(0.5, -0.25);
    float iflo = 1.0;
    for (int i2 = 0; i2 < 256; ++i2) 
    {
        if (dot(z2, z2) > 15.0) continue;
        if (iflo >= 0.4) {iflo -= 0.08*(1./iflo);}
        dz2 = 2.0*vec2(z2.x*dz2.x - z2.y*dz2.y, z2.x*dz2.y + z2.y*dz2.x) + vec2(1.0, 0.0);
        z2 = vec2(z2.x*z2.x - z2.y*z2.y, 2.0*z2.x*z2.y) + c2;
    }
    float d2 = abs(length(uv2) -2.0);
    d2 *= dot(z2, z2) <= 32.0 ? 0.0 : 0.5*sqrt(dot(z2,z2)/dot(dz2,dz2))*log(dot(z2,z2));

    vec3 col = vec3(9.*d,10.*d,12.0*d);
    vec3 col2 = vec3(iflo,iflo,iflo*2.4);
    glFragColor = mix(vec4(col*vec3(pow(d, 0.5)),1.0),vec4(col2*vec3(pow(d2, .2)),1.0),0.5*col2.z);
    
}
