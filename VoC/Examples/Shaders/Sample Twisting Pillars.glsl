#version 420

// original https://www.shadertoy.com/view/Wd33R8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//https://www.shadertoy.com/view/4dt3zn
//used this shader for inspiration/ the reflections and colloring

#define FAR 20.

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

vec3 doTwist(in vec3 p)
{
    float f = sin(time)*3.0;
    float c = cos(f*p.y);
    float s = sin(f*p.y);
    mat2  m = mat2(c,-s,s,c);
    return vec3(p.y,m*p.xz);
}

vec3 doTwist2(in vec3 p)
{
    float f = sin(time)*1.1;
    float c = cos(f*p.y);
    float s = sin(f*p.y);
    mat2  m = mat2(c,-s,s,c);
    return vec3(p.y,m*p.xz);
}

    

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float map (vec3 p)
{
    
  
   vec3 q = fract(p  ) * 2. - 1.;

   vec3 s = vec3(.99,.6,.4);
   
   float bd3= length (max (abs(doTwist(q))-s,0.)); 
    
    vec3 boxQ = q;
    boxQ += vec3(0.,0.5,0.);
    vec3 s6 = vec3(1.,0,1); 
    
   float bd6= length (max (abs((boxQ))-s6,0.)); 
    
    
   
    vec3 torusQ = q;
    torusQ -= vec3(0.0,0.95,0);
    float torus = sdTorus(torusQ,vec2(.90,0.5));
    
    
    vec3 torusQ2 = q;
    torusQ2 += vec3(0.0,0.95,0);
    float torus2 = sdTorus(torusQ2,vec2(.90,0.5));
       
    
    //box 2
    vec3 s2 = vec3(.05,.001,1.);
    vec3 i = q;
    i +=.0;
     float bd4= length (max (abs(doTwist2(i))-s2,0.)); 
        
 
    //circle
   float sd5;
   float x = sin(time);
   abs (x);
   sd5 = length(q) -0.65;
 
    float smbd = smin(bd3,bd3,.2);
    
    float y = max (-sd5, smbd);
 
    y =max(-torus ,y); 
    y =max(-torus2 ,y); 
    bd6 = smin(bd6,y,.2);
    y =min(y ,bd6);

    return y;
    
  
}

 float GetDist (vec3 p) 
    {
      
         float d;
        
        return  d ;
    }
    

float trace(vec3 o, vec3 r)
{
 float t = 0.0,d;
    for(int i=0; i< 128; i++){
    vec3 p = o + r * t;
   
        float d = map(p);
   
     
        if(abs(d)<.01 || t>FAR) break;        
        
        t += d*.25; 
    }
    return t;
}

//second trace for reflections
float traceRef(vec3 ro, vec3 rd){
    
    float t = 0., d;
    
    for (int i = 0; i < 48; i++){

        d = map(ro + rd*t);
        
        if(abs(d)<.002 || t>FAR) break;
        
        t += d;
    }
    
    return t;
}

float softShadow(vec3 ro, vec3 lp, float k){

    const int maxIterationsShad = 24; 
    
    vec3 rd = (lp-ro);

    float shade = 1.;
    float dist = .0035;    
    float end = max(length(rd), .001);
    float stepDist = end/float(maxIterationsShad);
    
    rd /= end;

    for (int i=0; i<maxIterationsShad; i++){

        float h = map(ro + rd*dist);
    
        shade = min(shade, smoothstep(0., 1., k*h/dist)); 

        dist += clamp(h, .5, .0);
        
        if (h<0. || dist > end) break; 
    }

    return min(max(shade, 0.) + .25, 1.); 
}

vec3 getObjectColor(vec3 p){
    
    vec3 col = vec3(1);
   
    if(fract(dot(floor(p), vec3(.3))) > .01) col = vec3(.5, sin(time), 0.);
 
    return col;
    
}

vec3 doColor(in vec3 sp, in vec3 rd, in vec3 sn, in vec3 lp, float t){
    
    vec3 ld = lp-sp;
    float lDist = max(length(ld), .001);
    ld /= lDist;
    
    float atten = 1. / (1. + lDist*.2 + lDist*lDist*.1);
   
    float diff = max(dot(sn, ld), 0.);
 
    float spec = pow(max( dot( reflect(-ld, sn), -rd ), 0.), 8.);

    vec3 objCol = getObjectColor(sp);

    vec3 sceneCol = (objCol*(diff + .15) + vec3(1., .6, .2)*spec*2.) * atten;
    
    
    float fogF = smoothstep(0., .95, t/FAR);
 
    sceneCol = mix(sceneCol, vec3(0), fogF); 

    return sceneCol;
    
}

vec3 getNormal( in vec3 p ){

  
    vec2 e = vec2(.0025, -.0025); 
    return normalize(
        e.xyy * map(p + e.xyy) + 
        e.yyx * map(p + e.yyx) + 
        e.yxy * map(p + e.yxy) + 
        e.xxx * map(p + e.xxx));
}

//--------

void main(void)
{
  
    vec2 uv = gl_FragCoord.xy/resolution.xy;
        
    uv = uv * 2.0 - 1.0;
    
    uv.x *= resolution.x / resolution.y;
    
    vec3 r = normalize(vec3(uv,1.));
 
    float the = time *0.25;
        
    vec3 o = vec3(tan(1.),tan(1.),time);
    
    float t = trace(o,r);
    
    vec3 lp = o + vec3(0., 1., -.5);
    
    o += r*t;
    
    vec3 sn = getNormal(o);

    vec3 sceneColor = doColor(o, r, sn, lp, t);
        
    float sh = softShadow(o, lp, 16.);
    
    r = reflect(r, sn);
  
    t = traceRef(o +  r*.01, r);
    
    o += r*t;
    
    sn = getNormal(o);
    
    sceneColor += doColor(o, r, sn, lp, t)*.25;
    
    sceneColor *= sh;
    
    float fog = 1. / (1. + t * t * 0.1);
    
    vec3 fc = vec3(fog);
    
    glFragColor = vec4(sqrt(clamp(sceneColor, 0., 1.)), 1);
    
    
}
