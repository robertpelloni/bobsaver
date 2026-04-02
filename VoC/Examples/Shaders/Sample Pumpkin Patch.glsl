#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3sGyzd

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//
// Pumpkin Patch by Philippe Desgranges
// Email: Philippe.desgranges@gmail.com
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//

#define MAX_DST 200.0
#define MIN_DST 0.008
#define S(a,b,c) smoothstep(a,b,c)
#define sat(a) clamp(a,0.0,1.0)
#define ZERO (min(frames,0))

//Material regions
#define PUMPKIN_DARK     0.0
#define PUMPKIN         1.0
#define PUMPKIN_INSIDE    2.0
#define GROUND_AO        3.0
#define GROUND            4.0
#define STEM            5.0

//#define MODELING

float speechHeight = 0.0;
float beat = 0.0;

#define pi 3.14159265359
#define pi2 (pi * 2.0)
#define halfPi (pi * 0.5)
#define degToRad (pi / 180.0)

mat4 scaleMatrix( in vec3 sc ) {
    return mat4(sc.x, 0,    0,    0,
                 0,      sc.y,    0,    0,
                0,      0,     sc.z,    0,
                0,      0,  0,    1);
}

mat4 rotationX( in float angle ) {
    
    float c = cos(angle);
    float s = sin(angle);
    
    return mat4(1.0, 0,     0,    0,
                 0,      c,    -s,    0,
                0,      s,     c,    0,
                0,      0,  0,    1);
}

mat3 rotationX3( in float angle ) {
    
    float c = cos(angle);
    float s = sin(angle);
    
    return mat3(1.0, 0,     0,
                 0,      c,    -s,
                0,      s,     c);
}

mat4 rotationY( in float angle ) {
    
    float c = cos(angle);
    float s = sin(angle);
    
    return mat4( c, 0,     s,    0,
                  0,    1.0, 0,    0,
                -s,    0,     c,    0,
                 0, 0,     0,    1);
}

mat3 rotationY3( in float angle ) {
    
    float c = cos(angle);
    float s = sin(angle);
    
    return mat3( c, 0,     s,
                  0,    1.0, 0,
                -s,    0,     c);
}

mat4 rotationZ( in float angle ) {
    float c = cos(angle);
    float s = sin(angle);
    
    return mat4(c, -s,    0,    0,
                 s,    c,    0,    0,
                0,    0,    1,    0,
                0,    0,    0,    1);
}

// http://iquilezles.org/www/articles/smin/smin.htm
float smin( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return min(a, b) - h*h*0.25/k;
}

// http://iquilezles.org/www/articles/smin/smin.htm
float smax( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*0.25/k;
}

vec2 combineMin(vec2 a, vec2 b)
{
    return (a.x < b.x)? a : b;
}

// Adapted from BigWIngs
vec4 N24(vec2 t) {
    float n = mod(t.x * 458.0 + t.y * 127.3, 100.0);
    return fract(sin(n*vec4(123., 1024., 1456., 264.))*vec4(6547., 345., 8799., 1564.));
}

// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdEllipsoidPrecise( in vec3 p, in vec3 r ) // approximated
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdEllipsoid( in vec3 p, in vec3 r )
{
    float k1 = length(p/r);
    return (k1-1.0)*min(min(r.x,r.y),r.z);
}

vec3 hash3( vec2 p )
{
    vec3 q = vec3( dot(p,vec2(127.1,311.7)), 
                   dot(p,vec2(269.5,183.3)), 
                   dot(p,vec2(419.2,371.9)) );
    return fract(sin(q)*43758.5453);
}

// https://www.iquilezles.org/www/articles/voronoise/voronoise.htm
float VoroNoise( in vec2 x, float u, float v )
{
    vec2 p = floor(x);
    vec2 f = fract(x);

    float k = 1.0 + 63.0*pow(1.0-v,4.0);
    float va = 0.0;
    float wt = 0.0;
    for( int j=-2; j<=2; j++ )
    for( int i=-2; i<=2; i++ )
    {
        vec2  g = vec2( float(i), float(j) );
        vec3  o = hash3( p + g )*vec3(u,u,1.0);
        vec2  r = g - f + o.xy;
        float d = dot(r,r);
        float w = pow( 1.0-smoothstep(0.0,1.414,sqrt(d)), k );
        va += w*o.z;
        wt += w;
    }

    return va/wt;
}

// Attributes of a PBR material
struct PBRMat
{
    vec3 albedo;
    float metalness;
    float roughness;
};

    
float spacing = 9.0;
float offsetMax = 3.5;

// Computes a PBR Material from material ID and world position
void GetColor(float id, vec3 pos, out PBRMat mat, vec2 pumpkinCenter)
{   

    
    vec3 orange = vec3(0.8, 0.3, 0.01);
    vec3 orangeDark = vec3(0.5, 0.01, 0.01);
    vec3 yellow = vec3(0.8, 0.8, 0.0);
    
    vec3 stem = vec3(0.15, 0.65, 0.02);
    vec3 stemDark = vec3(0.05, 0.15, 0.05);
    
    if (id <= PUMPKIN)
    {
        mat = PBRMat(mix(orange, orangeDark, id), 0.15 * id, id);
    } 
    else if (id <= GROUND)
    {
        
    
        float len = length(pos.xz - pumpkinCenter);
        float ao = 0.6 + 0.4 * S(0.5, 3.0, len);

   
        float noise2 = VoroNoise(pos.xz * 4.0, 1.0, 1.0);
        vec2 band = S(vec2(0.26), vec2(0.25), abs(fract(pos.xz * 0.07 + vec2(noise2 * 0.05)) - vec2(0.5))); 
        
        
        mat = PBRMat(mix( vec3(0.4, 0.01, 0.4), vec3(0.3, 0.01, 0.3), band.y) * ao, 0.05, 1.0);
    }  
    else
    {
        float ratio = id - STEM;
        
        mat = PBRMat(mix(stemDark, stem, ratio), 0.06, 1.0);
    }  
  
    return;
}

vec2 SDFPumpkin(vec3 pos, vec4 rnd)
{  

    float proxy = length(pos - vec3(0.0, 1.2, 0.0));
    
    if (proxy > 4.0)
    {
        return vec2(proxy - 3.0, 0.0);
    }
    else   
    {
        
        pos = (rotationY(rnd.z * 360.0) * vec4(pos, 1.0)).xyz;
        
        float bounce = sin(time * 10.0 + (rnd.x + rnd.a) * 234.4) * beat;
        
        float scX = rnd.x * 0.4 + 1.0 + bounce * 0.05;
        float scY = rnd.w * 0.4 + 1.0 - bounce * 0.1;
        
        pos *= vec3(scX, scY, scX);
        
        pos.y -= 1.25;
        
    
        
        float angle = atan(pos.x, pos.z);

        float section = smax(0.05, abs(sin(angle * 4.0)), 0.05) * 0.1;

        float longLen = length(pos.xz);

        float pinch = S(1.4, -0.2, longLen);

        float pumpkin = sdEllipsoid(pos, vec3(1.7, 1.5, 1.7)) + pinch * 0.6;
        
        float pumpkinDisplace =  ((sin(angle * 25.0) + sin(angle * 43.0)) * 0.0015 - section) * S(0.2, 1.3, longLen);

        pumpkin +=   pumpkinDisplace;

        //pumpkin *= mix(1.0, 0.5, pinch);

        float stem = longLen - 0.29 + S(1.1, 1.5, pos.y) * 0.15 + sin(angle * 4.0) * 0.01;
        
        float stemDisplace = sin(angle * 10.0);
        
        stem += stemDisplace * 0.005;

        stem -= (pos.y - 1.2) * 0.1;
        
        stem *= 0.8;
        
        float stemCut =  pos.y - 1.6 + pos.x * 0.3;

        stem = smax(stem, stemCut, 0.05);

        stem = max(stem, 1.0 - pos.y);

        float pumpkinID = clamp(pumpkinDisplace * 4.0 + 0.5, 0.0, 0.999);//, PUMPKIN_INSIDE, S(0.03, -0.05, pumpkin));
        
        float stemID = STEM + (0.5 + stemDisplace * 0.2) * S(0.1, -0.6, stemCut);
        
        
        pumpkin = abs(pumpkin) - 0.05;

        float face = length(pos.xy - vec2(0.0, 0.3)) - 1.1;
        face = max(face, -(length(pos.xy - vec2(0.0, 1.8)) - 2.0));
        
        float teeth = abs(pos.x - 0.4) - 0.16;
        teeth = smax(teeth, -0.45 - pos.y + pos.x * 0.1, 0.07);
        
        float teeth2 = abs(pos.x + 0.40) - 0.16;
        teeth2 = smax(teeth2, 0.5 + pos.y + pos.x * 0.05, 0.07);
        
        
        face = smax(face, -min(teeth, teeth2), 0.07);

        vec2 symPos = pos.xy;
        symPos.x = abs(symPos.x);

        float nose = -pos.y + 0.1;
        nose = max(nose, symPos.x - 0.25 + symPos.y* 0.5);

        float eyes = -pos.y + 0.48 - symPos.x * 0.17;
        eyes = max(eyes, symPos.x - 1.0 + symPos.y * 0.5);
        eyes = max(eyes, -symPos.x - 0.05 + symPos.y * 0.5);

        face = min(face, nose);
        face = min(face, eyes);

        face = max(face, pos.z);

        pumpkin = smax(pumpkin, -face, 0.03);
        
        

        pumpkin *= 0.9 / max(scX, scY);

        vec2 res = vec2(pumpkin, pumpkinID);
        res = combineMin(res, vec2(stem, stemID));

        return res;
    }
}

float groundHeight(vec2 xz, bool detailed)
{
    float h = sin(xz.x * 0.05) * 4.0;
    h += sin(xz.y * 0.05) * 4.0;
    
    h += sin(xz.y * 0.1 + xz.x * 0.2) * 0.5;
    
    h += sin(xz.y * 0.15 + xz.x * 0.3) * 0.3;
   
    
    return h;
}

vec2 SDFPumpkinCell(vec3 pos, vec2 cellId)
{   
    
    
    vec4 rnd = N24(cellId);
    
    vec2 offsetXZ = (rnd.xy - vec2(0.5)) * offsetMax;
    
    float ground0 = groundHeight((cellId + vec2(0.5)) * spacing + offsetXZ, false);
    
    vec2 pumpkin = SDFPumpkin(pos - vec3(offsetXZ.x, ground0, offsetXZ.y), rnd);
    
   
    
 

    return pumpkin;
}

// SDF of the scene
vec2 SDF(vec3 pos, bool precise)
{   
    
#ifdef MODELING
    vec2 pumpkin =  SDFPumpkinCell(pos, vec2(0.0));
#else

    vec2 posxz = pos.xz / spacing;
    
    vec2 cellId = floor(posxz);
    
    
    vec2 cellXZ = (fract(posxz) - vec2(0.5)) * spacing;

    vec3 cellPos = vec3(cellXZ.x, pos.y, cellXZ.y);
    
    
    // Make sure the pumpkin sits on flat ground
    vec4 rnd = N24(cellId);
    vec2 offsetXZ = (rnd.xy - vec2(0.5)) * offsetMax;
    vec2 centerPumpkin = (cellId + vec2(0.5)) * spacing + offsetXZ;
    float len = length(centerPumpkin.xy - pos.xz);
    float ground0 = groundHeight(centerPumpkin , true);
    float gound = pos.y - mix(ground0, groundHeight(pos.xz, true), S(1.0, 3.0, len));
    
    vec2 res = vec2(gound, GROUND);
    
    if (precise)
    {
        for (float z = -1.0; z <= 1.0; z++)
        {
            for (float x = -1.0; x <= 1.0; x++)
            {

                res = combineMin(res, SDFPumpkinCell(cellPos - vec3(x * spacing, 0.0,z * spacing), 
                                                     cellId + vec2(x, z)));
            }
        }
         
    }
    else
    {
        res = combineMin(res, SDFPumpkinCell(cellPos, cellId));
    }
#endif
    

    
    return res;
}

// http://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal( vec3 pos)
{
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e * SDF(pos+0.0005*e, false).x;
    }
    return normalize(n);
}

// inspired by
// http://iquilezles.org/www/articles/rmshadows/rmshadows.htm
float shadow(vec3 pos, vec3 lPos)
{   
    vec3 dir = lPos - pos;  // Light direction & disantce
    
    float len = length(dir);
    dir /= len;                // It's normalized now
    
    pos += dir * MIN_DST * 2.0;  // Get out of the surface
    
    float dst = SDF(pos, false).x; // Get the SDF
    
    // Start casting the ray
    float t = 0.0;
    float obscurance = 1.0;
    
    while (t < len)
    {
        if (dst < MIN_DST) return 0.0; 
        obscurance = min(obscurance, (20.0 * dst / t)); 
        t += dst;
        pos += dst * dir;
        dst = SDF(pos, false).x;
    }
    return obscurance;     
}

float shadow(vec3 p, vec3 n, vec3 lPos)
{
    return shadow(p + n * MIN_DST * 10.0, lPos);
}

// Cast a ray across the SDF return x: Distance, y: Materila Id
vec2 castRay(vec3 pos, vec3 dir, float maxDst, float minDst)
{
    vec2 dst = vec2(minDst * 2.0, 0.0);
    
    float t = 0.0;
    
    while (dst.x > minDst && t < maxDst)
    {
        dst = SDF(pos, true);
        t += dst.x;
        pos += dst.x * dir;
    }
    
    return vec2(t + dst.x, dst.y);
}

vec3 cookie(vec3 camPos, vec3 camDir, vec3 cookiePos, float radius, vec3 color)
{
    return vec3(0.0);
}

// A PBR-ish lighting model
vec3 PBRLight(vec3 pos, vec3 normal, vec3 view, PBRMat mat, vec3 lightPos, vec3 lightColor, float fresnel, bool shadows, float range)
{
    //Basic lambert shading stuff
    
    //return vec3(fresnel);
    
    vec3 key_Dir = lightPos - pos;
    
    float key_len = length(key_Dir);
    
    float atten = key_len / range;
    atten = 1.0 - atten * atten;
    if (atten < 0.0) return vec3(0.0);

    
    key_Dir /= key_len;
    

    float key_lambert = max(0.0, dot(normal, key_Dir));
    
     
    float key_shadow = shadows ? S(0.0, 0.10, shadow(pos, normal, lightPos)) : 1.0; 
    
    float diffuseRatio = key_lambert * key_shadow;
   
    
    vec3 key_diffuse = vec3(diffuseRatio);
    

    // The more metalness the more present the Fresnel
    float f = pow(fresnel + 0.5 * mat.metalness, mix(2.5, 0.5, mat.metalness));
    
    // metal specular color is albedo, it is white for dielectrics
    vec3 specColor = mix(vec3(1.0), mat.albedo, mat.metalness);
    
    vec3 col = mat.albedo * key_diffuse * (1.0 - mat.metalness);
    
    // Reflection vector
    vec3 refDir = reflect(view, normal);
    
    // Specular highlight (softer with roughness)
    float key_spec = max(0.0, dot(key_Dir, refDir));
    key_spec = pow(key_spec, 10.0 - 9.0 * mat.roughness) * key_shadow;
    
    float specRatio = mat.metalness * diffuseRatio;
    
    col += vec3(key_spec) * specColor * specRatio;
    col *= lightColor;
    

    
    return col * atten;
}

vec4 render(vec2 uvs)
{

#ifdef MODELING
    vec3 camPos = vec3(0.0, 2.0, -10);
    vec3 camDir = vec3(0.0, 0.0,  1.0);
#else
    
    float z = time * 4.0 - 38.0;
    
    float y = groundHeight(vec2(0.0, z), false);
    float yNext = groundHeight(vec2(0.0, z + 1.3), false);
    
    // build camera ray
    vec3 camPos = vec3(0.0, 2.0 + y, z);
    vec3 camDir = normalize(vec3(0.0, (yNext - y) * 0.3,  1.0));
#endif
    

    vec3 rayDir = camDir + vec3(uvs * 0.45, 0.0);
    
    
//    vec3 key_LightPos = camPos + vec3(6.0, 10.0, -5.0);  
    
    vec3 key_LightPos = camPos + vec3(6.0, 2.0, 5.0);
        //vec3 fill_LightPos =  (modelViewMat * vec4(-15.0, -7.0, 10.0, 0.0)).xyz;

    // mouse interaction
    vec2 mouse = mouse*resolution.xy.xy/resolution.xy;
    //if(mouse.x<.001) mouse = vec2(0.5, 0.5);
    mouse = vec2(0.5, 0.5);

    vec2 viewAngle = vec2((-mouse.x - 0.35 ) * pi2, (mouse.y - 0.54) * pi2);

    // then the viwe matrix
    mat4 viewMat =  rotationY(viewAngle.x) * rotationX(viewAngle.y);

    // transform the ray in object space
    rayDir = (viewMat * vec4(rayDir, 0.0)).xyz;

    
    vec2 d = castRay(camPos, rayDir, MAX_DST, MIN_DST);
    
    vec3 bg = vec3(0.0, 0.0, 0.2);
    bg.r += S( 0.25, 0.0, rayDir.y);
    bg.g += S( 0.16, -0.1, rayDir.y);
    
    vec3 col;
    
    if (d.x < MAX_DST)
    {
        // if it's a hit render the face
        
        vec3 pos = camPos + rayDir * d.x;
     
        vec3 n;
        
        vec2 cellId = floor(pos.xz / spacing);
        vec4 rnd = N24(cellId);
        vec2 offsetXZ = (rnd.xy - vec2(0.5)) * offsetMax;
        vec2 pumpkinCenter = (cellId + vec2(0.5)) * spacing + offsetXZ;

        // compute the surface material
        PBRMat mat;
        GetColor(d.y, pos, mat, pumpkinCenter);
        
        mat.albedo *= mat.albedo; // Convert albedo to linear space
        
        n = calcNormal(pos);

        col = mat.albedo * 0.2;
        
        // Fresnel
        float fresnel = 1.0 - sat(dot(n, -rayDir));
    
    
        // transform lights to object space
        vec3 innerLight = vec3(pumpkinCenter.x, groundHeight(pumpkinCenter.xy, false)  + 1.34 ,pumpkinCenter.y);
    
        //innerLight += sin(vec3(time * fract(pumpkinCenter.xyx * vec3(45.0, 35.0,12.0))) * 10.0) * 0.05;
        
        // Add lighting
        col += PBRLight(pos, n, rayDir, mat, key_LightPos, vec3(1.3), fresnel, true, 120.0);

        // Light from inside the pumpkin
        //float dst = length(pumpkinCenter.xy - pos.xz) * 0.25;
        //float lightAtten = max(0.0, (1.0 - dst * dst));
        col += PBRLight(pos, n, rayDir, mat, innerLight, vec3(8.0), fresnel, true, 4.5);// * lightAtten;
    
         //col *= S(0.0, 0.1, ao) * 0.5 + 0.5; // blend AO to unflatten a bit
        
          col = mix(col, vec3(1.0), S(0.0, -20.3,pos.y));
        
        col = pow(col,vec3(0.4545)); // gamma correction
        
        col = mix(col, bg, S(100.0, MAX_DST,d.x));
        
        return vec4(col, 0.0);
    }
    
    
    // Background
     col = bg;

  
    return vec4(col, 0.0);
}

// Classic stuff
void main(void)
{ 
    vec2 uv =(gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    
    

    
    float a = 0.0; //textureLod(iChannel0, vec2(0.0, 0.5), 0.0).r;
    float b = 0.0; //textureLod(iChannel0, vec2(0.01, 0.5), 0.0).r;
    float c = 0.0; //textureLod(iChannel0, vec2(0.5, 1.0), 0.0).r;
    
    speechHeight =  abs(a - b);
    beat = max(0.0, a + b + c - 1.0) * 0.5;
    
    vec3 res = render(uv).rgb;

    // Output to screen
    glFragColor = vec4(res.rgb,1.0);
}
