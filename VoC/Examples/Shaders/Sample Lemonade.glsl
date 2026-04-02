#version 420

// Tokyo Demo Fest 2014, 7 Lines GLSL Graphics Compo entry.
// Lemonade by Pentan (@c5h12)

out vec4 glFragColor;

//#define COMPO_CODE
#ifdef COMPO_CODE
//++++++++/+++++++++/+++++++++/+++++++++/+++++++++/+++++++++/+++++++++/++++++++

uniform float time;uniform vec2 resolution;uniform vec2 mouse;void main(){float

 L,l,n,d,A=24.;vec2 p,u=(gl_FragCoord.xy*2.-resolution)/resolution.y;L=dot(u,u)
;vec3 c=vec3(.9,1.,u.y*.1+.9);u+=time*.2-mouse;p=abs((fract(u*.8)*2.-1.)*mat2(
cos(time),sin(time),-sin(time),cos(time)));p=(p.x<p.y)?p.xy:p.yx;l=length(p);d=
smoothstep(.0,.1,(1./(1.+A*p.x)+1./(1.+A*dot(p,vec2(-.7,.7)))+1./(1.+A*max(.0,
.8-l)))-1.);c=mix(vec3(1.,.9,.4),mix(vec3(1.,1.,smoothstep(.9,.8,l)),c,
smoothstep(.9,.91,l)),d)*exp(-L*vec3(.05,.03,.2));glFragColor=vec4(c,1.);}

//++++++++/+++++++++/+++++++++/+++++++++/+++++++++/+++++++++/+++++++++/++++++++
#else

uniform float time;
uniform vec2 resolution;
uniform vec2 mouse;

void main(void) {
    vec2 u, p, r;
    float L, l, n, d, A=24.0;
    
    u = (gl_FragCoord.xy * 2.0 - resolution) / resolution.y;
    L = dot(u, u);
    vec3 c = vec3(0.9, 1.0, u.y * 0.1 + 0.9);
    u += time * 0.2 - mouse;
    r = (fract(u * 0.8) * 2.0 - 1.0) * mat2(cos(time), sin(time), -sin(time), cos(time));
    
// omitted texture to shrink 7 lines X(
#if 1
    vec2 v, a, q;
    float w, x;
    q = r * A;
    a = normalize(vec2(r.y, -r.x));
    p = floor(q);
    n = 0.0;
    for(int j = -3; j < 4; j++) {
        for(int i = -3; i < 4; i++) {
            u = p + vec2(ivec2(i, j));
            v = u - q;
            n += (fract(sin(dot(u, vec2(1.0,57.0)))*43758.5)*2.-1.) * exp(dot(v, v) * -1.0) * cos(dot(v, a) * 3.0);
        }
    }
#else
    n = 0.0;
#endif
    
    p = abs(r);
    p = (p.x < p.y)? p.xy : p.yx;
    
    l = length(p);
    d = (1.0/(1.0 + A * p.x) + 1.0/(1.0 + A * dot(p, vec2(-0.7, 0.7))) + 1.0 / (1.0 + A * max(0.0, 0.8 - l))) - 1.0;
    d = smoothstep(0.0, 0.1, d);
    
    c = mix(vec3(1.0, 1.0, smoothstep(0.9, 0.8, l)), c, smoothstep(0.89, 0.9, l));
    n = abs(n);
    c = mix(vec3(1.0, 0.9 + n * 0.1, 0.4 + n * 0.2), c, d);
    c = c * exp(-L*vec3(0.05, 0.03, 0.2));
    
    glFragColor = vec4(c, 1.0);
}

#endif
