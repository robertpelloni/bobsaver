#version 420

// original https://www.shadertoy.com/view/cllSzl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* "Deeper System" by @kishimisu (2023) - https://www.shadertoy.com/view/cllSzl
   [465 chars]
   
   Playing around with raymarching and neon lights
*/

#define r(a) mat2(cos(a + vec4(0,33,11,0)))

void main(void) {
	vec2 u = gl_FragCoord.xy;
    vec2 r  = resolution.xy; u += u - r;
    float d=0., m=d, t=time, c;
    vec3 g, p, q;
    
    for (g*=d; m++<60.; 
        p  = abs(d*normalize(vec3(u/r.y*r(t*.3), 1)))) 
        g += (cos(d*.2+vec3(0,1,2))*.5+1.) / (1.+pow(abs(
        c  = length(vec2(length(p.xy)-1.,mod(p.z+t*4.,14.)-7.))-.05)*40.,1.3)),
        q  = fract(p) - .5,
        d += min(c, length(q.xy*r(t) + 
          vec2(0, sin(q.z*6.28+t/.1)*sin(t+length(p.xy))/6.)) - .1) - d*d/5e2;
    
    glFragColor.rgb = (cos(d*4.+t+vec3(0,1,2))+1.) / exp(d*.2) * g + g;   
}
