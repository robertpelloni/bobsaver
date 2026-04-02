#version 420

// original https://www.shadertoy.com/view/Xs2fWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
"Cellular creature" by Emmanuel Keller aka Tambako - January 2016
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Contact: tamby@tambako.ch
*/

#define pi 3.141593

const float nbs = 6.1;
const float ncr0 = 6.;
const float cd = 4.1;
const float cdm = 0.02;
const float psm = 0.0007;

const float sr = 1.5;

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
  float objnr;
};
    
Lamp lamps[3];

vec3 campos = vec3(0., 0., 9.);
vec3 camdir = vec3(0., 0., -1.);
float fov = 4.7;

const vec3 ambientColor = vec3(0.2);
const float ambientint = 0.16;
const vec3 speccolor = vec3(0.95, 0.97, 1.);

vec3 colors[3];

#define specular
const float specint = 0.03;
const float specshin = 0.8;

const float normdelta = 0.0001;
const float maxdist = 17.;

vec3 posr;

float angle;
float angle2;

// Antialias. Change from 1 to 2 or more AT YOUR OWN RISK! It may CRASH your browser while compiling!
const float aawidth = 0.8;
const int aasamples = 1;

vec2 rotateVec(vec2 vect, float angle)
{
    vec2 rv;
    rv.x = vect.x*cos(angle) + vect.y*sin(angle);
    rv.y = vect.x*sin(angle) - vect.y*cos(angle);
    return rv;
}

vec3 rotateVec2(vec3 posr)
{
    posr = vec3(posr.x, posr.y*cos(angle2) + posr.z*sin(angle2), posr.y*sin(angle2) - posr.z*cos(angle2));
    posr = vec3(posr.x*cos(angle) + posr.z*sin(angle), posr.y, posr.x*sin(angle) - posr.z*cos(angle)); 
    
    return posr;
}

float radial_patterm(vec3 pos)
{
    vec2 uv0 = pos.xy;
    float a0 = atan(uv0.x, uv0.y);
    float ro = acos(abs(pos.z))/pi;
    
    float l = ro*cd;
    
    float sn = floor(0.5 + l*nbs);
    float ccr = sn/(cd*nbs); 

    float ncr = sn*ncr0;
    float ncr2p = ncr/(2.*pi);
    
    // Couldn't use this one yet
    //float f1 = l/sqrt(1. - z0*z0);
    
    // Empiric trick so that the holes on the "equator" don't look "compressed"
    if (sn>5.)
       a0*= (ncr - floor(pow(sn - 6., 1.75)))/ncr;
    
    // To break the symmetry at the "equator"
    a0+= pos.z<0.?0.04:0.;
    
    vec2 uv = ro*vec2(sin(a0), cos(a0));
    
    float a = (floor(a0*ncr2p) + 0.5)/ncr2p;
    vec2 cpos = ccr*vec2(sin(a), cos(a));

    return sn==0.?length(uv):distance(uv, cpos);
}

float map(vec3 pos)
{   
    vec3 posr = rotateVec2(pos);
 
    float d = radial_patterm(normalize(posr));
    
    return length(posr) - sr - 0.022*(pow(smoothstep(-0.001, cdm, d), 1.3) -1.);
}

float map2(vec3 pos)
{   
    vec3 posr = rotateVec2(pos);
 
    float d = radial_patterm(normalize(posr));
    
    float outside = length(pos) - sr  - 0.1*(pow(smoothstep(cdm*0.8, cdm, d), 1.3) -1.);
    float inside = length(pos) - sr*0.96;
    
  
    return max(outside, -inside);
}

vec2 trace(vec3 cam, vec3 ray, float maxdist) 
{
    float t = 1.8;
    vec3 pos;
    float dist;
    
      for (int i = 0; i < 40; ++i)
    {
        pos = ray*t + cam;
        dist = map(pos);
        if (dist>maxdist || abs(dist)<0.0001)
            break;
        t+= dist*0.9;
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
    /*vec3 posr = rotateVec2(pos);
    float d = radial_patterm(normalize(posr));
    
    float ic = smoothstep(-psm, psm, d - cdm);
    vec3 colo = mix(vec3(1.), vec3(0.5), ic); 

    return colo;*/
    return vec3(0.85);
}

vec3 lampShading(Lamp lamp, vec3 norm, vec3 pos, vec3 ocol, float objnr)
{
    vec3 pl = normalize(lamp.position - pos);
    float dlp = distance(lamp.position, pos);
    vec3 pli = pl/pow(1. + lamp.attenuation*dlp, 2.);
    vec3 nlcol = normalize(lamp.color);
    float dnp = dot(norm, pli);
      
    // Diffuse shading
    vec3 col = ocol*nlcol*lamp.intensity*smoothstep(-0.1, 1., dnp);
    
    // Specular shading
    #ifdef specular
    //if (dot(norm, lamp.position - pos) > 0.0)
        col+= speccolor*nlcol*lamp.intensity*specint*pow(max(0.0, dot(reflect(pl, norm), normalize(pos - campos))), specshin);
    #endif
    
    return col;
}

vec3 lampsShading(vec3 norm, vec3 pos, vec3 ocol, float objnr)
{
    vec3 col = vec3(0.);
    for (int l=0; l<3; l++) // lamps.length()
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
    if (tx<maxdist*0.65)
    {
        norm = getNormal(pos, normdelta);

        // Coloring
        col = obj_color(norm, pos);
      
        // Shading
        col = ambientColor*ambientint + lampsShading(norm, pos, col, objnr);
  }
  return RenderData(col, pos, norm, objnr);
}

vec4 render(vec2 gl_FragCoord)
{
  lamps[0] = Lamp(vec3(-2., 4.5, 10.), vec3(1., 1., 1.), 6.4, 0.1);
  lamps[1] = Lamp(vec3(9., -2.5, 4.), vec3(0.77, 0.87, 1.0), 4.5, 0.1);
  lamps[2] = Lamp(vec3(-9., -5., -4.), vec3(1.0, 0.6, 0.5), 2.2, 0.1);
    
  vec2 uv = gl_FragCoord.xy / resolution.xy; 
  uv = uv*2.0 - 1.0;
  uv.x*= resolution.x / resolution.y;

  vec3 ray = GetCameraRayDir(uv, camdir, fov);
    
  RenderData traceinf = trace0(campos, ray);
  vec3 col = traceinf.col;

  return vec4(col, 1.0);
}

void main(void)
{
    angle = -2.*pi*(mouse.x*resolution.x/resolution.x - 0.5);
    angle2 = -2.*pi*(mouse.y*resolution.y/resolution.y - 0.5);
    
    // Antialiasing
    vec4 vs = vec4(0.);
    for (int j=0;j<aasamples ;j++)
    {
       float oy = float(j)*aawidth/max(float(aasamples-1), 1.);
       for (int i=0;i<aasamples ;i++)
       {
          float ox = float(i)*aawidth/max(float(aasamples-1), 1.);
          vs+= render(gl_FragCoord.xy + vec2(ox, oy));
       }
    }
    glFragColor = vs/vec4(aasamples*aasamples);    
}
