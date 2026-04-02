#version 420

// original https://www.shadertoy.com/view/3dGcDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ----- Ray marching options ----- //
#define AA_SAMPLES 1 // antialisaing
// #define LOW_QUALITY // if your computer isn't powerful enough
#ifdef LOW_QUALITY
    #define MAX_STEPS 50
#else
    #define MAX_STEPS 200
#endif
#define MAX_DIST 50.
#define SURF_DIST 0.0001
#define NORMAL_DELTA 0.0001

#define FBM_MAX_ITER 10

// sub interpolation used in smoothstep
#define hermiteInter(t) t * t * (3.0 - 2.0 * t)

// ----- UsefulConstants ----- //
#define PI  3.14159265358979323846264338327

// ----- Useful functions ----- //
#define rot2(a) mat2(cos(a), -sin(a), sin(a), cos(a))
float maxComp(vec2 v) { return max(v.x , v.y); }
float maxComp(vec3 v) { return max(max(v.x , v.y), v.z); }
float cro(vec2 a,vec2 b) { return a.x*b.y - a.y*b.x; }
float map(float t, float a, float b) {return a + t * (b - a); } // considering that t is in [0-1]
float map(float t, float a, float b, float c, float d) { return c + (t - a) * (d - c) / (b - a); }
float mult(vec2 v) { return v.x*v.y; }
float mult(vec3 v) { return v.x*v.y*v.z; }
float sum(vec2 v) { return v.x+v.y; }
float sum(vec3 v) { return v.x+v.y+v.z; }
#define saturate(v) clamp(v, 0., 1.)

// ----- Noise stuff ----- //
// Based on Morgan McGuire and David Hoskins
// https://www.shadertoy.com/view/4dS3Wd
// https://www.shadertoy.com/view/4djSRW

float hash1(float p) {
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

vec3 hash3(float p) {
   vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
   p3 += dot(p3, p3.yzx+33.33);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}

float perlinNoise(float x) {
    float id = floor(x);
    float f = fract(x);
    float u = hermiteInter(f);
    return mix(hash1(id), hash1(id + 1.0), u);
}

vec3 perlinNoise3(float x) {
    float id = floor(x);
    float f = fract(x);
    float u = hermiteInter(f);
    return mix(hash3(id), hash3(id + 1.0), u);
}

vec3 fbm (float x, float H, int octaves) {
    float G = exp2(-H);
    vec3 v = vec3(0.);
    float f = 1.;
    float amp = 1.;
    float aSum = 1.;
    
    for ( int i=0; i < FBM_MAX_ITER; ++i) {
        if( i >= octaves) break;
        v += amp * perlinNoise3(f*x);
        f *= 2.;
        amp *= G;
        aSum += amp;
    }
    return v / aSum;
}

vec3 vectorWiggle(float x) {
    return fbm(x, 1., 2);
}

// polynomial smooth min (k = 0.1);
float polysmin( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float sphereSDF(vec3 p, float radius) { return length(p) - radius; }

// source: http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
// All components are in the range [0, 1], including hue.
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// All components are in the range [0, 1], including hue.
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float sceneSDF(vec3 p) {
    float d = 1.e10;
    
    float speed = 0.5;
    float t = time*speed;
    for(float i=0.0; i < 15.; ++i) {
        float h = hash1(i*4757.);
        float radius = map(pow(perlinNoise(i*15456. + t),3.), 0.05, 0.35);
        vec3 center = mix(1., 0.4, pow(perlinNoise(i*10.*h+ t), 3.))*(vectorWiggle(i*10.*h + t)*2.-1.);
        float sphere = sphereSDF(p - center, radius);
        
        d = polysmin(d, sphere, mix(0.05, 0.1, h));
    }
    return d;
}

// from iq technique
// source: https://www.shadertoy.com/view/3lsSzf
float calcOcclusion(vec3 pos, vec3 nor) {
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++) {
        float h = 0.01 + 0.11*float(i)/4.0;
        vec3 opos = pos + h*nor;
        float d = sceneSDF(opos);
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 2.0*occ, 0.0, 1.0 );
}

// source: https://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 getNormal(vec3 p) {
    const float h = NORMAL_DELTA;
    const vec2 k = vec2(1., -1.);
    return normalize( k.xyy * sceneSDF( p + k.xyy*h ) + 
                      k.yyx * sceneSDF( p + k.yyx*h ) + 
                      k.yxy * sceneSDF( p + k.yxy*h ) + 
                      k.xxx * sceneSDF( p + k.xxx*h ) );
}

// return dist, marchingCount
vec2 rayMarching(vec3 O, vec3 D) { // ray origin and dir
    float t = 0.0;
    float marchingCount = 0.0;
     
    for(int i = 0; i < MAX_STEPS; i++) {
        vec3 pos = O + D * t;
        float d = sceneSDF(pos);
        
        t += d * 0.6; // precision handling
        ++marchingCount;
        // If we are very close to the object, consider it as a hit and exit this loop
        if( t > MAX_DIST || abs(d) < SURF_DIST*0.99) break;

    }
    return vec2(t, marchingCount);
}

vec3 blendColor(float t, vec3 a, vec3 b) {
    return sqrt((1. - t) * pow(a, vec3(2.)) + t * pow(b, vec3(2.)));
}
    
vec3 render(vec3 O, vec3 D) { // ray origin and dir
    
    int reflexionsCount = 2;
    float shadowsAttenuation = 5.;
    float specularStrength = 20.;
    vec3 backgroundColor = vec3(2,43,58)/255.0;
    vec3 ballsColor = vec3(255,166,43)/255.0;
    
    // backgroundColor = vec3(29, 186, 34)/255.0;  // green
    // ballsColor = vec3(255, 68, 180)/255.0; // pink
    
    vec3 sunDir = normalize(vec3(0., 1., -1.));
    vec3 sunColor = normalize(vec3(0.7, 0.7, 0.5));
    float sunIntensity = 0.; 
    
    vec3 finalCol = vec3(0.0);
    bool skyReached = false;
    
    vec3 p, normal, ref;
    for(int i = 0; i < reflexionsCount; ++i) {// reflexion loop
        
        vec3 col = ballsColor;
        float d = rayMarching(O, D).x;
        
        if( d < MAX_DIST) {
            // intersected point position
            p = O + D * d;
            normal = getNormal(p);
            ref = normalize(reflect(D, normal));
            
            float occ = calcOcclusion(p, normal); // ambient occlusion
            float sunDiffuse = saturate(dot(normal, sunDir));
            
            float sunSpecular = pow(max(0., dot(normal, normalize(sunDir - D))), specularStrength); // Blinn-Phong
            // sunSpecular = pow(max(0., dot(sunDir, ref)), specularStrength); // Phong
            
            col += sunIntensity*sunColor*sunDiffuse + sunSpecular*sunColor;
            col *= mix(occ, 1., 0.5);
            col *= 0.3;
        }else {
            col = backgroundColor;
            skyReached = true;
        }
        
        // define new Origin and Direction for reflexion
        O = p + normal*SURF_DIST;
        D = ref;
        
        // mix reflexions colors
        // using step and mix to branchless set finalCol = col when i == 0
        if( i == 0) {
            finalCol = col;
        }else {
            float f = 0.6;
            if(skyReached) f /= 6.; // diminish impact of backgroundColor
                
            finalCol = blendColor(f, finalCol, col);
            // finalCol = (finalCol + col*f) / (1+f);
        }
        if(skyReached) break; // no reflexions calculation for sky
    }
    
    
    return vec3(saturate(finalCol));
}

vec3 computeCamDir(vec2 uv, vec3 camPos, vec3 camUp, vec3 lookAtPos) {
    vec3 camVec = normalize(lookAtPos - camPos);
    vec3 sideNorm = normalize(cross(camUp, camVec));
    vec3 upNorm = cross(camVec, sideNorm);
    vec3 worldFacing = (camPos + camVec);
    vec3 worldPix = worldFacing + uv.x * sideNorm + uv.y * upNorm;
    return normalize(worldPix - camPos);
}

void main(void) {

    vec2 uv = (gl_FragCoord.xy - .5*resolution.xy)/resolution.y;
    uv *= 1.1; // zoom
    
    vec3 O = vec3(1.5, 0., 0.); // origin

    vec3 finalColor = vec3(0.);
#if AA_SAMPLES > 1
    for (float i = 0.; i < float(AA_SAMPLES); i++) {
        for (float j = 0.; j < float(AA_SAMPLES); j++) {
            vec2 deltaUV = (vec2(i, j) / float(AA_SAMPLES) *2.0 - 1.0) / resolution.y;
            uv += deltaUV;
#endif
            vec3 D = computeCamDir(uv, O, vec3(0.,1.,0.), vec3(0.)); // dir
            finalColor += render(O, D);
#if AA_SAMPLES > 1
        }
    }
    finalColor /= float(AA_SAMPLES * AA_SAMPLES); // Average samples
#endif
    
    // gamma corection
    finalColor = pow(finalColor, vec3(1./2.2));
    
    
    vec3 hsv = rgb2hsv(finalColor);
    hsv.y *= 1.5; // saturate
    hsv.z *= 1.3;
    finalColor = hsv2rgb(saturate(hsv));
    
    // color grading
    finalColor *= vec3(1.07 ,0.92, 0.95);
    
    glFragColor = vec4(finalColor,1.);
}
