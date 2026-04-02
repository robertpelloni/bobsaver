#version 420

// original https://www.shadertoy.com/view/WtSXzz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//affine transformation matrix of eye in camera space
uniform mat4 eye;

float pi = 3.14159;

vec3 lightdir = vec3(1,-.4,1);
vec3 lightcol = vec3(1, .85, .8);

float noise(vec2 p)
{
    return fract(sin(p.x*16.+p.y*6463.)*200.);
}

float valueNoise(vec2 p)
{
    vec2 id = floor(p*10.);
    vec2 ld = fract(p*10.);
    
    ld = ld*ld*(3.-2.*ld);
    
    float bl = noise(id);
    float br = noise(id+vec2(1., 0.));
    float b = mix(bl, br, ld.x);
    
    float tl = noise(id+vec2(0., 1.));
    float tr = noise(id+vec2(1., 1.));
    float t = mix(tl, tr, ld.x);
    
    float bt = mix(b, t, ld.y);
    
    return bt;
}

float wave(vec3 p, float a, float wavelength, vec2 dir) 
{
dir = normalize(dir) ;
float k = 2.*pi/wavelength;
float c = sqrt(9.8 / k);
float f = k*(dot(dir, p.xz) -(time*c));

return a*sin(f-2.*a*cos(f));
} 

float map(vec3 p)
{
   float base = 0.;
   base += wave(p,0.8, 40., vec2(1,1) );
   base += wave(p, 0.6, 30., vec2(0.8,1)); 
   base += wave(p, 0.08, 20., vec2(1,.8));
    base += wave(p, 0.08, 10., vec2(.9,.9));
     base += wave(p, 0.03, 5., vec2(1,.9));
    base += wave(p, 0.04, 8., vec2(1,.9));
    base += .015*sin((p.x+p.z*.5) *1.);
   base += .01*sin((p.z+p.x*.5) *2.);
   base +=.003*sin((p.x+.8+p.z)*3.);
   return base -p.y;
}

vec3 getNormal(vec3 position) {
    vec3 e = vec3(0.03,0.0,0.0);

    return -normalize(vec3(
       map(position + e.xyz) - map(position - e.xyz),
       map(position + e.yxz) - map(position - e.yxz),
       map(position + e.yzx) - map(position - e.yzx)));
} 

vec2 ray(vec3 ro, vec3 rd, float dt, float mind, float maxd) 
{
   float i = mind;
   //float wi = 0.;
   float lastVal = 0.;
   //float lastValW = 0.;
   vec3 p = ro+rd*i;
   
   while(i < maxd) 
   {
      float val = map(p);
      //float valW = waterHeight(p);
      if(val>0.0 )
         return vec2(i-(abs(val)/(abs(val)+abs(lastVal)))*dt, 0.);
         
      i += dt;
      //if(waterHeight(p)>0.0) 
         //wi+=dt;
      p = ro + rd*i;
      dt *= 1.02;
      lastVal = val;
      //lastValW = valW;
   } 
   return vec2(80., 0.);
} 

vec3 drawSky(vec3 ro, vec3 rd) 
{
   vec3 base = mix(vec3(.75,.5,.55),vec3(.6,.62,.8),rd.y*2.);
   base += vec3(.9,.3,.2)*clamp(pow(1.-rd.y, 3.)*dot(rd,-normalize(lightdir)),0.,1.);
   float sunDot = clamp(dot(rd, -normalize(lightdir)), 0. ,1. );
   base +=.2*sunDot*vec3(.8,.5,.45);
   base +=.4*pow(sunDot,25.)*lightcol;
   base += .5*pow(sunDot, 64.)*lightcol;
   base += 10.*pow(sunDot, 512.)*lightcol;
   base -=.3*pow(valueNoise(rd.xz/rd.y/30.), 5.) *clamp(rd.y*5.,0.,1.);
   base -=.7*pow(valueNoise(rd.xz/rd.y/40.), 3.) *clamp(rd.y*5.,0.,1.);
   return base;
} 

vec3 drawWater(vec3 ro, vec3 rd, float d, float ud) 
{
   vec3 p = ro + rd*d;
   vec3 normal = getNormal(p);
   vec3 reflCol = drawSky(p, reflect(rd, normal) );
   vec3 base = mix(reflCol, mix(vec3(.15,.2,.4)*.5, vec3(.4,.7,.8), clamp((p.y/1.5+.5) * dot(-rd, lightdir) ,0.,1.)) ,pow(dot(rd, -normal),1.));
  
   return base;
}

vec3 drawLand(vec3 ro, vec3 rd, float d) 
{
   vec3 p = ro + rd*d;
   vec3 normal = getNormal(p);
   vec3 reflCol = drawSky(p, reflect(rd, normal) );
   vec3 base = vec3((dot(normal, -lightdir)+1.)/2.);
  
   return base;
}

void main(void)
{
     vec2 uv = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy;
  uv.x *= resolution.x / resolution.y;

  vec3 eyep = vec3(sin(mouse.x*resolution.x/resolution.x*2.), mouse.y*resolution.y/resolution.y, cos(mouse.x*resolution.x/resolution.x*2.))*10.;//eye[3].xyz;
  vec3 up = normalize(vec3(0, 1, 0));//eye[1].xyz;
  vec3 forward = normalize(-eyep);//normalize(vec3(sin(mouse*resolution.xy.x/250.), 0, cos(mouse*resolution.xy.x/250.)));//eye[2].xyz;
  vec3 right = -cross(forward, up);//eye[0].xyz;

  //ray.direction = normalize(eye * vec4(uv.x,uv.y,-1.,1.)).xyz
  vec3 rd = normalize(forward + ((right * uv.x) + (up * uv.y)));
  vec3 ro = eyep;

  vec2 rayResult = ray(ro, rd, 0.2, 0.5, 80.);
  vec3 finalColor = mix(drawWater(ro, rd, rayResult.x, rayResult.y) , drawSky(ro, rd), pow(rayResult.x/80., 4.) ) ;
  glFragColor = vec4(finalColor.xyz, 1.0 );
}
