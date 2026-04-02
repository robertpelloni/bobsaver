#version 420

// original https://www.shadertoy.com/view/3syBDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// noise
// Volume raycasting by XT95
// https://www.shadertoy.com/view/lss3zr
mat3 m = mat3( 0.00,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64 );
float hash( float n )
{
    return fract(sin(n)*43758.5453);
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.0-2.0*f);

    float n = p.x + p.y*57.0 + 113.0*p.z;

    float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                        mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
                    mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                        mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
    return res;
}

float fbm( vec3 p )
{
    float f;
    f  = 0.5000*noise( p ); p = m*p*2.02;
    f += 0.2500*noise( p ); p = m*p*2.03;
    f += 0.12500*noise( p ); p = m*p*2.01;
    f += 0.06250*noise( p );
    return f;
}

float numericalMieFit(float costh)
{
    //return 3.0 / (16.0 * 3.14159265359) * (1.0 + costh * costh) + 0.255;
    // This function was optimized to minimize (delta*delta)/reference in order to capture
    // the low intensity behavior.
    float bestParams[10];
    bestParams[0]=9.805233e-06;
    bestParams[1]=-6.500000e+01;
    bestParams[2]=-5.500000e+01;
    bestParams[3]=8.194068e-01;
    bestParams[4]=1.388198e-01;
    bestParams[5]=-8.370334e+01;
    bestParams[6]=7.810083e+00;
    bestParams[7]=2.054747e-03;
    bestParams[8]=2.600563e-02;
    bestParams[9]=-4.552125e-12;
    
    float p1 = costh + bestParams[3];
    vec4 expValues = exp(vec4(bestParams[1] *costh+bestParams[2], bestParams[5] *p1*p1, bestParams[6] *costh, bestParams[9] *costh));
    vec4 expValWeight= vec4(bestParams[0], bestParams[4], bestParams[7], bestParams[8]);
    return dot(expValues, expValWeight) * 0.25;
}
float numericalMieFitMultiScatter() {
    // This is the acossiated multi scatter term used to simulate multi scatter effect.
    return 0.1026;
}

float Roberts1(int n) {
    const float g = 1.6180339887498948482;
    const float a = 1.0 / g;
    return  fract(0.5 + a * float(n));
}

vec2 Roberts2(int n) {
    const float g = 1.32471795724474602596;
    const vec2 a = vec2(1.0 / g, 1.0 / (g * g));
    return fract(0.5 + a * vec2(n));
}

vec3 UniformSampleSphere(const vec2 e) {
    float Phi = 2. * 3.14159265359 * e.x;
    float CosTheta = 1. - 2. * e.y;
    float SinTheta = sqrt(1. - CosTheta * CosTheta);

    vec3 H;
    H.x = SinTheta * cos(Phi);
    H.y = SinTheta * sin(Phi);
    H.z = CosTheta;

    return H;
}

/////////////////////////////////////

float stepUp(float t, float len, float smo)
{
  float tt = mod(t += smo, len);
  float stp = floor(t / len) - 1.0;
  return smoothstep(0.0, smo, tt) + stp;
}

// iq's smin
float smin( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float map( in vec3 p )
{
    vec3 q = p - vec3(0.0,0.5,1.0)*time;
    float f = fbm(q);
    float s1 = 1.0 - length(p * vec3(0.5, 1.0, 0.5)) + f * 2.2;
    float s2 = 1.0 - length(p * vec3(0.1, 1.0, 0.2)) + f * 2.5;
    float torus = 1. - sdTorus(p * 2.0, vec2(6.0, 0.005)) + f * 3.5;
    float s3 = 1.0 - smin(smin(
                           length(p * 1.0 - vec3(cos(time * 3.0) * 6.0, sin(time * 2.0) * 5.0, 0.0)),
                           length(p * 2.0 - vec3(0.0, sin(time) * 4.0, cos(time * 2.0) * 3.0)), 4.0),
                           length(p * 3.0 - vec3(cos(time * 2.0) * 3.0, 0.0, sin(time * 3.3) * 7.0)), 4.0) + f * 2.5;
    
    float t = mod(stepUp(time, 4.0, 1.0), 4.0);
    
    float d = mix(s1, s2, clamp(t, 0.0, 1.0));
    d = mix(d, torus, clamp(t - 1.0, 0.0, 1.0));
    d = mix(d, s3, clamp(t - 2.0, 0.0, 1.0));
    d = mix(d, s1, clamp(t - 3.0, 0.0, 1.0));
    
    return max(0.0, clamp((d - 0.01) * 2., 0., 1.) * 16.);
}

float jitter;

#define MAX_STEPS 128
#define SHADOW_STEPS 64
#define VOLUME_LENGTH 30.
#define SHADOW_LENGTH 4.

vec4 cloudMarch(vec3 p, vec3 ray)
{
    float density = 0.;

    float stepLength = VOLUME_LENGTH / float(MAX_STEPS);
    vec3 light = normalize(vec3(1.0, 1.0, 1.0));
    vec3 bilight = normalize(cross(light, vec3(0.,1.,0.)));
    vec3 talight = cross(bilight, light);
    float phase = numericalMieFit(dot(ray, light));
    float multiScatterPhase = phase +  numericalMieFitMultiScatter();

    vec4 sum = vec4(0., 0., 0., 1.);
    float st = 1.;
    
    vec3 pos = p + ray * jitter * stepLength;
    
    for (int i = 0; i < MAX_STEPS; i++)
    {
        if (sum.a < 0.01) {
            break;
        }
        float d = map(pos);
    
        if( d > 0.001)
        {
            float shadow = 0.;        
            int shadowStep = int(mix(float(SHADOW_STEPS / 4), float(SHADOW_STEPS), sum.a));
            float shadowStepLength = SHADOW_LENGTH / float(shadowStep);
            vec3 lpos = pos + light * jitter * shadowStepLength;
            for (int s = 0; s < shadowStep; s++)
            {
                lpos += light * shadowStepLength;
                float len = float(s) * shadowStepLength * 1.;
                vec2 rnd = fract(Roberts2(s) + jitter);
                vec3 offset = (sin(rnd.x) * bilight + cos(rnd.x) * talight) * rnd.y;
                float lsample = map(lpos + len * offset);
                shadow += lsample;
            }
    
            density = d * stepLength;
            density = 1. - exp(-density);
            shadow = exp(-shadow * shadowStepLength * 0.1);
            float msPhase = mix(phase, multiScatterPhase, clamp(max(shadow / 3., 1. - st * 2.), 0., 1.));
            vec3 s = shadow * msPhase * vec3(1.1, .9, .9) * 10.;
            sum.rgb += vec3(s * density) * sum.a;

            vec3 ambOffset = fract(Roberts1(i) + jitter) * UniformSampleSphere(fract(Roberts2(i) + jitter)) * 2.;
            
            sum.rgb += 0.4 * density * sum.a * mix(vec3(.4, .7, 1.3), vec3(.7, .7, 1.), clamp((pos.y + 2.) / 3., 0., 1.));
            sum.a *= 1. - density;
            st *= exp(-d * 4. * stepLength);
        }
        else st = 1.;
        
        
        pos += ray * stepLength;
    }
    
    sum.rgb *= 2.;
    return sum;
}

mat3 camera(vec3 ro, vec3 ta, float cr )
{
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

vec3 aces_tonemap(vec3 color){  
    mat3 m1 = mat3(
        0.59719, 0.07600, 0.02840,
        0.35458, 0.90834, 0.13383,
        0.04823, 0.01566, 0.83777
    );
    mat3 m2 = mat3(
        1.60475, -0.10208, -0.00327,
        -0.53108,  1.10813, -0.07276,
        -0.07367, -0.00605,  1.07602
    );
    vec3 v = m1 * color;    
    vec3 a = v * (v + 0.0245786) - 0.000090537;
    vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
    return pow(clamp(m2 * (a / b), 0.0, 1.0), vec3(1.0 / 2.2)); 
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    jitter = hash(p.x + p.y * 57.0 + time);
    float rot = time * .333 + ((mouse.x*resolution.xy.x / resolution.x) - 0.5) * 16.;
    vec3 ro = vec3(cos(rot) * 10.0, ((mouse.y*resolution.xy.y / resolution.y) - 0.5) * -25., sin(rot) * 10.0);
    vec3 ta = vec3(0.0, 1., 0.0);
    mat3 c = camera(ro, ta, 0.0);
    vec3 ray = c * normalize(vec3(p, 1.75));
    vec4 col = cloudMarch(ro, ray);
    float sundot = clamp(dot(ray,normalize(vec3(1.0, 1.0, 1.0))),0.0,1.0);
    vec3 result = col.rgb + (mix(vec3(0.3, 0.6, 1.0), vec3(0.05, 0.35, 1.0), p.y + 0.75) + 0.8*vec3(1.0,0.7,0.3)*pow(sundot, 4.0)) * col.a;
        
    result = aces_tonemap(result);
    
    glFragColor = vec4(result, 1.0);
}
