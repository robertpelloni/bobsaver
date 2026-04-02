#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

vec2  surfacePos;

vec3 hsv(float h,float s,float v) {
    return mix(vec3(1.),clamp((abs(fract(h+vec3(3.,2.,1.)/3.)*6.-3.)-1.),0.,1.),s)*v;
}

void main( void ) {
    surfacePos = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    vec2 p = vec2(gl_FragCoord.x/resolution.x*3.0,gl_FragCoord.y/resolution.y*3.0);
    float t = time*0.025+0.4;
    vec2 sc = vec2(sin(t), cos(t));
    p = vec2(p.x*sc.x + p.y*sc.y, p.x*sc.y - p.y*sc.x);
    p = abs(mod(p, 2.0) - 1.0);
    float h = sin(length(p)*2.0);
    p.x /= resolution.x/resolution.y;
    glFragColor = vec4(hsv(sin(h*14.0)*0.5+0.5, 1.0, 1.0)*0.05 + texture2D(backbuffer, p).rgb*0.95, 1.0);
}
