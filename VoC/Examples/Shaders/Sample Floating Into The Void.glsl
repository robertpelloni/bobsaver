#version 420

// original https://www.shadertoy.com/view/WdcSWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 64
#define MAX_DIST 80.
#define SURF_DIST .01

float smin(float a, float b, float k)
{
 float h = clamp (0.5+0.5*(b-a)/k,0.,1.);
 return mix(b, a, h) - k*h*(1.0-h);
}
mat2 Rot (float a)
{
 float s = sin(a);
 float c = cos(a);
 return mat2(c,-s,s,c);
}

vec2 path(float z){
 float x = sin(z) + 3.0 * cos(z * 0.5) - 1.5 * sin(z * 0.12345);
 float y = cos(z) + 4.5 * sin(z * 0.3) + .2 * cos(z * 2.12345);
 return vec2(x,y);
}

mat2 R;
float T;

float map (vec3 p)
{
    vec2 o = path(p.z) / 5.0;
    p = vec3(p.x,p.y,p.z)-vec3(o.x,o.y,0.);

    float r = 3.14159*sin(p.z*0.15)+T*0.55*2.;
    R = mat2(cos(r), sin(r), -sin(r), cos(r));
    
    p.xy *= R;    
    p.xy *= (Rot (sin(time)*.1)); //rotation
    // repeat lattice
    const float a =1.;
     
       p.xy *= Rot(-p.z*abs(sin(time*0.005)) + time*.5); //rotation

    p = mod(p, a)-a*1.;

    vec3 q = fract(p) * 2. - 1.;
   // vec3 s = vec3(.5,(sin((p.z * 5.) +time)),.7);
    vec3 s = vec3(1.,0.1,1.);
    
  // q.xy *= Rot(p.z*0.5  + time*-.2)*1.; //rotation
   
    
    q.xz *= Rot(q.z *10. + time); //rotation
     //  q.zx *= Rot(q.y *20. + time); //rotation

    float bd3= length (max (abs(q)-s,0.)); 
    float sd5;
    float x = sin(time);
    abs (x);
    sd5 = length(q) -0.65;
    float sd6;
    vec3 l = q + vec3(0.,sin(time)*0.93,0.);
    sd6 = length(l) -0.05;
    float sd7;
    vec3 h = q + vec3(sin(time),0.,0.);
    q.xz *= Rot(time); //rotation
    sd7 = length(h) -0.05;   
    float sd8;
    vec3 h2 = q + vec3(sin(time),0.,0.);
    q.xz *= Rot(time); //rotation
    sd8 = length(h2) -0.05;
    float y = max (-sd5, bd3);
    float v1 = smin(sd6,sd7,0.2);
    v1 = smin(sd8,v1,0.2);
    float v = smin(y,v1,0.2);
    y =min(v ,y); 
    return y;  
}

float marchCount;

float trace(vec3 o, vec3 r)
{
    float t = 0.0; 
    marchCount = 0.0;
    for(int i=0; i<64; i++){
    vec3 p = o + r * t;
    float d = map(p);        
    if(d<.01 || t>MAX_DIST) break;
    t += d * 0.1;
    marchCount+= 1./d*0.01;
    }
    return t;
}

float traceRef(vec3 o, vec3 r){  
 float t = 0.0;
 for (int i = 0; i < 48; i++){
 vec3 p = o + r * t;
 float d = map (p);
  if(d<.002 || t>MAX_DIST) break;
   t += d * 0.2;     
  }
 return t;
}

vec3 GetNormal(vec3 p){
    vec2 e = vec2(.00025, -.00025); 
    return normalize(
        e.xyy * map(p + e.xyy) + 
        e.yyx * map(p + e.yyx) + 
        e.yxy * map(p + e.yxy) + 
        e.xxx * map(p + e.xxx));
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    vec3 r = normalize(vec3(uv,.8)); 
    float the = time *0.25;
        //  r.xz *= mat2(cos(the), -sin(the), sin(the), cos(the));
    vec2 a = path(time * 1.0)*1.0;
    vec3 o = vec3(a / 5.0,time);
    float t = trace(o,r);
    //remove for chaos
    o += r *t;    
    vec3 sn = GetNormal(o);
    vec3 sceneColor = sn;
    r = reflect(r, sn);
    t = traceRef(o +  r*.01, r);
    o += r*t;
    sn = GetNormal(o);
    sceneColor += sn;

    float fog = 1. / (1. + t * t * 0.1);
    sceneColor += vec3(fog);
    sceneColor *= 0.15;
    //glow code
    sceneColor *= marchCount * vec3(0.5, 0.5,0.5) * 0.09;

    sceneColor += marchCount * vec3(0.2, 0.1,0.1) * 0.1;
    sceneColor *= 2.5;

    glFragColor = vec4(sceneColor,1.0);  
}
