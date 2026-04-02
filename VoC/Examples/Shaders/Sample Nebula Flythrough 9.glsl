#version 420

// original https://www.shadertoy.com/view/tdtcRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//------------------------------------------------------------------------
// hlsl_compatibility.h
//------------------------------------------------------------------------
float saturate(float source)
{
    return clamp(source, 0.0,1.0);
}

vec4 saturatev4(vec4 source)
{
    return clamp(source, vec4(0.0,0.0,0.0,0.0),vec4(1.0,1.0,1.0,1.0));
}

vec2 nrmCenteredUv(vec2 fragPos)
{
    return vec2(2.0 * (fragPos.x-0.5), 2.0 * (fragPos.y-0.5));
}

//This emulates the shader setup that gives per-vertex eyeDir for screenspace effects
vec3 fovEyeDir( float fov, vec2 size, vec2 pos )
{
    vec2 xy = pos - size * 0.5;
    float cot_half_fov = tan( radians( 90.0 - fov * 0.5 ) );
    float z = size.y * 0.5 * cot_half_fov;
    return normalize( vec3( xy, z ) );
}

//------------------------------------------------------------------------
// deltas.h
//------------------------------------------------------------------------
vec3 setupBackToFrontIterator(vec3 rayStart, vec3 rayEnd, float steps, out vec3 outRayStart, out vec3 outRayEnd)
{    
    vec3 delta = (rayStart - rayEnd) / steps;
    vec3 temp = rayStart;
    outRayStart = rayEnd;
    outRayEnd = temp;
    return delta;
}

vec3 flatDelta(vec3 rayStart, vec3 delta, float i, float totalI)
{
    //vec3 extrapolatedRayStart = rayStart + i * delta;
    //vec3 rayMid = extrapolatedRayStart + (delta / 2.0);
    //return rayMid;
    return rayStart + (i * delta);
}

vec3 logDelta(vec3 rayStart, vec3 baseDelta, float i, float num_view_ray_steps)
{
    float tAmt = log(saturate(i / num_view_ray_steps));        // 0 .. 1  back .. front
    float tAmt2 = log(saturate((i + 1.0) / num_view_ray_steps));        // 0 .. 1  back .. front
    float interval = tAmt2 - tAmt;
    vec3 delta = baseDelta * interval;
    vec3 rayMid = rayStart + delta / 2.0;
    return rayMid;
}

//This gives more detail up close than at the back
vec3 backToFrontOneMinusPowDelta(vec3 rayStart, vec3 rayEnd, float i, float num_view_ray_steps)
{
    float tValue = (i / num_view_ray_steps);    //0 .. 1 back .. front
    float logTValue = 1.f - pow( (1.f - tValue), 2.f );    //tValue changes quickly at first, then gradually        
    vec3 rayMid = mix(rayStart, rayEnd, logTValue);    
    return rayMid;
}

// 1/3 of samples go from the back to bandAPct of the total region
// 1/3 of samples go from bandAPct to bandBPct
// 1/3 of samples go from bandBPct to the front.
vec3 backToFrontAdaptiveDelta2(vec3 rayStart, vec3 baseDelta, float i, float bandAPct, float bandBPct, float bandT)
{
    float bandA = bandT * bandAPct;
    float bandB = bandT * bandBPct;
    
    vec3 bandADelta = baseDelta * 1.5;
    vec3 bandBDelta = baseDelta * 1.0;
    vec3 bandCDelta = baseDelta * 0.5;

    if (i < bandA)
    {        
        vec3 extrapolatedRayStart = rayStart + i * bandADelta;
        vec3 rayMid = extrapolatedRayStart + (bandADelta / 2.0);
        return rayMid;
    }
    else if (i < bandB)
    {
        vec3 extrapolatedRayStart = rayStart + (bandA * bandADelta) + (i - bandA) * bandBDelta;
        vec3 rayMid = extrapolatedRayStart + (bandBDelta / 2.0);
        return rayMid;
    }
    else
    {
        vec3 extrapolatedRayStart = rayStart + (bandA * bandADelta) + ( (bandB-bandA) * bandBDelta) + (i - bandB) * bandCDelta;
        vec3 rayMid = extrapolatedRayStart + (bandCDelta / 2.0);
        return rayMid;
    }
}
//------------------------------------------------------------------------
// random.h
//------------------------------------------------------------------------
float rand(vec3 n){
  return fract(sin(dot(n ,vec3(12.9898,78.233,54.3819))) * 43758.5453);
}

//------------------------------------------------------------------------
//DAVE HOSKINS' HASH FUNCTIONS
// we use them mainly because they don't contain any sin/cos and so should be more consistent accross hardware
//------------------------------------------------------------------------
float rnd11(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    return fract(2.*p*p);
}

vec3 rnd23(vec2 p)
{
    vec3 p3 = fract(p.xyx * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

float rnd31(vec3 p3)
{
    p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
//------------------------------------------------------------------------

//------------------------------------------------------------------------
// noise.h
//------------------------------------------------------------------------
float hash(float n) { return fract(sin(n)*753.5453123); }

vec4 noise(vec3 x)
{
    vec3 p = floor(x);
    vec3 w = fract(x);
    vec3 u = w*w*(3.0 - 2.0*w);
    vec3 du = 6.0*w*(1.0 - w);

    float n = p.x + p.y*157.0 + 113.0*p.z;

    float a = hash(n + 0.0);
    float b = hash(n + 1.0);
    float c = hash(n + 157.0);
    float d = hash(n + 158.0);
    float e = hash(n + 113.0);
    float f = hash(n + 114.0);
    float g = hash(n + 270.0);
    float h = hash(n + 271.0);

    float k0 = a;
    float k1 = b - a;
    float k2 = c - a;
    float k3 = e - a;
    float k4 = a - b - c + d;
    float k5 = a - c - e + g;
    float k6 = a - b - e + f;
    float k7 = -a + b + c - d + e - f - g + h;

    return vec4(k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z,
        du * (vec3(k1, k2, k3) + u.yzx*vec3(k4, k5, k6) + u.zxy*vec3(k6, k4, k5) + k7*u.yzx*u.zxy));
}

vec4 fbmdcol(vec3 x)
{
    const float scale = 1.5;

    float a = 0.0;
    float b = 0.5;
    float f = 1.0;
    vec3  d = vec3(0, 0, 0);

    for (int i = 0; i<8; i++)
    {
        vec4 n = noise(f*x*scale);
        a += b*n.x;           // accumulate values        
        d += b*n.yzw*f*scale; // accumulate derivatives
        b *= 0.5;             // amplitude decrease
        f *= 1.8;             // frequency increase
    }

    return vec4(a, a, a, d);
}

vec4 fbmd(vec3 x)
{
    const float scale = 1.5;

    float a = 0.0;
    float b = 0.5;
    float f = 1.0;
    vec3  d = vec3(0, 0, 0);

    for (int i = 0; i<8; i++)
    {
        vec4 n = noise(f*x*scale);
        a += b*n.x;           // accumulate values        
        d += b*n.yzw*f*scale; // accumulate derivatives
        b *= 0.5;             // amplitude decrease
        f *= 1.8;             // frequency increase
    }

    return vec4(a, a, a, d);
}

vec3 repeatingLightSource(vec3 samplePoint, float spacing)
{   
       float halfSpacing = spacing / 2.0;
    vec3 lightPos = (floor( (samplePoint + halfSpacing) / spacing) * spacing);
    
    float rnd = rand(lightPos);
    vec3 offset = halfSpacing * vec3(rnd,-rnd,-rnd);
    
    /*float rndX = 2.0 * (0.5 * rnd11(lightPos.x));
    float rndY = 2.0 * (0.5 * rnd11(lightPos.y));
    float rndZ = 2.0 * (0.5 * rnd11(lightPos.z));
    vec3 offset = halfSpacing * vec3(rndX,rndY,rndZ);*/
    
    return lightPos + offset * 2.0;
}

vec3 singleLightSource(vec3 samplePoint, float spacing)
{   
    return vec3(360,-530, 2000);
}

float baseNoise(vec3 samplePoint, float noiseFreqFactor)
{
    return fbmdcol(samplePoint * noiseFreqFactor).r;
}

float calculateDensity(float noiseVal)
{
    return smoothstep(0.0,1.0, noiseVal);
}

float distToNearestLight(vec3 lightPos, vec3 samplePoint)
{    
    return length(lightPos - samplePoint);
}

float nrmDistToNearestLight(vec3 lightPos, vec3 samplePoint, float lightSize)
{
    return saturate(distToNearestLight(lightPos, samplePoint) / lightSize);
}

vec3 drawStar(vec3 starPos, vec3 samplePoint, float interval, float starSize)
{    
    float lightAttenuationCurve = 1.0;
    float gain = 10.0;
    float lighting = 0.0;
    float nrmDist = length(starPos - samplePoint) / 0.25;
    lighting += smoothstep(starSize, 0.0, nrmDist);
    return vec3(lighting,lighting,lighting) *  interval * gain;
}

vec3 inScatter(float density, vec3 lightPos, vec3 samplePoint, float interval, float lightSize)
{    
    float lightAttenuationCurve = 2.0;
    float minLightValue = 0.3;
    float lightGain = 5.0;
        
    float lighting = 1.0 - nrmDistToNearestLight(lightPos, samplePoint, lightSize);
                                                
    lighting = max(minLightValue, lightGain * pow(saturate(lighting), lightAttenuationCurve));
    
    //view lighting directly
    //return vec3(lighting,lighting,lighting) *  interval;
    
    vec3 peaks = vec3(0.4,0.5,0.2);
    
    //this defines how much overlap / colour blended regions
    vec3 under = peaks - 0.2;
    vec3 over = peaks + 0.20;
    
    //prevelant
    float col1Factor = smoothstep(under.r,peaks.r, density) * smoothstep(over.r,peaks.r, density);
    
    //prevelant
    float col2Factor = smoothstep(under.g,peaks.g, density) * smoothstep(over.g,peaks.g,density);    
    
    //rare
    float col3Factor = smoothstep(under.b,peaks.b, density) * smoothstep(over.b,peaks.b,density);
    
    //Orange, deep blues, bright pinks
    //vec3 col1 = vec3(1.5, 0.5, 0.1);    vec3 col2 = vec3(0.2, 0.2, 1.0);    vec3 col3 = vec3(5.0, 3.0, 0.0);

    //Blues yellows and whites    
    //vec3 col1 = vec3(0.2, 1.4, 2.0);    vec3 col2 = vec3(0.25, 0.5, 0.1);    vec3 col3 = vec3(5.0, 3.0, 0.0);

    //Deep blue dust cloud with bright spots
    //vec3 col1 = vec3(2.2, 1.0, 0.2);    vec3 col2 = vec3(0.3, 0.55, 1.5);    vec3 col3 = vec3(-1.5, -1.5, -1.0);
    
    //Orange blue dust with bright spots
    vec3 col1 = vec3(2.2, 1.0, 0.2);    vec3 col2 = vec3(0.3, 0.55, 1.5);    vec3 col3 = vec3(-0.5, -0.5, -0.5);
    
    //Blue orange
    //vec3 col1 = vec3(0.15, 0.0, 1.5);    vec3 col2 = vec3(0.5, 0.3, 0.0);    vec3 col3 = vec3(3.0, 2.0, 0.0);
    
    return lighting * (col1 * col1Factor + col2 * col2Factor + col3 * col3Factor) * interval;
}

vec3 extinguishDueToDust(vec4 col, float density, float interval)
{
    return col.rgb * saturate((1.0 - pow(saturate(density),16.0) * interval * 0.5));
}

vec3 extinguishDueToTransmittance(vec4 col, float noiseVal, float interval, vec3 rgbPowers)
{
    float amt = saturate(noiseVal * 4.0);
    float rExt = 1.0 - interval * pow(amt, rgbPowers.r);
    float gExt = 1.0 - interval * pow(amt, rgbPowers.g);
    float bExt = 1.0 - interval * pow(amt, rgbPowers.b);
    return col.rgb * vec3(rExt, gExt, bExt);
}

vec3 warpSamplePoint(vec3 samplePoint, float noiseFreqFactor, float domainWarp)
{
    float noise = baseNoise(samplePoint, noiseFreqFactor);
    float lowFreqNoise = baseNoise(samplePoint, noiseFreqFactor * 2.25);    //higher = more distorted + more aliased
    domainWarp *= (1.0 - lowFreqNoise);
    return samplePoint + noise * domainWarp;    
}

//a1,a2 results of intersection test (enter,leave distances)
vec4 integrate(vec3 eyePos, vec3 eyeDir, float a1, float a2, float domainWarp, float noiseFreqFactor, vec4 baseColour, vec3 rgbTransmittancePowers)
{
    float num_view_ray_steps = 125.0;
    
    float lightSpacing = 4500.0;
    float lightSize = 2000.0;
    float starSize = 500.0;    
    float totalDist = a2 - a1;
    vec3 rayStart = eyePos + eyeDir * a1;
    vec3 rayEnd = eyePos + eyeDir * a2;
    vec3 samplePoint;    
    vec3 oldSamplePoint;
    vec3 baseDelta = setupBackToFrontIterator(rayStart, rayEnd, num_view_ray_steps, rayStart, rayEnd);
    oldSamplePoint = rayStart;
    
    vec4 colourAccumulator = baseColour;
    
    float i = 0.0;
    while (i < num_view_ray_steps)
    {
        float fadeout = smoothstep(num_view_ray_steps, num_view_ray_steps*0.875, i);         
        samplePoint = flatDelta(rayStart, baseDelta, i, num_view_ray_steps);
        //samplePoint = backToFrontOneMinusPowDelta(rayStart, rayEnd, i, num_view_ray_steps);        
        //samplePoint = backToFrontAdaptiveDelta2(rayStart, baseDelta, i, 0.33, 0.33, num_view_ray_steps);
        vec3 delta = samplePoint - oldSamplePoint;
        float interval = length(delta) / totalDist;
        oldSamplePoint = samplePoint;
        
        vec3 noiseSamplePoint = warpSamplePoint(samplePoint, noiseFreqFactor, domainWarp);
        //vec3 starPos = singleLightSource(samplePoint, lightSpacing);
        vec3 starPos = repeatingLightSource(samplePoint, lightSpacing);
        float noiseVal = baseNoise(noiseSamplePoint, noiseFreqFactor);
        float density = calculateDensity(noiseVal) * 3.0;
        
        colourAccumulator.rgb += drawStar(starPos, samplePoint, interval, starSize) * fadeout * 2.0;
        colourAccumulator.rgb += inScatter(noiseVal, starPos, samplePoint, interval, lightSize) * fadeout * 1.5;
        colourAccumulator.rgb = extinguishDueToDust(colourAccumulator, density, interval);
        colourAccumulator.rgb = extinguishDueToTransmittance(colourAccumulator, noiseVal, interval, rgbTransmittancePowers);
        
        float len = length(starPos - samplePoint);
        
        i+=1.0;
        
        
        
        //when further away from light sources, increase the step size
        const float threshold = 2250.0;
        
        if ( len > threshold)
        {
            float t = (len-threshold) / threshold;
            t = max(0.0, min(1.75, t));                //0 .. 1.75
            i += t;
        }
    }
    
    return colourAccumulator;    
}

vec4 tonemap(vec4 col)
{
    return col;
}

void main(void)
{    
    // These are the shader constants passed in from the game
    vec4 nebulaSettingsProvider = vec4(1.0, 0.002, 1.0, 0.40);
    vec4 nebulaTextureSettingsProvider = vec4(5.0,3.0,4.0,0.25);  
    
    float noiseFreqFactor = 0.0005 * nebulaSettingsProvider.r;
    float domainWarp = 3000.0 * nebulaSettingsProvider.b;
    vec3 rgbTransmittancePowers = vec3(nebulaTextureSettingsProvider.rgb);
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    // Emulated screen-space eye Vectors        
    vec3 eyeDir = fovEyeDir( 90.0, resolution.xy, gl_FragCoord.xy );
    
    // Work out camera position, eye rays, fov etc
    float speed = 1320.0;
    float startTime = 23.0;
    vec3 eyePos = vec3(500.0,-400.0, -700.0 + (time + startTime) * speed);
    //vec3 eyePos = vec3(0.0,0.0,0.0);
    
    // Distance we will march through the volume.  a1 = start of ray, a2 = end of ray.
    float a1 = 0.0;
    float a2 = 7500.0;
                
    vec4 baseColour = vec4(0.0,0.0,0.0,0.0);
    vec4 col = integrate(eyePos, eyeDir, a1, a2, domainWarp, noiseFreqFactor, baseColour, rgbTransmittancePowers);

    // Output to screen   
    glFragColor = tonemap(col);
}
