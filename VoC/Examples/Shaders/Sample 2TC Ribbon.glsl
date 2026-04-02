#version 420

// original https://www.shadertoy.com/view/XtXGDM

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

float h=resolution.y, t=time;
void main() {
    vec2
        p = gl_FragCoord.xy/h;
    float
        s = sin(t),
        o = p.x/( .15+.125*s ) - 5.*t,
        u = (p.y-.5)/(.25+.0625*sin(300.*p.x*.01+s)),
        a = asin( u ),
        c = cos( a + o ),
        r = c>.17 ? 1.+log(c)*.5 : 0.,
        g = .5 + log(cos(a-o-3.14))/4.;
    
    glFragColor = vec4( r, (1.-r)*g, 0, 0 ) * cos( 1.35*u );
}
