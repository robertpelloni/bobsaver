#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wdlfWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// https://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdCapsule( vec2 p, vec2 a, vec2 b, float r )
{
  vec2 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

float letL(vec2 p) {
    return min(sdCapsule(p, vec2(0.2, 0.0), vec2(0.2, 1.0), 0.1),
               sdCapsule(p, vec2(0.2, 0.0), vec2(0.856, 0.0), 0.1));
}

float letI(vec2 p) {
    return min(sdCapsule(p, vec2(0.4, 0.0), vec2(0.6, 0.0), 0.1),
               min(sdCapsule(p, vec2(0.5, 0.0), vec2(0.5, 1.0), 0.1),
                   sdCapsule(p, vec2(0.4, 1.0), vec2(0.6, 1.0), 0.1)));
}

float letN(vec2 p) {
    return min(sdCapsule(p, vec2(0.856, 1.0), vec2(0.856, 0.0), 0.1),
               min(sdCapsule(p, vec2(0.0, 0.0), vec2(0.0, 1.0), 0.1),
                   sdCapsule(p, vec2(0.0, 0.0), vec2(0.856, 1.0), 0.1)))/2.0;
}

float letF(vec2 p) {
    return min(sdCapsule(p, vec2(0.2, 1.0), vec2(0.856, 1.0), 0.1),
               min(sdCapsule(p, vec2(0.2, 0.0), vec2(0.2, 1.0), 0.1),
                   sdCapsule(p, vec2(0.2, 0.56), vec2(0.8, 0.56), 0.1)))/2.0;
}

float letE(vec2 p) {
    return min(sdCapsule(p, vec2(0.1, 0.0), vec2(0.1, 1.0), 0.1),
               min(sdCapsule(p, vec2(0.1, 0.0), vec2(0.856, 0.0), 0.1),
                   min(sdCapsule(p, vec2(0.1, 0.5), vec2(0.8, 0.5), 0.1),
                       sdCapsule(p, vec2(0.1, 1.0), vec2(0.856, 1.0), 0.1))));
}

float rand(vec2 p) {
    return fract(sin(dot(p, vec2(3213213.312321, 98021.321391)))*32312.31231);
}

float intensity(vec2 p, float ot) {
    vec2 id = floor(p*2.6);
    p = fract(p*2.6)*1.1-0.05;

    float t = ot*1.2-id.y;
    float ph = fract(t);
    float cy = floor(t);

    vec2 q = p;
    q *= 2.0;

    float[8] ds = float[](
        letL(q),
        letI(q),
        letF(q),
        letE(q),
        letL(q),
        letI(q),
        letN(q),
        letE(q));

    int fi = int(mod(cy+id.x-id.y*4.0, 8.0));
    int ti = (fi+1)%8;
    float df = ds[fi], dt = ds[ti];
    float m = 1.0/(1.0+exp(-4.0*(ph*2.0-1.0)));
    
    return min(1.1, 1.0/exp(mix(df, dt, m)*40.0));

}

void main(void)
{
    vec2 p = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    
    vec3 col = vec3(intensity(p, time),
                    intensity(p, time-0.1),
                    intensity(p, time-0.2));
    col -= log(1.0+length(p))*0.5;
    
    glFragColor = vec4(col,1.0);
    return;
}
