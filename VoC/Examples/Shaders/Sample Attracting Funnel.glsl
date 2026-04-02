#version 420

// original https://www.shadertoy.com/view/3tXSRS

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

// The defines to switch on and off some features
#define specular
#define pattern
//#define bump
#define balls
//#define ball_reflection
#define shadow
//#define test_mode

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

#define HOLE_OBJ      1
#define BALL_OBJ      2

// Campera options
vec3 campos = vec3(0.5, -0.4, 10.);
vec3 camtarget = vec3(0., 0., 0.);
vec3 camdir;
float fov = 5.8;
float angle;
float angle2;

const float normdelta = 0.0001;
const float maxdist = 60.;

const vec3 ball_color = vec3(1., 0.1, 0.1);
const float ballR = 0.3;

const vec3 ambientColor = vec3(0.3);
const float ambientint = 0.12;
const vec3 speccolor = vec3(0.95, 0.97, 1.);

const float specint_hole = 0.047;
const float specshin_hole = 23.;
const float specint_ball = 0.18;
const float specshin_ball = 30.;

const float shi = 0.84;
const float shf = 0.4;

const float bottom = 7.5;
const float txtSpeed = 2.;
const float cdif = 0.012;
const float holeWidth = 0.5;
const float pati = 0.33;
const float bumpHeight = 0.015;

vec3 posr;

// Antialias. Change from 1 to 2 or more AT YOUR OWN RISK! It may CRASH your browser while compiling!
const float aawidth = 0.8;
const int aasamples = 1;

// Union operation from iq
vec2 opU(vec2 d1, vec2 d2)
{
    return (d1.x<d2.x) ? d1 : d2;
}

vec2 rotateVec(vec2 vect, float angle)
{
    vec2 rv;
    rv.x = vect.x*cos(angle) + vect.y*sin(angle);
    rv.y = vect.x*sin(angle) - vect.y*cos(angle);
    return rv;
}

float hash(vec3 p)  // replace this by something better
{
    p  = fract( p*0.3183099+.1 );
    p *= 17.0;
    return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}

float polarNoise0(vec3 x)
{   
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    return mix(mix(mix( hash(p+vec3(0,0,0)), 
                        hash(p+vec3(1,0,0)),f.x),
                   mix( hash(p+vec3(0,1,0)), 
                        hash(p+vec3(1,1,0)),f.x),f.y),
               mix(mix( hash(p+vec3(0,0,1)), 
                        hash(p+vec3(1,0,1)),f.x),
                   mix( hash(p+vec3(0,1,1)), 
                        hash(p+vec3(1,1,1)),f.x),f.y),f.z);
}

const mat3 m = mat3( 0.00,  0.80,  0.60,
                    -0.80,  0.36, -0.48,
                    -0.60, -0.48,  0.64 );

float polarNoise(vec3 pos1)
{
    vec3 q = 8.0*pos1;
    float f = 0.0;
    f  = 0.5000*polarNoise0(q); q = m*q*2.;
    f += 0.2500*polarNoise0(q); q = m*q*2.;
    f += 0.1250*polarNoise0(q); q = m*q*2.;
    f += 0.0625*polarNoise0(q); q = m*q*2.;
    
    return f;
}

float polarNoise2(vec3 pos)
{
    float a = 2.*atan(pos.y, pos.x);
    vec3 pos1 = vec3(pos.z, length(pos.yx) + time*txtSpeed, a);
    vec3 pos2 = vec3(pos.z, length(pos.yx) + time*txtSpeed, a+12.57);    
    
    float f1 = polarNoise(pos1);
    float f2 = polarNoise(pos2);
    float f = mix(f1, f2, smoothstep(-5., -6.285, a));
    
    f = smoothstep(0.01, 0.2, f)-smoothstep(0.2, 0.52, f)+smoothstep(0.45, 0.63, f);
    f = 0.8-pati+f*pati;
    
    return f;
}

float polarNoiseN(vec3 pos1)
{
    vec3 q = 8.0*pos1;
    float f = 0.0;
    f  = 0.5000*polarNoise0(q); q = m*q*2.;
    f += 0.2500*polarNoise0(q); q = m*q*2.;
    
    return f;
}

float polarNoise2N(vec3 pos)
{
    float a = 2.*atan(pos.y, pos.x);
    vec3 pos1 = vec3(pos.z, length(pos.yx) + time*txtSpeed, a);
    vec3 pos2 = vec3(pos.z, length(pos.yx) + time*txtSpeed, a+12.57);    
    
    float f1 = polarNoiseN(pos1);
    float f2 = polarNoiseN(pos2);
    float f = mix(f1, f2, smoothstep(-5., -6.285, a));
    
    //f = smoothstep(0.01, 0.2, f)-smoothstep(0.2, 0.52, f)+smoothstep(0.45, 0.63, f);
    
    return f;
}

float map_ball(vec3 pos, vec3 ballPos, float ballR)
{   
    float d = length(pos-ballPos) - ballR;
    
    return d;
}

float holeFunct(vec2 pos, float holeWidth)
{
    float f1 = min(0.6/(max(length(pos)-holeWidth, 0.)), bottom);
    float f2 = 4.*min(0.6/(max(length(pos)+holeWidth*0.5, 0.)), bottom);
    
    //return min(f1, f2);
    return f1;
}

float map_hole(vec3 pos, bool hasBump)
{  
    #ifdef bump
    if (hasBump)
    {
       vec3 pos2 = vec3(pos.yx, 0.);
       pos.z+= bumpHeight*polarNoise2N(pos2);
    }
    #endif     
    
    float d = pos.z + holeFunct(pos.yx, holeWidth);
    #ifdef test_mode
    d = max(d, -pos.y);
    #endif
    
    return d;
}

vec3 getBallPos(float offset)
{
    float ii = mod(time*txtSpeed + offset, 19.8);
    float ii2 = offset + floor(time/19.8);
    vec3 hv = vec3(15.5*ii2, 22.4*ii2, 71.9*ii2);
    float ballX = -15. + ii -4.8*smoothstep(13., 20.8, ii);
    float ballZ = -holeFunct(vec2(ballX, 0.), holeWidth);
    
    float hf2 = -holeFunct(vec2(ballX+0.01, 0.), holeWidth);
    vec2 df = ballR*normalize(vec2(hf2-ballZ, 0.01));
    ballX-= df.x;
    ballZ+= df.y;
    
    #ifdef test_mode
    vec3 ballPos = vec3(ballX, 0., ballZ);
    #else
    float ballAngle = -pow(abs(0.9/(ballX+0.28)), 2.2) + hash(hv)*2.*pi;
    vec2 ballPos0 = rotateVec(vec2(ballX, 0), ballAngle);   
    vec3 ballPos = vec3(ballPos0.x, ballPos0.y, ballZ);
    #endif
    
    return ballPos;
}

float map_balls(vec3 pos)
{
    float ball1 = map_ball(pos, getBallPos(0.), ballR);
    float ball2 = map_ball(pos, getBallPos(6.6), ballR);
    float ball3 = map_ball(pos, getBallPos(13.2), ballR);
    
    float b = min(min(ball1, ball2), ball3);
    
    #ifdef test_mode
    b = max(b, -pos.y);
    #endif
    
    return b;
}

vec2 map(vec3 pos, bool hasBump)
{
    vec2 res;
    
    float hole = map_hole(pos, hasBump);
    
    #ifdef balls
    float ballss = map_balls(pos);
    res = opU(vec2(hole, HOLE_OBJ), vec2(ballss, BALL_OBJ));
    #else
    res = vec2(hole, HOLE_OBJ);
    #endif
    
    return res;
}

vec2 trace(vec3 cam, vec3 ray, float maxdist) 
{
    float t = 1.8;
    vec3 pos;
    float dist;
    float objnr = 0.;
    
      for (int i = 0; i < 70; ++i)
    {
        pos = ray*t + cam;
        vec2 res = map(pos, false);
        dist = res.x;
        if (dist>maxdist || abs(dist)<0.0001)
            break;
        t+= dist*(0.85-float(i)*0.0122);
        objnr = abs(res.y);
      }
        
      return vec2(t, objnr);
}

vec3 getNormal(vec3 pos, float e)
{
    vec2 q = vec2(0, e);
    vec3 norm = normalize(vec3(map(pos + q.yxx, true).x - map(pos - q.yxx, true).x,
                          map(pos + q.xyx, true).x - map(pos - q.xyx, true).x,
                          map(pos + q.xxy, true).x - map(pos - q.xxy.x, true)));
    return norm;
}

vec3 obj_color(vec3 norm, vec3 pos, float objnr)
{
    vec3 colo;
    
    if (int(objnr)==BALL_OBJ)
       colo = ball_color;
    else
    {
       #ifdef test_mode
       colo = vec3(0.7);
       #else
       #ifdef pattern
       vec3 posr = vec3(pos.yx, cdif);
       vec3 posg = vec3(pos.yx, 0.);
       vec3 posb = vec3(pos.yx, -cdif);
       //colo = vec3(polarNoise2(posg));
       colo = vec3(polarNoise2(posr), polarNoise2(posg), polarNoise2(posb));
       #else
       colo = vec3(0.7);
       #endif
       #endif
    }
    
    colo*= smoothstep(bottom, bottom*0.25, -pos.z);
    colo*= smoothstep(maxdist*0.3, maxdist*0.1, length(pos.yx));

    return colo;
}

// From https://www.shadertoy.com/view/Xds3zN;
float softshadow(vec3 ro, vec3 rd, float mint, float tmax)
{
    float res = 1.0;
    float t = mint;
    for(int i=0; i<25; i++)
    {
        float h = map(ro + rd*t, false).x;
        res = min(res, 4.5*h/t);
        t += clamp(h, 0.01, 0.12);
        if( h<0.001 || t>tmax ) break;
    }
    return smoothstep(0.0, 0.8, res);
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
    float specint = int(objnr)==HOLE_OBJ?specint_hole:specint_ball;
    float specshin = int(objnr)==HOLE_OBJ?specshin_hole:specshin_ball;
    
    if (dot(norm, lamp.position - pos) > 0.0)
        col+= speccolor*nlcol*lamp.intensity*specint*pow(max(0.0, dot(reflect(pl, norm), normalize(pos - campos))), specshin)*smoothstep(bottom, 0., -pos.z);
    #endif
    
    // Softshadow
    #ifdef shadow
    //if (int(objnr)==HOLE_OBJ)
       col*= shi*softshadow(pos, normalize(lamp.position - pos), shf, 6.) + 1. - shi;
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

// Sets the position of the camera with the mouse and calculates its direction
void setCamera()
{
   /*
    vec2 mouse*resolution.xy2;
   if (mouse*resolution.xy.x==0. && mouse*resolution.xy.y==0.)
      mouse*resolution.xy2 = resolution.xy*vec2(0.52, 0.65);
   else
      mouse*resolution.xy2 = mouse*resolution.xy.xy;
   **/ 
   campos = vec3(3.5 + 10.*cos(1.3 + 1.3*mouse.x*resolution.x/resolution.x)*(1. - 0.0*mouse.y*resolution.y/resolution.y),
                 -13. + 12.*(mouse.y*resolution.y/resolution.y),
                 -5.5 + 10.*sin(1.3 + 1.3*mouse.x*resolution.x/resolution.x)*(1. + 0.6*mouse.y*resolution.y/resolution.y));
   camtarget = vec3(0., -3.2 + 2.8*mouse.y*resolution.y/resolution.y + 0.1, 1.);
    
   #ifdef test_mode
   campos.z-= 1.5;
   camtarget.z-= 1.5;
   fov = 4.;
   #endif
    
   camdir = camtarget - campos;   
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
      col = obj_color(norm, pos, objnr);
      
      // Shading
      col = ambientColor*ambientint + lampsShading(norm, pos, col, objnr);
  }
  return RenderData(col, pos, norm, objnr);
}

// Fresnel reflectance factor through Schlick's approximation: https://en.wikipedia.org/wiki/Schlick's_approximation
float fresnel(vec3 ray, vec3 norm, float n2)
{
   float n1 = 1.; // air
   float angle = acos(-dot(ray, norm));
   float r0 = dot((n1-n2)/(n1+n2), (n1-n2)/(n1+n2));
   float r = r0 + (1. - r0)*pow(1. - cos(angle), 5.);
   return clamp(r, 0., 0.8);
}

vec4 render()
{
  lamps[0] = Lamp(vec3(7., -8., 3.5), vec3(1.0, 1.0, 1.0), 11.2, 0.1);
  lamps[1] = Lamp(vec3(-14., 2.5, 29.), vec3(0.7, 0.82, 1.0), 7.0, 0.1);
  lamps[2] = Lamp(vec3(1., 0., 1.2), vec3(1.0, 0.6, 0.4), 0.6, 0.1);
    
  vec2 uv = gl_FragCoord.xy / resolution.xy; 
  uv = uv*2.0 - 1.0;
  uv.x*= resolution.x / resolution.y;

  vec3 ray = GetCameraRayDir(uv, camdir, fov);
    
  RenderData traceinf = trace0(campos, ray);
  vec3 col = traceinf.col;
    
  #ifdef ball_reflection
  if (int(traceinf.objnr)==BALL_OBJ)
  {
     vec3 refray;
     float rf = 1.;
     refray = reflect(ray, traceinf.norm);

     RenderData traceinf_ref = trace0(traceinf.pos, refray);
     rf = 0.75*fresnel(ray, traceinf.norm, 2.5)*smoothstep(bottom, 0., -traceinf.pos.z);

     col = mix(col, traceinf_ref.col, rf);    
  }
  #endif
    
  return vec4(col, 1.0);
}

void main(void)
{
    setCamera();
    
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
