#version 420

// original https://www.shadertoy.com/view/styyWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//prototype state - code neither optimized nor readable

#define MAX_STEPS 100
#define MAX_DIST 80.
#define SURF_DIST .00001
#define SURF_MUL 13000.

#define EYE_DIS 0.7
#define FIL_COR 1.5

#define time time * 1.0 //bpm adjustment 1.0 = 124bpm

mat2 Rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float GetDist(vec3 p) {

    p *= 1. + smoothstep(-1., 0.5,sin(time*6.5))*0.01;
    vec3 r = p ;
    float l = length(p);
    r.xz *= Rot(sin(time/19.)*6.28*smoothstep(10., 100., l));
    r.zy *= Rot(sin(time/14.)*6.28*smoothstep(5., 100., l));
    r.yx *= Rot(sin(time/11.)*6.28*smoothstep(3., 100., l));
    
    float web = length(cross(sin(r/ (1.0 + smoothstep(5., 10., l))), normalize(r)))-(sin(time*1.75+r.y-r.z)*0.02+0.03);
    
    float dp = 1. - smoothstep(0., 1., dot(sin(p/10.), cos(p/10.))+sin(time/3.25));
    web -= smoothstep(0.98, 1., sin(pow(length(p), 1.7)/50. - (time*3.25)))*0.08*dp;
    
    p *= 1. + smoothstep(-0.5,1.0,sin(time*3.25))*0.1;

    float wire = abs(dot(sin(p+vec3(0.,0.,0.)), cos(p+(3.14/2.))))-(smoothstep(-0.5, 1., sin(time/17.))*3.);
                         
    p *= 1. + smoothstep(-0.3,1.0,sin(time*6.5))*(0.1+sin(time*3.25)*0.05);
    
    float sphere = abs(length(p)-5.+(sin(time/7.)*2.))-(sin(time/21.)*.5+1.);

    float d = mix(sphere, wire, 0.5+(sin(time/11.)*0.2));
    
    
    d = mix(d, web, sin(time/12.)*0.25+0.3);
    
    
    d = min(d, pow(web, 1.2));
    
    return d;
}

vec3 RayMarch(vec3 ro, vec3 rd) {
    float dO=15.0;
    int steps = 0;
    for(int i=0; i<MAX_STEPS; i++) {
        steps = i;
        vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        dO += dS;
        if(dO>MAX_DIST || dS<(SURF_DIST * (pow(dO/ MAX_DIST,1.5)*SURF_MUL+1.))) break;
    }
    
    return vec3(dO, steps, 0.);
}

vec3 GetNormal(vec3 p) {
    vec2 e = vec2(.001, 0);
    vec3 n = GetDist(p) - 
        vec3(GetDist(p-e.xyy), GetDist(p-e.yxy),GetDist(p-e.yyx));
    
    return normalize(n);
}

float GetLight(vec3 p) {
    vec3 lightPos = vec3(cos(time / 12.)*30., 20., sin(time / 12.)*30.);
    vec3 l = normalize(lightPos-p);
    vec3 n = GetNormal(p);
    
    float dif = clamp(dot(n, l)*.5+.5, 0., 1.);
    //float d = RayMarch(p+n*SURF_DIST*2., l).x;
    
    return dif;
}

vec3 R(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = p+f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i-p);
    return d;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 m = mouse*resolution.xy.xy/resolution.xy;
    
    float colL = 0.;
    float colR = 0.;

    vec3 p1 = vec3(0), p2 = vec3(0);
    vec3 ro = vec3(0, 4.+(sin(time/13.)*3.), -30.+(sin(time/11.)*5.));
    ro.yz *= Rot(-m.y*3.14+1.);
    ro.xz *= Rot(-m.x*6.2831);

    vec3 rd = R(uv, ro, vec3(0,1,0), 1.+sin(time/3.)*.1);

    vec3 rmd = RayMarch(ro, rd);
    float depth = pow(1. - rmd.x / MAX_DIST, 2.);

    if(rmd.x<MAX_DIST) 
    {
        p1 = ro + rd * rmd.x;
        colL = GetLight(p1) * depth * depth;
        colL += rmd.y / float(MAX_STEPS) * depth * (1.5-smoothstep(10., 20., length(p1)));
    }
    
    float eyedis = EYE_DIS; //smoothstep(-0.1, 0., sin(time/2.))*0.2;
    ro += cross(rd, vec3(0.,-1.,0.)) * eyedis;
    rd = R(uv, ro, vec3(0,1,0), 1.+sin(time/3.)*.1);

    rmd = RayMarch(ro, rd);
    depth = pow(1. - rmd.x / MAX_DIST, 1.);

    if(rmd.x<MAX_DIST) 
    {
        p2 = ro + rd * rmd.x;
        colR = GetLight(p2) * depth * depth;
        colR += rmd.y / float(MAX_STEPS) * depth * (1.5-smoothstep(10., 20., length(p2)));
    }
    
    colL *= FIL_COR; //red filter correction
    colR /= FIL_COR; //blue filter correction
    
    //neural flash
    float dp = 1. - smoothstep(0., 1., dot(sin(p1/10.), cos(p1/10.))+sin(time/3.25));
    float nfL = 1. - smoothstep(0.98, 1., sin(pow(length(p1), 1.7)/50. - (time*3.25))) * dp; 
    float nfR = 1. - smoothstep(0.98, 1., sin(pow(length(p2), 1.7)/50. - (time*3.25))) * dp;
    
    colL *= (1.5 - smoothstep(10., 15., length(p1)) * nfL);
    colR *= (1.5 - smoothstep(10., 15., length(p2)) * nfR);

    vec3 colS = smoothstep(vec3(0.), vec3(1.), vec3(colL, colR, colR));
    
    colS = pow(colS, vec3(.4545));    // gamma correction
    
    glFragColor = vec4(colS,1.0);
}
