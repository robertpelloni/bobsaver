#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/ft2SR1

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 3D puzzle I made using Blender and 3D-printed using my Ender 3 Pro
//
// Although the parts have a complex shape, they are the result of a simple set
// of CSG operations (union, intersect and difference). The puzzle is inspired by the
// wooden 'Pillar 5' puzzle, but most of the bars are extended so they fill up all space when
// combined, forming a solid cube of 20x20x20. 
// The cube is then intersected by sphere to yield the final form.
// The puzzle I printed was intersected by a sphere of radius 6.65 (arbitrarily chosen).
// Try different values for RADIUS (14.0 for a die, 18.0 for cube)

// Turn on LAYERS to display the 3D-printing layers (finer texture in reality)
//#define LAYERS

// Turn on for a more colorful color scheme (makes it a lot slower somehow!)
//#define COLORFUL

const float A90 = acos(0.);
const float A45 = A90 * 0.5;
const float A135 = A90 * 1.5;
const float A180 = A90 * 2.0;
const float A225 = A90 * 2.5;
const float PI = A90 * 4.0;
const float PI2 = A90 * 8.0;

const float C45 = cos(A45);         // Cos(45°) = Sin(45°)
const float W = sqrt(2.);           // Half width of a bar
const float W2 = W * 2.0;           // Full width of a bar
const vec3 SIZE = vec3(W, W, 10.);  // Half size of a bar

const float RADIUS = 6.65;          // Radius of the sphere
const float DV = 0.1;
const float SRADIUS = RADIUS * RADIUS;

const float PZ = -RADIUS * 2.0;     // Z-coordinate of the plate on which the parts are lying

const float FAR = 300.0;

// Helpers for mirror and 90° rotation
const vec3 Q = vec3(-1, 0, 1);

#define MIRX(a) (a * Q.xzz)
#define MIRY(a) (a * Q.zxz)
#define MIRZ(a) (a * Q.zzx)
#define MIRXY(a) (a * Q.xxz)

#define ROTX90(a) (a).xzy * Q.zxz
#define ROTY90(a) (a).zyx * Q.xzz
#define ROTZ90(a) (a).yxz * Q.xzz
#define ROTXY90(a) (a).zxy * Q.xxz
// Note: ROTXY90 = ROTX90( ROTY90(a) )

struct Ray{
    vec3 ro;
    vec3 rd;
};

struct Camera{
    vec3 from;
    vec3 at;
    vec3 up;
    float aper;

    vec3 look;
    vec3 hor;
    vec3 ver;
};

// Starting position of the part when laying on the plate
// (ending position will be (0, 0, 0))
const vec3[15] p0 = vec3[15] (
vec3(0.0, 14.0, PZ-W), 
vec3(6.5, -16.5, PZ+2.0), 
vec3(-7.0, 11.0, PZ), 
vec3(-7.0, 10.0, PZ), 
vec3(7.0, 11.0, PZ), 
vec3(7.0, 10.0, PZ), 
vec3(-6.5, 0.0, PZ-W2), 
vec3(6.5, 0.0, PZ-W2), 
vec3(-6.5, -11.5, PZ+W), 
vec3(6.5, -4.0, PZ-W), 
vec3(-6.5, -4.0, PZ-W), 
vec3(6.5, -14.0, PZ), 
vec3(0.0, 8.5, PZ), 
vec3(-7.0, -15.5, PZ-W),
vec3(-7.5, -16.5, PZ)
);

// Intermediate position before shifting into place
// (ending position will be (0, 0, 0))
const vec4[15] p1 = vec4[15] (
vec4(0.0, 0.0, 0.0, 0.0), 
vec4(0.0, 0.0, 8.0, 0.0), 
vec4(8.0, -8.0, 0.0, 0.0), 
vec4(-8.0, -8.0, 0.0, 0.0), 
vec4(8.0, 8.0, 0.0, 0.0), 
vec4(-8.0, 8.0, 0.0, 0.0), 
vec4(0.0, 6.0, 12.0, 0.0), 
vec4(0.0, -6.0, 12.0, 0.0), 
vec4(0.0, 20.0, 0.0, 0.0), 
vec4(0.0, 2.0, 2.0, 1.0), 
vec4(0.0, -2.0, 2.0, -1.0), 
vec4(0.0, -8.0, 8.0, 0.0),
vec4(0.0, 8.0, 8.0, 0.0), 
vec4(0.0, 20.0, 0.0, 0.0),
vec4(20.0, 0.0, 0.0, 0.0) 
);

// Starting orientation of the part when laying down
// (ending orientation will be (0, 0, 0))
const vec3[15] rot = vec3[15] (
vec3(A180, -A45, -A90), 
vec3(A90, 0.0, 0.0), 
vec3(-A90, 0.0, A90), 
vec3(-A90, 0.0, A90), 
vec3(A90, 0.0, A90), 
vec3(-A90, A180, -A90), 
vec3(A135, 0.0, 0.0), 
vec3(-A135, 0.0, A180), 
vec3(0.0, A45, A90), 
vec3(0.0, -A45, -A90), 
vec3(0.0, A45, A90), 
vec3(A225, 0.0, A180),
vec3(A135, 0.0, 0.0), 
vec3(0.0, A45, -A90),
vec3(A45, 0.0, A180)
);

const float speed = 1.5;

int frame;
vec3[15] ipos;    // animated position per part
mat3[15] irot;    // animated orientation per part

#ifdef LAYERS
mat3[15] itrot;   // inverse matrix of starting orientation
#endif

// Distance functions ---------------------------------------------------------

float sdBox(in vec3 p, in vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

// Box rotated 45° over the Z-axis
float sdBar45(in vec3 p, in vec3 b )
{
    vec3 d = abs(vec3((p.x - p.y) * C45, (p.x + p.y) * C45, p.z)) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float applyDents(in vec3 p, in float dentX, in float dentY )
{
    float g = 2.0 - step(abs(p.z), dentX * 2.) * mod(p.z + 14.0, 4.);
    float f = -(p.x + abs(g)) * C45;
    float h = 2.0 - step(abs(p.z), dentY * 2.) * mod(p.z + 12.0, 4.);
    f = max(f, -(p.y + abs(h)) * C45 );
    return f;
}

// Box rotated 45° over the Z-axis with 'dents'
// dentX: nr. dents in X-dir (0, 1 or 3)
// dentY: nr. dents in Y-dir (0 or 2)
float sdDentedBar45(in vec3 p, in float dentX, in float dentY )
{
    vec3 d = abs(vec3((p.x - p.y) * C45, (p.x + p.y) * C45, p.z)) - SIZE;
    float f = min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
    
    f = max(f, applyDents(p, dentX, dentY));
    return f;
}

// Distance functions of the puzzle parts ----------------------------------------

float mapPart0(in vec3 pos)
{
    vec3 p1 =  vec3(-pos.z - 4.0, -pos.x, pos.y);
   
    float res1 = sdBox( pos - vec3(0.0, 0.0, -7.0), vec3(2.0, 10.0, 3.0) );
    res1 = max( res1, -sdBar45( vec3(abs(pos.x), abs(pos.y), pos.z) - vec3(2., 2., -1.), SIZE ) );

    float res = sdDentedBar45( p1, 3., 0. );
    return min( res, res1 );
}

float mapPart1(in vec3 pos)
{
    float res = sdBox( vec3(abs(pos.x), pos.y, pos.z) - vec3(7.0, 0.0, -6.0), vec3(3.0, 2.0, 4.0) );
    res = min( res, sdBar45 ( ROTY90(pos) - vec3(2.0, 0.0, 0.), SIZE ) );
    res = min( res, sdBar45 ( vec3(abs(pos.x), pos.y, pos.z) - vec3(4., 0.0, -6.), vec3(W, W, 4.) ) );
    
    vec3 pbar = ROTY90( pos - vec3(0.0, 0.0, -2.0));
    return max( res, applyDents (pbar, 3., 0.));
}

float mapPart5(in vec3 pos)
{
    float res1 = sdBox( pos - vec3(-5.0, 5.0, 6.0), vec3(5.0, 5.0, 4.0) );
    res1 = max(res1, pos.y * C45 - pos.z * C45);    
    vec3 pbar = vec3(-pos.x - 2.0, pos.y - 2.0, pos.z);
    float res = sdBar45( pbar, SIZE );
    res = min( res, res1 );
    return max(res, applyDents (pbar, 3., 2.));
}

float mapPart2(in vec3 pos)
{
    return mapPart5(MIRXY(pos));
}

float mapPart3(in vec3 pos)
{
    return mapPart5(MIRY(pos));
}

float mapPart4(in vec3 pos)
{
    return mapPart5(MIRX(pos));
}

float mapPart6(in vec3 pos)
{
    float res = sdBox( pos - vec3(0, 6, -5), vec3(10, 4, 5) );
    res = max( res, -sdBox( pos - vec3(0.0, 6.0, -7.1), vec3(2.0, 4.2, 3.1) ) );
    res = max( res, -sdBar45 ( ROTX90(pos) - vec3(0.0, 4.0, 6.), SIZE ) );
    res = min( res, sdBar45 ( ROTY90(pos) - vec3(2.0, 4.0, 0.), SIZE ) );
    res = max( res, -(pos.y - pos.z) * C45 + 2.8 ); 
    
    vec3 pbar = ROTY90( pos - vec3(0.0, 4.0, -2.0));
    return max( res, applyDents (pbar, 3., 2.));
}

float mapPart7(in vec3 pos)
{
    return mapPart6(MIRY(pos));
}

float mapPart8(in vec3 pos)
{
    return sdDentedBar45 ( ROTXY90( pos ), 3., 0. );
}

float mapPart9(in vec3 pos)
{
    float res = sdBar45 ( ROTX90(pos) - vec3(4, 0, 0), SIZE );
    vec3 rpos = ROTY90(pos);
    res = min( res, sdBar45 ( vec3(rpos.x, abs(rpos.y), rpos.z) - vec3(0.0, 2.0, 7.0), vec3(W, W, 3.) ) );
    vec3 pbar = ROTY90( ROTZ90(pos) - vec3(0.0, 4.0, 0.0));
    return max( res, applyDents (pbar, 3., 2.));
}

float mapPart10(in vec3 pos)
{
    return mapPart9(MIRX(pos));
}

float mapPart12(in vec3 pos)
{
    float res = sdBox ( pos - vec3(0., 6., 5.), vec3(10., 4., 5.) );
    res = max(res, -pos.y * C45 + pos.z * C45);
    res = max(res, -pos.y * C45 - pos.z * C45 + 2.8);
    vec3 pbar = ROTY90(pos * Q.zzx - vec3(0, -10, -2));
    res = max( res, applyDents (pbar, 3., 0.));
    res = min( res, sdBar45( ROTY90(pos - vec3( 0, 4, 2)), SIZE ));
    res = max( res, -sdBar45( ROTX90(pos - vec3( 0, 1, 4)), SIZE ));
    return max( res, -sdBar45( vec3(abs(pos.x), pos.y, pos.z) - vec3( 2, 2, 0), SIZE ));
}

float mapPart11(in vec3 pos)
{
    return mapPart12( MIRY(pos));
}

float mapPart13(in vec3 pos)
{
    float res = sdBar45 ( ROTX90(pos - vec3(0, 0, 4)) , SIZE );
    return max( res, -sdBar45 ( ROTY90(pos - vec3(0, 0, 2)) , SIZE ));
}

float mapPart14(in vec3 pos)
{
    return sdBar45 ( ROTY90(pos - vec3(0, 0, 2)) , SIZE );
}

float mapPlate(in vec3 pos)
{
    return sdBox( pos - vec3(0., 0., PZ - 1.), vec3(25., 25., 2.0) );
}

vec2 animate(in Ray ray, float time)
{
    float rds = dot(ray.rd, ray.rd);
    float ros = dot(ray.ro, ray.ro);
    vec2 glim = vec2(FAR, 0.0);

    int index2 = (int(time) / 2) % 15;  // 0..14, 0..14 (2 times)
    float f1 = mod(time, 1.0);   // 0..1, 0..1, ... (30 times)
    float ease = smoothstep(0.0, 1.0, f1);
    
    vec3 spreading = vec3(vec2(max(1.0, RADIUS / 6.65)), 1.0);

    for (int index = min(frame, 0); index < 15; index++)
    {
        vec3 p0 = p0[index] * spreading;
        vec4 pp = p1[index];
        vec3 p1 = pp.xyz;
        vec3 rot = rot[index];

        vec3 p = vec3(0);
        vec3 r = vec3(0);

        if (index2 == index)
        {
            if (pp.w == 0.0)
            {
                switch (int(time) % 2)
                {
                    case 0:
                        p = mix(p0, p1, ease);
                        r = vec3(rot * (1.0 - f1));
                        break;
                    case 1:
                        p = mix(p1, vec3(0), ease);
                        break;
                }
            }
            else  // An extra animation step
            {
                vec3 p2 = p1;
                p1 = p1 + vec3(8.0, 0.0, 0.0) * pp.w;
                time *= 1.5;
                f1 = mod(time, 1.0);
                ease = smoothstep(0.0, 1.0, f1);
                switch (int(time) % 3)
                {
                    case 0:
                        p = mix(p0, p1, ease);
                        r = vec3(rot * (1.0 - f1));
                        break;
                    case 1:
                        p = mix(p1, p2, ease);
                        break;
                    case 2:
                        p = mix(p2, vec3(0), ease);
                        break;
                }
            }
        }
        else if (index2 < index)
        {
            r = rot;
            p = p0;
        }
        ipos[index] = p;
        
        // Calculate rotation matrix
        float sa = sin(r.z), ca = cos(r.z);
        float sb = sin(r.y), cb = cos(r.y);
        float sc = sin(r.x), cc = cos(r.x);
        irot[index]= mat3(
            ca*cb, sa*cb, -sb, 
            ca*sb*sc - sa*cc, sa*sb*sc+ca*cc, cb*sc,
            ca*sb*cc + sa*sc, sa*sb*cc-ca*sc, cb*cc);
            
#ifdef LAYERS            
        // Calculate inverse rotation matrix
        sa = sin(rot.z), ca = cos(rot.z);
        sb = sin(rot.y), cb = cos(rot.y);
        sc = sin(rot.x), cc = cos(rot.x);
        itrot[index]= inverse(mat3(
            ca*cb, sa*cb, -sb, 
            ca*sb*sc - sa*cc, sa*sb*sc+ca*cc, cb*sc,
            ca*sb*cc + sa*sc, sa*sb*cc-ca*sc, cb*cc)); 
#endif            
        
        
        // Calculate sphere limits
        float a = rds;
        for (int j = 0; j < 2; j++)
        {
            vec3 p1 = j == 0 ? p : vec3(p.x, p.y, 2. * PZ - p.z);
            float b = 2.0 * dot(ray.rd, ray.ro - p1);
            float c = dot(p1, p1) + ros - 2.0 * dot(p1, ray.ro) - SRADIUS;        
            float disc = b * b - 4.0 * a * c;
            if (disc >= 0.0) 
            {
                disc = sqrt(disc);
                glim.x = min(glim.x, (-b - disc) / 2. / a);
                glim.y = max(glim.y, (-b + disc) / 2. / a);
            }
        }
        
    }
    return glim;
}

float mapPart(in int index, in vec3 pos, out vec3 tpos)
{
    tpos = (vec3(pos.x, pos.y, abs(pos.z - PZ) + PZ) - ipos[index]) * irot[index];
    float dist = length(tpos) - RADIUS;
    if (dist <= DV)
    {
        float d2;
        switch(index)
        {
            case 0:  d2 = mapPart0  (tpos); break;
            case 1:  d2 = mapPart1  (tpos); break;
            case 2:  d2 = mapPart2  (tpos); break;
            case 3:  d2 = mapPart3  (tpos); break;
            case 4:  d2 = mapPart4  (tpos); break;
            case 5:  d2 = mapPart5  (tpos); break;
            case 6:  d2 = mapPart6  (tpos); break;
            case 7:  d2 = mapPart7  (tpos); break;
            case 8:  d2 = mapPart8  (tpos); break;
            case 9:  d2 = mapPart9  (tpos); break;
            case 10: d2 = mapPart10 (tpos); break;
            case 11: d2 = mapPart11 (tpos); break;
            case 12: d2 = mapPart12 (tpos); break;
            case 13: d2 = mapPart13 (tpos); break;
            case 14: d2 = mapPart14 (tpos); break;
        }
        dist = max( dist, d2 );
    }
    return dist;
}

vec2 map(in vec3 pos, out vec3 upos)
{
    upos = vec3(0);
    int ix = -1;
    float res = FAR;
    for (int index = min(frame, 0); index < 15; index++)
    {
        vec3 tpos;
        float dist = mapPart(index, pos, tpos);

        if (dist < res) 
        { 
            upos = tpos; 
            ix = index; 
            res = dist;
        }
    }
    return vec2( res, float(ix) );
}

// Camera
Camera getCamera() {
    Camera camera;
    
    bool down = false;//dot(mouse*resolution.xy.xy, mouse*resolution.xy.zw) > 0.01;
    float ta = time * 0.2;
    
    float dst = 35.0;
    vec2 mo = mouse*resolution.xy.xy / resolution.xy;
    camera.from = down 
        ? vec3(
            cos(mo.x * PI2) * sin(mo.y * PI * 0.2),
            sin(mo.x * PI2) * sin(mo.y * PI * 0.2),
            cos(mo.y * PI * 0.3)) * dst
           : vec3(sin(ta), cos(ta), 0.44) * dst;
    camera.up = vec3(0.0, 0.0, 1.0);
    camera.at = vec3(0.0, 0.0, down ? mo.y * PZ * 0.5 : 0.0);
    camera.aper =  20. * 3.141 / 180.0; // 1.0 / dst;
    camera.look = camera.at - camera.from;
    float dmin = length(camera.look);
    float hsize = camera.aper * dmin, vsize = hsize;
    if (hsize * resolution.x / resolution.y > vsize)
        hsize = vsize * resolution.x / resolution.y;
    else
        vsize = hsize * resolution.y / resolution.x;
    camera.hor = normalize(cross(camera.look, camera.up)) * hsize;
    camera.ver = normalize(cross(camera.hor, camera.look)) * vsize;

    return camera;
}

Ray getCameraRay( in Camera camera, in vec2 uv ) {
    Ray ray;
    ray.ro = camera.from;
    ray.rd = normalize(camera.look + uv.x * camera.hor + uv.y * camera.ver);
    return ray;
}

// CSG operations

// 'union' is a reserved word
vec2 combine( vec2 d1, vec2 d2 )
{
    return (d1.x<d2.x) ? d1 : d2;
}

vec2 intersect( vec2 d1, vec2 d2 )
{
    return (d1.x>d2.x) ? d1 : d2;
}

vec2 subtract( vec2 d1, vec2 d2 )
{
    return (d1.x>-d2.x) ? d1 : vec2(-d2.x, d2.y);
}

vec2 castRay( in Ray ray, vec2 glim, out vec3 rpos )
{
    float t = glim.x;
    float ix = -1.;

    int i=0;
    rpos = vec3(0);
    for( ; i<80; i++ )
    {
        float precis = 0.001*t;
        vec2 res = map(ray.ro + ray.rd*t, rpos);
        ix = res.y;
        if( res.x<precis || t>glim.y ) break;
        t += res.x;
    }

    if( t>glim.y ) ix = -1.;
    return vec2( t, ix );
}

vec3 calcNormal( in int index, in vec3 pos, in float t )
{
    vec2 e = vec2(1.0,-1.0)*0.05;
    vec3 rpos;
    return normalize( e.xyy*mapPart(index, pos + e.xyy, rpos) + 
                      e.yyx*mapPart(index, pos + e.yyx, rpos) + 
                      e.yxy*mapPart(index, pos + e.yxy, rpos) + 
                      e.xxx*mapPart(index, pos + e.xxx, rpos) );
}

vec3 render( in Ray ray, out vec3 pos)
{ 
    float time = min(mod(time / speed, 32.0), 29.999);
 
    vec2 glim = animate(ray, time);

    vec3 col = vec3(0.0);
    float alpha = 0.0;
    
    vec3 rpos;
    vec2 res = castRay(ray, glim, rpos);
    float t = res.x;

    int index = int(res.y);
    if( index >= 0 )
    {
        pos = ray.ro + t*ray.rd;
        bool refl = pos.z < PZ;
        vec3 nor = calcNormal(index, pos, t);
        
        float i = mod(res.y / 13.5, 1.);

#ifdef LAYERS        
        vec3 p2 = rpos * itrot[index] + p0[index] - PZ;
        nor.z += abs(sin(p2.z * 15.0) * 2.0);
        nor = normalize(nor);
        i = p2.z / 5.0;
#endif        
        
#ifdef COLORFUL        
        col = vec3(
            clamp(abs(i * 6.0 - 3.0) - 1.0, 0.0, 1.0),
            clamp(2.0f - abs(i * 6.0f - 2.0f), 0.0, 1.0),
            clamp(2.0f - abs(i * 6.0f - 4.0f), 0.0, 1.0)
        );
#else        
        col = vec3(1.0, 0.4, 0.1);
#endif        

        alpha = 1.0;

        // lighting        
        vec3 lig = normalize( vec3(0.5, 1.5, refl ? -1.0 : 1.0) );
        vec3 mir = reflect( ray.rd, nor );
        float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        float spec = pow(clamp( dot( mir, lig ), 0.0, 1.0 ), 30.);

        float lin = (dif + 0.5) * (0.4 + 0.6 * min(1.0, abs(pos.z - PZ) * 0.2));
        col = col*lin + spec;
        
        if (refl)
        {
            col = mix(col, vec3(.4), 0.7);
        }        
    }
    else
    {
        col = vec3(0.4);
    }

    return clamp(col, 0.0, 1.0);
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), 0.0, cos(cr));
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(void)
{
    frame = frames;

    Camera camera = getCamera();
    vec2 uv = gl_FragCoord.xy * 2.0 / resolution.xy - 1.0;
    
    Ray ray = getCameraRay(camera, uv);
    vec3 pos;
    vec3 color = render(ray, pos);
    

    glFragColor = vec4(color , 0.);
}
