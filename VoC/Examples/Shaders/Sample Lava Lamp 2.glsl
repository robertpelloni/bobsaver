#version 420

// original https://www.shadertoy.com/view/7dV3W3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

I originally created this on Khan Academy :)

*/

precision lowp float;
const vec2 u_res = vec2(1280, 720);

/* uncomment for anti-aliasing: */
//#define MULTIPASS; 

#define pi 3.1415926

//point-light source structure
struct Light {
    vec3 o;
    vec3 col;
};

//light ray structure
struct lightR {
    vec3 col;
    vec3 dir;
};

//material structure
struct material {
    vec3 albedo;
    float rough;
    float metal;
};

//lights array
Light lights[4];

//sdBox, sdCone, and smin by Inigo Quilez
float sdBox( vec3 p, vec3 b ) 
{ 
    vec3 q = abs(p) - b; 
    return length(max(q,0.0))+min(max(q.x,max(q.y,q.z)),0.0); 
}

float smin(float a, float b, float k)
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*k*(1.0/4.0);
}

float sdCone(vec3 p, vec2 c, float h)
{
  // c is the sin/cos of the angle, h is height
  // Alternatively pass q instead of (c,h),
  // which is the point at the base in 2D
  vec2 q = h*vec2(c.x/c.y,-1.0);

  vec2 w = vec2( length(p.xz), p.y );
  vec2 a = w - q*clamp( dot(w,q)/dot(q,q), 0.0, 1.0 );
  vec2 b = w - q*vec2( clamp( w.x/q.x, 0.0, 1.0 ), 1.0 );
  float k = sign( q.y );
  float d = min(dot( a, a ),dot(b, b));
  float s = max( k*(w.x*q.y-w.y*q.x),k*(w.y-q.y)  );
  return sqrt(d)*sign(s);
}

float blob(vec3 p, vec4 i, float t)
{
    float h = sin(t + i.z) * 30.0;
    float s = clamp((h + 50.0) / 50.0, 0.5, 1.0);
    return length(p + vec3(i.x, h, i.y)) - i.w * s;
}

/*float Bblob(vec3 p, vec4 i, float t)
{
    float h = sin(t + i.z) * 150.0;
    return length(p + vec3(i.x, h - 20.0, i.y)) - i.w;
}*/

//transparent signed dist func
float tsdf(vec3 p)
{
    float shape = max(sdCone(p+vec3(0,-180,0),vec2(sin(.09),cos(.09)),188.0), p.y - 70.0);

    float d = max(shape, p.y - 49.3);

    return d;
}

//main signed dist function
float sdf(vec3 p)
{

    //time
    float t = time * 0.2;

    //floor
    float d = p.y + 80.0;

    //pedestal
    d = min(d, sdBox(p+vec3(0,70,0),vec3(40,10,40)));

    //walls
    d = min(d, -sdBox(p, vec3(200)));

    //translated blob position
    vec3 mp = p + vec3(0, -20, 0);

    //lamp components
    float top = max(sdCone(p+vec3(0,-90,0),vec2(sin(.3),cos(.3)),40.), p.y - 70.0);
    float bottom = max(sdCone(-p+vec3(0,-49,0),vec2(sin(.4),cos(.4)),40.), -p.y - 50.);
    float base = sdCone(p+vec3(0,20,0),vec2(sin(.4),cos(.4)),40.);

    //adding the lamp pieces
    d = min(d, top);
    d = min(d, bottom);
    d = min(d, base);

    //lava blobs
    float b = d;

    b = smin(b, blob(mp, vec4(-6,5,1,5), t), 10.);
    b = smin(b, blob(mp, vec4(-3,0,2.3,5), t), 10.);
    b = smin(b, blob(mp, vec4(0,8,3,2), t), 10.);
    b = smin(b, blob(mp, vec4(0,7,4,2), t), 10.);
    b = smin(b, blob(mp, vec4(-8,-4,5,3), t), 10.);
    b = smin(b, blob(mp, vec4(7,0,6,3), t), 10.);
    b = smin(b, blob(mp, vec4(2,2,7,4), t), 10.);

    //constrain blobs to the container
    float container = tsdf(vec3(p.xz, clamp(p.y, -3.0, 44.0)).xzy);
    b = max(b, container + 2.0);
    b = max(b, p.y - 50.0);
    b = max(b, -p.y - 10.0);

    d = min(d, b);

    return d;
}

material getMaterial(vec3 p)
{

    //walls
    if(max(abs(p.x), abs(p.z)) > 199.0){
        return material(
            vec3(1),
            0.1,
            0.0
        );
    }

    if(max(abs(p.x), abs(p.z)) < 50.0)
    {
        //blob stuff
        if( p.y > -11.0 && p.y < 49.9 && length(p.xz) < 16.0)
        {
            return material(
                vec3(0.4, 0.1, 0.4),
                0.1,
                0.0
            );
        }

        //shiny lamp metal
        if( p.y > -59.5 && p.y < 80.0)
        {
            return material(
                vec3(0.2),
                0.2,
                1.0
            );
        }
    }

    return material(
        vec3(0.1, 0.4, 0.5),
        1.0,
        0.0
    );

}

//normal calculation
vec3 getNormal(vec3 pos)
{

    //epsilon value
    float h = 0.1;

    float dist1 = sdf(pos);
    return normalize(vec3(
        sdf(pos + vec3(h, 0, 0)) - dist1,
        sdf(pos + vec3(0, h, 0)) - dist1,
        sdf(pos + vec3(0, 0, h)) - dist1
    ));
}

//glass normal calculation
vec3 getGlassNormal(vec3 pos)
{

    //epsilon value
    float h = 0.1;

    float dist1 = tsdf(pos);
    return normalize(vec3(
        tsdf(pos + vec3(h, 0, 0)) - dist1,
        tsdf(pos + vec3(0, h, 0)) - dist1,
        tsdf(pos + vec3(0, 0, h)) - dist1
    ));
}

//create a ray for a given screen position
vec3 createRay(vec2 pos)
{
    return normalize(vec3(pos, 200.0));
}

//raymarching loop
float raymarch(vec3 ro, vec3 rd, out bool hit)
{
    const int MAX_STEPS = 70;
    const float epsilon = 0.5;

    hit = false;
    float totalDist = 0.0;
    for(int i = 0; i < MAX_STEPS; i ++){
        float d = sdf(ro + rd * totalDist);
        if(abs(d) < epsilon){
            hit = true;
            break;
        }
        totalDist += d;
    }
    return totalDist;
}

float glassmarch(vec3 ro, vec3 rd, out bool hit)
{
    const int MAX_STEPS = 20;
    const float epsilon = 0.5;

    hit = false;
    float totalDist = 0.0;
    for(int i = 0; i < MAX_STEPS; i ++){
        float d = tsdf(ro + rd * totalDist);
        if(abs(d) < epsilon){
            hit = true;
            break;
        }
        totalDist += d;
    }
    return totalDist;
}

float shadowmarch(vec3 rc, vec3 ld, float md)
{
    const int MAX_STEPS = 50;
    const float step = 0.1;

    float t = 0.0;
    for(int i = 0; i < MAX_STEPS; i++){
        float s = sdf(rc + ld * t);
        if(t > md) return 1.0;
        if(s < 0.0) return 0.0;
        t += max(step, s);
    }

    return 1.0;
}

//normal distribution function
float NDF(vec3 h, vec3 n, float a)
{
    float a2 = a * a;
    float dotHN = dot(h, n);
    float x = dotHN * dotHN * (a2 - 1.0) + 1.0;

    return a2 / (pi * x * x);
}

//geometry function
float GF(vec3 v, vec3 n, float a)
{
    float dotNV = max(dot(n, -v), 0.0);
    float a2 = a * a;
    float k = (a + 1.0) * (a + 1.0) / 8.0;

    return dotNV / (dotNV * (1.0 - k) + k);
}

//fresnel function
vec3 FF(vec3 v, vec3 n, vec3 f0)
{
    float x = clamp(1.0 - dot(v, n), 0.0, 1.0);
    return f0 + (1.0 - f0) * pow(x, 5.0);
}

//calculate contribution of individual light
vec3 calcLight (material c, vec3 n, vec3 rd, lightR lr)
{

    vec3 dir = lr.dir;
    vec3 l = lr.col;

    //material values
    vec3 a = c.albedo;
    float rough = c.rough;
    float metal = c.metal;

    //halfway vector
    vec3 h = normalize(rd + dir);

    vec3 f0 = mix(vec3(0.01), a, metal);

    //normal distribution
    float nd = NDF(dir, n, rough);

    //geometry occulsion
    float g = GF(dir, n, rough)*GF(rd, n, rough);

    //fresnel
    vec3 f = FF(-rd, n, f0);

    //some dot products
    float dotDN = max(dot(-dir, n), 0.0);
    float dotRN = max(dot(-rd, n), 0.0);

    //specular denominator
    float specDenom = 2.0 * dotDN * dotRN + .0001;
    vec3 spec = g * nd * f / specDenom;

    //diffuse contribution
    vec3 kd = (vec3(1) - f) * (1.0 - metal);

    vec3 fin = ((kd * a / pi) + spec) * l * dotDN;
    return fin;
}

//calculate contribution of all lights
vec3 doLighting(material c, vec3 n, vec3 rc, vec3 rd, bool doShadow)
{
    vec3 fCol = vec3(0.0);

    const int len = 4;
    for(int i = 0; i < 4; i++)
    {
        //get the light
        Light light = lights[i];

        //find light ray direction
        vec3 dir = normalize(rc - light.o);

        //light radius
        float r = length(rc - light.o);

        //light brightness (attenuation)
        float b = 1.0 / r;

        //resulting light ray color
        vec3 l = light.col * b;

        //light ray
        lightR lr = lightR(l, dir);

        //shadows
        float s = doShadow ? shadowmarch(rc, -dir, r) : 1.0;

        //final light contribution
        vec3 fin = calcLight(c, n, rd, lr) * s;

        fCol += fin;
    }

    //ambient light
    fCol += c.albedo * (1.0 - c.metal) * 0.1;

    //global directional lighting 
    //const vec3 sCol = vec3(0.1);
    //const vec3 sDir = normalize(vec3(1, -5, 0));
    //float s = shadowmarch(rc, -sDir);
    //fCol += calcLight(c, n, rd, lightR(sCol, sDir))*s;

    //fog
    float fog = exp(-length(rc) * 0.01);

    return fCol * fog;
}

//create a matrix
mat3 yMat(float a){
    return mat3(cos(a), 0, sin(a), 0, 1, 0, -sin(a), 0, cos(a));
}

mat3 xMat(float a){
    return mat3(1, 0, 0, 0, cos(a), -sin(a), 0, sin(a), cos(a));
}

vec4 shadeP (float t, vec3 cam, mat3 rot, vec2 unit)
{
    //ray initial values
    vec3 ro = rot * cam;
    vec3 rd = rot * createRay(unit);

    //raymarch the ray
    bool hit;
    float d = raymarch(ro, rd, hit);

    //fragment color
    vec3 col = vec3(0);

    if(!hit){
        return vec4(col, 1);
    }

    //find ray collision
    vec3 rc = ro + rd * d;

    //find collision normal
    vec3 normal = getNormal(rc);

    //find material
    material c = getMaterial(rc);

    //raymarch the glass
    bool glass;

    const material glassMat = material(vec3(1), 0.4, 1.0);
    const vec3 glassTint = vec3(2, 1, 2);

    float gd = glassmarch(ro, rd, glass);
    vec3 gc = gd * rd + ro;
    bool glassVis = gd < d || !hit;

    //shade material
    col = doLighting(c, normal, rc, rd, true);

    //glass shading
    if(glass && glassVis)
    {
        col *= glassTint;
        col += doLighting(glassMat, getGlassNormal(gc), gc, rd, false) * 0.1;

    }

    //cheap HDR
    col = col / (col + 1.0);

    //gamma correction
    col = pow(col, vec3(1.0 / 2.2));

    return vec4(col, 1);
}       

void main(void)
{

    //set the light positions
    lights[0] = Light(
        vec3(80, 10, 100), vec3(200, 100, 100)
    );

    lights[1] = Light(
        vec3(120, 80, -130), vec3(250, 250, 500)
    );

    lights[2] = Light(
        vec3(-50, 120, 120), vec3(300)
    );

    lights[3] = Light(
        vec3(-90, 110, -80), vec3(100, 200, 100)
    );

    //time increment
    float t = mod(time * 0.4, 2.0 * pi);

    //create rotation matrix
    mat3 rot = yMat(t) * xMat(sin(t)*.1-0.4);

    //find the screen scale
    float scale = 2.0 / min(resolution.x, resolution.y);

    //create clip-space-ish coordinates
    vec2 clip = (gl_FragCoord.xy - resolution.xy / 2.0)*scale;

    //translate clip space into unit space
    vec2 unit = clip * 100.0;

    //camera position
    const vec3 cam = vec3(10, -10, -199);

    # ifdef MULTIPASS
        glFragColor = (
            shadeP(t, cam, rot, unit) + 
            shadeP(t, cam, rot, unit + vec2(0.25))
        ) * 0.5;

    # else
        glFragColor = shadeP(t, cam, rot, unit);

    # endif
}
