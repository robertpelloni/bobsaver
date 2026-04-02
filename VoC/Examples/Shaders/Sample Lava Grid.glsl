#version 420

// original https://www.shadertoy.com/view/NtVXzh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

float h21 (vec2 a) {
    return fract(sin(dot(a.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float h21 (vec2 p, float sc) {
    p.x = mod(p.x, sc); p.y = mod(p.y, sc);
    return fract(sin(dot(p.xy, vec2(12.9898, 78.233)))*43758.5453123);
}

float mlength(vec2 uv) {
    return max(abs(uv.x), abs(uv.y));
}

// this isnt adding much + quite expensive
float selength(vec2 uv, float n) {
    return pow(pow(abs(uv.x), n) + pow(abs(uv.y), n), 1./n);
}

vec2 movingTiles(vec2 uv, float sc, float speed){
    float time = speed * time;
    
    // Change me for different patterns
    float val = 2. * abs(uv.x) + 2. * abs(uv.y) + 1. * time;
    float ft = fract(val);
   
    uv *= sc;
    
    float s = step(0.5, ft);
    float a = 0.5;
    
    uv.x +=      s * sign(fract(uv.y * a) - a) * ft * 2.;
    uv.y += (1.-s) * sign(fract(uv.x * a) - a) * ft * 2.;
    
    return fract(uv * 1.);
}

float rand(vec2 ipos, vec2 fpos, float sc) {
    float val = 6. * length(fpos-0.5) + h21(ipos, sc) - time;
    //float val = h21(ipos, sc) + time;
    
    float a = 2. * pi * h21(ipos, sc);
    float c = cos(a); 
    float s = sin(a);
    
    float v1 = h21(vec2(c * floor(val), s * floor(val)) + 0.01 * ipos, sc);
    float v2 = h21(vec2(c * (floor(val) + 1.), s * (floor(val) + 1.)) + 0.01 * ipos, sc);  
    
    float m = fract(val);
    m = m * m * (3. - 2. * m);
   
    return mix(v1, v2, m);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy)/ resolution.y; 
    uv += 0.02 * time;
    
    float c = 30.;
    float sc = 17.;
    
    // Cut into grid
    vec2 ipos = floor(sc * uv) + 0.5;  
    vec2 fpos = fract(sc * uv) - 0.;
    
    // Corner positions
    vec2 lp  = ipos + vec2(1,0);
    vec2 tp  = ipos + vec2(0,1);
    vec2 tlp = ipos + vec2(1,1);  
    vec2 idp = ipos + vec2(0,0);

    // Generate values for each corner of uv
    float sc2 = c * sc;
    float l  = rand(lp,  fpos, sc2);
    float t  = rand(tp,  fpos, sc2);
    float tl = rand(tlp, fpos, sc2);
    float id = rand(idp, fpos, sc2);

    // Smooth fpos so boundaries meet smoothly
    vec2 sfpos = fpos * fpos * (3. - 2. * fpos);

    // Box lerp between the corner values
    float v = l  * sfpos.x      * (1.-sfpos.y)
             + t  * (1.-sfpos.x) * sfpos.y
             + tl * sfpos.x      * sfpos.y
              + id * (1.-sfpos.x) * (1.-sfpos.y);
        
    // Do the tile pattern (maybe this should be fpos?)
    uv = movingTiles(uv, sc, 0.2 + 0.0003 * cos(10. * v + time));

    // Draw stuff
    float n = 4.;
    vec3 e = vec3(1.);
    vec3 col = v * pal(0.025 - 0.05 * h21(uv) + selength(uv-0.5, n), 
                       e, e, e, 0.5 * v  + 2.6 * vec3(0.,0.33,0.66));
    /*
    float k = 1.;
    float s = smoothstep(-k, k, -0.5 - 0.5 * cos(10. * v) + v);
    vec3 col =  s * v * pal(0.025 - 0.05 * h21(uv) + selength(uv-0.5, n), 
                       e, e, e, 0.5 * v  + 2.6 * vec3(0.,0.33,0.66));
    col += (1. - s) * v;
    */
    
    glFragColor = vec4(col,1.0);
}

