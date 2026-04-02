#version 420

// original https://www.shadertoy.com/view/MdK3Rm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
"" by Emmanuel Keller aka Tambako - January 2016
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Contact: tamby@tambako.ch
*/

#define pi 3.141593
#define sin45 0.7071067

// Switches, you can play with them!
//#define shadow
#define ambocc
#define specular
#define curved_framework
#define color_changes
#define fog_variation
//#define antialiaising

struct Lamp
{
  vec3 position;
  vec3 color;
  float intensity;
  float attenuation;
};

struct DirLamp
{
  vec3 direction;
  vec3 color;
  float intensity;
};

struct RenderData
{
  vec3 col;
  vec3 pos;
  vec3 norm;
  int objnr;
};
    
//Lamp lamps[2];
DirLamp lamps[3];

// Every object of the scene has its ID
#define SKY_OBJ         0
#define FRAMEWORK_OBJ   1

// Framework options
const float T0 = 1.;
const float T0D = 0.6;
const float TF = 8.;
const float TR = 150.;

// Campera options
vec3 campos;
vec3 camdir;
float fov = 2.;
float cspeed = 180.;

// Ambient light
const vec3 ambientColor = vec3(0.3);
const float ambientint = 0.05;

// Fog
const vec3 fogColor1 = vec3(0.7);
const vec3 fogColor2 = vec3(0.5, 0.73, 1.);
vec3 fogColor;
const float fogdens0 = 0.0024;
float fogdensf;

// Shading options
const float specint = 0.2;
const float specshin = 20.;
const float aoint = 1.3;
const float shi = 0.85;
const float shf = 0.4;

// Tracing options
const float normdelta = 0.002;
const float maxdist = 1000.;

// Antialias. Change from 1 to 2 or more AT YOUR OWN RISK! It may CRASH your browser while compiling!
const float aawidth = 0.67;
const int aasamples = 2;

// 1D hash function
float hash( float n ){
    return fract(sin(n)*3538.5453);
}

vec2 rotateVec45(vec2 vect)
{
    vec2 rv;
    rv.x = vect.x*sin45 - vect.y*sin45;
    rv.y = vect.x*sin45 + vect.y*sin45;
    return rv;
}

vec2 rotateVec45i(vec2 vect)
{
    vec2 rv;
    rv.x = vect.x*sin45 + vect.y*sin45;
    rv.y = vect.x*sin45 - vect.y*sin45;
    return rv;
}

// Rotates the position vector in function of the position of the mouse
vec3 getCameraDir()
{
   //vec2 mouse*resolution.xy2;
   //if (mouse*resolution.xy.x==0. && mouse*resolution.xy.y==0.)
   //   mouse*resolution.xy2 = resolution.xy*vec2(0.5, 0.5);
   //else
   //   mouse*resolution.xy2 = mouse*resolution.xy.xy; 
    //vec2 mouse=vec2(1.0,1.0);
   
    //float angle = -2.*pi*(mouse.x*resolution.x/resolution.x - 0.5);
    //float angle2 = 0.8*pi*(mouse.y*resolution.y/resolution.y - 0.47);  

    float angle = 0;
    float angle2 = 0;  
    
    vec3 posr = vec3(0., 0., 1.);
    posr = vec3(posr.x, posr.y*cos(angle2) + posr.z*sin(angle2), posr.y*sin(angle2) - posr.z*cos(angle2));
    posr = vec3(posr.x*cos(angle) + posr.z*sin(angle), posr.y, posr.x*sin(angle) - posr.z*cos(angle)); 
    
    return normalize(posr);
}

float bar(vec3 pos, float e)
{
    vec2 d = abs(pos.xy) - vec2(e, e);
    return min(max(d.x,max(d.y,d.y)),0.0) + length(max(d,0.0)); 
}

float mapBarsRot(vec3 pos)
{
    vec3 posr = pos;
    posr.z = mod(posr.z, TF);
    posr.yz = rotateVec45(posr.yz);
    vec3 posr2 = pos;
    posr2.z = mod(posr2.z, TF);
    posr2.yz = rotateVec45i(posr2.yz);
    
    float fact = T0*TF*0.5;

    posr = abs(posr);
    posr.xy-= vec2(fact, fact*sin45);
    posr2 = abs(posr2);
    posr2.xy-= vec2(fact, fact*sin45);
        
    return max(min(bar(posr.xyz, T0/2.), bar(posr2.xyz, T0/2.)), bar(pos.xyz, fact + T0/2.));
}

float mapBars(vec3 pos)
{     
    vec3 pos0 = pos;
    float fact = T0*TF*0.5;
    
    vec3 posr = pos;
    posr.z = mod(posr.z + 1000., TF*TF + 3.6);
    posr.yz = rotateVec45(posr.yz);
    vec3 posri = pos;
    posri.z = mod(posri.z + 1000., TF*TF + 3.6);
    posri.yz = rotateVec45i(posri.yz);
   
    pos = abs(pos);
    pos.xy-= vec2(fact*TF);
    
    posr = abs(posr);
    posr.xy-= vec2(fact*TF);
    posr.y+= TF;
 
    posri = abs(posri);
    posri.xy-= vec2(fact*TF);
    posri.y+= TF;
    
    vec3 pos2 = abs(pos);
    pos2.xy-= vec2(fact);
    
    vec3 posr2 = abs(posr);
    posr2.xy-= vec2(fact);
    
    vec3 posri2 = abs(posri);
    posri2.xy-= vec2(fact);
    
    //return bar(pos2, T0/2.);
        
    float v1 = min(min(bar(pos2, T0/2.), mapBarsRot(pos)), mapBarsRot(pos.yxz));
    float v2 = min(min(bar(posr2, T0/2.), mapBarsRot(posr)), mapBarsRot(posr.yxz));
    float v3 = min(min(bar(posri2, T0/2.), mapBarsRot(posri)), mapBarsRot(posri.yxz));
    float v4 = max(min(v2, v3), bar(pos0/TF, fact + T0/2.));
    return min(v1, v4);
}

float mapBars2(vec3 pos)
{
    return min(mapBars(pos), mapBars(pos.yxz));
}

vec3 getWaveDelta(vec3 pos)
{
    #ifdef curved_framework
    return vec3(35.*sin(pos.z/368.) + 41.*sin(pos.z/185.) + 2.*sin(pos.z/96.), 
                75.*sin(pos.z/225.) + 9.*sin(pos.z/78.) + 5.*sin(pos.z/118.), 
                0.);
    #else
    return vec3(0.);
    #endif
}

// Combines all the distance fields
vec2 map(vec3 pos)
{
    pos+= getWaveDelta(pos);
    return vec2(mapBars2(pos), FRAMEWORK_OBJ);           
}

// Main tracing function
vec2 trace(vec3 cam, vec3 ray, float maxdist) 
{
    float t = 0.;
    float objnr = 0.;
    
    for (int i = 0; i < 64; ++i) // 64 85
    {
        vec3 pos = ray*t + cam;
        vec2 res = map(pos);
        float dist = res.x;
        if (dist>maxdist || abs(dist)<0.08)
            break;
        t+= dist*(0.9 + float(i)*0.009);
        //t+= dist*0.82;
        objnr = abs(res.y);
    }
    return vec2(t, objnr);
}

// From https://www.shadertoy.com/view/MstGDM
// Here the texture maping is only used for the normal, not the raymarching, so it's a kind of bump mapping. Much faster
vec3 getNormal(vec3 pos, float e)
{  
    e = pow(distance(campos, pos), 2.)*0.00001;
    vec2 q = vec2(0, e);
    return normalize(vec3(map(pos + q.yxx).x - map(pos - q.yxx).x,
                          map(pos + q.xyx).x - map(pos - q.xyx).x,
                          map(pos + q.xxy).x - map(pos - q.xxy).x));
}

// Gets the color of the metal rings
vec3 framework_color(vec3 pos,vec3 norm)
{
    #ifdef color_changes
    vec3 fc = vec3(0.58 + 0.03*sin(pos.z/687.), 
                   0.41 + 0.09*sin(pos.z/537.), 
                   0.12 + 0.07*sin(pos.z/856.));
    #else
    vec3 fc = vec3(0.58, 0.41, 0.12);
    #endif
    vec2 tpos = vec2(dot(pos.yx, norm.xy) + pos.z, dot(pos.yz, norm.zy) - 1.5*pos.z + 0.2);
    vec3 mc = vec3(0.0,0.0,0.0);
    float mc2 = 0.0;
    vec3 col1 = mix(mix(mc, fc*mc, 0.5), fc, 0.4);
    col1 = mix(col1, vec3(0.05), smoothstep(0.65, 1., mc2));
    col1 = mix(col1, vec3(0.42, 0.19, 0.13), smoothstep(0.55, 0., mc2));
        
    return col1;
}

// Gets the color of the sky
vec3 sky_color(vec3 ray)
{
    return fogColor;
}

float calcAO( in vec3 p, in vec3 n, float maxDist, float falloff )
{
    float ao = 0.0;
    const int nbIte = 5;
    for( int i=0; i<nbIte; i++ )
    {
        float l = hash(float(i))*maxDist;
        vec3 rd = n*l;
        ao += (l - map(p + rd.x).x) / pow(1.+l, falloff);
    }
    return clamp( 1.35*(1.-ao/float(nbIte)), 0., 1.);
}

// Shading of the objects pro lamp
vec3 lampShading(DirLamp lamp, vec3 norm, vec3 pos, vec3 ocol, int objnr, int lampnr)
{
    vec3 pl = normalize(lamp.direction);
      
    // Diffuse shading
    vec3 col = ocol*lamp.color*lamp.intensity*clamp(dot(norm, pl), 0., 1.);
    
    // Specular shading
    #ifdef specular
    if (dot(norm, lamp.direction) > 0.0)
        col+= lamp.color*lamp.intensity*specint*pow(max(0.0, dot(reflect(pl, norm), normalize(pos - campos))), specshin);
    #endif
    
    // Softshadow
    #ifdef shadow
    col*= shi*softshadow(pos, normalize(vec3(lamp.position.x, 4.9, lamp.position.z) - pos), shf, 100.) + 1. - shi;
    #endif
    
    return col;
}

// Shading of the objects over all lamps
vec3 lampsShading(vec3 norm, vec3 pos, vec3 ocol, int objnr)
{
    vec3 col = vec3(0.);
    for (int l=0; l<3; l++) // lamps.length()
        col+= lampShading(lamps[l], norm, pos, ocol, objnr, l);
    
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

// Tracing and rendering a ray
RenderData trace0(vec3 tpos, vec3 ray, float maxdist)
{
    vec2 tr = trace(tpos, ray, maxdist);
    float tx = tr.x;
    int objnr = int(tr.y);
    vec3 col;
    vec3 pos = tpos + tx*ray;
    vec3 norm;
 
    lamps[0] = DirLamp(vec3(-2., 1., -5.), vec3(1., 1., 1.), 1.5);
    lamps[1] = DirLamp(vec3(2., 3., -5.), vec3(1., .95, .75), 1.5);
    lamps[2] = DirLamp(vec3(2., -1., 5.), vec3(0.6, 0.75, 1.), 1.5);

    // Fog
    #ifdef fog_variation
    fogdensf = 0.15*sin(tpos.z/452.) + 0.1*sin(tpos.z/216.) + 0.05*sin(tpos.z/143.);
    #else
    fogdensf = 0.3;
    #endif
    float fogdens = (1.2 + 2.*fogdensf)*fogdens0;
    fogColor = mix(fogColor2, fogColor1, 0.7 + fogdensf);
    
    if (tx<maxdist)
    {
        norm = getNormal(pos, normdelta);
        col = framework_color(pos, norm);
      
        // Shading
        col = ambientColor*ambientint + lampsShading(norm, pos, col, objnr);
        
        // Ambient occlusion
        #ifdef ambocc
        col*= 1. - aoint + aoint*vec3(calcAO(pos, norm, 7., 1.1));
        //col = vec3(calcAO(pos, norm, 25., 0.9));
        #endif
        
        float fogd = clamp(exp(-pow(fogdens*tx, 2.)), 0., 1.);
        col = mix (fogColor, col, fogd);
    }
    else
    {
        objnr = SKY_OBJ;
        col = sky_color(ray);
    }
    return RenderData(col, pos, norm, objnr);
}

// Main render function with reflections
vec4 render(vec2 gl_FragCoord)
{   
  vec2 uv = gl_FragCoord.xy / resolution.xy; 
  uv = uv*2.0 - 1.0;
  uv.x*= resolution.x / resolution.y;

  vec3 ray = GetCameraRayDir(uv, camdir, fov);
  
  RenderData traceinf = trace0(campos, ray, maxdist);
  vec3 col = traceinf.col;

  return vec4(col, 1.0);
}

void main(void)
{
    campos = vec3(0., 0., time*cspeed);
    campos-= getWaveDelta(campos);
    camdir = getCameraDir();
    camdir+= (getWaveDelta(campos - camdir*vec3(0., 0., 0.)) - getWaveDelta(campos + camdir*vec3(0., 0., 20.)))*0.055;
    
    // Antialiasing
    #ifdef antialiaising
    vec4 vs = vec4(0.);
    for (int j=0;j<aasamples ;j++)
    {
       float oy = float(j)*aawidth/max(float(aasamples-1), 1.);
       for (int i=0;i<aasamples ;i++)
       {
          float ox = float(i)*aawidth/max(float(aasamples-1), 1.);
          vs+= render(gl_FragCoord + vec2(ox, oy));
       }
    }
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    glFragColor = vs/vec4(aasamples*aasamples);
    #else
    glFragColor = render(gl_FragCoord.xy);
    #endif 
}
