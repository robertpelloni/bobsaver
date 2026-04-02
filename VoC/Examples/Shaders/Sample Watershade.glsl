#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/WsBczK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// convert screen coordinates to space ones with origin in centre
vec2 pixelToSpace(vec2 pixel) {
    return (pixel/resolution.xy) *
        vec2(1.0, resolution.y / resolution.x);
}

int hash(vec2 where) {
    ivec2 i = ivec2(where);
    return (31 * i.x) ^  (i.y * 91);
}

vec2 random2(vec2 st){
    st = vec2( dot(st,vec2(127.1,311.7)),
              dot(st,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}

// Gradient Noise by Inigo Quilez - iq/2013
// https://www.shadertoy.com/view/XdXGW8
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( random2(i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ),
                     dot( random2(i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( random2(i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ),
                     dot( random2(i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}
float smoothie(float x) {
    return tanh(((x-0.5)*5.0)+1.0)/2.0;
}
vec2 smoothie(vec2 v) {
    return vec2(smoothie(v.x), smoothie(v.y));
}
void main(void)
{
    vec2 where = 16.0 * pixelToSpace(gl_FragCoord.xy);

    float dx = 1.0* noise(where+vec2(time*0.2));
    float dy = 1.0* noise(where+vec2(-time*0.2));
    float swirl = noise(vec2(0,dy));
    float r = 3.0* noise(vec2(dx,0));
    float effect = 1.0 / (1.0+ r*r);
    float t = 4.0 * effect * noise(vec2(dx,dy));
    vec2 ds = vec2(r*cos(t), r*sin(t));
    where = where + ds;
    float lev = noise(where);
    float blot = clamp(4.0*noise(where*0.2)+2.0, 0.0, 1.1);
    lev = (lev+0.5) *blot;
    vec3 col = vec3(lev);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
