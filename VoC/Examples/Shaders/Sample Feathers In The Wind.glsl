#version 420

// original https://www.shadertoy.com/view/tljcRW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Feathers in the Wind - by Martijn Steinrucken aka BigWings 2020
// Email:countfrolic@gmail.com Twitter:@The_ArtOfCode
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// An effect created for a YouTube tutorial. You can watch it here:
// Part 1: https://youtu.be/68IFmCCy_AM
// Part 2: https://youtu.be/hlM940IqpRU

#define S smoothstep
#define T (time*.5)

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c,-s,s,c);
}

float Feather(vec2 p) {
    float d = length(p-vec2(0,clamp(p.y, -.3, .3)));
    float r = mix(.1, .03, S(-.3, .3, p.y));
    float m = S(.01, .0, d-r);
    
    float side = sign(p.x);
    float x = .9*abs(p.x)/r;
    float wave = (1.-x)*sqrt(x) + x*(1.-sqrt(1.-x));
    float y = (p.y-wave*.2)*80.+side*56.;
    float id = floor(y+20.);
    float n = fract(sin(id*564.32)*763.); 
    float shade = mix(.5, 1., n);
    float strandLength = mix(.7, 1., fract(n*34.));
    
    float strand = S(.4, .0, abs( fract(y)-.5 )-.35);
    strand *= S(.1,-.2, x-strandLength);
    
    d = length(p-vec2(0,clamp(p.y, -.45, .1)));
    float stem = S(.01,.0, d+p.y*.025);
    
    return max(strand*m*shade, stem);
}

vec3 Transform(vec3 p, float angle) {
    p.xz *= Rot(angle);
    p.xy *= Rot(angle*.7);
    
    return p;
}

vec4 FeatherBall(vec3 ro, vec3 rd, vec3 pos, float angle) {
    
    vec4 col = vec4(0);
    
    float t = dot(pos-ro, rd);
    vec3 p = ro + rd * t;
    float y = length(pos-p);
    
    if(y<1.) {
        float x = sqrt(1.-y);
        vec3 pF = ro + rd * (t-x) - pos; // front intersection
        float n = pF.y*.5+.5;
        
        pF = Transform(pF, angle);
        vec2 uvF = vec2(atan(pF.x, pF.z), pF.y); // -pi<>pi, -1<>1
        uvF *= vec2(.25,.5);
        float f = Feather(uvF);
        vec4 front = vec4(vec3(f), S(0., .6, f));
        
        front.rgb *= n*n;
        
        vec3 pB = ro + rd * (t+x) - pos; // back intersection
        n = pB.y*.5+.5;
        pB = Transform(pB, angle);
        vec2 uvB = vec2(atan(pB.x, pB.z), pB.y); // -pi<>pi, -1<>1
        uvB *= vec2(.25, .5);
        float b = Feather(uvB);
        vec4 back = vec4(vec3(b), S(0., .6, b));
        back.rgb *= n*n;//*.5+.5;
        
        col = mix(back, front, front.a);
    }
    col.rgb = sqrt(col.rgb);
    
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 M = mouse*resolution.xy.xy/resolution.xy -.5;
    
    vec3 bg = vec3(.2, .2, .7)*(uv.y+.5)*2.5;
    bg += vec3(.8, .6, .4)*(-uv.y+.5);
    
    vec4 col = vec4(bg, 0);
    
    vec3 ro = vec3(0,0,-3);
    vec3 rd = normalize(vec3(uv, 1));
   
    for(float i=0.; i<1.; i+=1./80.) {
        
        float n = fract(sin(i*564.3)*4570.3);
        float x = mix(-8., 8., fract(fract(n*10.)+T*.1))+M.x;
        float y = mix(-2., 2., n)+M.y;
        float z = mix(5., 0., i);
        float a = T+i*563.34;
        
        vec4 feather = FeatherBall(ro, rd, vec3(x, y, z), a);
        
        feather.rgb = mix(bg, feather.rgb, mix(.3, 1., i));
        feather.rgb = sqrt(feather.rgb);
        
        col = mix(col, feather, feather.a);
    }
    
    col = pow(col, vec4(.4545)); // gamma correction
    
    glFragColor = col;
}
