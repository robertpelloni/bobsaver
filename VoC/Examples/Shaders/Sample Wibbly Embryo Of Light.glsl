#version 420

// original https://www.shadertoy.com/view/ld2cWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* 
 * Created by Hadyn Lander 
 * 3D noise from Nikita Miropolskiy, nikat/2013 https://www.shadertoy.com/view/XsX3zB
 * That basically includes all of this neat looking code up top:
 */

/* discontinuous pseudorandom uniformly distributed in [-0.5, +0.5]^3 */
vec3 random3(vec3 c) {
    float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
    vec3 r;
    r.z = fract(512.0*j);
    j *= .125;
    r.x = fract(512.0*j);
    j *= .125;
    r.y = fract(512.0*j);
    return r-0.5;
}

/* skew constants for 3d simplex functions */
const float F3 =  0.3333333;
const float G3 =  0.1666667;

/* 3d simplex noise */
float simplex3d(vec3 p) {
     /* 1. find current tetrahedron T and it's four vertices */
     /* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
     /* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/
     
     /* calculate s and x */
     vec3 s = floor(p + dot(p, vec3(F3)));
     vec3 x = p - s + dot(s, vec3(G3));
     
     /* calculate i1 and i2 */
     vec3 e = step(vec3(0.0), x - x.yzx);
     vec3 i1 = e*(1.0 - e.zxy);
     vec3 i2 = 1.0 - e.zxy*(1.0 - e);
         
     /* x1, x2, x3 */
     vec3 x1 = x - i1 + G3;
     vec3 x2 = x - i2 + 2.0*G3;
     vec3 x3 = x - 1.0 + 3.0*G3;
     
     /* 2. find four surflets and store them in d */
     vec4 w, d;
     
     /* calculate surflet weights */
     w.x = dot(x, x);
     w.y = dot(x1, x1);
     w.z = dot(x2, x2);
     w.w = dot(x3, x3);
     
     /* w fades from 0.6 at the center of the surflet to 0.0 at the margin */
     w = max(0.6 - w, 0.0);
     
     /* calculate surflet components */
     d.x = dot(random3(s), x);
     d.y = dot(random3(s + i1), x1);
     d.z = dot(random3(s + i2), x2);
     d.w = dot(random3(s + 1.0), x3);
     
     /* multiply d by w^4 */
     w *= w;
     w *= w;
     d *= w;
     
     /* 3. return the sum of the four surflets */
     return dot(d, vec4(52.0));
}

/* const matrices for 3d rotation */
const mat3 rot1 = mat3(-0.37, 0.36, 0.85,-0.14,-0.93, 0.34,0.92, 0.01,0.4);
const mat3 rot2 = mat3(-0.55,-0.39, 0.74, 0.33,-0.91,-0.24,0.77, 0.12,0.63);
const mat3 rot3 = mat3(-0.71, 0.52,-0.47,-0.08,-0.72,-0.68,-0.7,-0.45,0.56);

/* directional artifacts can be reduced by rotating each octave */
float simplex3d_fractal(vec3 m) {
    return   0.5333333*simplex3d(m*rot1)
            +0.2666667*simplex3d(2.0*m*rot2)
            +0.1333333*simplex3d(4.0*m*rot3)
            +0.0666667*simplex3d(8.0*m);
}

/*
* The Nintendo Super Mess of code below is all me. I am sorryish.
*/

// Comment out the enxt line to limit the length of "rays"
#define UNLIMITED            

#define CENTERSCALE 0.6
#define CENTERCONNECTEDNESS 0.35
#define RADIUS 0.5            // Has a bigger impact if UNLIMITED is disabled
#define FLAMEBOOST 0.15        // Adds the flame shape mask over the top of the multiplied noise to maintain more of original shape.
#define EDGE 0.65            // Edge cutoff 
#define FALLOFFPOW 4.0        // Only used is UNLIMITED is disabled
#define NOISEBIGNESS 1.5 
#define NIGHTSPEEDBONUS 1.25         
#define PI 3.14159265359

float getNoiseValue(vec2 p, float time)
{
    vec3 p3 = vec3(p.x, p.y, 0.0) + vec3(0.0, 0.0, time*0.025);
    float noise = simplex3d(p3*32.0);// simplex3d_fractal(p3*8.0+8.0);
    return 0.5 + 0.5*noise;
}

void main(void)
{
    float time = 28.22+NIGHTSPEEDBONUS*time;
    float bignessScale = 1.0/NOISEBIGNESS;
    vec2 p = gl_FragCoord.xy / resolution.y;
    float aspect = resolution.x/resolution.y;
    vec2 positionFromCenter = p-vec2(0.5*aspect, 0.5);
    
    float innerOrbEdge = (1.0-CENTERCONNECTEDNESS)*CENTERSCALE*RADIUS;
    vec2 pOffset = normalize(positionFromCenter) * mix(innerOrbEdge-length(positionFromCenter), 1.0, step(CENTERSCALE*RADIUS, length(positionFromCenter)));
    p = vec2(0.5*aspect, 0.5)+pOffset;//normalize(positionFromCenter)*min(length(positionFromCenter)+CENTERCONNECTEDNESS*CENTERSCALE*RADIUS, CENTERSCALE*RADIUS);    
    
    bignessScale = mix(1.2*bignessScale, bignessScale, step(CENTERSCALE*RADIUS, length(positionFromCenter)));
    
    
    float noise = getNoiseValue(bignessScale*0.25*p, time);
    
    float distanceFromCenter = clamp(1.0-length(positionFromCenter)/RADIUS, 0.0, 1.0);
    
    float scaledDistance = distanceFromCenter * noise;
    
    
    float falloffMask = 1.0; 
    
    #ifndef UNLIMITED
        falloffMask =  2.0*scaledDistance-1.0;
        falloffMask = clamp(1.0-pow(abs(falloffMask), FALLOFFPOW), 0.0, 1.0);
    #endif
    
    float thinnerMask;
    
    thinnerMask = 1.0-clamp(abs(distanceFromCenter-(1.0-CENTERSCALE))/CENTERSCALE, 0.0, 1.0);
    thinnerMask = pow(thinnerMask, 16.0);    
    thinnerMask = clamp(0.9*thinnerMask, 0.0, 1.0);
    
    float finalValue;
    finalValue = falloffMask;
    
    float innerBall = clamp(abs(distanceFromCenter-(1.0-CENTERSCALE))/CENTERSCALE, 0.0, 1.0);
    innerBall = smoothstep(0.5, 0.85, innerBall);
    innerBall += noise;
    
    finalValue = mix( (noise*falloffMask+thinnerMask)*thinnerMask + innerBall, noise*falloffMask+thinnerMask, step(distanceFromCenter, 1.0-CENTERSCALE));
    
    finalValue = smoothstep(EDGE,EDGE+0.1, finalValue);
    
    
    vec3 colorNoise;
    colorNoise.x    = getNoiseValue(bignessScale*0.25*p, 10.0+time);
    colorNoise.y     = getNoiseValue(bignessScale*0.25*p, 00.0+time);
    colorNoise.z    = getNoiseValue(bignessScale*0.25*p, 30.0+time);
    
    colorNoise.x = smoothstep(EDGE,EDGE+0.1, colorNoise.x);
    colorNoise.y = smoothstep(EDGE,EDGE+0.1, colorNoise.y);
    colorNoise.z = smoothstep(EDGE,EDGE+0.1, colorNoise.z);
    
    
    vec3 finalColor;
    //finalColor = vec3(colorNoise.x, colorNoise.y, colorNoise.x+colorNoise.y); 
    finalColor = mix(vec3(colorNoise.x, 0.0, 0.2*colorNoise.x), vec3(colorNoise.x, 1.0, 1.0), 1.0-colorNoise.y);
    finalColor += vec3(1.0) * (pow(clamp(distanceFromCenter+CENTERSCALE, 0.0, 1.0), 8.0));
    
    //finalColor = clamp(finalColor, vec3(0.0), vec3(1.0));
    
    finalColor *= finalValue;
    
    vec3 bgColor = mix(vec3(0.00,0.07,0.15), vec3(0.15,0.35,0.5), distanceFromCenter*0.5);
    bgColor += vec3(1.0,.2,0.4)* pow(distanceFromCenter, 4.0);
    finalColor += bgColor;
    
    glFragColor = vec4(finalColor,1.0);
}
