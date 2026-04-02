#version 420

// original https://www.shadertoy.com/view/7ddSzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.1415926535

float h21 (vec2 a) {
    return fract(sin(dot(a.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float h11 (float a) {
    return fract(sin(a * 12.9898) * 43758.5453123);
}

//iq palette
vec3 pal(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d) {
    return a + b * cos(2. * pi * (c * t + d));
}
/*
float getAngleLength(float a, float b) {
    return min(1. - abs(a-b), abs(a-b));
}
*/
void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    uv.y += 0.04 * cos(time);
    
    // polar uv
    vec2 puv = vec2(atan(uv.y, uv.x), length(uv));
    vec3 col = vec3(0);
    float t = mod(time * 1., 6000.);
    float px = 1. / resolution.y;
    
    vec2 aRange = vec2(-pi, pi);
    vec2 lRange = vec2(0., 0.5);
    
    float aLength = 2. * pi;
    float lLength = 0.5;
        
    float id = 0.;
    vec2 diff;
    float seed = floor(t / 6.);
    float a;
        
    //PLAY WITH THESE VARIABLES :D
    float minAngle = pi / 32.;
    float minLength = 0.015;
    
    float iters = 5.;
    float borderSize = 0.0;
    float minIters = 1.;

    // replace this with polar equations to get cool shape
    float lengthDistort = 1.1 * puv.y;
    //float angleDistort = puv.x;

    for(float i = 0.; i < iters; i++) {   
        float rand  = h21(vec2(i + id, seed));
        float rand2 = h21(vec2(i - id, seed));
        float rand3 = h21(vec2(i + 0.5 * id, seed));
        
        float aSplit  = rand  * aLength + aRange.x; // split angle below length split
        float aSplit2 = rand2 * aLength + aRange.x; // split angle above length split
        float lSplit  = rand3 * lLength + lRange.x; // split length
        
        aSplit  = clamp(aSplit,  aRange.x + minAngle,  aRange.y - minAngle);
        aSplit2 = clamp(aSplit2, aRange.x + minAngle,  aRange.y - minAngle);
        lSplit  = clamp(lSplit,  lRange.x + minLength, lRange.y - minLength);
        
        //if(h21(vec2(aSplit, lSplit)) > 0.9 && i+1. > minIters) break;

        // diff is used to give unique id to each sector
        diff = vec2(0);
        
        if(lengthDistort < lSplit){
            if(puv.x + .5 * (1. + cos(aSplit2 + time)) < aSplit){
                aRange = vec2(aRange.x, aSplit);
                diff.x = aSplit;
            }
            else{
                aRange = vec2(aSplit, aRange.y);
                diff.x = -lSplit;
            }
            lRange = vec2(lRange.x, lSplit);
            diff.y = -aSplit;
        }
        else{
            if(puv.x + .5 * (1. + cos(aSplit + time)) < aSplit2){
                aRange = vec2(aRange.x, aSplit2);
                diff.x = aSplit;
            }
            else{
                aRange = vec2(aSplit2, aRange.y);
                diff.x = -lSplit;
            }
            lRange = vec2(lSplit, lRange.y);
            diff.y = lSplit;
        }

        // + 10. ensures topleft, bottomright have different Ids
        id = length(diff * 100. + 10.);  
        
        aLength = aRange.y - aRange.x;
        lLength = lRange.y - lRange.x;
    }
    
    float fade = 1.- abs(pow(cos(t * 2. * pi / 6.),10.));

    a += step(puv.x, aRange.y) * step(lengthDistort, lRange.y) 
    * (1.-smoothstep(-10. * px, 100. * px,.5 * lRange.x + .5 * lRange.y-0.5 * fade));
       
    col = vec3(a);
    vec3 e = vec3(0.5);
    vec3 al = pal(id * 0.5, e * 1.1, e * 1.1, vec3(1,.7,.4), vec3(0,.15,.2));
    // vec3 al = pal(id * 0.1, e * 1.2, e, e * 2.0, vec3(0, 0.33, 0.66));
    col = a * al;
    
    glFragColor = vec4(col, 1.);
    
}
