#version 420

// original https://www.shadertoy.com/view/WtlXDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
"Golf Ball" by Emmanuel Keller aka Tambako - August 2017
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Contact: tamby@tambako.ch
*/

#define pi 3.141593

struct Lamp
{
  vec3 position;
  vec3 color;
  float intensity;
  float attenuation;
};

struct RenderData
{
  vec3 col;
  vec3 pos;
  vec3 norm;
  float dist;
};
    
Lamp lamps[3];

//#define testmode;

vec3 campos = vec3(0., 0., 9.);
vec3 camtarget = vec3(0., 0., 0.);
vec3 camdir;
float fov = 4.7;

const vec3 ambientColor = vec3(0.1);
const float ambientint = 0.16;
const vec3 speccolor = vec3(0.95, 0.97, 1.);

const float normdelta = 0.0001;
const float maxdist = 100.;

const float fogdens = 0.012;
const float sr = 1.;
#ifdef testmode
const float gridDist = 3.2;
const int nblamps = 1;
#else
const float gridDist = 2.2;
const int nblamps = 3;
#endif

const int nbref = 3;
const float ior = 4.2;

// Antialias. Change from 1 to 2 or more AT YOUR OWN RISK! It may CRASH your browser while compiling!
const float aawidth = 0.8;
const int aasamples = 2;

vec3 posr;

float angle;
float angle2;

float hash( float n ){
    return fract(sin(n)*3538.5453);
}

float hash2(vec3 p)
{
    p  = fract( p*0.3183099+.1 );
    p *= 17.0;
    return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}

float noise(vec3 x)
{
    //x.x = mod(x.x, 0.4);
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0 - 2.0*f);
    
    float n = p.x + p.y*157.0 + 113.0*p.z;
    return mix(mix(mix(hash(n + 0.0), hash(n + 1.0),f.x),
                   mix(hash(n + 157.0), hash(n + 158.0),f.x),f.y),
               mix(mix(hash(n + 113.0), hash(n + 114.0),f.x),
                   mix(hash(n + 270.0), hash(n + 271.0),f.x),f.y),f.z);
}

vec3 rotateVec2(vec3 posr, vec2 angle)
{
    posr = vec3(posr.x, posr.y*cos(angle.y) + posr.z*sin(angle.y), posr.y*sin(angle.y) - posr.z*cos(angle.y));
    posr = vec3(posr.x*cos(angle.x) + posr.z*sin(angle.x), posr.y, posr.x*sin(angle.x) - posr.z*cos(angle.x)); 
    
    return posr;
}

float map(vec3 pos)
{
    vec3 posr2 = mod(pos + vec3(gridDist), gridDist*2.) - vec3(gridDist);
    vec3 posr3 = floor(0.5/gridDist*(pos + vec3(gridDist))); 
    
    return length(posr2) - sr*(1. + 0.3*cos(time*2.7 + 0.55*posr3.x + 0.55*posr3.y + 0.55*posr3.z));
}

vec2 trace(vec3 cam, vec3 ray, float maxdist) 
{
    float t = 1.8;
    vec3 pos;
    float dist;
    
      for (int i = 0; i < 130; ++i)
    {
        pos = ray*t + cam;
        dist = map(pos);
        if (dist>maxdist || abs(dist)<0.0001)
            break;
        t+= dist;
      }
        
      return vec2(t, dist);
}

// From https://www.shadertoy.com/view/MstGDM
vec3 getNormal(vec3 pos, float e)
{
    vec2 q = vec2(0, e);
    vec3 norm = normalize(vec3(map(pos + q.yxx) - map(pos - q.yxx),
                          map(pos + q.xyx) - map(pos - q.xyx),
                          map(pos + q.xxy) - map(pos - q.xxy)));
    return norm;
}

vec3 obj_color(vec3 norm, vec3 pos)
{
    #ifdef testmode
    return vec3(0.7);
    #else
    posr = floor(0.5/gridDist*(pos + vec3(gridDist)));    
    return vec3(hash2(posr), hash2(posr + vec3(15., 7., 9.)), hash2(posr + vec3(25., 17., 49.)));
    #endif
}

vec3 getSkyColor(vec3 ray)
{  
    vec3 col;
    col.r = 0.55*clamp(0.2-ray.z, 0., 1.);
    col.g = 0.8*clamp(0.4-ray.z, 0., 1.);
    col.b = clamp(1.-ray.z, 0., 1.);
    
    col = mix (col, vec3(1.), 0.02*pow(max(0., dot(ray, vec3(0.2, 0.2, -1.))), 120.));
    
    return col;
}

vec3 lampShading(Lamp lamp, vec3 norm, vec3 pos, vec3 ocol, float objnr)
{
    pos-= campos;
    
    vec3 pl = normalize(lamp.position - pos);
    float dlp = distance(lamp.position, pos);
    vec3 pli = pl/pow(1. + lamp.attenuation*dlp, 2.);
    vec3 nlcol = normalize(lamp.color);
    float dnp = dot(norm, pli);
      
    // Diffuse shading
    vec3 col = ocol*nlcol*lamp.intensity*smoothstep(-0.1, 1., dnp);
    
    return col;
}

vec3 lampsShading(vec3 norm, vec3 pos, vec3 ocol, float objnr)
{
    vec3 col = vec3(0.);
    for (int l=0; l<nblamps; l++) // lamps.length()
        col+= lampShading(lamps[l], norm, pos, ocol, objnr);
    
    return col;
}

// From https://www.shadertoy.com/view/lsSXzD, modified
vec3 GetCameraRayDir(vec2 vWindow, vec3 vCameraDir, float fov)
{
    vec3 vForward = normalize(vCameraDir);
    vec3 vRight = normalize(cross(vec3(0.0, 1.0, 0.0), vForward));
    vec3 vUp = normalize(cross(vForward, vRight));
    
    vec3 vDir = normalize(vWindow.x * vRight + vWindow.y * vUp + vForward * fov);

    return vDir;
}

RenderData trace0(vec3 tpos, vec3 ray)
{
    vec2 t = trace(tpos, ray, maxdist);
    float tx = t.x;
    vec3 col;
    float objnr = t.y;
    
    vec3 pos = tpos + tx*ray;
    vec3 norm;
    if (tx<maxdist)
    {
        norm = getNormal(pos, normdelta);

        // Coloring
        col = obj_color(norm, pos);
      
        // Shading
        col = ambientColor*ambientint + lampsShading(norm, pos, col, objnr);
    }
    else
       col = getSkyColor(ray);
    
  return RenderData(col, pos, norm, tx);
}

// Fresnel reflectance factor through Schlick's approximation: https://en.wikipedia.org/wiki/Schlick's_approximation
float fresnel(vec3 ray, vec3 norm, float n2)
{
   #ifdef testmode
   return 1.;
   #else
   float n1 = 1.; // air
   float angle = acos(-dot(ray, norm));
   float r0 = dot((n1-n2)/(n1+n2), (n1-n2)/(n1+n2));
   float r = r0 + (1. - r0)*pow(1. - cos(angle), 5.);
   return clamp(r, 0., 0.8);
   #endif
}

vec4 render()
{
  lamps[0] = Lamp(vec3(-2., 4.5, 1.), vec3(1., 1., 1.), 4.8, 0.08);
  lamps[1] = Lamp(vec3(9., -2.5, 4.), vec3(0.77, 0.87, 1.0), 5.1, 0.1);
  lamps[2] = Lamp(vec3(-9., -5., -4.), vec3(1.0, 0.6, 0.5), 3.6, 0.1);
    
  vec2 uv = gl_FragCoord.xy / resolution.xy; 
  uv = uv*2.0 - 1.0;
  uv.x*= resolution.x / resolution.y;

  vec3 ray = GetCameraRayDir(uv, camdir, fov);
    
  RenderData traceinf = trace0(campos, ray);
  vec3 col = traceinf.col;
    
  float dist = traceinf.dist;     
    
  vec3 refray;
  float rf = fresnel(ray, traceinf.norm, ior);
    
  float fogdens2 = fogdens*(0.7 + 2.3*noise(ray*8. + vec3(0.4*time)));
   
  float fogd = clamp(exp(-pow(fogdens2*dist, 2.)), 0., 1.);
  vec3 ray0 = ray;
    
  col = mix(getSkyColor(ray), traceinf.col, fogd*(1. - rf));
  //col = traceinf.col;
  
 for (int r=0; r<nbref+1; r++)
  {
      if (traceinf.dist<=maxdist)
      {
         refray = reflect(ray, traceinf.norm);
         if (r<nbref)
         {
             RenderData traceinf_ref = trace0(traceinf.pos, refray);
             rf*= fresnel(ray, traceinf.norm, ior);
             
             float fogd2 = clamp(exp(-pow(fogdens2*traceinf_ref.dist, 2.)), 0., 1.);             
             col = vec3(mix(col, mix(getSkyColor(refray), traceinf_ref.col, fogd*fogd2), rf*fogd));
             fogd*= fogd2;
             
             traceinf = traceinf_ref;
             ray = refray;
         }
         else
         {
            rf*= fresnel(ray, traceinf.norm, ior);
            col = mix(col, getSkyColor(refray), rf*fogd);
         }
      }
  }
    
  return vec4(col, 1.0);
}

void main(void)
{
   //vec2 mouse*resolution.xy2;
   //if (mouse*resolution.xy.x==0. && mouse*resolution.xy.y==0.)
   //   mouse*resolution.xy2 = resolution.xy*vec2(0.52, 0.65);
   //else
   //   mouse*resolution.xy2 = mouse*resolution.xy.xy;    
    
   campos = rotateVec2(campos, vec2(5.*mouse.x*resolution.x/resolution.x, 3.1*mouse.y*resolution.y/resolution.y + 1.6));
   camdir = camtarget - campos;   
    
    // Antialiasing
    vec4 vs = vec4(0.);
    for (int j=0;j<aasamples ;j++)
    {
       float oy = float(j)*aawidth/max(float(aasamples-1), 1.);
       for (int i=0;i<aasamples ;i++)
       {
          float ox = float(i)*aawidth/max(float(aasamples-1), 1.);
          vs+= render();
       }
    }
    glFragColor = vs/vec4(aasamples*aasamples);    
}
