#version 420

// original https://www.shadertoy.com/view/ttVXDw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define t (time*.15)
#define steps 50.
#define scale 2.5

vec2 sphere(vec3 p, vec3 rd, float r){
    float b = dot( -p, rd ),
    inner = b*b - dot(p,p) + r*r;
    return inner < 0. ?  vec2(-1.) : vec2(b - sqrt(inner), b + sqrt(inner));
}

float formula(vec3 p) {
    p*=scale;
    float m=100.;
    for (int i=0; i<7; i++) {
        p=abs(p)/dot(p,p)-1.;
        vec3 ap=abs(p);
        m=min(min(ap.z,min(ap.x,ap.y)),m);
    }
    m=pow(max(0.,1.-m),250.);
    return m*2.+dot(p,p)*.05+.1;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy - .5;  
    uv.x*=resolution.x/resolution.y;
    float distorig=1.3+sin(t*1.35435);    
    vec3 ro = -vec3(0.,0., 2.),
         rd =normalize(vec3(uv,1.)),
         v = vec3(0), p;
    vec2 tt;
    //vec2 m=mouse*resolution.xy.xy/resolution.xy*3.14;
    //if (mouse*resolution.xy.z<.1) m=vec2(t*.3);
    vec2 m=vec2(t*.3);
    float c,s;
    mat2 rot;
    c=cos(-m.x),s=sin(-m.x);
    rot = mat2(c,-s,s,c);    
    ro.xz*=rot;
    rd.xz*=rot;
    ro.yz*=rot;
    rd.yz*=rot;

    float st=1.5/steps;
    for (float i=5.; i<steps; i++) {
        float d=i*st;
        tt = sphere(ro, rd, d);
        p = ro+rd*tt.x;
        v+=formula(p)*step(0.,tt.x)*smoothstep(0.,distorig,distorig-tt.x+.4);
        p = ro+rd*tt.y;
        v+=formula(p)*step(0.,tt.x)*smoothstep(0.,distorig,distorig-tt.y+.4);
    }

    glFragColor.xyz = vec3(1.,.95,.9)*v*.1*smoothstep(0.,8.,time);
}
