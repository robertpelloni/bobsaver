#version 420

// original https://www.shadertoy.com/view/4djfW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

single pass tracing of a "bezier-patch"
and its 4*4 control points;

https://www.shadertoy.com/view/MtsXzl
Shows that these are seamless.
...There multiple iterations are just multiple octaves of noise
...to vary amplitude and frequency over time more than here.
... here frequency is constant, duh.

2 cubic bezier splines (4 CVs) over 2 domains
1 quadratic interpolation of 2 domain's cubic beziers.

this is a re-post of 
https://www.shadertoy.com/view/ltsXzl
with global "float a=b" changed to "#define a (b)"
This increases compatibility and compile time.

Textures disabled, they are just distracting.

cubic spline has nice first and second derivative.
first derivative at corner points
tends to be close to 0, but unlike smoothstep() it is not ==0.
that would be possible, but look worse for no good reason.

Using ray marching to render a cubic hermite rectangle. 
Raytrace bounding box, raymarch interior. 
The control points of the rectangle are 1d, 
which makes it easier to render, 
but limits the control points to only moving on the Y axis.
*/

/*
3 modesof computing the bilinear smoothstep()
mode==0 ; original, likely slowest
mode==1 ; likely faster, a few less multiplications
mode==-1; likely fastest, like mode1, but with type vec3()
*/
#define mode 0

#define SHOW_BOUNDINGBOX   0
#define SHOW_CONTROLPOINTS 1

float scale = 0.5;
float offset = 0.5;

#define CP00 ( (sin(time*0.30) * 0.5 + 0.5) * scale + offset)
#define CP01  ((sin(time*0.10) * 0.5 + 0.5) * scale + offset)
#define CP02  ((sin(time*0.70) * 0.5 + 0.5) * scale + offset)
#define CP03  ((sin(time*0.52) * 0.5 + 0.5) * scale + offset)
#define CP10  ((sin(time*0.20) * 0.5 + 0.5) * scale + offset)
#define CP11  ((sin(time*0.40) * 0.5 + 0.5) * scale + offset)
#define CP12  ((sin(time*0.80) * 0.5 + 0.5) * scale + offset)
#define CP13  ((sin(time*0.61) * 0.5 + 0.5) * scale + offset)
#define CP20  ((sin(time*0.50) * 0.5 + 0.5) * scale + offset)
#define CP21  ((sin(time*0.90) * 0.5 + 0.5) * scale + offset)
#define CP22  ((sin(time*0.60) * 0.5 + 0.5) * scale + offset)
#define CP23  ((sin(time*0.32) * 0.5 + 0.5) * scale + offset)
#define CP30  ((sin(time*0.27) * 0.5 + 0.5) * scale + offset)
#define CP31  ((sin(time*0.64) * 0.5 + 0.5) * scale + offset)
#define CP32  ((sin(time*0.18) * 0.5 + 0.5) * scale + offset)
#define CP33  ((sin(time*0.95) * 0.5 + 0.5) * scale + offset)

#define FLT_MAX 3.402823466e+38

//=======================================================================================

#if mode==0
 float CubicHermite (float A, float B, float C, float D, float t){
    float t2 = t*t;
    float t3 = t*t*t;
    float a = -A/2.0 + (3.0*B)/2.0 - (3.0*C)/2.0 + D/2.0;
    float b = A - (5.0*B)/2.0 + 2.0*C - D / 2.0;
    float c = -A/2.0 + C/2.0;
       float d = B;    
    return a*t3 + b*t2 + c*t + d;
 }
//above is easy to modify, below likely performs faster
#endif

#if mode>0
 #define MAD(a,b,c) (a*b+c) 
 float CubicHermite(float A,float B,float C,float D,float t){D*=.5; 
  //return MAD(MAD(MAD(D+.5*(((B-C)*3.)-A),t,A-2.5*B+2.*C-D),t,.5*(C-A)),t,B); 
  float a=D+.5*(((B-C)*3.)-A),b=A-2.5*B+2.*C-D,c=.5*(C-A);
  //return MAD(MAD(MAD(a,t,b),t,c),t,B); 
 return ((a*t+b)*t+c)*t+B;}
//above is not optimized borvector processing,
//below may perform even better, or at least is smaller?
#endif
#if mode<0
 #define MAD(a,b,c) (a*b+c) 
 float CubicHermite(float A,float B,float C,float D,float t){D*=.5;
 //return MAD(MAD(MAD(D+.5*(((B-C)*3.)-A),t,A-2.5*B+2.*C-D),t,.5*(C-A)),t,B); 
 vec3 p=vec3(D+.5*(((B-C)*3.)-A),A-2.5*B+2.*C-D,.5*(C-A)); 
 //return MAD(MAD(MAD(p.x,t,p.y),t,p.z),t,B); 
 return ((p.x*t+p.y)*t+p.z)*t+B; }
#endif

//=======================================================================================
float HeightAtPos(vec2 P){
    float CP0X = CubicHermite(CP00, CP01, CP02, CP03, P.x);
    float CP1X = CubicHermite(CP10, CP11, CP12, CP13, P.x);
    float CP2X = CubicHermite(CP20, CP21, CP22, CP23, P.x);
    float CP3X = CubicHermite(CP30, CP31, CP32, CP33, P.x);
    return CubicHermite(CP0X, CP1X, CP2X, CP3X, P.y);
}

//=======================================================================================
vec3 NormalAtPos( vec2 p )
{
    float eps = 0.01;
    vec3 n = vec3( HeightAtPos(vec2(p.x-eps,p.y)) - HeightAtPos(vec2(p.x+eps,p.y)),
                         2.0*eps,
                         HeightAtPos(vec2(p.x,p.y-eps)) - HeightAtPos(vec2(p.x,p.y+eps)));
    return normalize( n );
}

//=======================================================================================
bool RayIntersectAABoxNoY (vec2 boxMin, vec2 boxMax, in vec3 rayPos, in vec3 rayDir, out vec2 time)
{
    vec2 roo = rayPos.xz - (boxMin+boxMax)*0.5;
    vec2 rad = (boxMax - boxMin)*0.5;
    vec2 m = 1.0/rayDir.xz;
    vec2 n = m*roo;
    vec2 k = abs(m)*rad;
    vec2 t1 = -n - k;
    vec2 t2 = -n + k;
    time = vec2( max( t1.x, t1.y ),
                 min( t2.x, t2.y ));
    return time.y>time.x && time.y>0.0;}

//=======================================================================================
float RayIntersectSphere (vec4 sphere, in vec3 rayPos, in vec3 rayDir){
    //get the vector from the center of this circle to where the ray begins.
    vec3 m = rayPos - sphere.xyz;
    //get the dot product of the above vector and the ray's vector
    float b = dot(m, rayDir);
    float c = dot(m, m) - sphere.w * sphere.w;
    //exit if r's origin outside s (c > 0) and r pointing away from s (b > 0)
    if(c > 0.0 && b > 0.0)
        return -1.0;
    //calculate discriminant
    float discr = b * b - c;
    //a negative discriminant corresponds to ray missing sphere
    if(discr < 0.0)
        return -1.0;
    //ray now found to intersect sphere, compute smallest t value of intersection
    float collisionTime = -b - sqrt(discr);
    //if t is negative, ray started inside sphere so clamp t to zero and remember that we hit from the inside
    if(collisionTime < 0.0)
        collisionTime = -b + sqrt(discr);
    return collisionTime;}

//=======================================================================================
vec3 DiffuseColor (in vec3 pos){// checkerboard pattern
 return vec3(mod(floor(pos.x*10.)+floor(pos.z * 10.),2.)< 1.?1.:.4);}

//=======================================================================================
vec3 ShadePoint (in vec3 pos, in vec3 rayDir, float time, bool fromUnderneath)
{
    vec3 diffuseColor = DiffuseColor(pos);
    vec3 reverseLightDir = normalize(vec3(1.0,1.0,-1.0));
    vec3 lightColor = vec3(0.95,0.95,0.95);    
    vec3 ambientColor = vec3(0.05,0.05,0.05);

    vec3 normal = NormalAtPos(pos.xz);
    normal *= fromUnderneath ? -1.0 : 1.0;

    // diffuse
    vec3 color = diffuseColor * ambientColor;
    float dp = dot(normal, reverseLightDir);
    if(dp > 0.0)
        color += (diffuseColor * dp * lightColor);
    
    // specular
    vec3 reflection = reflect(reverseLightDir, normal);
    dp = dot(rayDir, reflection);
    if (dp > 0.0)
        color += pow(dp, 15.0) * vec3(0.5);        
    
    // reflection (environment mappping)
    reflection = reflect(rayDir, normal);
    //color += texture(iChannel0, reflection).rgb * 0.25;    
    
    return color;
}

//=======================================================================================
vec3 HandleRay (in vec3 rayPos, in vec3 rayDir, in vec3 pixelColor, out float hitTime)
{
    float time = 0.0;
    float lastHeight = 0.0;
    float lastY = 0.0;
    float height;
    bool hitFound = false;
    hitTime = FLT_MAX;
    bool fromUnderneath = false;
    
    vec2 timeMinMax = vec2(0.0);
    if (!RayIntersectAABoxNoY(vec2(0.0), vec2(1.0), rayPos, rayDir, timeMinMax))
        return pixelColor;
    
    time = timeMinMax.x;
    
    const int c_numIters = 100;
    float deltaT = (timeMinMax.y - timeMinMax.x) / float(c_numIters);
    
    vec3 pos = rayPos + rayDir * time;
    float firstSign = sign(pos.y - HeightAtPos(pos.xz));
    
    for (int index = 0; index < c_numIters; ++index)
    {        
        pos = rayPos + rayDir * time;
        
        height = HeightAtPos(pos.xz);
        
        if (sign(pos.y - height) * firstSign < 0.0)
        {
            fromUnderneath = firstSign < 0.0; 
            hitFound = true;
            break;
        }
        
        time += deltaT;        
        lastHeight = height;
        lastY = pos.y;
    }
    
    
    if (hitFound) {
        time = time - deltaT + deltaT*(lastHeight-lastY)/(pos.y-lastY-height+lastHeight);
        pos = rayPos + rayDir * time;
        pixelColor = ShadePoint(pos, rayDir, time, fromUnderneath);
        hitTime = time;
    }
    else
    {
        #if SHOW_BOUNDINGBOX
            pixelColor += vec3(0.2);
        #endif
    }
    
    return pixelColor;
}

//=======================================================================================
vec3 HandleControlPoints (in vec3 rayPos, in vec3 rayDir, in vec3 pixelColor, inout float hitTime)
{
    const float c_controlPointRadius = 0.02;
    #if SHOW_CONTROLPOINTS
    float cpHitTime = RayIntersectSphere(vec4(-1.0, CP00, -1.0, c_controlPointRadius), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(1.0,0.0,0.0);
    }
    cpHitTime = RayIntersectSphere(vec4(0.0, CP01, -1.0, c_controlPointRadius), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(1.0,0.0,0.0);
    }    
    cpHitTime = RayIntersectSphere(vec4(1.0, CP02, -1.0, c_controlPointRadius), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(1.0,0.0,0.0);
    }    
    cpHitTime = RayIntersectSphere(vec4(2.0, CP03, -1.0, c_controlPointRadius), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(1.0,0.0,0.0);
    }        
    
    
    cpHitTime = RayIntersectSphere(vec4(-1.0, CP10, 0.0, c_controlPointRadius), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(0.0,1.0,0.0);
    }
    cpHitTime = RayIntersectSphere(vec4(0.0, CP11, 0.0, c_controlPointRadius), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(0.0,1.0,0.0);
    }    
    cpHitTime = RayIntersectSphere(vec4(1.0, CP12, 0.0, c_controlPointRadius), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(0.0,1.0,0.0);
    }       
    cpHitTime = RayIntersectSphere(vec4(2.0, CP13, 0.0, c_controlPointRadius), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(0.0,1.0,0.0);
    }      
    
    
    cpHitTime = RayIntersectSphere(vec4(-1.0, CP20, 1.0, c_controlPointRadius), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(0.0,0.0,1.0);
    }
    cpHitTime = RayIntersectSphere(vec4(0.0, CP21, 1.0, c_controlPointRadius), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(0.0,0.0,1.0);
    }    
    cpHitTime = RayIntersectSphere(vec4(1.0, CP22, 1.0, c_controlPointRadius), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(0.0,0.0,1.0);
    }     
    cpHitTime = RayIntersectSphere(vec4(2.0, CP23, 1.0, c_controlPointRadius), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(0.0,0.0,1.0);
    }     
    
    
    cpHitTime = RayIntersectSphere(vec4(-1.0, CP30, 2.0, c_controlPointRadius), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(1.0,1.0,0.0);
    }
    cpHitTime = RayIntersectSphere(vec4(0.0, CP31, 2.0, c_controlPointRadius), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(1.0,1.0,0.0);
    }    
    cpHitTime = RayIntersectSphere(vec4(1.0, CP32, 2.0, c_controlPointRadius), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(1.0,1.0,0.0);
    }     
    cpHitTime = RayIntersectSphere(vec4(2.0, CP33, 2.0, c_controlPointRadius), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(1.0,1.0,0.0);
    }       
    #endif
    
    return pixelColor;
}

//=======================================================================================
void main(void)
{        
    //----- camera
    vec2 mouse = mouse*resolution.xy.xy / resolution.xy;

    vec3 cameraAt     = vec3(0.5,0.5,0.5);

    float angleX = 3.14 + time * 0.25;
    float angleY = 0.5;
    vec3 cameraPos    = (vec3(sin(angleX)*cos(angleY), sin(angleY), cos(angleX)*cos(angleY))) * 5.0;
    cameraPos += vec3(0.5,0.5,0.5);

    vec3 cameraFwd  = normalize(cameraAt - cameraPos);
    vec3 cameraLeft  = normalize(cross(normalize(cameraAt - cameraPos), vec3(0.0,sign(cos(angleY)),0.0)));
    vec3 cameraUp   = normalize(cross(cameraLeft, cameraFwd));

    float cameraViewWidth    = 6.0;
    float cameraViewHeight    = cameraViewWidth * resolution.y / resolution.x;
    float cameraDistance    = 6.0;  // intuitively backwards!
    
        
    // Objects
    vec2 rawPercent = (gl_FragCoord.xy / resolution.xy);
    vec2 percent = rawPercent - vec2(0.5,0.5);
    
    vec3 rayTarget = (cameraFwd * vec3(cameraDistance,cameraDistance,cameraDistance))
                   - (cameraLeft * percent.x * cameraViewWidth)
                   + (cameraUp * percent.y * cameraViewHeight);
    vec3 rayDir = normalize(rayTarget);
    
    
    float hitTime = FLT_MAX;
    vec3 pixelColor = vec3(0);// texture(iChannel0, rayDir).rgb;
    pixelColor = HandleRay(cameraPos, rayDir, pixelColor, hitTime);
    pixelColor = HandleControlPoints(cameraPos, rayDir, pixelColor, hitTime);
    
    glFragColor = vec4(clamp(pixelColor,0.0,1.0), 1.0);
}
