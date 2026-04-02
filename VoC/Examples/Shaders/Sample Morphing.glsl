#version 420

// original https://www.shadertoy.com/view/MslSDN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Sebastien Durand - 2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define U(a,b) (a.x*b.y-b.x*a.y)

vec2 P = vec2(1,.72), O = vec2(-1.16,.63);
vec3 L = normalize(vec3(P, 1)), Y = vec3(0,1,0), E = Y*.01;
vec2 A[15], T[4];
float tMorph;

// Distance to Bezier
vec2 B(vec2 m, vec2 n, vec2 o, vec3 p) {
    vec2 q = p.xy;
    m-= q; n-= q; o-= q;
    float x = U(m, o), y = 2. * U(n, m), z = 2. * U(o, n);
    vec2 i = o - m, j = o - n, k = n - m, 
         s = 2. * (x * i + y * j + z * k), 
         r = m + (y * z - x * x) * vec2(s.y, -s.x) / dot(s, s);
    float t = clamp((U(r, i) + 2. * U(k, r)) / (x + x + y + z), 0.,1.);
    r = m + t * (k + k + t * (j - k));
    return vec2(sqrt(dot(r, r) + p.z * p.z), t);
}

float smin(float a, float b, float k){
    float h = clamp(.5+.5*(b-a)/k, 0., 1.);
    return mix(b,a,h)-k*h*(1.-h);
}

// Distance to scene
float M(vec3 p) {
    // Distance to Cube
    float dShape;
    if (tMorph > 0.) {
            vec3 d = abs(p-vec3(.0,.6,0)) - vec3(1.1,.6,.8);
           dShape = min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
    } else { 
        dShape = length(p-vec3(.1,.4,0))-1.;
    }
    // Distance to teapot
    vec2 h = B(P, vec2(.92, .48), vec2(.72, .42), p);
    float a = 99., 
        r = length(p), 
        b = min(min(B(vec2(-.6, .78), vec2(-1.16, .84), O, p).x - .06, 
                    B(O, vec2(-1.2, .42), vec2(-.72, .24), p).x - .06), 
                max(p.y - .9, min(abs(B(vec2(1.16, .96), vec2(1.04, .9), P, p).x - .07) - .01, 
                                  h.x * (1. - .75 * h.y) - .08)));
    for(int i=0;i<13;i+=2) 
        a = min(a, (B(A[i], A[i + 1], A[i + 2], vec3(r * sin(acos(p.y / r)), p.y, 0)).x - .015) * .8);
    float dTeapot = smin(a,b,.02);
    
    // !!! The morphing is here !!!
    return mix(dTeapot, dShape, clamp(abs(tMorph),0.,1.));
}

void main() {
    tMorph = cos(time*.5);
    tMorph*=tMorph*tMorph*tMorph*tMorph;
    //tMorph*=tMorph;
    
// TODO precalcul this    
//    A[0]=vec2(0,0);A[1]=vec2(16,0);A[2]=vec2(16,1);A[3]= vec2(20,4);A[4]=vec2(20,10);A[5]=vec2(20,16);A[6]=vec2(16,30);A[7]=vec2(15,31);
//  A[8]=vec2(14,30);A[9]=vec2(14,32);A[10]=vec2(3,34);A[11]=vec2(0,35);A[12]=vec2(4,38);A[13]=vec2(5,40);A[14]=vec2(0,40);
//  for(int i=0;i<15;i++)
//        A[i] = vec2(.04,.03)*A[i];

    // Compressed teapot
    T[3] = vec2(5.04, 4040.39);
    T[2] = vec2(314.14, 353432.3);
    T[0] = vec2(201616., 40100.);
    T[1] = vec2(151620.2, 313016.1);
    
    // Decompress teapot
    for(int i=0;i<15;i++)
        A[i] = vec2(4,3)*fract(T[i/4] / pow(100., float(i-4*(i/4))));

    // Configure camera
    vec2 r = resolution.xy, m = mouse.xy / r,
      q = gl_FragCoord.xy / r.xy, p =q+q - 1.;
    p.x *= r.x/r.y;
    float j=.0, s=1.,e = .0001, h = .1, t=5.+.2*time + 4.*m.x;
    vec3 C = (.8-length(p*p))*vec3(.5,1.2,.5),
      c= C,
      o = 2.9*vec3(cos(t), .7- m.y,sin(t)),
      w = normalize(Y * .4 - o), u = normalize(cross(w, Y)), v = cross(u, w),
      d = normalize(p.x * u + p.y * v + w+w), n, x;

    // Do Ray marching
    t=0.;
    for(int i=0;i<60;i++) 
        if (h>e && t<4.7) t += h = .7*M(o + d * t);
    // Render colors
    if (h < .001) {
        x = o + t * d;
        n = normalize(vec3(M(x+E.yxx)-M(x-E.yxx),M(x+E)-M(x-E),M(x+E.xxy)-M(x-E.xxy)));
        // Calculate Shadows
        for(int i=0;i<20;i++){
            j += .02;
            s = min(s, M(x+L*j)/j);
        }
        // Teapot color 
        vec3 c1 = clamp(abs(fract(vec3(1,.6,.3)+(time-3.)*.02)*6.-3.)-1.,0.,1.); 
        // Quadrillage
     // x = floor(4.*x);
     // c1*= mod(iGlobalTime,10.)>6. ? mix(1.1,.3, mod(x.x + x.y+ x.z, 2.)) : 1.;
        // Shading
        c = mix(C,mix(sqrt((clamp(3.*s,0.,1.)+.3)*c1),
                vec3(1)*pow(max(dot(reflect(L,n),d),0.),99.),.4),2.*dot(n,-d));
    }
    glFragColor=vec4(c,1);    
}
