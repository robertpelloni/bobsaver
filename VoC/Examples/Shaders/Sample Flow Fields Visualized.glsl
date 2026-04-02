#version 420

// original https://www.shadertoy.com/view/Wt2SWt

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//3D gradient noise by Íñigo Quílez
vec3 hash(vec3 p){
    p = vec3( dot(p,vec3(127.1,311.7, 74.7)),
              dot(p,vec3(269.5,183.3,246.1)),
              dot(p,vec3(113.5,271.9,124.6)));

    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise(in vec3 p){
    vec3 i = floor( p );
    vec3 f = fract( p );
    
    vec3 u = f*f*(3.0-2.0*f);

    return mix( mix( mix( dot( hash( i + vec3(0.0,0.0,0.0) ), f - vec3(0.0,0.0,0.0) ), 
                          dot( hash( i + vec3(1.0,0.0,0.0) ), f - vec3(1.0,0.0,0.0) ), u.x),
                     mix( dot( hash( i + vec3(0.0,1.0,0.0) ), f - vec3(0.0,1.0,0.0) ), 
                          dot( hash( i + vec3(1.0,1.0,0.0) ), f - vec3(1.0,1.0,0.0) ), u.x), u.y),
                mix( mix( dot( hash( i + vec3(0.0,0.0,1.0) ), f - vec3(0.0,0.0,1.0) ), 
                          dot( hash( i + vec3(1.0,0.0,1.0) ), f - vec3(1.0,0.0,1.0) ), u.x),
                     mix( dot( hash( i + vec3(0.0,1.0,1.0) ), f - vec3(0.0,1.0,1.0) ), 
                          dot( hash( i + vec3(1.0,1.0,1.0) ), f - vec3(1.0,1.0,1.0) ), u.x), u.y), u.z );
}

float dist2Line(vec2 a, vec2 b, vec2 p) { 
    p -= a, b -= a;
    float h = clamp(dot(p, b) / dot(b, b), 0., 1.); 
    return length( p - b * h );                       
}

vec2 rotate2D(vec2 _st, float _angle){
    _st -= 0.5;
    _st =  mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle)) * _st;
    _st += 0.5;
    return _st;
}

#define PI 3.1415

float cell(vec2 uv){
    return smoothstep(.1, .05, dist2Line(vec2(.2, .5), vec2(.8, .5), uv));
}

void main(void) {
    vec2 uv = gl_FragCoord.xy/resolution.y;
    float f = noise(vec3(uv * 2., date.w));
    uv *= 16.;
    uv -= vec2(.5);
    vec2 i_uv = floor(uv);
    vec2 f_uv = fract(uv);
    vec2 nf_uv = rotate2D(f_uv, f * PI * 2.);
    float clr = cell(nf_uv);
    clr *= step(distance(i_uv.x, 13.), 8.)
         * step(distance(i_uv.y, 7.), 6.);
    glFragColor = vec4(clr);
}
