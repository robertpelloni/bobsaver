#version 420

// original https://www.shadertoy.com/view/XXcGRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec4 o=vec4(0.0);
    float i,e,R,s, t = time;
    vec3 n,q,p, 
         r = vec3(resolution.xy,1.0), 
         d = ( .4*r - gl_FragCoord.xyy ) / r.y; d.z = 1.;
    n += .6;
    o *= 0.;
    for( q-- ; i++<52. ; i>31. ? d /= -d : d )
    {
        o += e*e/25.;
        q +=   mix( dot( n, p = d*e*R*.2 ) * n , p, cos( e = sin(t)*.2+.1 ) ) 
             + cross(n,p) * sin(e);
        p = vec3( log2( R = length(q) ) - t , -q.z/R , atan(q.x,q.y) );
        for( e = --p.y + i/7e2, s = 1. ; s < 1e3 ; s += s )
            e += cos( dot(  r = cos(p*s + t/20.), r.zyy ) ) / s;
    }
    glFragColor=o;
}