#version 420

// original https://www.shadertoy.com/view/wl3XR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Plento
// "Jumper Wires"

// Raymarched breadboard model with some literal jumping wires

#define ShowWires

vec2 R;
const float pi = 3.14159;
#define m vec2(R.x/R.y*(mouse*resolution.xy.x/R.x-.5),mouse*resolution.xy.y/R.y-.5)
#define FAR 100.
#define ss(a, b, t) smoothstep(a, b, t)

vec3 hash31(float p)
{
   vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
   p3 += dot(p3, p3.yzx+33.33);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}
mat2 rot(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

float box( vec3 p, vec3 b ){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float torus( vec3 p, vec2 t ){
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}
// https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float smoothsub( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); 
}

float map(vec3 rp){
    float d = 999.;
    
    rp.xz*=rot(time*.5 -1.);
    
    vec3 rp2 = rp;
    
    rp.x = -abs(rp.x);
    
    float board = box(rp-vec3(0., -.98, 0.), vec3(1., .05, 2.5)) - .05;
    
    d = min(d, board);
    d = smoothsub(box(rp-vec3(0., -.84, 0.), vec3(.03, .05, 3.)),d, .06);
    
    vec3 b = vec3(.07, .2, .07);
    vec3 rrp = rp - vec3(.09, 0., .07);
    rrp = mod(rrp, b)-b*.5;
    
    float rep = max(box(rrp, vec3(.013, .4, .013)),
        box(rp-vec3(-.36, -1., 0.), vec3(.22, .15, 2.5))
    );    
    
    d = smoothsub(rep, d, .03);
    
    float rep2 = max(box(rrp, vec3(.013, .04, .013)),
        box(rp-vec3(-.89, -1., 0.), vec3(.05, .15, 2.36))
    );  
    
    d = smoothsub(rep2, d, .03);
    
    vec3 p = rp2-vec3(0., -1.0, 1.);
    p = mod(p, vec3(0., 0., 0.4))-vec3(0., 0., 0.4)*0.5;
    
    p.yz *= rot(pi/2.);
    
    vec3 irp = rp2-vec3(time+1.2,-0.5,0.);
    irp = mod(irp, vec3(4.5,0.,0.))-vec3(4.5,0.,0.)*0.5;
    irp.xz*=rot(pi/4.);
    
    #ifdef ShowWires
    d = min(d, max(torus(p, vec2(0.5, 0.02)), box(irp, vec3(0.8, 0.5, 2.4))));
    #endif
    
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

float march(vec3 rd, vec3 ro){
     float t = 0., d = 0.;   
    
    for(int i = 0; i < 80; i++){
        d = map(ro + rd*t);        
        if(abs(d) < .0015 || t > 60.) break;
        
        t += d * .75;
    }
    return t;
}

vec3 color(vec3 p, vec3 rd, vec3 n, float t){
    vec3 lp = vec3(6., 9.0, -5.0);
    vec3 ld = normalize(lp-p);
       vec3 ref = reflect( rd, n );
    
    float faloff = 1.-exp(-(4. / length(lp - p)));
    
    float spec = pow(max(dot(normalize(reflect(ld, n)), rd), 0.), 12.);
    float dif = max(dot(n, ld), .05);
    
    p.xz*=rot(time*.5-1.);
    p.x = abs(p.x);
    
    vec3 col = vec3(0);
    float mat = step(0.865, abs(p.y));
    
    float id = floor(p.z/ 0.4 - 0.5);
    vec3 wire = hash31(id*346.24);
    
    vec3 board = vec3(.95, .7, .4);
    float bnd = ss(2.382, 2.383, abs(p.z));
    board = mix(vec3(.6, 0., 0.), board, ss(0.01, 0.015, abs(p.x-.99)+bnd));
    board = mix(vec3(0., .1, .6), board, ss(0.01, 0.015, abs(p.x-.78)+bnd));
    
    col = mix(wire, board, mat);
    
    col *= 2.*dif*vec3(1., 1., 1.) * faloff;
    col += vec3(0.8, 0.8, 0.8) * spec * .25;
    
    col = mix(vec3(0), col, 1.-step(50., t));
     
    return col;   
}

void main(void) { //WARNING - variables void ( out vec4 f, in vec2 u ){ need changing to glFragColor and gl_FragCoord.xy
    R = resolution.xy;
    vec2 uv = vec2(gl_FragCoord.xy - 0.5*R.xy)/R.y;
    
    float zm = max(5.- (time * 7.), 0.8);
    vec3 rd = normalize(vec3(uv, zm));
    //vec3 ro = vec3(0., m.y*10., m.x*10. - 3.);
    vec3 ro = vec3(0., 0.5, -2.9);
    
    rd.yz*=rot(0.65);
    
    float t = march(rd, ro);
    
    vec3 n = normal(ro + rd*t);
    vec3 col = color(ro + rd*t, rd, n, t);
    
    glFragColor = vec4(sqrt(clamp(col, .0, 1.)), 1.);
    
}

