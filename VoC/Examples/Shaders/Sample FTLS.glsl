#version 420

// original https://www.shadertoy.com/view/lldfR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define T time * 8.
#define PI2 6.28318
#define R resolution.xy

//Dave Hoskins
//https://www.shadertoy.com/view/4djSRW
float H1(float p) {
    vec3 x  = fract(vec3(p) * .1031);
    x += dot(x, x.yzx + 19.19);
    return fract((x.x + x.y) * x.z);
}

//IQ cosine palattes
//http://www.iquilezles.org/www/articles/palettes/palettes.htm
vec3 PT(float t) {return vec3(.5) + vec3(.5) * cos(6.28318 * (vec3(1) * t + vec3(0, .33, .67)));}

void main(void) { //WARNING - variables void (out vec4 C, vec2 U) { need changing to glFragColor and gl_FragCoord
    
    vec2 U = gl_FragCoord.xy;
    vec4 C = glFragColor;

    //ray direction
    vec2 uv = (U - R * .5) / R.y;
    vec3 f = vec3(0, 0, 1),
         r = vec3(f.z, 0, -f.x),
         d = normalize(f + 1. * uv.x * r + 1. * uv.y * cross(f, r));
    
    float a = (atan(d.y, d.x) / PI2) + .5, //polar  0-1
          l = floor(a * 24.) / 24.; //split into 24 segemnts
    vec3 c = PT(H1(l + T * .0001)) * step(.1, fract(a * 24.)); //segment colour and edge
    float m = mod(abs(d.y) + H1(l) * 4. - T * .01, .3); //split segments 
    c *= step(m, .16) * m * 16. * max(abs(d.y), 0.); //split segments
    
    C = vec4(c, 1.);

    glFragColor = C;
}
