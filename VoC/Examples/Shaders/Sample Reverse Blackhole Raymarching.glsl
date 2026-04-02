#version 420

// original https://www.shadertoy.com/view/tdXyRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535

#define CONVERGENCE 0.001f
// low values = higher time in black hole objects
// next idea would be to more anylitcally do this
#define DARK_ANTI_CONVERGENCE 0.05f
// change this to lessen the effect, increasing produces less artifacts
// 1 is where the pull/push of the black hole is equal to the ray
#define VIEW_RAY_WEIGHT 4.0f
#define ITERATIONS 120u
// toggle between normal and reverse black holes
// because of the anti convergence 0 is buggy, need to revisit
#define PUSH 1
#define GRID_SIZE 7.5
// colors
vec3 paloffset = vec3(16., 8., 16.3);
vec3 palRep = vec3(8., 4., 6.);
// anim
vec3 mainSeq = vec3(0);
vec3  darkSceneSeq = vec3(0);

void setAnimations()
{
    mainSeq.x = smoothstep(0., 4., mod(time, 40.)) - smoothstep(8., 12., mod(time, 40.));
    mainSeq.y = smoothstep(0., 4., mod(time + 20., 40.)) - smoothstep(8., 12., mod(time + 20., 40.));
    mainSeq.z = smoothstep(18., 20., mod(time, 40.)) - smoothstep(38., 40., mod(time, 40.));

    darkSceneSeq.x = mod(time/16., 4.);
      darkSceneSeq.y = mod(time -2., 1.) * (mod(time, 16.) > 15. ? 1. : 0.);
    darkSceneSeq.z = smoothstep(12., 13., mod(time - 2., 16.)) - smoothstep(15., 16., mod(time- 2., 16.));

    paloffset += vec3(time) * 0.4;
    palRep += vec3(0.5 + 0.5 *sin(time * PI * 0.01), 0.5 + 0.5 *cos(time * PI * 0.01), 0.5 + 0.5 *sin(time * PI * 0.01 + 40.));
}

// Camera code, shamelessly copied from https://www.shadertoy.com/view/4s3SRN
vec3 cp[16];
void setCamPath(){
    const float sl = GRID_SIZE;
    const float yBump = GRID_SIZE/2.;
    cp[0] = vec3(0, yBump, sl);
    cp[1] = vec3(0, yBump, 2. * sl);
    cp[2] = vec3(sl, yBump, 2.* sl);
    cp[3] = vec3(2.*sl, yBump,2.* sl);
    cp[4] = vec3(2.*sl, yBump, sl);    
    cp[5] = vec3(2.*sl, yBump, 0);    
    cp[6] = vec3(sl, yBump, 0);
    cp[7] = vec3(0, yBump, 0);
    
    cp[8] = vec3(0, yBump, sl);
    cp[9] = vec3(0, yBump, 2. * sl);
    cp[10] = vec3(sl, yBump, 2.* sl);
    cp[11] = vec3(2.*sl, yBump,2.* sl);
    cp[12] = vec3(2.*sl, yBump, sl);    
    cp[13] = vec3(2.*sl, yBump, 0.);    
    cp[14] = vec3(sl, yBump, 0.);
    cp[15] = vec3(0., yBump, 0.);
    // for(int i =0; i < 16; i++)cp[i] += vec3(GRID_SIZE/2. + 2., 0., GRID_SIZE/2. + 2.);
}
vec3 Catmull(vec3 p0, vec3 p1, vec3 p2, vec3 p3, float t){
    return (((-p0 + p1*3. - p2*3. + p3)*t*t*t + (p0*2. - p1*5. + p2*4. - p3)*t*t + (-p0 + p2)*t + p1*2.)*.5);
}
vec3 camPath(float t){    
    const int aNum = 16;    
    t = fract(t/float(aNum))*float(aNum);    // Repeat every 16 time units.
    // Segment number. Range: [0, 15], in this case.
    float segNum = floor(t);
    // Segment portion. Analogous to how far we are alone the individual line segment. Range: [0, 1].
    float segTime = t - segNum; 
    if (segNum == 0.) return Catmull(cp[aNum-1], cp[0], cp[1], cp[2], segTime);     
    for(int i=1; i<aNum-2; i++){
        if (segNum == float(i)) return Catmull(cp[i-1], cp[i], cp[i+1], cp[i+2], segTime); 
    }    
    if (segNum == float(aNum-2)) return Catmull(cp[aNum-3], cp[aNum-2], cp[aNum-1], cp[0], segTime); 
    if (segNum == float(aNum-1)) return Catmull(cp[aNum-2], cp[aNum-1], cp[0], cp[1], segTime);
    return vec3(0);
}

// Signed distance functions
float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdCappedCylinder( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

// gradients
// prefer exact gradients for cleaner effect
// also good exercise to do this

vec3 grdBox(vec3 p, vec3 b)
{             
    vec3 q = abs(p) - b;
    float t = length(max(q, 0.));
    
    // asymptotic limit; cant use step since infintiy can win in 0 * (1/0)
    float lambda = (t == 0. ? 0. : (1./t));
     
    float dx = step(0., q.x) * q.x * sign(p.x) * lambda +
                step(q.x, 0.) * step(max(q.z, q.y), q.x) * sign(p.x);
    float dy = step(0., q.y) * q.y * sign(p.y) * lambda +
                step(q.y, 0.) * step(max(q.x, q.z), q.y) * sign(p.y);
    float dz = step(0., q.z) * q.z * sign(p.z) * lambda +
                step(q.z, 0.) * step(max(q.x, q.y), q.z) * sign(p.z);
    
    return vec3(
        dx,
        dy,
        dz
    );
}

vec3 grdTorus(vec3 p, vec2 t)
{
    float xzLength = length(p.xz);
    
    vec2 q = vec2(xzLength-t.x,p.y);
    
      float sdTorus = length(q)-t.y;
    
    float d = (1./sdTorus) * (xzLength-t.x) * (1./xzLength);
    
    return vec3(
        d * p.x,
        (1./sdTorus) * p.y,
        d * p.z
    );
}

vec3 grdSphere(vec3 p)
{
    float b = length(p);
    return vec3(
        (p.x)/b,
        (p.y)/b,
        (p.z)/b
    );
}

vec3 grdCappedCylinder( vec3 p, float h, float r )
{
    //  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
    // return min(max(d.x,d.y),0.0) + length(max(d,0.0));
    
    float lengthXZ = length(p.xz);
    vec2 d = abs(vec2(lengthXZ,p.y)) - vec2(h,r);  
    
    float outerDistance = length(max(d,0.0));
    
    // asymptotic limit; cant use step since infintiy can win in 0 * (1/0)
    float lambda = (outerDistance == 0. ? 0. : (1./outerDistance));
    
    float zeta = lambda * d.x  * 1./lengthXZ;
    
    float dx = step(d.x, 0.) * step(d.y, d.x) * sign(lengthXZ) * 1./lengthXZ * p.x +
               step(0., d.x) * zeta * p.x;
                                
    float dz = step(d.x, 0.) * step(d.y, d.x) * 1./lengthXZ * p.z +
               step(0., d.x) * zeta * p.z; 
                                
    float dy = step(d.y, 0.) * step(d.x, d.y) * sign(p.y) +
               step(0., d.y) * (d.y * sign(p.y)) * lambda;
    
    return vec3(
        dx,
        dy,
        dz 
    );  
    
}

float distanceToDarkScene(vec3 p, out vec3 gradient)
{    
    float animation = 2. * mainSeq.x + 1.;
    float c = GRID_SIZE;
    vec3 q = mod(p +vec3(3.5,3.5,3.5) +0.5*c,c)-0.5*c;
    
    vec3 b = vec3(1., animation, 1.);
   
    float dstS = sdSphere(q, 1.);
    vec3 grdS = grdSphere(q);

    float dstB = sdBox(q, b);
    vec3 grdB = grdBox(q, b);
    
    float dstC = sdCappedCylinder(q, 0.6, 2.);
    vec3 grdC = grdCappedCylinder(q, 0.6, 2.);
    
    float dstT = sdTorus(q, vec2(1., 0.6));
    vec3 grdT = grdTorus(q, vec2(1., 0.6));
    
    float dist;
    if (darkSceneSeq.x <1.)
    { 
        gradient = grdS;
        dist = mix(dstS, dstB, darkSceneSeq.y);
    }    
    else if (darkSceneSeq.x < 2.)
    {
        gradient = grdB;
        dist = mix(dstB, dstC, darkSceneSeq.y);
    }
    else if (darkSceneSeq.x < 3.)
    {
        gradient = grdC;
        dist = mix(dstC, dstT, darkSceneSeq.y);
    }
    else
    { 
        gradient = grdT;
        dist = mix(dstT, dstS, darkSceneSeq.y);
    }
       
    return max(dist, DARK_ANTI_CONVERGENCE);
}

float distanceToScene(vec3 p)
{   
    vec2 animation = vec2(6.5 *mainSeq.x + 1., mainSeq.x + 1. );
    float c = GRID_SIZE;
    vec3 q = mod(p+0.5*c,c)-0.5*c;

    float dstT = min(sdTorus(q, vec2(2.5, 0.5)), sdTorus(q, vec2(0.01, 1.5 + 0.5 *sin(time)))) ;
    float dstC = sdCappedCylinder(q, 2., 1.);
    float dstS = sdSphere(q, 1.);
    float dstB1 = sdBox(q, vec3(animation.x, 1., 1.)); 
    float dstB2 = sdBox(q, vec3(1., 1., animation.x)); 
    
    return mix(
           mix(dstS, min(dstB1, dstB2), mainSeq.x),
           mix(dstC, dstT, mainSeq.y),
    mainSeq.z);
      
}

vec3 distortRay (vec3 ray, float darkDist, vec3 gradient)
{
    float animation = (darkSceneSeq.z * 0.7) + 0.3;   
    
    float radiusShrinker = 1./(DARK_ANTI_CONVERGENCE * DARK_ANTI_CONVERGENCE);
    
    float inverseOfSquaresLaw =  1./(darkDist * darkDist * radiusShrinker);
    
    #if PUSH
        vec3 g = gradient;
    #else
        vec3 g = -gradient;
    #endif
    
    vec3 combined = normalize(VIEW_RAY_WEIGHT * ray * animation + (1.- animation) * g * inverseOfSquaresLaw );
    return combined;    
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy*0.5)/resolution.y;
  
    setAnimations();
    float speed = time*0.35 + 8.;
    //speed = 0.;
    
    // Initiate the camera path spline points. Kind of wasteful not making this global, but I wanted
    // it self contained... for better or worse. I'm not really sure what the GPU would prefer.
    setCamPath();
    // Camera Setup.
    vec3 ro = camPath(speed); // Camera position, doubling as the ray origin.
    vec3 lk = camPath(speed + .5);  // "Look At" position.
    vec3 lp = camPath(speed + .5) + vec3(0, .25, 0);     
    float FOV = 1.57; // FOV - Field of view.
    vec3 fwd = normalize(lk-ro);
    vec3 rgt = normalize(vec3(fwd.z, 0, -fwd.x));
    vec3 up = (cross(fwd, rgt));
    
    // Unit direction ray.
    vec3 ray = normalize(fwd + FOV*(uv.x*rgt + uv.y*up));

    vec3 start = ro;
    
    vec3 p = start;
       
    bool backdropHit = false;
    float travel = 0.;

    uint last_i = 0u;
    for (uint i = 0u; i < ITERATIONS; i++)
    {
        float sceneDist = distanceToScene(p);
        
        vec3 darkGradient;
        float darkDist = distanceToDarkScene(p, darkGradient);
        
        if (sceneDist < CONVERGENCE){ last_i = i; break;}
        
        float marchDist = min(sceneDist, darkDist);
        
        travel += marchDist;
        
        ray = distortRay(ray, darkDist, darkGradient);
        p += ray * marchDist;
        
        if (i == ITERATIONS - 1u){ backdropHit = true; }
    }
    
    float r = 0.5 + 0.5 * sin((p.x/palRep.x) - paloffset.x);
    float g = 0.5 + 0.5 * sin((p.x/palRep.y) - paloffset.y);
    float b = 0.5 + 0.5 * sin((p.x/palRep.z) - paloffset.z);
   
    
    vec3 color = vec3(r, g, b) * min(20./travel, 1.);
    
    glFragColor = vec4(color - float(last_i) / float(ITERATIONS), 1.0);
    
    if (backdropHit)
    {
        glFragColor = vec4(0.,0. ,0., 1.0);
    }
}
