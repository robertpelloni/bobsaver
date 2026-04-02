#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/stlGWs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_FLOAT 1e6
#define MIN_FLOAT 1e-6

struct Cylinder{vec3 A, B; float r;};
struct Ray{ vec3 origin, dir; };
struct HitRecord{ float t; vec3 p; vec3 normal; };
struct Tube{vec3 points[3], colors[3];};

vec3 rayDirection(float fieldOfView, vec2 size) {
    vec2 xy = gl_FragCoord.xy - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

mat3 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat3(s, u, -f);
}

bool cylinderHit(const in Ray ray,  const in Cylinder cyl, out vec2 dst) {
  float cxmin, cymin, czmin, cxmax, cymax, czmax;
  if (cyl.A.z < cyl.B.z) {
      czmin = cyl.A.z - cyl.r; czmax = cyl.B.z + cyl.r;
  } else {
      czmin = cyl.B.z - cyl.r; czmax = cyl.A.z + cyl.r;
  }
  if (cyl.A.y < cyl.B.y) {
      cymin = cyl.A.y - cyl.r; cymax = cyl.B.y + cyl.r;
  } else {
      cymin = cyl.B.y - cyl.r; cymax = cyl.A.y + cyl.r;
  }
  if (cyl.A.x < cyl.B.x) {
      cxmin = cyl.A.x - cyl.r; cxmax = cyl.B.x + cyl.r;
  } else {
      cxmin = cyl.B.x - cyl.r; cxmax = cyl.A.x + cyl.r;
  }
    /*
  if (optimize) {
   if (start.z >= czmax && (start.z + dir.z) > czmax) return;
   if (start.z <= czmin && (start.z + dir.z) < czmin) return;
   if (start.y >= cymax && (start.y + dir.y) > cymax) return;
   if (start.y <= cymin && (start.y + dir.y) < cymin) return;
   if (start.x >= cxmax && (start.x + dir.x) > cxmax) return;
   if (start.x <= cxmin && (start.x + dir.x) < cxmin) return;
  }
    */

    vec3 AB = cyl.B - cyl.A;
    vec3 AO = ray.origin - cyl.A;
    vec3 AOxAB = cross(AO, AB);
    vec3 VxAB  = cross(ray.dir, AB);
    float ab2 = dot(AB, AB);
    float a = dot(VxAB, VxAB);
    float b = 2. * dot(VxAB, AOxAB);
    float c = dot(AOxAB, AOxAB) - (cyl.r * cyl.r * ab2);
    float d = b * b - 4. * a * c;
    if (d < 0.)
        return false;
    
    //rec.t = (-b - 1. * sqrt(d)) / (2. * a);
    
    float[2] coef = float[2](1., -1.); 
    for(int i=0; i<2; i++){
        float time = (-b - coef[i] * sqrt(d)) / (2. * a);
        dst[i] = time;
    }
    return true;
}

float sdCylinder(vec3 p, vec3 a, vec3 b, float r)
{
    vec3  ba = b - a;
    vec3  pa = p - a;
    float baba = dot(ba,ba);
    float paba = dot(pa,ba);
    float x = length(pa*baba-ba*paba) - r*baba;
    float y = abs(paba-baba*0.5)-baba*0.5;
    float x2 = x*x;
    float y2 = y*y*baba;
    
    float d = (max(x,y)<0.0)?-min(x2,y2):(((x>0.0)?x2:0.0)+((y>0.0)?y2:0.0));
    
    return sign(d)*sqrt(abs(d))/baba;
}

vec3 rz( in vec3 uv, float a){
    float c = cos( a );
    float s = sin( a );
    return vec3( c * uv.x - s * uv.y, s * uv.x + c * uv.y, uv.z );
}

const float PI = acos(-1.);

#define HASHSCALE1 .1031
float hash11(float p){
        vec3 p3  = fract(vec3(p) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float hash11n(float p){
    return hash11(p) * 2. - 1.;
}

float fbm1x(float x, float time){
    float amplitude = 1.;
    float frequency = 1.;
    float y = sin(x * frequency);
    float t = 0.01*(-time * 130.0);
    y += sin(x*frequency*2.1 + t)*4.5;
    y += sin(x*frequency*1.72 + t*1.121)*4.0;
    y += sin(x*frequency*2.221 + t*0.437)*5.0;
    y += sin(x*frequency*3.1122+ t*4.269)*2.5;
    y *= amplitude*0.06;
    return y;
}

vec2 shiftAtPos(float x, float time){
    return vec2(fbm1x(x, time), fbm1x(x + 78.233, time));
}

vec3 hsv2rgb(in vec3 c){
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z * mix( vec3(1.0), rgb, c.y);
}

Tube tubes(float z){
    float ang = hash11(z) * PI * 10.;
    vec3 base = rz(vec3(0., .35, z), ang);
    vec3 points[] = vec3[3](base + vec3(0., hash11n(z + 4.13) * .1, 0.),
                          rz(base + vec3(0., hash11n(z + 5.07) * .1, 0.), PI * .66 + hash11n(z) * .1),
                          rz(base + vec3(0., hash11n(z + 2.31) * .1, 0.), PI * 1.33 + hash11n(z + 3.17) * .1));
                          
    float c1 = fbm1x(z, time * .1);
    vec2 c2 = shiftAtPos(c1, 2.) * 1.25;
    
    return Tube(points, vec3[3](hsv2rgb(vec3(c1, 1., 1.)), hsv2rgb(vec3(c2.x, 1., 1.)), hsv2rgb(vec3(c2.y, 1., 1.))));
}

vec3 hall(Ray ray){
    //ray.dir.xy = abs(ray.dir.xy);
    vec3 res = vec3(MAX_FLOAT);
    
    float dst = (.25 - ray.origin.x)/ray.dir.x;
    if(dst > 0. && dst < res.b){
        vec3 p = ray.origin + ray.dir * dst;
        res.r = .4;
        res.g = (.65 + .35 * smoothstep(.5, .4, p.y));
        res.b = dst;
    }
    
    dst = (-.25 - ray.origin.x)/ray.dir.x;
    if(dst > 0. && dst < res.b){
        vec3 p = ray.origin + ray.dir * dst;
        res.r = .4;
        res.g = (.65 + .35 * smoothstep(.5, .4, p.y));
        res.b = dst;
    }
    
    dst = (.25 - ray.origin.y)/ray.dir.y;
    if(dst > 0. && dst < res.b){
        vec3 p = ray.origin + ray.dir * dst;
        res.r = .3;
        res.g = (.85 + .25 * smoothstep(.5, .4, p.x));
        res.b = dst;
    }
    
    dst = (-.25 - ray.origin.y)/ray.dir.y;
    if(dst > 0. && dst < res.b){
        vec3 p = ray.origin + ray.dir * dst;
        res.r = .3;
        res.g = (.85 + .25 * smoothstep(.5, .4, p.x));
        res.b = dst;
    }
    
    return res;
}

const float TUBE_RAD = .005;
float getCylDensity(in Ray ray, vec3 a, vec3 b, float minD, out float dst){
    const float BIGGER_RAD = .0125;
    vec2 r;
    if(cylinderHit(ray, Cylinder(a, b, BIGGER_RAD), r) && r.x < minD){
        dst = r.x;
        float den = pow(clamp((r.y - r.x)/(BIGGER_RAD * 2.), 0., 1.), 16.) * .1;
            
        if(cylinderHit(ray, Cylinder(a, b, TUBE_RAD), r) && r.x < minD){
            den += pow(clamp((r.y - r.x)/(TUBE_RAD * 2.), 0., 1.), 4.);
        }
        return pow(clamp(den, 0., 1.), .1);
    }
    return 0.;
}

vec3 HALL_COLOR = vec3(0.114,0.012,0.149);
//vec3[3] TUBE_COLORS = vec3[3](vec3(1.000,0.933,0.502), vec3(215., 67., 255.)/255., vec3(67., 108., 255.)/255.);
vec4 world(const in Ray ray){
    vec3 hall = hall(ray);
    float minDist = hall.b;
    vec4 result = vec4(HALL_COLOR, 0.);
    float fade = smoothstep(3., 0., minDist);
    {
        vec3 p = ray.origin + ray.dir * minDist;
        float z = fract(p.z) > .5 ? ceil(p.z) : floor(p.z);
        //vec3[] tubes = tubes(z);
        Tube tubes = tubes(z);
        for(int i=1; i<4; i++){
            float dst = sdCylinder(p, tubes.points[i-1], tubes.points[i%3], TUBE_RAD);
            result.rgb = mix(result.rgb, tubes.colors[i-1],
            .25 * pow(smoothstep(50., 0., dst), 16000. + 32000. * pow(smoothstep(.001, .1, distance(p.z, z)), .75))
           + 1. * pow(smoothstep(1., .001, dst), 1024.));
        }
    }
    result.rgb *= hall.g * fade;
    
    float first = ceil(ray.origin.z);
    for(int i=8; i>0; i--){
        Tube tubes = tubes(first - float(i));
        
        float dst;
        float den = getCylDensity(ray, tubes.points[0], tubes.points[1], minDist, dst);
        result.rgb = mix(result.rgb, mix(tubes.colors[0], vec3(1.), den * (2.-dst) * .35) * smoothstep(8., 7., dst), den);
        den = getCylDensity(ray, tubes.points[1], tubes.points[2], minDist, dst);
        result.rgb = mix(result.rgb, mix(tubes.colors[1], vec3(1.), den * (2.-dst) * .35) * smoothstep(8., 7., dst), den);
        den = getCylDensity(ray, tubes.points[2], tubes.points[0], minDist, dst);
        result.rgb = mix(result.rgb, mix(tubes.colors[2], vec3(1.), den * (2.-dst) * .35) * smoothstep(8., 7., dst), den);
    }
    return result;
}

void main(void) {
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy)/resolution.y;
    
    vec2 e = shiftAtPos(1., time * .75) * .15;
    vec2 l = shiftAtPos(1., time * .75 - 2.) * .15;
    float time = -time * 2. + e.y * 5.;
    
    vec3 eye = vec3(e, time);
    vec3 viewDir = rayDirection(60., resolution.xy);
    vec3 worldDir = viewMatrix(eye, eye + vec3(l, -1.), rz(vec3(0., 1., 0.), l.y * 3.)) * viewDir;
    
    glFragColor = world(Ray(eye, worldDir));
}
