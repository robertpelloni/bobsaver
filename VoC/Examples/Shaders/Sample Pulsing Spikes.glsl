#version 420

// original https://www.shadertoy.com/view/wtBSRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI2 6.28318530718
#define PI 3.14159265359
#define e 2.71828182845904523536

float lineDF(vec2 a, vec2 b, vec2 p){
    vec2 ab = b-a;
    vec2 ap = p-a;
    float t = dot(ap,ab)/dot(ab,ab);
    t = clamp(t,0.,1.);
    vec2 c = a + t*ab;
    return length(p-c);
}

void main(void)
{
    float t = time*3.;
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    float scale = 1.5;
    uv *= scale;

    float t2 = t*2.;
    float t3 = t*.1;
    float c = 999999.;
    float c2 = 999999.;
    vec2 prev = vec2(0);
    float skip = 23.;//floor(mod(t2,24.)/2.)*2.+3.;
    float waves = floor(mod(t3,6.));
    float f = pow(cos(t3*PI2-PI2)*.5+.5, 8.);

    for (float a = 0.; a < PI2+.1; a += PI2/50.){
        // lines
        float a2 = a * skip + PI/2.;
        vec2 p = vec2(cos(a2), sin(a2))*.5;
        vec2 off = normalize(p) * mix(.0,.15,cos(a2*waves+t2)*.5+.5);
        p += mix(off, vec2(0), f);;
        if (a > 0.){        
            float ci = lineDF(prev,p,uv);
            c = min(c,ci);
        }
        prev = p;
        
        // circles
        float a0 = a + PI/2.;
        vec2 p0 = vec2(cos(a0), sin(a0))*.5;
        vec2 off0 = normalize(p0) * mix(.0,.15,sin(a0*waves+t2)*.5+.5);
        p0 += mix(off0, vec2(0), f);
        float s = .005;
        float c2i = length(p0-uv)-s;
        c2 = min(c2,c2i);
    }
    
    // combine
    c = min(c,c2);
    
    // step
    float w = 1.5*scale/resolution.y;//*mix(1.,300.,sin(t)*.5+.5);
    float lw = .001;
    c = smoothstep(lw+w,lw-w, c);
    
    vec3 col = vec3(c);
    col *= (0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4)));
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
