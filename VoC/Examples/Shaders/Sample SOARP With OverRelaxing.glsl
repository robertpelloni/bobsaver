#version 420

// original https://www.shadertoy.com/view/Wlf3Rs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Based on the previous generation https://www.shadertoy.com/view/3tXGRX
// Thanks as always to iq, Jamie Wong, BigWIngs (Art of Code) for the tutorials
// Special thanks to ollj and shau for their suggestions on the previous iteration
// -----------------------------------------------------------------------------
// Limited the number of reflection bounces to 20 for safety.
// Update: Fixed bug in shadow march (thanks ollj!)
// ^^ lol, shadows are still wrong. I'll figure out out soon.

#define NUM_LIGHTS 1
#define AMBIENT_LIGHT 1.61
#define NUM_SPHERES    6

// adapted sdf functions by iq
float sdfSphere(vec3 p, vec3 t, float r)
{
    return length(p-t)-r;   
}
float sdfBox( vec3 p, vec3 t, vec3 b )
{
  vec3 d = abs(p - t) - b;
  return length(max(d,0.0))
         + min(max(d.x,max(d.y,d.z)),0.0); // remove this line for an only partially signed sdf 
}
float sdfPlane( vec3 p, vec3 t, vec4 n )
{
  // n must be normalized
  return dot(p-t,n.xyz) + n.w;
}
float sdfTorus( vec3 p, vec3 tr, vec2 t )
{
    p = p-tr;
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}
float opUnion( float d1, float d2 ) {  return min(d1,d2); }

float opSub( float d1, float d2 ) { return max(-d1,d2); }

float opInter( float d1, float d2 ) { return max(d1,d2); }
////////

// objects map

//From Shane (via shau) to avoid conditionals
vec2 nearest(vec2 a, vec2 b) 
{    
    float s = step(a.x, b.x);
    return s * a + (1. - s) * b;    
}

float distanceToClosest(vec3 p, inout int pick)
{
    //floor
    vec2 d = vec2(sdfPlane(p,vec3(0.0,-2.0,0.0),normalize(vec4(0.0,1.0,0.0,1.0))), 1.);
    
    //cross
    d = nearest(d, vec2(opUnion( sdfBox(p, vec3(0.0), vec3(4.0,6.0,1.0)), sdfBox(p, vec3(0.0), vec3(1.0,6.0,4.0))), 2.)); 

    float offset = 0.0; 
    float offsetinc = 6.28318 / float(NUM_SPHERES);
    for (int s = 0; s < NUM_SPHERES; s ++) {
        d = nearest(d, vec2(sdfSphere(p,vec3(6.5 * cos(time+offset),0.75*cos(time*offset),6.5 * sin(time+offset)),1.0), float(s) + 3.));
        d = nearest(d, vec2(sdfSphere(p,vec3(8.5 * cos(-time+offset),0.95*cos(-time*offset * 0.33),8.5 * sin(-time+offset)),1.2), float(s) + 3.));
        offset += offsetinc;
    }

    pick = int(d.y);
    return d.x;
}

vec3 estimateNormal(vec3 p, inout int pick)
{
    const float EPSILON = 0.00085;
 return normalize(vec3(
        distanceToClosest(vec3(p.x + EPSILON, p.y, p.z),pick) - distanceToClosest(vec3(p.x - EPSILON, p.y, p.z),pick),
        distanceToClosest(vec3(p.x, p.y + EPSILON, p.z),pick) - distanceToClosest(vec3(p.x, p.y - EPSILON, p.z),pick),
        distanceToClosest(vec3(p.x, p.y, p.z  + EPSILON),pick) - distanceToClosest(vec3(p.x, p.y, p.z - EPSILON),pick)
    ));   
}

vec3 getLightPosition(int l)
{
    vec3 lps[6] = vec3[](vec3(-8.0 * cos(time * 0.25),3.5,-8.0 * sin(time * 0.25)),
                vec3(-5.80 * sin(time*0.5),-5.5*cos(time*0.5)+4.95 ,5.5* cos(time * 0.5)),
                vec3(5.80 * sin(time*0.5),-5.5*cos(time*0.5)+4.95 ,-5.5* cos(time * 1.3)),
                vec3(-5.80 * sin(time*0.5),-5.5*cos(time*0.5)+4.95 ,-5.5* cos(time * 2.7)),
                vec3(-5.80 * sin(time*0.5),-5.5*cos(time*0.5)+4.95 ,-5.5* cos(time * 4.5)),
                vec3(-5.80 * sin(time*0.5),-5.5*cos(time*0.5)+4.95 ,-5.5* cos(time * 0.5)));
    if (l > 5)
    {
        return lps[0];
    }

    return lps[l];
}
// soft shadows from iq's tutorial
float shadowMarch( vec3 lightOrigin, vec3 surfacePoint )
{
    vec3 direction = normalize((lightOrigin)-surfacePoint);
    float blendFactor = 128.18;
    int pickTarget = 0;
      float res = 1.0;
    float ph = 1e20;
    float end = distance(surfacePoint,lightOrigin);
    for( float s=0.0001; s < end; )
    {
        vec3 marchStep = lightOrigin + direction * s;
        float distNow = distanceToClosest(marchStep, pickTarget);
        if( distNow<0.00085)
            return 0.0;
        float y = distNow*distNow/(2.0*ph);
        float d = sqrt(distNow*distNow-y*y);
        res = min( res, blendFactor*d/max(0.0,s-y) );
        ph = distNow;
        s += distNow;
    }
    return res; 
}
vec3 lightSurfacePoint(vec3 eye, vec3 surfacePoint, vec3 surfaceNormal, float ambientLight, int materialPick)
{
    vec3 surfaceColour = vec3(0.0);
    float shadow = 1.0;
    vec3 colours[9] = vec3[](vec3(0.2,0.4,0.6), vec3(0.0,0.6,0.13), vec3(0.5,0.5,0.55), vec3(0.8,0.7,0.2), vec3(0.18,0.64,0.38), vec3(0.75,0.51,0.1), vec3(0.95,0.41,0.51), vec3(0.3,0.4,0.8), vec3(0.2,0.6,0.6));
    vec3 speculars[9] = vec3[](vec3(0.9,0.9,0.9),vec3(0.9,0.9,0.9),vec3(0.9,0.9,0.9), vec3(0.9,0.9,0.9), vec3(0.9,0.9,0.9), vec3(0.9,0.9,0.9), vec3(0.9,0.9,0.9), vec3(0.9,0.9,0.9), vec3(0.9,0.9,0.9));
    float shine[9] = float[](10.0,10.0,10.0,10.0,10.0,10.0,10.0,10.0,10.0);

vec3 intensities[9] = vec3[](vec3(0.9,0.9,0.9),vec3(0.9,0.9,0.9),vec3(0.8,0.8,0.8), vec3(0.4,0.4,0.4), vec3(0.1,0.4,0.8), vec3(0.25,0.51,0.1), vec3(0.35,0.81,0.01), vec3(0.1,0.3,0.4), vec3(0.9,0.9,0.9));

    
    for (int l = 0; l < NUM_LIGHTS; l ++)
    {
        vec3 lightPos = getLightPosition(l);
        vec3 N = surfaceNormal;
        vec3 L = normalize(lightPos - surfacePoint);
        vec3 V = normalize(eye - surfacePoint);
        vec3 R = normalize(reflect(-L, N));
        
        float dotLN = dot(L, N);
        float dotRV = dot(R, V);
        vec3 colour = colours[materialPick] * 0.01;
        if (dotLN < 0.0) 
        {
            // Light not visible from this point on the surface
            colour =  colours[materialPick] * 0.01;
        } 
        else if (dotRV < 0.0) 
        {
        // Light reflection in opposite direction as viewer, apply only diffuse
        // component
            colour = intensities[l] * (colours[materialPick] * dotLN);
            shadow = min(shadow, shadowMarch(lightPos, -surfacePoint));
        }
        else
        {
            colour = intensities[l] * (colours[materialPick] * dotLN + speculars[materialPick] * pow(dotRV, shine[materialPick]));
            shadow = min(shadow, shadowMarch(lightPos, -surfacePoint));
        }

        surfaceColour += colour;//phongLight((colours[materialPick]* shadow *ambientLight), lightSpec[l], 10.7, getLightPosition(l), lightIntensity[l], surfacePoint, normal, eye);
    }
    return surfaceColour * ambientLight * shadow;
}

void main(void)
{
    // pixel coordinates (from -1 to 1)
    vec2 uv = (gl_FragCoord.xy/resolution.xy)* 2.0 - 1.0;
    uv.x *= resolution.x/resolution.y;

    // camera setup and ray cast
    float zoom = 1.0;
    vec3 lookAt = vec3(0.0,0.5,0.0);
    vec3 camOrigin = vec3(10.0 * cos(time * 0.1),6.5 * cos(time * 0.5)+4.2,-10.0 * sin(time * 0.1));
    vec3 forwardVec = normalize(lookAt - camOrigin);
    vec3 rightVec = normalize(cross(vec3(0.0,1.0,0.0),forwardVec));
    vec3 upVec = cross(forwardVec,rightVec);
    
    vec3 centerVec = camOrigin + forwardVec * zoom;
    vec3 intersectVec = centerVec + uv.x * rightVec + uv.y * upVec;
    vec3 rayDirection = normalize(intersectVec - camOrigin);
    
    // config and work variables
    vec3 surfacePoint = vec3(0.0);
    vec3 col = vec3(0.1,0.3,0.44);

    float marchDistance = 0.0f;
    vec3 marchVec = camOrigin;
    int pickTarget = 0;
    vec3 surfaceNormal = vec3(0.0);
    
    const float MAX_DISTANCE = 128.0;
    const float CLOSE_ENOUGH = 0.00085;
    
    vec3 marchStep = vec3(0.0);
       float distNow = 0.0;
    float overEstimate = 10.2;
    float errorAmount = 99999.;
    float previousDistance = 0.0;
    vec3 colAccum = vec3(0.0);
    float bounceCount = 0.0;
    float refMixVal = 0.35; // don't start with a solid mix
//initialize with sky colour
    pickTarget = 0;
    colAccum =  vec3(0.2,0.4,0.6) - rayDirection.y * 0.5;
    float reflectivity[9] = float[](0.4,0.3,0.85,0.65,0.65,0.65,0.75,0.75,0.5);
    float stepLength = 0.0;
    float pixelRadius = 0.00000001;
    
    for (marchDistance = 0.0; marchDistance < MAX_DISTANCE;)
    {
        marchStep = marchVec + rayDirection * marchDistance;
        distNow = distanceToClosest(marchStep, pickTarget);
        bool failCondition = overEstimate > 1.0 && (abs(distNow)+previousDistance) < stepLength;
        if (failCondition)
        {
            stepLength -= overEstimate * stepLength;
            overEstimate = 1.0;
        }
        else
        {
            stepLength = distNow * overEstimate;
            overEstimate += 1.0;
        }
        previousDistance = distNow;

        float errorNow = distNow / marchDistance;
        if (!failCondition && errorNow < errorAmount)
        {
            errorAmount = errorNow;
        }

        marchDistance += distNow;

        if (marchDistance >= MAX_DISTANCE || bounceCount >= 20.0 || errorAmount < pixelRadius)
        {
          // sky colour
                int lastPick = pickTarget;
                pickTarget = 0;
                colAccum = mix(colAccum,vec3(0.2,0.4,0.6) - rayDirection.y * 0.5,
                            clamp(reflectivity[lastPick]+bounceCount*0.1,0.0,1.0));

                break;   
        }
        
        if (distNow <= CLOSE_ENOUGH)
           {
            // hit something!
               surfaceNormal = estimateNormal(marchStep, pickTarget);
            // calculate colour accumulation
            colAccum = mix(colAccum,lightSurfacePoint(marchVec , marchStep, surfaceNormal, AMBIENT_LIGHT, pickTarget),
                    clamp(reflectivity[pickTarget] + refMixVal + bounceCount * 0.1,0.0,1.0));
              rayDirection = normalize(reflect((rayDirection ), surfaceNormal));
            bounceCount += 1.0;
            marchDistance = 0.01;
            // move camera origin to reflection location
            marchVec = marchStep; // + rayDirection * marchDistance;
        }
                
    }
    col = colAccum;
    glFragColor = vec4(col,1.0);
}
