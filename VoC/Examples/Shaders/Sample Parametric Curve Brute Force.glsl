#version 420

// original https://www.shadertoy.com/view/7lGSRW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Cole Peterson

/*
    Brute forcing a parametric curve.
    I know approximating the distance to trig functions is tricky 
    and I'm curious about a more practical solution rather than just sampling it 
    over and over again. Anyone have some insight?
*/

#define R resolution.xy
#define m vec2(R.x/R.y*(mouse*resolution.xy.x/R.x-.5),mouse*resolution.xy.y/R.y-.5)
#define KEY(v,m) texelFetch(iChannel1, ivec2(v, m), 0).x
#define ss(a, b, t) smoothstep(a, b, t)
#define ch(chan, p) texelFetch(chan,  ivec2(p), 0)
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

const float pi = 3.14159;

float capTorus(in vec3 p, in vec2 sc, in float ra, in float rb){
  p.x = abs(p.x);
  float k = (sc.y*p.x>sc.x*p.y) ? dot(p.xy,sc) : length(p.xy);
  return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

float rbox( vec3 p, vec3 b, float r ){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float smin( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

float line( vec3 p, vec3 a, vec3 b, float r ){
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

float mat = 0.;
float md = 99.;
void newmat(float d, float nm){
    if(d < md){
        md = d;
        mat = nm;
    }
}

#define trackRad 22.

// The parametric line
vec3 trackPos(float t){
    float h = 16.*cos(2.0*t);
    return vec3(2.*trackRad*cos(t)- 2.*cos(3.*t), h, trackRad*sin(2.*t) - 2.*cos(4.*t));
}

mat4 lookAt(vec3 o, vec3 p){
    vec3 Z = normalize(p - o);
    
    vec3 X = normalize(cross(vec3(0., 1., 0.), Z));
    vec3 Y = normalize(cross(Z, X));
    
    return mat4(X.x, Y.x, Z.x, o.x,
                X.y, Y.y, Z.y, o.y,
                X.z, Y.z, Z.z, o.z,
                0., 0., 0., 1.);
}

// Afwul
float aproxTrack(vec3 p){
    float n = 15.;
    float inc = 2.*pi / n;
    float md = 999.;
    vec3 lp = trackPos(0.);
    
    for(float t = 0.; t < n + 1.; t++){
        vec3 pos = trackPos(t*inc);
        vec3 v = p - pos;
        float d = line(p, lp, pos, .01) + .13;
        
        md = min(md, d);
        lp = pos;
    }
    
    return md;
}

float map(vec3 p){
    float d = 999.;
    
    for(float i = 1.; i < 5.; i++){
        vec3 pos = trackPos(time + i*.25 + 0.3);
        vec3 p0 = p - pos;
        d = min(length(p0)-2.8, d);
    }
    
    newmat(d, 1.);
    
    d = min(aproxTrack(p) - .5, d);
    newmat(d, 2.);
    
    return d;
}

vec3 normal( in vec3 pos ){
    vec2 e = vec2(0.002, -0.002);
    return normalize(
        e.xyy * map(pos + e.xyy) + 
        e.yyx * map(pos + e.yyx) + 
        e.yxy * map(pos + e.yxy) + 
        e.xxx * map(pos + e.xxx));
}

vec3 color(vec3 ro, vec3 rd, vec3 n, float t){
    vec3 p = ro + rd*t;
    
    vec3 lp = vec3(1., 15.0, -1.);
    vec3 ld = normalize(lp-p);
    
    float dd = length(p - lp);
    float dif = max(dot(n, ld), .1);
    float spec = pow(max(dot( reflect(-ld, n), -rd), 0.), 13.);
    float fog = ss(90., 88., t);
    
    vec3 objCol = vec3(0);
    
    if(mat == 1.){
        objCol = vec3(1., 1., 1.);
    }
    else if(mat == 2.){
        objCol = vec3(0., 1., 0.);
    }
    
    objCol *= dif;
    objCol += vec3(0.8, 0.4, 0.2) * spec * .25;
    
    vec3 col = objCol;
    
    col = mix(.0*vec3(1., 1., 1.), col, fog);

    return col;
}

void main(void) {
    vec2 uv = vec2(gl_FragCoord.xy - 0.5*R.xy)/R.y;
    vec4 rd = vec4(normalize(vec3(uv, 0.4)), 0.);
    vec3 ro = vec3(0., 0., -6.);
    
    ro = trackPos(time);
    ro.y += 5.;
    
    rd *= lookAt(ro, trackPos(time + .7));
    
    float d = 0.0, t = 0.0;
    for(int i = 0; i < 44; i++){
        d = map(ro + rd.xyz*t); 
        
        if(d < 0.001) break;
        
        if(t > 90.){
            t = 90.;
            break;
        }
        
        t += d * .95;
    }

    vec3 n = normal(ro + rd.xyz*t);
    
    vec3 col = color(ro, rd.xyz, n, t);
    
    glFragColor = vec4(col, 1.0);
}

