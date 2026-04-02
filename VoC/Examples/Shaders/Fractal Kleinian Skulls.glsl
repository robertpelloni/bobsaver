#version 420

// original https://www.shadertoy.com/view/wtsyRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// kleinian skulls
// by wj
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// This is a stripped down version of what I am using on my 2017 web 
// page: http://www.wothke.ch/269life (to correctly view that page you may 
// need one of last year's browsers - e.g. no later than Chromium 75 or FireFox 66.0. Sadly 
// KhronosGroup decided to make an incompatible change to their WEBGL GL_EXT_draw_buffers 
// specs which sadly was implemented by most of the browsers in the second half 
// of 2019 and which breaks pages that depend on the original semantics.)

// The code is based on knighty's "pseudo kleinian" Fragmentarium stuff with parts
// pilfered from boxplorer2. More detailed credits can be found below.

precision highp float;

#define RIM_BLEEDING    

#define DE_EPS 0.0001
#define MAX_DIST 10.0

#define MAX_STEPS 137    // Maximum raymarching stepscoloring
                
#define REFACTOR 0.5

#define TThickness 4.50741e-008        // Change a little the basic d_shape
#define Ziter 3

#define COLOR_ITERS 7                                            // Number of fractal iterations for coloring
#define REFITER 3                                                // reflections
#define DIST_MULTIPLIER 0.363001
#define ITERS 11                                                // Number of fractal iterations            
#define CSize vec3(0.808001 ,0.808,1.167)                        // Size of the box folding cell
#define Size 1.                                                    // Size of inversion sphere
#define C vec3(0,0,0)                                            // Julia seed
#define Offset vec3(-4.88759e-007,1.73877e-007,-1.51991e-007)    // Translation of the basic d_shape
#define DEoffset 0.                                                // A small value added to the DE - simplify
#define MAXI 1.0
            
// "defines" used to completely avoid unused calculations
#define OptionalJuliaSeed p=p;
#define DEfacScale k                

#define BLEND 0.543                                                 // Blend with 0 trap
                
#define PI_HALF 1.5707963267948966192313216916398

#define ONE_PLUS_ULP 1.000000059604644775390625
#define ONE_MINUS_ULP 0.999999940395355224609375
#define ULP 0.000000059604644775390625

#define MIN_NORM 0.00001

#define AO_EPS        0.0499998     // Base distance at which ambient occlusion is estimated.
#define AO_STRENGTH    0.149624    // Strength of ambient occlusion.

const vec3 backgroundColor= vec3(0.02, 0.06, 0.16);
const float speed= 3.95070000e-004;
const float min_dist= 0.000794328;        // Distance at which raymarching stops
const float glow_strength= 0.499999;    // How much glow is applied after MAX_STEPS
const float dist_to_color= 0.200951;     // How is background mixed with the surface color after MAX_STEPS
//const float time= 0.0;
const int preset= 0;

// Colors.
vec3 specularColor = vec3(1.0, 0.8, 0.4),
    glowColor = vec3(0.03, 0.4, 0.4),
    aoColor = vec3(0, 0, 0);

const vec3 NORM_LIGHT=  normalize(vec3(1.0,0.5,0.7));

// Compute the distance from `pos` to the PKlein basic shape.
float d_shape(vec3 p) {
    // => this is the magic sauce that you want to tinker with :-)
    // pearls: nice blue/pearl finish 
   float rxy = (length(p.x));
   return max(rxy,  -(length(p.xy)*p.z-TThickness) / sqrt(dot(p,p)+abs(TThickness)));
}    

// Compute the distance from `pos` to the PKlein.

// stripped down version of knighty's "pseudo kleinian" distance 
// estimate.. (see "Fragmentarium") - see used "defines" to recover standard impl
float d(vec3 p) {
    float r2;
    float DEfactor=1.;
            
    for(int i=0; i<ITERS; i++){                //Box folding (repetition)
        p=2.*clamp(p, -CSize, CSize)-p;
        //Inversion
        r2=dot(p,p);
        float k=max(Size/r2, MAXI);
        p*=k; DEfactor*= DEfacScale;
        OptionalJuliaSeed        // use define to completely remove if not used..
                
//        if (!(r2<1.)) break; // add some rectangular beams for menger?
                
    }                
    return (DIST_MULTIPLIER*d_shape(p-Offset)/abs(DEfactor)-DEoffset);
}

// Compute the color (In the original "Fragmentarium" impl color would be calculated 
// directly within the above d() function.. and the below impl is repeating the 
// the respective last call of d(p).. still this seems to be faster (e.g. 16fps vs 15fps) than 
// doing the calc for all the d() calls within march() - not counting all the additional d() 
// calls for reflections and AO..
vec3 color(vec3 p) {
    float r2=dot(p,p);
    float DEfactor=1.;
    vec4  col=vec4(0.0);
    float rmin=10000.0;;

    vec3 Color= vec3(-1.072,5.067, 0.647 );

    for(int i=0; i<COLOR_ITERS; i++){    //Box folding                    
        vec3 p1=2.*clamp(p, -CSize, CSize)-p;
        col.xyz+=abs(p-p1);
        p=p1;
        //Inversion
        r2=dot(p,p);
        float k=max(Size/r2, MAXI);
        col.w+=abs(k-1.);
        p*=k; DEfactor*= DEfacScale;;
        OptionalJuliaSeed        // use define to completely remove if not used..
                
        r2=dot(p,p);
        rmin=min(rmin,r2);
    }                
    return mix(vec3(sqrt(rmin)),(0.5+0.5*sin(col.z*Color)), BLEND);
}

// Compute the normal at `pos`.
// `d_pos` is the previously computed distance at `pos` (for forward differences).
vec3 generateNormal(vec3 pos, float d_pos) {
    vec2 Eps = vec2(0, max(d_pos, MIN_NORM));    
    return normalize(vec3(
        // calculate the gradient in each dimension from the intersection point
        -d(pos-Eps.yxx)+d(pos+Eps.yxx),
        -d(pos-Eps.xyx)+d(pos+Eps.xyx),
        -d(pos-Eps.xxy)+d(pos+Eps.xxy)
    ));
}

// Blinn-Phong shading model (http://en.wikipedia.org/wiki/BlinnPhong_shading_model)
// `normal` and `view` should be normalized.
vec3 blinn_phong(vec3 normal, vec3 view, vec3 color) {
    vec3 halfLV = normalize(NORM_LIGHT + view);
    float diffuse= max( dot(normal, halfLV), 0.0 );
    float specular = pow(diffuse, 32.0 );    /*specular exponent*/
                    
#ifdef RIM_BLEEDING
    // with rim lighting (diffuse light bleeding to the other side)
    diffuse = dot(normal, NORM_LIGHT); 
#endif
    return color * (diffuse * 0.5 + 0.75) + specular * specularColor;
}

// FAKE Ambient occlusion approximation. based on
// http://www.iquilezles.org/www/material/nvscene2008/rwwtt.pdf
// uses current distance estimate as first dist. the size of AO is independent from distance from eye
float ambient_occlusion(vec3 p, vec3 n, float DistAtp, float side) {
    float ao_ed= DistAtp*AO_EPS/min_dist;    // Dividing by min_dist makes the AO effect independent from changing min_dist
    float ao = 1.0, w = AO_STRENGTH/ao_ed;
    float dist = 2.0 * ao_ed;

    for (int i=0; i<5; i++) {
        float D = side * d(p + n*dist);
        ao -= (dist-D) * w;
        w *= 0.5;
        dist = dist*2.0 - ao_ed;
    }
    return clamp(ao, 0.0, 1.0);
}

float march(inout vec3 p, in vec3 dp, inout float D, inout float totalD, in float side, in float MINDIST_MULT){
    // Intersect the view ray with the Mandelbox using raymarching.
    // The distance field actually marched is the "calculated DE" minus (totalD * min_dist)
    // A perfect distance field have a gradient magnitude = 1. Assuming d() gives a perfect DE, 
    // we have to multiply D with MINDIST_MULT in order to restore a gradient magnitude of 1
    int steps= 0;
    for (int dummy=0; dummy<MAX_STEPS; dummy++) {
        totalD+=D;
        D = (side * d(p + totalD * dp) - totalD * min_dist) * MINDIST_MULT;

        steps++;    // mimick what any non stupid-WEBGL loop would allow to do in the loop condition
                
        if (!(abs(D)>max(totalD*8192.0*ULP,ULP) && totalD < MAX_DIST)) break;            
    }
    p += (totalD+D) * dp;
    return float(steps);
}

// original "noise()" impl used somewhat cheaper variant of IQ's procedural 2D noise: https://www.shadertoy.com/view/lsf3WH
// - to reduce GPU load, respective impl has been replaced by a texture-lookup based one (see https://www.shadertoy.com/view/4sfGzS).
float noise3d( in vec3 x ) {
    vec3 p = floor(x);
    vec3 f = fract(x);
     f = f*f*(3.0-2.0*f);
                    
    vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
    vec2 rg = vec2(0.0);//texture( iChannel0, (uv+0.5)/256.0, 0.0).yx;
    return mix( rg.x, rg.y, f.z );
}

// By TekF...
void BarrelDistortion( inout vec3 ray, float degree )
{
    ray.z /= degree;
    ray.z = ( ray.z*ray.z - dot(ray.xy,ray.xy) );
    ray.z = degree*sqrt(ray.z);
}

mat3 RotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c);
}

vec3 cameraDirection() 
{
    // Camera direction borrowed from David Hoskins's
    // https://www.shadertoy.com/view/4s3GW2
    // I am too lazy to add more sophisticated flight controls for now
    vec2 xy = gl_FragCoord.xy / resolution.xy;
    vec2 uv = (-1. + 2.0 * xy) * vec2(resolution.x/resolution.y,1.0);

    mat3 mZ = RotationMatrix(vec3(.0, .0, 1.0), sin(time*.2)*.1);
    mat3 mX = RotationMatrix(vec3(1.0, .0, .0),  0.0);
    mat3 mY = RotationMatrix(vec3(.0, 1.0, 0.0), 0.0);
    mX = mY * mX * mZ;
    
    vec3 dir = vec3(uv.x, uv.y, 1.2);
    BarrelDistortion(dir, .5);
    dir = mX * normalize(dir);
    
    return dir;
}

void main(void) {
    
    vec3 dir= cameraDirection();
    vec3 camera= vec3(1.0+sin(time*.13)*.8, 1.4, sin(time*.2)*.1);    
    
    
    vec3 dp = normalize(dir);
    float noise =  noise3d(vec3(gl_FragCoord.xy.x, gl_FragCoord.xy.y, 0));

    vec3 p = camera;

    float totalD = 0.0, D = d(p);
                    
    float side = sign(D);
    D = noise * abs(D);
                    
    float MINDIST_MULT=1.0/(1.0+min_dist);
    D *= MINDIST_MULT;

    vec3 finalcol= vec3(0.);
    float refpart= 1.0;

    bool cont= true;
    float firstD= 0.;  // save first step for depth buffer
                        
    for(int i= 0; i<REFITER; i++){
        float steps= march(p, dp, D, totalD, side, MINDIST_MULT);
        if (i == 0) { firstD= totalD + D; }
                        
        vec3 col= backgroundColor;

        // We've got a hit or we're not sure.
        if (totalD < MAX_DIST) {
            float D1= min_dist*.5*totalD;
            vec3 n= side * generateNormal(p, max(256.0*ULP, D1));
            col= color(p);
                            
            col= blinn_phong(n, -dp, col);            
            col= mix(aoColor, col, ambient_occlusion(p, n, D1, side));

            dp= reflect(dp,n);    // update the ray

            p-= (totalD+D) * dp;        // without this there would be obvious reflection errors..
            D= (9. + noise) * D1;

            // We've gone through all steps, but we haven't hit anything.
            // Mix in the background color.
            if (D > max(totalD*8192.0*ULP,ULP)){
                float dc= clamp(log(D/min_dist) * dist_to_color, 0.0, 1.0);
                col= mix(col, backgroundColor, dc);
            }
        } else {
            cont= false;
        }

        // Glow is based on the number of steps.
        col= mix(col, glowColor, (float(steps)+noise)/float(MAX_STEPS) * glow_strength);
        finalcol+= refpart*col;
        refpart*= REFACTOR;
        if (!cont) break;
    }            

    glFragColor= vec4(finalcol, 1.0);
}
