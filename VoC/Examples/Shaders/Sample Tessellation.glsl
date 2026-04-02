#version 420

// original https://www.shadertoy.com/view/3lyfDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// All components are in the range [0…1], including hue.
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float fsnoise(vec2 c){
    return fract(sin(dot(c, vec2(12.9898, 78.233))) * 43758.5453);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy;// [0,resolution] coords
    uv *= 2.0;// zoom out.

    // Pattern generation.
    vec2 p=uv.xy/resolution.y*4. + time;
    vec2 I=floor(p/4.);
    p = mod(p,4.) - 2.0;
    float i;
    for(;i++<9.;){
        p=abs(p)-1.;
        p/=dot(p,p);
        if(length(p)<1.)
        break;
    }    
    vec4 o;
    o.rgb = rgb2hsv(vec3(fsnoise(I+i*.1),1.,1.))/abs(sin(max(p.x,p.y)*5.))/i;

    // Output to screen
    glFragColor = vec4(o.rgb,1.0);
}
