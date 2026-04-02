#version 420

// original https://www.shadertoy.com/view/3tfXRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1416
#define SKY_COLOR vec3(0.027, 0.151, 0.354)
#define LIGHT_SKY vec3(0.45, 0.61, 0.98)
#define STAR_COLOR vec3(0.92, 0.92, 0.14)
#define MOON_COLOR vec3(0.81, 0.81, 0.81)

//Noise functions from https://www.youtube.com/watch?v=zXsWftRdsvU
float noise11(float p) {
    return fract(sin(p*633.1847) * 9827.95);
}
    
float noise21(vec2 p) {
    return fract(sin(p.x*827.221 + p.y*3228.8275) * 878.121);
}

vec2 noise22(vec2 p) {
    return fract(vec2(sin(p.x*9378.35), sin(p.y*75.589)) * 556.89);
}

//From https://codepen.io/Tobsta/post/procedural-generation-part-1-1d-perlin-noise
float cosineInterpolation(float a, float b, float x) {
    float ft = x * PI;
    float f = (1. - cos(ft)) * .5;
    return a * (1. - f) + b * f;
}

float smoothNoise11(float p, float dist) {
    float prev = noise11(p-dist);
    float next = noise11(p+dist);
       
    return cosineInterpolation(prev, next, .5);
}

float smoothNoise21(vec2 uv, float cells) {
    vec2 lv = fract(uv*cells);
    vec2 id = floor(uv*cells);
    
    //smoothstep function: maybe change it later!
    lv = lv*lv*(3.-2.*lv);
    
    float bl = noise21(id);
    float br = noise21(id+vec2(1.,0.));
    float b = mix(bl, br, lv.x);
    
    float tl = noise21(id+vec2(0.,1.));
    float tr = noise21(id+vec2(1.,1.));
    float t = mix(tl, tr, lv.x);
    
    return mix(b, t, lv.y);
}

vec2 smoothNoise22(vec2 uv, float cells) {
    vec2 lv = fract(uv*cells);
    vec2 id = floor(uv*cells);
    
    //smoothstep function: maybe change it later!
    lv = lv*lv*(3.-2.*lv);
    
    vec2 bl = noise22(id);
    vec2 br = noise22(id+vec2(1.,0.));
    vec2 b = mix(bl, br, lv.x);
    
    vec2 tl = noise22(id+vec2(0.,1.));
    vec2 tr = noise22(id+vec2(1.,1.));
    vec2 t = mix(tl, tr, lv.x);
    
    return mix(b, t, lv.y);
}

float valueNoise11(float p) {
    float c = smoothNoise11(p, 0.5);
    c += smoothNoise11(p, 0.25)*.5;
    c += smoothNoise11(p, 0.125)*.25;
    c += smoothNoise11(p, 0.0625)*.125;
    
    return c /= .875;
}

float valueNoise21(vec2 uv) {
    float c = smoothNoise21(uv, 4.);
    c += smoothNoise21(uv, 8.)*.5;
    c += smoothNoise21(uv, 16.)*.25;
    c += smoothNoise21(uv, 32.)*.125;
    c += smoothNoise21(uv, 64.)*.0625;
    
    return c /= .9375;
}

vec2 valueNoise22(vec2 uv) {
    vec2 c = smoothNoise22(uv, 4.);
    c += smoothNoise22(uv, 8.)*.5;
    c += smoothNoise22(uv, 16.)*.25;
    c += smoothNoise22(uv, 32.)*.125;
    c += smoothNoise22(uv, 64.)*.0625;
    
    return c /= .9375;
}

vec3 point(vec2 p, vec2 uv, vec3 color, float size, float blur) {
    float dist = distance(p, uv);
    
    return color*smoothstep(size, size*(0.999-blur), dist);
}

float mapInterval(float x, float a, float b, float c, float d) {
    return (x-a)/(b-a) * (d-c) + c;
}

float blink(float time, float timeInterval) {
    float halfInterval = timeInterval / 2.0;
    //Get relative position in the bucket
    float p = mod(time, timeInterval);
    
    
    if (p <= timeInterval / 2.) {
        return smoothstep(0., 1., p/halfInterval);
    } else {
        return smoothstep(1., 0., (p-halfInterval)/halfInterval);
    }
}

vec3 sampleBumps(vec2 p, vec2 uv, float radius) {
    float dist = distance(p, uv);
    
    if (dist < radius) {
        return vec3((1.-valueNoise21(uv*10.))*.1);
    }
    return vec3(0.); 
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 ouv = uv;
    uv -= .5;
    uv.x *= resolution.x/resolution.y;
    
    vec2 mouse = mouse*resolution.xy.xy / resolution.xy;
    
    float time = time + mouse.x*10.;
        
    //vec3 col = vec3(0.0);
    //float m = valueNoise21(uv);    
    vec3 col = mix(LIGHT_SKY, SKY_COLOR, ouv.y+.6);
    
    col *= .65 + (1.-ouv.y);
    
    //Add clouds
    vec2 timeUv = uv;
    timeUv.x += time*.1;
    timeUv.y += valueNoise11(timeUv.x+.352)*.01;
    float cloud = valueNoise21(timeUv);
    col += cloud*.1;
    
    //Add stars in the top part of the scene
    float timeInterval = 5.;
    float timeBucket = floor(time / timeInterval);
    
    // Moon
    vec2 moonPosition = vec2(-0.600, 0.25);
    
    col += point(moonPosition, uv, MOON_COLOR, 0.15, 0.3);
    // Moon bumps
    col += sampleBumps(moonPosition, uv, 0.12);
    
    for (float i = 0.; i < 25.; i++) {
        vec2 starPosition = vec2(i/10., i/10.);
        
        starPosition.x = mapInterval(valueNoise11(timeBucket + i*827.913)-.4, 0., 1., -0.825, 0.825);
        starPosition.y = mapInterval(valueNoise11(starPosition.x)-.3, 0., 1., -0.445, 0.445);
        
        float starIntensity = blink(time, timeInterval);
        //Hide stars that are behind the moon
        if (distance(starPosition, moonPosition) > 0.14) {
            col += point(starPosition, uv, STAR_COLOR, 0.001, 0.0)*clamp(starIntensity-.1, 0.0, 1.0)*10.0;
            col += point(starPosition, uv, STAR_COLOR, 0.009, 3.5)*starIntensity*3.0;
        }
    }
  //col = vec3(blink(time, timeInterval));
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
