#version 420

// original https://www.shadertoy.com/view/stdBRs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* Creative Commons Licence Attribution-NonCommercial-ShareAlike 
 * phreax 2022
 *
 * Special thanks to: iq, evvvvil, nusan, bigwings, fabrice, flopine, yx 
 * for their amazing content and learning material.
 * 
 */
#define PI 3.141592
#define TAU PI*2.

#define DISTORT 0

float tt;
vec3 ro;
vec2 beamId;

// from "Palettes" by iq. https://shadertoy.com/view/ll2GD3
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

vec3 getPal(int id, float t) {

    id = id % 7;

    vec3          col = pal( t, vec3(.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,-0.33,0.33) );
    if( id == 1 ) col = pal( t, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.10,0.20) );
    if( id == 2 ) col = pal( t, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.3,0.20,0.20) );
    if( id == 3 ) col = pal( t, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,0.5),vec3(0.8,0.90,0.30) );
    if( id == 4 ) col = pal( t, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,0.7,0.4),vec3(0.0,0.15,0.20) );
    if( id == 5 ) col = pal( t, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(2.0,1.0,0.0),vec3(0.5,0.20,0.25) );
    if( id == 6 ) col = pal( t, vec3(0.8,0.5,0.4),vec3(0.2,0.4,0.2),vec3(2.0,1.0,1.0),vec3(0.0,0.25,0.25) );
    
    return col;
}

float repeat(inout float x, float n) {
    float id = floor(n*x)/n;
    x = fract(n*x);
    return id;
}

float box(vec3 p, vec3 r) {
    vec3 q = abs(p) - r;
    return max(max(q.x, q.y),q.z);
}

mat2 rot(float a) { return mat2(cos(a), sin(a), -sin(a), cos(a));}

vec2 repeat(inout vec2 p, vec2 size) {
    vec2 c = floor((p + size*0.5)/size);
    p = mod(p + size*0.5,size) - size*0.5;
    return c;
}

float repeatSingle(inout float p, float size) {
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    if (p >= 0.)
        p = mod(p + halfsize, size) - halfsize;
    return c;
}

void transform(inout vec3 p) {
    
    float repz =8.;

    float idz = repeatSingle(p.z,8.);  
    p.xy *= rot(.25*PI*mod(idz, repz));
}

vec3 colorStripeTexture(vec3 p, vec2 matId) {

    matId = abs(matId);
    int mat = int((matId.x*2.))+int(matId.y*2.);
    
    float dim = p.x*4.;
    
    if(mat % 3 == 1) dim = p.y*3.;
    if(mat % 3 == 2) dim = p.z*.4;
    
    float id = repeat(dim, 5.2) + matId.y/3. + tt*.6;
    vec3 col = getPal(4, id);
    return col;
}

vec2 moda(vec2 p, float repetitions) {
    float angle = 2.*PI/repetitions;
    float a = atan(p.y, p.x) + angle/2.;
    a = mod(a,angle) - angle/2.;
    return vec2(cos(a), sin(a))*length(p);
}

vec3 kalei(vec3 p) {
  float w = 1.;
      p = abs(p) -.2;
  for(float i=0.; i < 4.; i++) {
        float t1 = 2.+sin(i+tt) + sin(.7*tt)*.4;
        p.xy *= rot(.3*t1);
        p -= 0.1 + .1*i;
        p.y -= 0.3;
        p = abs(p);
 
    }
    p /= w;
    return p;
}

// by Nusan
float curve(float t, float d) {
  t/=d;
  return mix(floor(t), floor(t)+1., pow(smoothstep(0.,1.,fract(t)), 5.));
}

float map(vec3 p) {
    
    p.xy *= (1.+abs(.1*p.x))*rot(curve(tt, 4.)*.5*PI);

    #if DISTORT
    p.y += 0.1*sin(p.z+2.*tt);
    p.x+= 0.1*sin(p.z*1.5+1.*tt);
    #endif

    transform(p);
    //p = kalei(p);
    float blen =2.8;

    float outer = 1.45;
    float inner = .9;
    
    float maskout = box(p, vec3(vec2(outer), blen));
    float maskin = box(p, vec3(vec2(inner), blen + .3));
   
    beamId = repeat(p.xy, vec2(.39));
    float beam = max(box(p, vec3(vec2(.16), blen)), -box(p, vec3(vec2(.1), blen+.3)));
    
    
    float frame = max(maskout, -maskin);
    float d = max(beam, maskout);
    d = max(d, frame);
    return d;
   
}

void cam(inout vec3 p) {
    p.z += 8.*tt;;

}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.x;
    tt = time;
         ro = vec3(0, 0., -15.);
    vec3 rd = normalize(vec3(uv, 1.5)),
         lp = vec3(0., 0., 2.);
    
    cam(ro);
    cam(lp);
    

    float i, t, d = 0.1;

    vec3 p = ro;
    
    vec2 matId;
    for(i=0.; i<300.; i++) {
    
          
        d = map(p);
        matId = beamId; // save id
        
        if(d < 0.001 || t > 200.) break;
            
        p += rd*d;
        t += d;
    }
    
    vec2 e = vec2(0.0035, -0.0035);
    
    vec3 fo, co;
    co = fo = mix(vec3(0.957,0.937,0.867), vec3(1.), uv.y+.5);
    
    if(d < 0.001) {
        vec3 al;
        
        vec3 n = normalize( e.xyy*map(p+e.xyy) + e.yyx*map(p+e.yyx) +
                            e.yxy*map(p+e.yxy) + e.xxx*map(p+e.xxx));
        al = colorStripeTexture(p, matId)*1.2;
        
        vec3 l = normalize(lp-p);
        float dif = max(dot(n, l), .0);
        float spe = pow(max(dot(reflect(-rd, n), -l), .0), 40.);
        float sss = smoothstep(0., 1., map(p+l*.4))/.4; 
        
        co =  al*mix(1., .8*spe+(.9*dif+1.5*sss), .4);
        
        co = mix(co, fo, 1.-exp(-.000005*t*t*t));
        
    }

    // Output to screen
    glFragColor = vec4(co, 1.);
}
