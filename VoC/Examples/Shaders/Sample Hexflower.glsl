#version 420

// original https://www.shadertoy.com/view/dtfGRH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* Creative Commons Licence Attribution-NonCommercial-ShareAlike 
   phreax 2022
   
   Based on https://www.shadertoy.com/view/7ltBRs
*/

#define PI 3.141592
#define TAU PI*2.
#define SIN(x) (.5+.5*sin(x))

float tt;

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( TAU*(c*t+d) );
}

vec3 getPal(int id, float t) {

    vec3                col = pal( t, vec3(.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,-0.33,0.33) );
    if( id == 1 ) col = pal( t, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.10,0.20) );
    if( id == 2 ) col = pal( t, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.3,0.20,0.20) );
    if( id == 3 ) col = pal( t, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,0.5),vec3(0.8,0.90,0.30) );
    if( id == 4 ) col = pal( t, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,0.7,0.4),vec3(0.0,0.15,0.20) );
    if( id == 5 ) col = pal( t, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(2.0,1.0,0.0),vec3(0.5,0.20,0.25) );
    if( id == 6 ) col = pal( t, vec3(0.8,0.5,0.4),vec3(0.2,0.4,0.2),vec3(2.0,1.0,1.0),vec3(0.0,0.25,0.25) );
    
    return col;
}

vec3 colorStripeTexture(vec3 p) {
    return vec3(1);
}

float box(vec3 p, vec3 r) {
    vec3 q = abs(p) - r;
    return max(max(q.x, q.y),q.z);
}

mat2 rot(float a) { return mat2(cos(a), sin(a), -sin(a), cos(a));}

float repeat(inout float x, float n) {
    float id = floor(n*x)/n;
    x = fract(n*x);
    return id;
}

vec2 repeat(inout vec2 p, vec2 size) {
    vec2 c = floor((p + size*0.5)/size);
    p = mod(p + size*0.5,size) - size*0.5;
    return c;
}

float pMod1(inout float p, float size) {
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    p = mod(p + halfsize, size) - halfsize;
    return c;
}

vec2 moda(vec2 p, float repetitions) {
    float angle = 2.*PI/repetitions;
    float a = atan(p.y, p.x) + angle/2.;
    a = mod(a,angle) - angle/2.;
    return vec2(cos(a), sin(a))*length(p);
}

/*float pring(vec3 p, float s, float r) {
    
    float dp = prism(p, vec2(s, .2));
    
    dp = max(dp, -prism(p, vec2(s-r, .3)));
    return dp;
}*/

float pModSingle1(inout float p, float size) {
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    if (p >= 0.)
        p = mod(p + halfsize, size) - halfsize;
    return c;
}

vec3 kalei(vec3 p) {
  float w = 1.;
      p = abs(p) -.2;
  for(float i=0.; i < 3.; i++) {
        float t1 = 2.+sin(i+tt) + sin(.7*tt)*.4;
        p.xy *= rot(.3*t1);
        p -= 0.1 + .1*i;
       // p.y -= 0.3;
        p = abs(p);
 
    }
    p /= w;
    return p;
}
vec2 foldSym(vec2 p, float N) {
    float t = atan(p.x,-p.y);
    t = mod(t+PI/N,2.0*PI/N)-PI/N;
    p = length(p.xy)*vec2(cos(t),sin(t));
    p = abs(p)-0.25;
    p = abs(p)-0.25;
    return p;
}

vec2 beamId;
float map(vec3 p) {

    vec3 bp = p;
    float repz = 8.;
    float idz = pModSingle1(p.z,repz);
    
    //p.xy *= rot(tt*TAU/16.*sign(mod(idz, 2.)-.5));
    p.xy = foldSym(p.xy, 6.);
   

    p.y += 0.4*sin(p.z*TAU/4.+tt*TAU/2.);
    
    p.xy *= rot(.25*PI*mod(idz, 2.));

   
    //p = kalei(p);
    float blen = 3.9;

    float outer = 1.3;
    float inner = 1.1;
    float maskout = box(p, vec3(vec2(outer), blen));
    float maskin = box(p, vec3(vec2(inner), blen + .3));
    beamId = repeat(p.xy, vec2(.2));
    float beam = box(p, vec3(vec2(.07), blen));
    
    float frame = max(maskout, -maskin);
    float d = max(beam, maskout);
    d = max(d, frame);
    return d;
   
}

float calcAO(vec3 p, vec3 n)
{
    float sca = 2.0, occ = 0.0;
    for( int i=0; i<5; i++ ){
    
        float hr = 0.01 + float(i)*0.5/4.0;        
        float dd = map(n * hr + p);
        occ += (hr - dd)*sca;
        sca *= 0.7;
    }
    return clamp( 1.0 - occ, 0.0, 1.0 );    
}

void cam(inout vec3 p) {
    p.z += 4.*tt;;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.x;
    
    //uv *= rot(.5*PI);
    tt = time+.1;
    
    tt = mod(tt, 8.);
    vec3 ro = vec3(0, 0., 0.),
         rd = normalize(vec3(uv, .25)),
         lp = vec3(0., 0., 2.);
    
    cam(ro);
    cam(lp);
    vec3 col;
    float i, t, d = 0.1;

    vec3 p = ro;
    
    vec2 beamIdTemp;
    for(i=0.; i<200.; i++) {
    
          
        d = map(p);
        beamIdTemp = beamId; // save id
        
        if(d < 0.001 || t > 100.) break;
            
        p += rd*d;
        t += d;
    }
    
    vec2 e = vec2(0.0035, -0.0035);
    
    if(d < 0.001) {
        vec3 al = vec3(0.000,1.000,0.616);
        al = getPal(5, beamIdTemp.y/10. + sin(tt*TAU/16.));
        vec3 n = normalize( e.xyy*map(p+e.xyy) + e.yyx*map(p+e.yyx) +
                            e.yxy*map(p+e.yxy) + e.xxx*map(p+e.xxx));
        
        vec3 l = normalize(lp-p);
        float dif = max(dot(n, l), .0);
        float spe = pow(max(dot(reflect(-rd, n), -l), .0), 40.);
        float sss = smoothstep(0., 1., map(p+l*.4))/.4; 
        float ao = calcAO(p, n);
        
        col =  al*mix(1., spe+.9*(dif+1.5*sss), .4);
        col = mix(col, col*ao, .9);
        
        float fog = 1.-exp(-t*0.04);
        
        col = mix(col, vec3(.1), fog);
    }

    // Output to screen
    glFragColor = vec4(col, 1.);
}
