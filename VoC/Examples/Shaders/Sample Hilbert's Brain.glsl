#version 420

// original https://www.shadertoy.com/view/XdscWr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535898

const float puddleY = 0.2;

/* *********************** Hilbert curve ***********************/

/* This is based on the following 2D shader:

    https://www.shadertoy.com/view/XtjXW3

   The code was refactored for legibility and is better
   explained here:

    https://www.shadertoy.com/view/MdXcWn

*/

#define swap(a,b) tmp=a; a=b; b=tmp;

#define plot(U,l) ( dot(U,l) > 0.  ? abs( dot(U , vec2(-l.y,l.x)) ) : 0. )
#define plotC(U,l)  abs( length(U-(l)/2.) - .5 )
          
// symU and rotU apply to vectors that range from 0 to 1
void symU(inout vec2 u) {
    u.x = 1.-u.x;
}

void rotU(inout vec2 u) {
    u.xy = vec2(u.y,1.-u.x);
}

// symV and rotV apply to unit vectors that range from -1 to 1

void symV(inout vec2 v) {
    v.x= -v.x;
}

void rotV(inout vec2 v) {
    v.xy = vec2(v.y,-v.x);
}

float textureFunc(vec2 U ) {
    const float iter = 2.;
    
    vec2 P = vec2(.5);
    vec2 I = vec2(1,0);
    vec2 J = vec2(0,1);
    
    vec2 l = -I;
    vec2 r;
    
    vec2 qU;
    vec2 tmp;
    
    for (float i = 0.; i < iter; i++) {
        qU      = step(.5,U);         // select quadrant
        bvec2 q = bvec2(qU);          // convert to boolean
        
        U       = 2.*U - qU;          // go to new quadrant
        
        l = q.x ? (q.y ? -J : -I)            // node left segment
                : (q.y ?  l :  J);
                    

        r = (q.x==q.y)?  I : (q.y ?-J:J);    // node right segment
        
        // the heart of Hilbert curve : 
        if (q.x) { // sym
            symU(U);
            symV(l);
            symV(r);
            swap(l,r);
           }
        if (q.y) { // rot+sym
            rotU(U); symU(U);
            rotV(l); symV(l);
            rotV(r); symV(r);
           }
    }
    
    float s=iter* 25.;
    float o=length(l+r) > 0. ? plotC (U-P, l+r) : plot (U-P, l) + plot (U-P, r); 
    return pow(sin(smoothstep(.33+.01*s,.33-.01*s,o)*0.5*PI),2.);
}

/* ************************************************************ */

/* Basic operations from:
 *   http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
 */
float opU( float d1, float d2 )
{
    return min(d1,d2);
}

// 3D Primitives

float sdPlane( vec3 p ) {
    return p.y;
}

float sdSphere( vec3 p, float s ) {
  return length(p)-s;
}

float udRoundBox( vec3 p, vec3 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}

// 2D Primitives (degenerate cases of IQ's 3D dist functions):
//  http://iquilezles.org/www/articles/distfunctions/distfunctions.htm

float udRoundRect( vec2 p, vec2 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}

/* ************************************************************ */

/* The brain consists of Hilbert curves on a sphere.
 *
 * The Hilbert curve is defined over a unit square x,y=[0,1].
 * To map it onto a sphere, I draw it on the sides of a cube
 * and use IQ's patched sphere parametrization to squash it
 * into a sphere.
 *
 * Reference: http://iquilezles.org/www/articles/patchedsphere/patchedsphere.htm */

vec2 sphereToCube(in vec3 pointOnSphere) {
   return vec2(
        pointOnSphere.x/pointOnSphere.z,
        pointOnSphere.y/pointOnSphere.z
    );
}

void sphereTangents(in vec3 pointOnSphere, out vec3 u, out vec3 v) {
    u = vec3(
        -(1.+pointOnSphere.y*pointOnSphere.y),
        pointOnSphere.x*pointOnSphere.y,
        pointOnSphere.x);
    v = vec3(
        pointOnSphere.x*pointOnSphere.y,
        -(1.+pointOnSphere.x*pointOnSphere.x),
        pointOnSphere.y);
}

/* Check if x and y are between 0 and 1. If so, return v,
 * otherwise return zeros. This allows us to use a sum of
 * vectors to test what face of the cube we are on */ 
vec2 insideBounds(vec2 v) {
    vec2 s = step(vec2(-1.,-1.), v) - step(vec2(1.,1.), v);
    return s.x * s.y * v;
}

float getSphereMappedTexture(in vec3 pointOnSphere) {
    /* Test to determine which face we are drawing on.
     * Opposing faces are taken care of by the absolute
     * value, leaving us only three tests to perform.
     */
    vec2 st = abs(
        insideBounds(sphereToCube(pointOnSphere    )) +
        insideBounds(sphereToCube(pointOnSphere.zyx)) +
        insideBounds(sphereToCube(pointOnSphere.xzy)));
    return textureFunc(st);
}

vec3  brainCenter = vec3(0., 0.85, 0.);
float brainRadius = 2.;

float sdBrain(vec3 p) {
    return
        getSphereMappedTexture(p) * -0.13 +
        sdSphere(p-brainCenter, brainRadius);
}

vec3 brainColor(vec3 p) {
    float f = smoothstep(0.1, 0.4, getSphereMappedTexture(p));
    return mix(vec3(1.0,0.4,0.5),vec3(1.0,0.6,0.7),f);
}

/* ************************************************************ */

/* The puddle is based on my lathe operator. If I take a 2D
 * rectangle and sweep it a full 360 degrees, I would get a
 * circular disc. By varying the length of that rectangle, I
 * make a puddle.
 */
 
// Periodic sinusoidal function gives us the shape of the puddle.
float puddle(float a) {
    return  0.45 +
            0.05 * sin(a *  1.0) +
           -0.06 * sin(a *  2.0) +
            0.03 * sin(a *  4.0) +
            0.04 * sin(a *  8.0);
}

// The distance field in 2D, which is swept around to form the puddle.
// Thin rectangle with rounded edges, to make the puddle edges round.
float crossSection(vec2 p, float len) {
    return udRoundRect(p, vec2(len, 0.0), .1);
}

// Generates the puddle. Sweeps the crossSection around while varying
// the length according to the angle.
float opPuddle( vec3 p ) {
    float dia = puddle(atan(p.x, p.z)) * 7.;
    return crossSection(vec2(length(p.xz), p.y - puddleY), dia);
}

/* ************************************************************ */

/* Tile floor */

vec3 tilePlane(vec3 p) {
    p.xz = mod(p.xz, 1.1);
    return p;
}

bool usePuddle;

/* This function returns a distance field in 3D. It consists of
 * an infinite plane of tiles, the brain, and the puddle.
 */
float map(vec3 p){
    float d =
        opU(
            udRoundBox(tilePlane(p),vec3(1.,0.1,1.),0.05),
            sdBrain(p)
        );
    
    if(usePuddle) {
        return opU(d, opPuddle(p));
    } else {
        return d;
    }
}

// Soft shadow code modified from: https://www.shadertoy.com/view/Xds3zN

float softshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<16; i++ )
    {
        float h = map( ro + rd*t );
        res = min( res, 8.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

/* Ray-marching code based on https://www.shadertoy.com/view/MlXSWX */

// Surface normal.
vec3 getNormal(in vec3 p) {
    
    const float eps = 0.001;
    return normalize(vec3(
        map(vec3(p.x+eps,p.y,p.z))-map(vec3(p.x-eps,p.y,p.z)),
        map(vec3(p.x,p.y+eps,p.z))-map(vec3(p.x,p.y-eps,p.z)),
        map(vec3(p.x,p.y,p.z+eps))-map(vec3(p.x,p.y,p.z-eps))
    ));

}

// Standard ray marching routine. I find that some system setups don't like anything other than
// a "break" statement (by itself) to exit.
float march(vec3 rayOrigin, vec3 rd) {
    const float minDist = .05;
    float t = 0.0, dt;
    for(int i=0; i<128; i++){
        dt = map(rayOrigin + rd*t);
        if(dt<minDist || t>150.){ break; } 
        t += dt*0.75;
    }
    return (dt < minDist) ? t : -1.;
}

void main(void)
{
    // Screen coordinates.
    vec2 uv = (gl_FragCoord.xy - resolution.xy*0.5)/resolution.y;

    // Camera Setup.
    vec3 lookAt = vec3(0.0, 1.0, 0.0);  // "Look At" position.
    vec3 camPos = lookAt + vec3(
        3.0 - mouse.x*resolution.xy.x/resolution.x*7.,
        6.0 - mouse.y*resolution.xy.y/resolution.y*4.,
        -6.); // Camera position, doubling as the ray origin.

    // Lights
    vec3 light_pos  = vec3(5., 7., -1.);
    
    // Using the above to produce the unit ray-direction vector.
    float FOV = PI/3.; // FOV - Field of view.
    vec3 forward = normalize(lookAt-camPos);
    vec3 right = normalize(vec3(forward.z, 0., -forward.x )); 
    vec3 up = cross(forward, right);
    
    usePuddle = true;
    
    // rd - Ray direction.
    vec3 rd = normalize(forward + FOV*uv.x*right + FOV*uv.y*up);
    float t = march(camPos, rd);
    
    // The final scene color. Initated to sky color.
    vec3 sceneCol = vec3(0.);
    
    // The ray has effectively hit the surface, so light it up.
    if(t > 0.){
        float specular = 0.;
        float diffuse  = 110.;
        
        // Surface position and surface normal.
        vec3 sp = t * rd+camPos;
        vec3 sn = getNormal(sp);
        
        if(opPuddle(sp) < 0.05) {
            // We have hit the puddle
            usePuddle = false;
            
            vec3 refractedRd = refract(-rd, sn, 1./1.33);
            float t = march(sp, refractedRd);
            
            sp = t * refractedRd+sp;
            sn = getNormal(sp);
            
            sceneCol -= vec3(0.0, 0.4, 0.4);
            specular = 1.0;
        }
        
        // The floor is white, the brain is textured.
        if(sp.y < 0.2) {
            sceneCol += vec3(1.0);
            specular = 0.7;
        } else {
            sceneCol += brainColor(sp);
            specular = 0.4;
        }

        // Light direction vectors.
        vec3 ld  = light_pos-sp;

        // Distance from respective lights to the surface point.
        float distlpsp  = max(length(ld),  0.001);
        
        // Ambient light.
        float ambience = 0.15;
        
        // Normalize the light direction vectors.
        ld  /= distlpsp;
        
        // Diffuse lighting.
        float diff  = max( dot(sn, ld), 0.0) * 110.;
        
        // Light attenuation
        diff /= distlpsp*distlpsp;
        
        // Specular highlights.
        specular *= pow(max( dot( reflect(-ld, sn), -rd ), 0.0 ), 8.);
        
        usePuddle = false;
        
        // Soft shadow based on:
        //   https://www.shadertoy.com/view/Xds3zN
        float shadow = softshadow( sp, ld, 0.02, 2.5 );
        
        sceneCol *= diff*shadow*0.5 + ambience*0.5 + specular;
    }

    glFragColor = vec4(clamp(sceneCol, 0., 1.), 1.0);
}
