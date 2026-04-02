#version 420

// original https://www.shadertoy.com/view/7tXXDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MIN_FLOAT 1e-6
#define MAX_FLOAT 1e6

struct Ray{ vec3 origin, dir;};
struct HitRecord{ float t; vec3 p;};

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

mat3 lookAt(in vec3 eye, in vec3 tar, in float r){
    vec3 cw = normalize(tar - eye);// camera w
    vec3 cp = vec3(sin(r), cos(r), 0.);// camera up
    vec3 cu = normalize(cross(cw, cp));// camera u
    vec3 cv = normalize(cross(cu, cw));// camera v
    return mat3(cu, cv, cw);
}

bool plane_hit(in vec3 ro, in vec3 rd, in vec3 po, in vec3 pn, out float dist) {
    float denom = dot(pn, rd);
    if (denom > MIN_FLOAT) {
        vec3 p0l0 = po - ro;
        float t = dot(p0l0, pn) / denom;
        if(t >= MIN_FLOAT && t < MAX_FLOAT){
            dist = t;
            return true;
        }
    }
    return false;
}

mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}

float sixth = 0.1666666666666667;
float third = 0.3333333333333333;

vec4 permute (vec4 v) { return mod((v * 34.0 + 1.0) * v, 289.0); }
vec4 taylor (vec4 v) { return 1.79284291400159 - v * 0.85373472095314; }

vec4 snoise(vec3 v) {

    vec3 i  = floor(v + dot(v, vec3(third)));
    vec3 p1 = v - i + dot(i, vec3(sixth));

    vec3 g = step(p1.yzx, p1.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min(g.xyz, l.zxy);
    vec3 i2 = max(g.xyz, l.zxy);

    vec3 p2 = p1 - i1 + sixth;
    vec3 p3 = p1 - i2 + third;
    vec3 p4 = p1 - 0.5;
    
    vec4 ix = i.x + vec4(0.0, i1.x, i2.x, 1.0);
    vec4 iy = i.y + vec4(0.0, i1.y, i2.y, 1.0);
    vec4 iz = i.z + vec4(0.0, i1.z, i2.z, 1.0);

    vec4 p = permute(permute(permute(iz)+iy)+ix);

    vec4 r = mod(p, 49.0);

    vec4 x_ = floor(r / 7.0);
    vec4 y_ = floor(r - 7.0 * x_); 

    vec4 x = (x_ * 2.0 + 0.5) / 7.0 - 1.0;
    vec4 y = (y_ * 2.0 + 0.5) / 7.0 - 1.0;

    vec4 h = 1.0 - abs(x) - abs(y);

    vec4 b0 = vec4(x.xy, y.xy);
    vec4 b1 = vec4(x.zw, y.zw);

    vec4 s0 = floor(b0) * 2.0 + 1.0;
    vec4 s1 = floor(b1) * 2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));

    vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

    vec3 g1 = vec3(a0.xy, h.x);
    vec3 g2 = vec3(a0.zw, h.y);
    vec3 g3 = vec3(a1.xy, h.z);
    vec3 g4 = vec3(a1.zw, h.w);

    vec4 n = taylor(vec4(dot(g1,g1),dot(g2,g2),dot(g3,g3),dot(g4,g4)));    

    vec3 n1 = g1 * n.x;
    vec3 n2 = g2 * n.y;
    vec3 n3 = g3 * n.z;
    vec3 n4 = g4 * n.w;

    vec4 m = vec4(dot(p1,p1),dot(p2,p2),dot(p3,p3),dot(p4,p4));
    
    vec4 m1 = max(0.6 - m, 0.0);
    vec4 m2 = m1 * m1;
    vec4 m3 = m2 * m1;
    vec4 m4 = m2 * m2;
    
    vec3 q1 = -6.0 * m3.x * p1 * dot(p1, n1) + m4.x * n1;
    vec3 q2 = -6.0 * m3.y * p2 * dot(p2, n2) + m4.y * n2;
    vec3 q3 = -6.0 * m3.z * p3 * dot(p3, n3) + m4.z * n3;
    vec3 q4 = -6.0 * m3.w * p4 * dot(p4, n4) + m4.w * n4;
     
    vec3 q = q1+q2+q3+q4;
    
    vec4 t = vec4(dot(p1,n1),dot(p2,n2),dot(p3,n3),dot(p4,n4));
    
    return (42.0 * vec4(q, dot(m4, t)));
    
}

float fbm1x(float x, float time){
    float amplitude = 1.;
    float frequency = 1.;
    float y = sin(x * frequency);
    float t = time * -2.;
    y += sin(x*frequency*2.1 + t)*4.5;
    y += sin(x*frequency*1.72 + t*1.121)*4.0;
    y += sin(x*frequency*2.221 + t*0.437)*5.0;
    y += sin(x*frequency*3.1122+ t*4.269)*2.5;
    y *= amplitude * 0.06;
    return y;
}

float sdCone(vec3 p, vec2 c, float h){
  float q = length(p.xz);
  return max(dot(c.xy,vec2(q,p.y)),-h-p.y);
}

float smin( float a, float b, float k ){
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float smax(float a, float b, float k)
{
    return log(exp(k*a)+exp(k*b))/k;
}

float scene(vec3 p, float h, inout vec2 offset, bool calculateOffset){
    float yFactor = p.y;
    float time = time * 2.;
    if(calculateOffset)
        offset = vec2(fbm1x(yFactor, time), fbm1x(yFactor + 78.233, time))
                 * smoothstep(-1., 2., yFactor);
    p -= vec3(offset.x, h, offset.y);
    return sdCone(p, vec2(.9, .33), 4.);
}

float inner(vec3 p, vec2 offset){
   vec3 mp = p;
   mp.xz -= offset;
   
   
   mp *= 2.;
   mp.y *= max(.25 - p.y, .4) * .5;
   mp.y -= time * 2.5;
   
   vec4 sn = snoise(mp * rotateY(fbm1x(p.y, time * .75)));
   float h = 1.;
   return distance(sn.w, max(scene(p, h, offset, false), 0.) * 2.);
}

#define MAX_MARCHING_STEPS 128
vec3 march(vec3 eye, vec3 marchingDirection, float start, float end) {
    float depth = start;
    vec2 offset;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        float dist = scene(eye + depth * marchingDirection, 2., offset, true);
        if (dist < MIN_FLOAT) {
            return vec3(depth, offset);
        }
        depth += dist;
        if (depth >= end) {
            return vec3(end, 0., 0.);
        }
    }
    return vec3(end, 0., 0.);
}

const float MAX_DIST = 100.;
#define CLR_BLUE vec3(0.000,0.082,0.702)
#define CLR_PURPLE vec3(0.427,0.020,0.478)
void main(void) {
    vec3 color = vec3(0.);
    float a = (resolution.x - mouse.x*resolution.xy.x) * .05;
    vec3 eye = vec3(8. * sin(a), 0., 8. * cos(a));
    vec3 viewDir = rayDirection(45., resolution.xy);
    vec3 worldDir = viewMatrix(eye, vec3(0., .4, 0.), vec3(0., 1., 0.)) * viewDir;
    float baseDist;
    if(plane_hit(eye, worldDir, vec3(0., -1., 0.), vec3(0., -1., 0.), baseDist)){
        vec3 p = eye + worldDir * baseDist;
        float f = mod(floor(p.z) + floor(p.x), 2.);
        color = f * vec3(.3) * smoothstep(8., 2., length(p));
    }else{
        baseDist = MAX_FLOAT;
    }
    
    Ray camRay = Ray(eye, worldDir);
    HitRecord rec;

    vec3 dist = march(camRay.origin, camRay.dir, 0., MAX_DIST);
    if (dist.x < MAX_DIST - MIN_FLOAT && dist.x < baseDist) {
        float t = dist.x;
        for(int i=0; i<MAX_MARCHING_STEPS; i++)    {
            vec3 curSamplePoint = eye + worldDir * t;
            color += mix(CLR_PURPLE, CLR_BLUE, smoothstep(0., .2 * (4. - curSamplePoint.y), length(curSamplePoint.xz)))  * smoothstep(.05, 0., inner(curSamplePoint, dist.yz)) * (1. + .5 * fbm1x(curSamplePoint.y, time * 20.));
            t += .0066;
        }
    }
    glFragColor = vec4(color, 1.);
}
