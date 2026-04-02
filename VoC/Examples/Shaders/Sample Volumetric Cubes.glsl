#version 420

// original https://www.shadertoy.com/view/WlySzy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* 
  raymarching volumes by integration of light sources 
  wrt transmission through the scene, over total distance marched.
 
  features multiple light sources, volumetric shadows
  there are no hard surfaces in this scene, but I'll add those in 
  my next shader.
  
  What is so interesting about the Volumetric Rendering Equation
  is that it is essentially a generalization of the rendering equation.
  a high density cube should be similar to a hard surface cube with a 
  good subsurface scatter approximation.
  
  references 
  'Volumetric Integration' by SebH - https://www.shadertoy.com/view/XlBSRz
  http://www.frostbite.com/2015/08/physically-based-unified-volumetric-rendering-in-frostbite/
  https://graphics.pixar.com/library/ProductionVolumeRendering/paper.pdf
 */

float sdfSphere(vec3 p, float radius){
    return length(p) - radius;
}

float sdfBoxGrid( vec3 p, vec3 b ) // I removed the positive portion
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0);
}

// I would like to include hard surfaces in the future which requires a 
// lot of changes:
// probably a preliminary trace to get the final hit that does not integrate,
// and then separately integrate over that distance so the integrating
// ray march distance is not perturbed by tracing close to a surface
// which I saw when testing this with a fractal sdf.
// also each light evaluation will check shadows of solids
float map(vec3 p)
{
    float minD = 0.05; // restrict max step for better scattering evaluation
    return minD;
}

vec3 evaluateLight(in vec3 lpos, in vec3 pos)
{
    vec3 lightPos = lpos;
    vec3 L = lightPos-pos;
    vec3 val = 1.0/dot(L,L) * vec3(1.);
    return val;
}

// the map to volumes is actually quite expensive 
// since each march needs to check volumetric shadows
void getParticipatingMedia(out float sigmaS, out float sigmaE, out vec3 mediaColor, in vec3 p, out float dist)
{
    float heightFog = -0.6;
    heightFog = 0.8*clamp((heightFog-p.y)*1.0, 0.0, 1.0);
    
    float cubeDensity = pow(1.5, 2.+ p.x );
    p.xy = mod(p.xy+1.5, vec2(3.))-1.5; // repetition
    dist = -sdfBoxGrid(p, vec3(1.));
    dist += heightFog;
    float boxVol = clamp(dist * cubeDensity, 0., 1.);
    
    const float constantFog = 0.0;
    mediaColor = mix(vec3(1.), vec3(1.,0.,0.), sin(time));
    mediaColor = mix(mediaColor, vec3(0.9,1.1,.8), clamp(heightFog,0.,.1)*10.);
    
    sigmaS = constantFog + heightFog*10. + boxVol;
   
    float sigmaA = 0.;
    /* //to showcase absorption vs scattering, with colored absorption which as I understand is more correct.
    float sigmaAFactor = 0.;
    if(p.y > .0)
        sigmaAFactor = 1.;
    sigmaA = 0.1* sigmaAFactor;
    mediaColor = mix(vec3(1.), mediaColor, clamp(sigmaAFactor,0.,1.));
    */
    
    sigmaE = max(0.000000001, sigmaA + sigmaS); // to avoid division by zero extinction - sebH
}

float phaseFunction()
{
    return 1.0/(4.0*3.14);
}

float volumetricShadow(in vec3 from, in vec3 to)
{
    const float numStep = 16.0; // quality control. Bump to avoid shadow alisaing
    float shadow = 1.0;
    float sigmaS = 0.0;
    float sigmaE = 0.0;
    vec3 ro = from;
    vec3 rd = to - from;
    float dd = length(rd) / numStep;
    for(float s=0.5; s<(numStep-0.1); s+=1.0)// start at 0.5 to sample at center of integral part
    {
        vec3 p = ro + rd*(s/(numStep));
        vec3 mediaColor = vec3(1.);
        float dist = 0.;
        getParticipatingMedia(sigmaS, sigmaE, mediaColor, p, dist);
        shadow *= exp(-sigmaE * dd);
    }
    return shadow;
}

vec3 lightContrib(vec3 p){
    const int NUM_LIGHTS = 3;
    vec3 lightPositions[NUM_LIGHTS];
    lightPositions[0] = vec3(3.5* sin(time), 1.5*cos(time)+ 2.5, 1.);
    lightPositions[1] = lightPositions[0] * vec3(-1., 1.7, 1.);
    lightPositions[2] = vec3(-1.5 * cos(time*.5), 0., sin(time*.5)*3.);
    vec3 lightColors[NUM_LIGHTS];
    lightColors[0] = 100.0*vec3( 1.0, 0.9, .5);
    lightColors[1] = 20.*vec3(0.2, 0.5, 1.);
    lightColors[2] = 20.*vec3(1., 1.1, 1.1);
    vec3 col = vec3(0.);
    // only checking shadow for the first light source for since it is the biggest
    // which is visually pleasing but improper for the integral
    // since evaluating a light source implies checking its shadow (but I'm skipping for the smaller lights)
    // doing all lights will kill performance
    col += lightColors[0]*evaluateLight(lightPositions[0], p)*volumetricShadow(p,lightPositions[0]);
    col += lightColors[1]*evaluateLight(lightPositions[1], p);
    col += lightColors[2]*evaluateLight(lightPositions[2], p);
    
    return col;
}

void trace(vec3 ro, vec3 rd, inout vec3 finalPos, inout vec3 normal, inout vec3 albedo, inout vec4 scatTrans)
{
    const int numIter = 200;
    
    float sigmaS = 0.0;
    float sigmaE = 0.0;
    
    // Initialize volumetric scattering integration (to view)
    float transmittance = 1.0;
    vec3 scatteredLight = vec3(0.0, 0.0, 0.0);
    
    float t = 0.01; // hack: always have a first step of 1 unit to go further
    float material = 0.0;
    vec3 p = vec3(0.0, 0.0, 0.0);
    float dd = 0.0;
    for(int i=0; i<numIter; ++i)
    {
        vec3 p = ro + t*rd;
        vec3 mediaColor = vec3(1.);
        float dist = 0.;
        getParticipatingMedia(sigmaS, sigmaE, mediaColor, p, dist);
        
        // following is SebH's improved integration 
        // I've added an absorption color to the media
        
        // See slide 28 at http://www.frostbite.com/2015/08/physically-based-unified-volumetric-rendering-in-frostbite/
        vec3 S = lightContrib(p) * sigmaS * phaseFunction();// incoming light
        vec3 Sint = (S - S * exp(-sigmaE * dd)) / sigmaE; // integrate along the current step segment
        scatteredLight += transmittance * Sint * mediaColor; // accumulate and also take into account the transmittance from previous steps
        // Evaluate transmittance to view independentely
        transmittance *= exp(-sigmaE * dd);
        
        dd = map(p);

        t += dd;
    }
    
    finalPos = ro + t*rd;
    
    scatTrans = vec4(scatteredLight, transmittance);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
    float move = 0.;
    //if(mouse*resolution.xy.z > 0.)
    //    move = -.521 + sin(mouse*resolution.xy.x/resolution.x);
    // Camera
    vec3 ro = vec3(0., 3.8, -7.); // camera and ray origin
    vec3 look = ro + vec3(move, -.1 , .5);  // lookat coordinates.
    float FOV = 3.14159/3.;
    vec3 forward = normalize(look-ro);
    vec3 right = normalize(vec3(forward.z, 0., -forward.x )); 
    vec3 up = cross(forward, right);

    // rd - Ray direction.
    vec3 rd = normalize(forward + FOV*uv.x*right + FOV*uv.y*up);

    vec3 finalPos = ro;
    vec3 albedo = vec3( 0.0, 0.0, 0.0 );
    vec3 normal = vec3( 0.0, 0.0, 0.0 );
    vec4 scattered = vec4( 0.0, 0.0, 0.0, 0.0 );
    trace(ro, rd, finalPos, normal, albedo, scattered);
       
    // this isn's entirely correct but I wanted a background. 
    // background * transmittance + scattered light
    vec3 color = .25* mix(vec3(0.5,0.3,0.6),vec3(0.8,0.5,0.4),smoothstep(-1.5, .3, rd.y)) * scattered.w + scattered.rgb;
    
    color = pow(color, vec3(1./2.2));
    
    //debug: transmission
    //color = vec3(1.) * scattered.w; 

    
    glFragColor = vec4(color, 1.0);
}

