#version 420

// original https://www.shadertoy.com/view/wdyGzV

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Anti aliasing. Change to 2 or more for better graphics, but slooooow performance.
#define AA 1

#define ZERO (min(frames,0))

#define MAX_STEPS 250
#define MAX_DIST 50.0
#define SURF_DIST .001

const vec3 camera_pos = vec3(0.0, 0.0, 0.3);
const vec3 plane_pos = vec3(0.0, 1.0, 0.0);
const vec3 corner_pos = vec3(-14.1, -2.0, -1.);
vec3 light_pos = vec3(-2.5, 5.5, -4.0);

#define OBJ_EMPTY 0
#define OBJ_BASE 1
#define OBJ_TOP 2
#define OBJ_DOOR 3

// Math
const float PI = 3.1415926535897932384626433832795;
const float PI_2 = 1.57079632679489661923;
const float PI_4 = 0.785398163397448309616;

mat4 viewMatrix(vec3 eye, vec3 center, vec3 up) 
{
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat4(
        vec4(s, 0.0),
        vec4(u, 0.0),
        vec4(-f, 0.0),
        vec4(0.0, 0.0, 0.0, 1)
    );
}

// Noise

vec2 random(vec2 st)
{
    st = vec2( dot(st,vec2(127.1,311.7)),
              dot(st,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}

float noise(vec2 st)
{
    vec2 f = fract(st);
    vec2 i = floor(st);
    
    vec2 u = f * f * f * (f * (f * 6. - 15.) + 10.);
    
    float r = mix( mix( dot( random(i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ),
                     dot( random(i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( random(i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ),
                     dot( random(i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
    return r * .5 + .5;
}

float fbm(vec2 st)
{
    float value = 0.;
    float amplitude = .5;
    float frequency = 0.;
    
    for (int i = 0; i < 8; i++)
    {
        value += amplitude * noise(st);
        st *= 2.;
        amplitude *= .5;
    }
    
    return value;
}

//https://www.shadertoy.com/view/4djSRW
float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * 443.8975);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

// Primitives

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0));
}

float sdCappedCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float rounding( in float d, in float h )
{
    return d - h;
}

float opOnion( in float sdf, in float thickness )
{
    return abs(sdf)-thickness;
}

float opUnion( float d1, float d2 ) { return min(d1,d2); }
float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }

float opIntersection( float d1, float d2 ) { return max(d1,d2); }

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

float opSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); }

float opSmoothIntersection( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h); }

struct object
{
    float d;
    int id;
};
    
object closest(object o1, object o2)
{
    if (o1.d < o2.d)
        return o1;
    
    return o2;
}

float distRoom(vec3 p, vec3 s)
{
    float room = sdBox(p - vec3(0.0, -4.0, 0.0), s);
    return room;
}

float distRooms(vec3 p, vec3 s)
{
    vec3 c = vec3(0.999, 0.0, 1.5);
    vec3 q = mod(p+0.5*c,c)-0.5*c;
    return distRoom(q, s);
}

object distBase(vec3 p)
{
    float base = sdBox(p - vec3(-10.0, -4.0, 5.0), vec3(100.0, 3.0, 60.0));
    float room = distRooms(p, vec3(0.33, 3.0, 0.55));
    
    base = opSmoothSubtraction(room, base, 0.03);
    
    return object(base, OBJ_BASE);
}

object distTop(vec3 p)
{
    float base = sdBox(p - vec3(-10.0, -1.0, 5.0), vec3(100.0, 0.05, 60.0));
    float room = distRooms(p, vec3(0.28, 4.0, 0.50));
    
    base = opSmoothSubtraction(room, base, 0.03);
    
    return object(base, OBJ_TOP);
}

object distDoor(vec3 p)
{
    p = p - vec3(0.0, -1.4, 3.65);
    vec3 c = vec3(1.1, 0.0, 1.5);
    vec3 q = mod(p+0.5*c,c)-0.5*c;
    
    float door = sdBox(q, vec3(0.08, 0.2, 0.1));
    
    return object(door, OBJ_DOOR);
}

object distDoorBase(vec3 p)
{
    p = p - vec3(0.0, -1.4, 3.65);
    vec3 c = vec3(1.1, 0.0, 1.5);
    vec3 q = mod(p+0.5*c,c)-0.5*c;
    
    float base = sdBox(q, vec3(0.11, 0.23, 0.12));
    float doorSub = sdBox(q, vec3(0.08, 0.2, 0.2));

    
    base = opSmoothSubtraction(doorSub, base, 0.006);
    
    return object(base, OBJ_TOP);
}

object getDist(vec3 p) 
{
    object base = distBase(p);
    object top = distTop(p);
    object door = distDoor(p);
    object doorBase = distDoorBase(p);

    return closest(closest(closest(base, top), door), doorBase);
}

object rayMarch(vec3 ro, vec3 rd)
{
    object obj;
    obj.id = OBJ_EMPTY;
    obj.d = 0.0;
    
    for (int i = 0; i < MAX_STEPS; i++)
    {
        vec3 p = ro + rd * obj.d;
        object o = getDist(p);
        
        obj.d += o.d;
        obj.id = o.id;
        
        if (obj.d > MAX_DIST || o.d < SURF_DIST) break;
    }
    
    return obj;
}

// Auxiliar functions
vec3 getNormal(vec3 p)
{
    object o = getDist(p);
    vec2 e = vec2(0.01, 0.0);
    
    vec3 n = o.d - vec3(
        getDist(p - e.xyy).d,
        getDist(p - e.yxy).d,
        getDist(p - e.yyx).d);
    
    return normalize(n);
}

float getVisibility(vec3 p0, vec3 p1, float k)
{
    vec3 rd = normalize(p1 - p0);
    float t = 10.0f * SURF_DIST;
    float maxt = length(p1 - p0);
    float f = 1.0f;
    while(t < maxt)
    {
        object o = getDist(p0 + rd * t);

        if(o.d < SURF_DIST)
            return 0.0f;

        f = min(f, k * o.d / t);

        t += o.d;
    }

    return f;
}

vec3 lighting(vec3 n, vec3 rd, vec3 pos, float spec_power)
{
    vec3 light_dir = normalize(light_pos - pos);
    float light_intensity = 0.5;
    
    vec3 refd = reflect(rd, n);
    float diff = max(0.0, dot(light_dir, n));
    float spec = pow(max(0.0, dot(refd, light_dir)), spec_power);
    float rim = (1.0 - max(0.0, dot(-n, rd)));
    
    vec3 l = vec3(diff, spec, rim);
    
    return l * .8 + (l * light_intensity * 2.0); 
}

float ambientOcclusion(vec3 p, vec3 n)
{
    float stepSize = 0.004f;
    float t = stepSize;
    float oc = 0.0f;
    for(int i = 0; i < 10; ++i)
    {
        object obj = getDist(p + n * t);
        oc += t - obj.d;
        t += float(i * i) * stepSize;
    }

    return 1.0 - clamp(oc * 0.2, 0.0, 1.0);
}

vec3 getSky(vec2 uv)
{
    float n = fbm(uv * 250.0);
    
    n = smoothstep(0.6, 0.65, n);
    
    return vec3(n);
}

vec2 triplanar(vec3 p, vec3 normal)
{
    if (abs(dot(normal, vec3(0.0, 1.0, 0.0))) > .8)
    {
        return p.xz;
    }
    else if (abs(dot(normal, vec3(1.0, 0.0, 0.0))) > .8)
    {
        return p.yz;
    }
    else
    {
        return p.xy;
    }
}

vec3 baseTexture(vec2 uv)
{
    uv *= 360.0;
    uv.y *= 0.01;
    float n = smoothstep(0.1, 1.0, noise(uv));
    return vec3(n);
}

vec3 baseMaterial(vec3 pos, vec3 n)
{
    pos += vec3(.2);
    pos *= 0.4;
    n = abs(n);
    vec3 t0 = baseTexture(triplanar(pos, n));
    return t0;
}

vec3 doorTexture(vec2 uv)
{
    uv *= 340.0;
    uv.y *= 0.01;
    float n = smoothstep(0.0, 0.7, mod(uv.x, 1.0));

    return vec3(n);
}

vec3 doorMaterial(vec3 pos, vec3 n)
{
    pos += vec3(.2);
    pos *= 0.4;
    n = abs(n);
    vec3 t0 = doorTexture(triplanar(pos, n));
    return t0;
}

vec3 topTexture(vec2 uv)
{
    uv.x += .52;
    uv.y += .829;

    uv.x *= 5.0;
    uv.y *= 3.34;

    float len = 0.015;
    float val = max(smoothstep(0.03, len, mod(uv.x, 2.0)), smoothstep(0.03, len, mod(uv.y, 2.0)));
    return vec3((1.0 - val) * .7 + .3);
}

vec3 topMaterial(vec3 pos, vec3 n)
{
    pos += vec3(.2);
    pos *= 0.4;
    n = abs(n);
    vec3 t0 = topTexture(triplanar(pos, n));
    return t0;
}

vec3 render(object o, vec3 p, vec3 ro, vec3 rd, vec2 suv)
{
    vec3 normal = getNormal(p);
    float shadow = getVisibility(p, light_pos, 50.0);
    
    if (o.id == OBJ_EMPTY || o.d > MAX_DIST)
    {
        return getSky(suv - vec2(0.0, time * .0007));
    }
    else if (o.id == OBJ_BASE)
    {
        vec3 l = lighting(normal, rd, p, 55.0);
        vec3 t = vec3(.4) * baseMaterial(p, normal);
        float ao = ambientOcclusion(p, normal);
        vec3 c = ao * ((t * .5) + (l.r * t * shadow * .8) + l.g + (l.b * .1 * shadow));
        return clamp(c, vec3(0.0), vec3(1.0));
    }
    else if (o.id == OBJ_DOOR)
    {
        vec3 l = lighting(normal, rd, p, 55.0);
        vec3 t = vec3(.7) * doorMaterial(p, normal);
        float ao = ambientOcclusion(p, normal);
        vec3 c = ao * ((t * .5) + (l.r * t * shadow * .8) + l.g + (l.b * .1 * shadow));
        return clamp(c, vec3(0.0), vec3(1.0));
    }
    else if (o.id == OBJ_TOP)
    {
        vec3 l = lighting(normal, rd, p, 55.0);
        vec3 t = vec3(.6) * topMaterial(p, normal);
        float ao = ambientOcclusion(p, normal);
        vec3 c = ao * ((t * .5) + (l.r * t * shadow * .8) + l.g + (l.b * .1 * shadow));
        return clamp(c, vec3(0.0), vec3(1.0));
    }
    
    return normal;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    
    vec3 ro = camera_pos;
    ro.xy += ((mouse*resolution.xy.xy / resolution.xy) - vec2(.5)) * 0.2;
    
    vec3 tot = vec3(0.0);
#if AA>1
    for(int m=ZERO; m<AA; m++)
    for(int n=ZERO; n<AA; n++)
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (2.0*(gl_FragCoord+o)-resolution.xy)/resolution.y;
#else    
        vec2 p = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
#endif

        // ray direction
        vec3 rd = normalize( vec3(p,2.0) );

         // ray differentials
        vec2 px = (2.0*(gl_FragCoord.xy+vec2(1.0,0.0))-resolution.xy)/resolution.y;
        vec2 py = (2.0*(gl_FragCoord.xy+vec2(0.0,1.0))-resolution.xy)/resolution.y;
        vec3 rdx = normalize( vec3(px,2.0) );
        vec3 rdy = normalize( vec3(py,2.0) );
        
        // render    
        object obj = rayMarch(ro, rd);
        vec3 p2 = ro + rd * obj.d;

        vec3 col = clamp(render(obj, p2, ro, rd, uv), vec3(0.0), vec3(1.0));

        // gamma
        col = pow( col, vec3(0.4545) );

        tot += col;
#if AA>1
    }
    tot /= float(AA*AA);
#endif
    
    tot = tot * .9 + .1;
    
    float mask = clamp((1.0 - pow(length(uv * 2.0), 120.0)), 0.0, 1.0);
    float border = pow(abs(length(uv * 1.98)), 120.0);
    
    //glFragColor = glFragColor = vec4(tot, 1.0);
    glFragColor = vec4(tot, 1.0) * mask + (1.0 - mask) * vec4(1.0) * border;
}
