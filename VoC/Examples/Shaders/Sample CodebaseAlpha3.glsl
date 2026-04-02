#version 420

// original https://www.shadertoy.com/view/tdyGW1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdSphere(in vec3 p, in float r)
{
  return length(p) - r;
}

float maxComp(in vec3 p)
{
  return max(p.x,max(p.y,p.z));
}

float sdBox(vec3 p, vec3 b)
{
  vec3  di = abs(p) - b;
  float mc = maxComp(di);
  return min(mc,length(max(di,0.0)));
}

vec3 saturate(in vec3 a)   { return clamp(a, 0.0, 1.0); }
vec2 saturate(in vec2 a)   { return clamp(a, 0.0, 1.0); }
float saturate(in float a) { return clamp(a, 0.0, 1.0); }

void rot(inout vec2 p, float a)
{
  float c = cos(a);
  float s = sin(a);
  p = vec2(c*p.x + s*p.y, -s*p.x + c*p.y);
}

// soft min function
float smin(float a, float b, float k)
{
  float res = exp( -k*a ) + exp( -k*b );
  return -log( res )/k;
}

float distanceEstimator(in vec3 p, out float ref)
{
  float s0 = sdBox(p + vec3(0.0, 0.0, 0.0), vec3(0.7));
  float s1 = max(s0, -sdSphere(p,0.9));
  float s2 = sdSphere(p - sin(time * 0.3) * vec3(2.0 * sin(time), 0, 2.0 * cos(time)), 0.5);

  float d = smin(s1, s2, 8.0);
  float box = sdBox(p - vec3(0.0,-1.0,0.0), vec3(2.0, 0.1, 2.0));
  
  // return max(sphere1, -sphere2);
  float o = min(box, d);
  
  if (o == box)
  {
    ref = 0.7;
  }
  else
  {
    ref = 0.3;
  }
  
  return o;

}

#define TOLERANCE       0.001
#define MAX_RAY_LENGTH  32.0
#define MAX_RAY_MARCHES 60

float rayMarch(in vec3 ro, in vec3 rd, out float ref)
{
  float t = 0.1;
  for (int i = 0; i < MAX_RAY_MARCHES; i++)
  {
    float distance = distanceEstimator(ro + rd*t, ref);
    if (distance < TOLERANCE || t > MAX_RAY_LENGTH) break;
    t += distance;
  }
  return t;
}

// Calculate vector normal to pos
vec3 normal(in vec3 pos)
{
  vec3 eps = vec3(.001,0.0,0.0);
  vec3 nor;
  float ref;
  nor.x = distanceEstimator(pos+eps.xyy, ref) - distanceEstimator(pos-eps.xyy, ref);
  nor.y = distanceEstimator(pos+eps.yxy, ref) - distanceEstimator(pos-eps.yxy, ref);
  nor.z = distanceEstimator(pos+eps.yyx, ref) - distanceEstimator(pos-eps.yyx, ref);
  return normalize(nor);
}

// Specular lighting
float specular(in vec3 nor, in vec3 ld, in vec3 rd)
{
  return pow(max(dot(reflect(ld, nor), rd), 0.), 75.);
}

// Diffuse lighting
float diffuse(in vec3 nor, in vec3 ld)
{
  return max(dot(nor, ld),0.0);
}

float softShadow(in vec3 pos, in vec3 ld, float mint, float k)
{
  float res = 1.0;
  float t = mint;
  for (int i=0; i<32; i++)
  {
    float ref;
    float distance = distanceEstimator(pos + ld*t, ref);
    res = min(res, k*distance/t);
    t += max(distance, mint*0.2);
  }
  return clamp(res,0.25,1.0);
}

const vec3 lightPos1 = 20.0*vec3(-0.3, 0.15, 1.0);
const vec3 lightPos2 = 20.0*vec3(-0.33,  -0.2, -1.0);
const vec3 lightCol1 = vec3(8.0/8.0,7.0/8.0,6.0/8.0);
const vec3 lightCol2 = vec3(8.0/8.0,6.0/8.0,7.0/8.0);

vec3 getSkyColor(in vec3 rayDir)
{
  vec3 lightDir1 = normalize(lightPos1);
  vec3 lightDir2 = normalize(lightPos2);
  float ld1      = max(dot(lightDir1, rayDir), 0.0);
  float ld2      = max(dot(lightDir2, rayDir), 0.0);
  vec3 final     = vec3(0.125);

  //if ((rayDir.y > abs(rayDir.x)*1.0) && (rayDir.y > abs(rayDir.z*0.25))) final = vec3(2.0)*rayDir.y;
  //float roundBox = length(max(abs(rayDir.xz/max(0.0,rayDir.y))-vec2(0.9, 4.0),0.0))-0.1;
  //final += vec3(0.8)* pow(saturate(1.0 - roundBox*0.5), 6.0);
  
  final += pow(lightCol1, vec3(2.0, 1.5, 1.5)) * pow(ld1, 8.0);
  final += lightCol1 * pow(ld1, 200.0);
  final += pow(lightCol2, vec3(2.0, 1.5, 1.5)) * pow(ld2, 8.0);
  final += lightCol2 * pow(ld2, 200.0);
  return final;
}

vec3 render(in vec3 ro, in vec3 rd)
{
  // position of light source
  vec3 lightPos = -2.0*vec3(1.5, 3.0, -1.0);
  // background color
  vec3 skyCol = mix(vec3(0.8, 0.8, 1.0)*0.3, vec3(0.8, 0.8, 1.0)*0.6, 0.25 + 0.75*rd.y);
  vec3 color  = vec3(0.5, 0.8, 1.0);

  vec3 aggCol = vec3(0.0);
  //float reflectionFactor = 0.3;
  float aggReflectionFactor = 1.0;

  for (int i = 0; i < 4; i++)
  {
    float reflectionFactor;
    float t = rayMarch(ro,rd, reflectionFactor);
    
    if (t < MAX_RAY_LENGTH)
    {
        // Ray intersected object
        vec3 pos = ro + t * rd;
        vec3 ld = normalize(pos - lightPos);
    
        vec3 nor = normal(pos);
    
        // diffuse lighting
        float d = diffuse(nor, ld);
        // specular lighting
        //float s = specular(nor, ld, rd);
    
        float sh = softShadow(pos, ld, 0.01, 16.0);
        vec3 refDir = reflect(rd, nor);
    
        aggCol += aggReflectionFactor * reflectionFactor * color * d * sh;
        aggReflectionFactor *= 1.0- reflectionFactor;
        
        ro = pos;
        rd = refDir;
    } 
    else
    {
        // Ray intersected sky
        aggCol += aggReflectionFactor * getSkyColor(rd);
        break;
    }
  }
  
  return aggCol;
}

void main(void)
{
  // Normalized pixel coordinates (from 0 to 1)
  vec2 p = gl_FragCoord.xy/resolution.xy - vec2(0.5);
  p.x *= resolution.x/resolution.y;
    
  // camera
  vec3 ro = 3.0*vec3(2.0, 1.0, 0.2);
  rot(ro.xz, time*0.2);
  vec3 ww = normalize(vec3(0.0, 0.0, 0.0) - ro);
  vec3 uu = normalize(cross( vec3(0.0,1.0,0.0), ww ));
  vec3 vv = normalize(cross(ww,uu));
  // ray direction
  vec3 rd = normalize( p.x*uu + p.y*vv + 2.5*ww );

  vec3 col = render(ro, rd);
  
  glFragColor = vec4(col, 1.0);
}
