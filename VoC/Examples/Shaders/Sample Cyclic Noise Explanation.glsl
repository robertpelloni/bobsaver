#version 420

// original https://www.shadertoy.com/view/3tcyD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Cyclic noise is created by nimitz.
// He uses it a lot, like in here: https://www.shadertoy.com/view/wl3czN
// I just rewrote his code, renamed some variables and tried to explain it a bit.

// Left is vanilla 
// Right is the derivative, fed into a pallete

// The basic structure of the loop is like an fbm.
// You are stacking octaves of noise.
// But the noise itself is generated in an interesting way:
// You do something like a 1-tap dot prodcut (Perlin,Simplex) noise inside of a sinewave lattice.
// Then you apply some rotation and scale, and repeat. 

// Turbulent noise is 
// 1.-abs(noise)
//#define TURBULENT

mat3 getOrthogonalBasis(vec3 direction){
    direction = normalize(direction);
    vec3 right = normalize(cross(vec3(0,1,0),direction));
    vec3 up = normalize(cross(direction, right));
    return mat3(right,up,direction);
}

float cyclicNoise(vec3 p){
    float noise = 0.;
    
    // These are the variables. I renamed them from the original by nimitz
    // So they are more similar to the terms used be other types of noise
    float amp = 1.;
    const float gain = 0.6;
    const float lacunarity = 1.5;
    const int octaves = 8;
    
    const float warp = 0.3;    
    float warpTrk = 1.2 ;
    const float warpTrkGain = 1.5;
    
    // Step 1: Get a simple arbitrary rotation, defined by the direction.
    vec3 seed = vec3(-1,-2.,0.5);
    mat3 rotMatrix = getOrthogonalBasis(seed);
    
    for(int i = 0; i < octaves; i++){
    
        // Step 2: Do some domain warping, Similar to fbm. Optional.
        
        p += sin(p.zxy*warpTrk - 2.*warpTrk)*warp; 
    
        // Step 3: Calculate a noise value. 
        // This works in a way vaguely similar to Perlin/Simplex noise,
        // but instead of in a square/triangle lattice, it is done in a sine wave.
        
        noise += sin(dot(cos(p), sin(p.zxy )))*amp;
        
        // Step 4: Rotate and scale. 
        
        p *= rotMatrix;
        p *= lacunarity;
        
        warpTrk *= warpTrkGain;
        amp *= gain;
    }
    
    
    #ifdef TURBULENT
    return 1. - abs(noise)*0.5;
    #else
    return (noise*0.25 + 0.5);
    #endif
}

float get(vec2 uv){
    float noise = cyclicNoise(vec3(uv*10.,time));
    float noiseb = cyclicNoise(vec3(uv*10. - 3.,time) - noise*1.);

    return noiseb*pow(max(noise,0.),1.) - (1.-  noise)* (abs(noise)*.4 );
}

// Bruteforce derivative. 
// You could calculate this analyticall inside of cyclicNoise() 
// if you wished to do so, and it would be much cheaper 
vec2 derivative(vec2 uv, float eps){
    vec2 t = vec2(eps,0);
    return vec2(
        get(uv + t.xy) - get(uv - t.xy),
        get(uv + t.yx) - get(uv - t.yx)
        );
}

// iq pallete: https://iquilezles.org/www/articles/palettes/palettes.htm
#define pal(a,b,c,d,e) ((a) + (b)*sin((c)*(d) + (e)))

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.y;
    vec3 col = vec3(0);
    
    if(gl_FragCoord.xy.x > resolution.x/2.){
        float noise = get(uv);
        vec2 dxdy = derivative(uv,0.003).xy;
        col += pal(0.5,0.5,vec3(1,2,4),1.,dxdy.x*19. + time )*pow(max(noise,0.),0.9);
    
    } else {
        float noise = cyclicNoise(vec3(uv*10.,time));
        col += pal(0.5,0.5,vec3(1,2,4),1.,noise + time )*pow(max(noise,0.),0.9);
    
    }
    
    // gamma correction
    col = pow(max(col,0.),vec3(0.4545));
    //col = pow(abs(col),vec3(0.4545));
    
    glFragColor = vec4(col,1.0);
}
