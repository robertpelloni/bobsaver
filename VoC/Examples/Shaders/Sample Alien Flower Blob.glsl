#version 420

// original https://www.shadertoy.com/view/tt2XRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define PI2 6.28318530718
#define S01(t) sin(t) * .5 + .5
#define C01(t) cos(t) * .5 + .5
#define S(a,b,t)  mix(a, b, S01(t))
#define C(a,b,t)  mix(a, b, C01(t))
#define BPM 130.
#define BPS BPM/60.

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
    
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    float scale = 15.;
    uv *= scale;
    float t = time*BPS;
    
    //uv = abs(uv);
    
    float t2 = t / 32.;
    uv += vec2(cos(t2*PI2)*1., sin(t2*PI2))*1. * sin(t2*PI2*3.)*2.;
    
    float c = 9999.;
    vec2 prev = vec2(0);
    
    float a0 = atan(uv.x,uv.y)/PI2+.5;
    float l0 = length(uv);
    
    float t1 = t / 8.;
    float count = 20.;
    float inc = PI2/count;
    float lw = mix(.05,.15,sin(l0*.05*PI2*15.)*.5+.5) * (l0*.5);
    for (float a = 0.; a < count+.5; a += inc){
        float a1 = a+PI/2. + t1;
        vec2 p = vec2(cos(a1),sin(a1)) * sin(a1*6.)*5.;
        if(a > 0.){
            c = min(c, lineDF(prev,p,uv) + lw);
        }
        c = min(c,length(p-uv)-.2);
        prev = p;
    }
    
    float w = (7./resolution.y);
    float l = .25;
    c = smoothstep(l+w,l-w,c);
    
    c = pow(c,.125);
    
    
    vec3 col = vec3(c);

    // Output to screen
    uv /= scale;
    //col = mix(col, vec3(1,0,0), step(abs(uv.y),.5/resolution.y)*.1); // hori
    //col = mix(col, vec3(0,1,0), step(abs(uv.x),.5/resolution.y)*.1); // vert
    glFragColor = vec4(col,1.0);
}
