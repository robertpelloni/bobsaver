#version 420

// original https://www.shadertoy.com/view/tt23zR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//-----------------------------------------------------------
// ref
// https://qiita.com/edo_m18/items/876f2857e67e26a053d6
// https://qiita.com/edo_m18/items/cbba0cc4e33a5aa3be55
//-----------------------------------------------------------

#define saturate(a) clamp(a, 0., 1.);

#define EPS 0.0001

#define USE_DIRECTIONAL_LIGHT
#define USE_AMBIENT_LIGHT

#define SAMPLE_COUNT 48

#define SHADOW_LENGTH 2.5
#define SHADOW_ITERATIONS 4

#define DENSITY_INTENSITY 0.5
#define AMBIENT_INTENSITY 8.0

vec3 ABSORPTION_INTENSITY = vec3(.5, .8, .7) * .5;

vec3 sunDirection = normalize(vec3(.5, 1., .5));
vec3 lightColor = vec3(1., 1., .8) * 1.;        
    
vec3 ambientLightDir = normalize(vec3(0., -1., 0.));
vec3 ambientLightColor = vec3(.5, .7, 1.);

vec3 cloudColor = vec3(.8, .9, 1.);    
    
//

mat3 m = mat3( 0.00,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64);

float hash(float n)
{
    return fract(sin(n) * 43758.5453);
}

float noise(in vec3 x)
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    
    f = f * f * (3.0 - 2.0 * f);
    
    float n = p.x + p.y * 57.0 + 113.0 * p.z;
    
    float res = mix(mix(mix(hash(n +   0.0), hash(n +   1.0), f.x),
                        mix(hash(n +  57.0), hash(n +  58.0), f.x), f.y),
                    mix(mix(hash(n + 113.0), hash(n + 114.0), f.x),
                        mix(hash(n + 170.0), hash(n + 171.0), f.x), f.y), f.z);
    return res;
}

float fbm(vec3 p)
{
    float f;
    p = m * p * 1.2;
    f  = 0.5000 * noise(p);
    p = m * p * 2.;
    f += 0.2500 * noise(p);
    p = m * p * 2.4;
    f += 0.1250 * noise(p);
    return f;
}

float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float scene(vec3 p) {
    // return 1. - length(p) * .2 + fbm(p * .7 + time);
    return 1. - sdTorus(p, vec2(8., .5)) + fbm(p * .7 + time) * 2.8;
}

vec3 getNormal(vec3 p) {
    vec2 e = vec2(EPS, 0);
    return normalize(
        vec3(
            scene(p + e.xyy) - scene(p - e.xyy),
            scene(p + e.yxy) - scene(p - e.yxy),
            scene(p + e.yyx) - scene(p - e.yyx)
        )
    );
    
    /* cheap
    const float h = EPS;
    const vec2 k = vec2(1., -1.);
    return normalize(
        k.xyy * scene(p + k.xyy * h) +
        k.yyx * scene(p + k.yyx * h) +
        k.yxy * scene(p + k.yxy * h) +
        k.xxx * scene(p + k.xxx * h)
    );
    */
}

mat3 camera(vec3 ro, vec3 ta) {
    vec3 forward = normalize(ta - ro);
    vec3 side = normalize(cross(forward, vec3(0., 1., 0.)));
    vec3 up = normalize(cross(side, forward));
    return mat3(side, up, forward);
}

vec4 rayMarchFog(vec3 p, vec3 dir) {    
    float zStep = 16. / float(SAMPLE_COUNT);
    
    float transmittance = 1.;
    
    vec3 color = vec3(0.);    
    
    float densityScale = DENSITY_INTENSITY * zStep;
    float shadowSize = SHADOW_LENGTH / float(SHADOW_ITERATIONS);
    vec3 shadowScale = ABSORPTION_INTENSITY * shadowSize;
    vec3 shadowStep = sunDirection * shadowSize;    
    
    for(int i = 0; i < SAMPLE_COUNT; i++) {
        float density = scene(p);
        
        if(density > EPS) {
            //float tmp = density / float(SAMPLE_COUNT);
            density = saturate(density * densityScale);
            
            // directional light            

            #ifdef USE_DIRECTIONAL_LIGHT
            
            {
            vec3 shadowPosition = p;
            float shadowDensity = 0.;
            for(int si = 0; si < SHADOW_ITERATIONS; si++) {
                float sp = scene(shadowPosition);
                shadowDensity += sp;
                shadowPosition += shadowStep;
            }
            vec3 attenuation = exp(-shadowDensity * shadowScale);
            vec3 attenuatedLight = lightColor * attenuation;
            color += cloudColor * attenuatedLight * transmittance * density;
            }
                
            #endif
            
            // ambient light
            
            #ifdef USE_AMBIENT_LIGHT
            
            {
            float shadowDensity = 0.;
            vec3 shadowPosition = p + ambientLightDir * .05;
            shadowDensity += scene(p) * .05;
            shadowPosition = p + ambientLightDir * .1;
            shadowDensity += scene(p) * .05;
            shadowPosition = p + ambientLightDir * .2;
            shadowDensity += scene(p) * .1;
            float attenuation = exp(-shadowDensity * AMBIENT_INTENSITY);
            vec3 attenuatedLight = vec3(ambientLightColor * attenuation);
            color += cloudColor * attenuatedLight * transmittance * density;
            }
            
            #endif
            
            transmittance *= 1. - density;            
        }

        if(transmittance < EPS) {
            break;
        }
        
        p += dir * zStep;
        
    }
    
    //return color;
    return vec4(color, 1. - transmittance);
}

void main(void) {
      vec2 aspect = vec2(resolution.x / resolution.y, 1.);
      vec2 uv = (gl_FragCoord.xy / resolution.xy - .5) * aspect;
    
    vec2 mouse = mouse*resolution.xy.xy / resolution.xy - .5;

      // camera settings
      float fov = 1.2;
    vec3 lookAt = vec3(10. * mouse.x, 10. * mouse.y, 0.) * 0.;
    vec3 cameraPos = vec3(
        // cos(time * .6) * 20.,
        // sin(time * .8) * 20.,
        0.,
        0.,
        20.
    );

      // raymarch
      vec3 rayOrigin = cameraPos;
      vec3 rayDirection = camera(rayOrigin, lookAt) * normalize(vec3(uv, fov));

    vec4 color = vec4(vec3(0.), 0.);
    
    vec4 res = rayMarchFog(rayOrigin, rayDirection);
    color += res;
    //return;
    
    vec3 bg = mix(
        vec3(.2, .1, .8),
        vec3(.7, .7, 1.),
        1. - (uv.y + 1.) * .8
    );
    
    color.rgb += bg;
    
    glFragColor = color;
}
