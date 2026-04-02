#version 420

// original https://www.shadertoy.com/view/4tVXz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535
#define iterations 200

vec3 huetorgb(float hue) {
    float h = mod(hue,1.0);
    h *= 3.0;
    float sgmt = floor(h);
    h = fract(h);
    vec3 rgb;
    if      (sgmt == 0.0) rgb = vec3(mix(1.0,0.0,h), mix(0.0,1.0,h), 0.0          ) ;
    else if (sgmt == 1.0) rgb = vec3(0.0,            mix(1.0,0.0,h), mix(0.0,1.0,h));
    else                  rgb = vec3(mix(0.0,1.0,h), 0.0,            mix(1.0,0.0,h));
    return pow(normalize(rgb),vec3(0.5));
}

float atan2(vec2 vec) {
    if (vec.x == 0.0) {
        if (vec.y>0.0) return PI;
        else return -PI;
    }
    else return atan(vec.y,vec.x);
}

vec2 cmplxPOW(vec2 z, float exponent) {
    float r = length(z);
    float o = atan2(z);
    r = pow(r, exponent);
    o = exponent*o;
    return vec2(r*cos(o),r*sin(o));
}

float calcdist(vec2 p) {
    //float line1 = abs(p.x+0.2);
    //float line2 = abs(p.y);
    float r = length(p);
    float o = atan2(p);
    float flower1 = abs(0.5*sin(4.0*o+time)-r);
    float flower2 = abs(0.5*sin(4.0*o+PI+time)-r);
    return min(flower1,flower2);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = 2.0*uv-1.0;
    uv.x *= resolution.x / resolution.y;
    uv *= 1.0/pow(2.0,4.0*sin(time*0.2)+4.0);
    uv.x += -0.9;
    uv.y += 0.2;
    
    vec3 col = vec3(0.8);
    
    
    vec2 z = vec2(0.0);
    vec2 c = uv;
    bool inset = true;
    float orbit = 999999.9;
    float f = 0.0;
    for (int i = 0; i < iterations; i ++) {
        z = cmplxPOW(z,4.0/*+2.0*sin(0.2*time)*/) + c;
        orbit = min(orbit,calcdist(z));
        ++f;
        if (dot(z,z)>4.0) {
            inset = false;
            break;
        }
    }
    
    col = huetorgb(1.0/(1.0+orbit*10.0)+0.6);
    //if (inset) col = vec3(0.0);
    
    glFragColor = vec4(col, 1.0);
    
}
