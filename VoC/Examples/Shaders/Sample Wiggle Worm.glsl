#version 420

// original https://www.shadertoy.com/view/t3f3RS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define P(z) vec3(sin(time),0,(z))
#define T time
#define rot(a) mat2(cos(a+vec4(0,33,11,0)))

void main(void)
{
    vec4 o = vec4(0.0);
    vec2 u = gl_FragCoord.xy;
    
    float s=.002,d=0.,i=0.;
    vec3  r = vec3(resolution.xy,0.0);
    
    vec3  p = P(T),ro=p,
          Z = normalize( P(T+1.) - p),
          X = normalize(vec3(Z.z,0,-Z)),
          D = vec3(rot(sin(T*.4)*3.)*(u-r.xy/2.)/r.y, 1) 
             * .5 * mat3(-X, cross(X, Z), Z);
    o -= o;
    for(; i++ < 120. && s > .001;) {
        p = ro + D *d;
        float g = dot(sin(.55*p)+sin(p),sin(.75*p)) +
                  dot(sin(.35*p),cos(p*.4));
        p.x -= .5;
        p.y += sin(p.z)*g*.3 + sin(6.*T+p.z*6.)*.1;
        s = length(p.xy - P(p.z).xy) - .1;
        for (float a = .5; a < 4.;
            s -= abs(dot(sin(T+T+T+p * a * 16.), vec3(.0125))) / a,
            a += a);
        d += s;
        o.rgb += sin(p*10.) *.012 + .02;
    }

    o.rgb = pow(o.rgb * exp(-d/5.), vec3(.45));
    
    glFragColor = o;
}