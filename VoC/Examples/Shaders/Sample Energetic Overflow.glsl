#version 420

// original https://www.shadertoy.com/view/clBXzw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define e(p,r) mod(p, r) - r/2.
void main(void) { //WARNING - variables void (out vec4 O, vec2 u) { need changing to glFragColor and gl_FragCoord.xy
	vec2 u = gl_FragCoord.xy;
    vec2 R = resolution.xy; u += u - R;
    vec3 p, g;
    float i = 0., d = i, t=time*.5, s, r;
    
    for (g *= i; i++ < 60.; 
        p = abs(d*normalize(vec3(u/R.y, 1))),
        p.z += t*12.73,
        p.xy *= mat2(cos(d*.03+vec4(0,33,11,0))),
        r = .5 + sin(t) * (sin(p.z*2.)*.1 + cos(p.z*4.)*.05),
        d += min(s = min(
            length(e(p, vec3(5,5,20))) - r, 
            length(vec2(length(p.xy)-8., e(p.z, 20.)))-.25), 
            length(e(p.xy, 5.)) - r),
        g += 1. / (1. + pow(abs(s)*40., 1.3)))
    
    glFragColor.rgb = (1.5 * (cos(d + t + vec3(0,1,2)) + 1.) * g + g) / exp(d*.01);
}
