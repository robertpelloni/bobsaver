#version 420

// original https://www.shadertoy.com/view/ttfcDl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdCircle( in vec2 p, in float r ) 
{
    return length(p)-r;
}

float ndot(vec2 a, vec2 b ) { return a.x*b.x - a.y*b.y; }

float sdRhombus( in vec2 p, in vec2 b ) 
{
    vec2 q = abs(p);

    float h = clamp( (-2.0*ndot(q,b) + ndot(b,b) )/dot(b,b), -1.0, 1.0 );
    float d = length( q - 0.5*b*vec2(1.0-h,1.0+h) );
    d *= sign( q.x*b.y + q.y*b.x - b.x*b.y );
    
    return d;
}

// sca is the sin/cos of the orientation
// scb is the sin/cos of the aperture
float sdArc( in vec2 p, in vec2 sca, in vec2 scb, in float ra, in float rb )
{
    p *= mat2(sca.x,sca.y,-sca.y,sca.x);
    p.x = abs(p.x);
    float k = (scb.y*p.x>scb.x*p.y) ? dot(p.xy,scb) : length(p.xy);
    return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

#define PI 3.1415926
float sdHeart(in vec2 p, in float radius) {
    float offset = 3.0-2.0*sqrt(2.0);
    float extra = 0.05;
    vec2 center = vec2(0.0, offset+extra);
    float r = 1.0-center.y;
    
    // Construct the heart in normalized coordinates where radius of inner circle is 1.0
    vec2 _p = (p/radius)*r+center;
    
    float br = sqrt(2.0)/2.0;
    float d = sdRhombus( _p, vec2(1.0) );
    float dc1 = sdCircle( _p-vec2(0.5, 0.5), br );
    float dc2 = sdCircle( _p-vec2(-0.5, 0.5), br );

/*
    if(dc1 < 0.0 && d < 0.0)
        d = min(d, -sdArc(_p-vec2(0.5, 0.5), vec2(sin(3.0*PI/4.0), cos(3.0*PI/4.0)), vec2(sin(PI/2.0), cos(PI/2.0)), br, 0.0));
    else
        d = min(d, dc1);
                      
    if(dc2 < 0.0 && d < 0.0)
        d = min(d, -sdArc(_p-vec2(-0.5, 0.5), vec2(sin(PI/4.0), cos(PI/4.0)), vec2(sin(PI/2.0), cos(PI/2.0)), br, 0.0));
    else
        d = min(d, dc2);
*/

    d = min(min(d,dc1),dc2);
    if(_p.y < 0.0) d += 1.5*abs(_p.x)*abs(_p.y)*abs(_p.y)*r*r
        ; // pull the sides of the heart inward

    // Fix scaling
    return d*radius/r;
}

void main(void)
{
    vec2 p = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    p /= 0.75;
    
    float radius = 0.7 + 0.1*sin(10.0*time);
    float d = sdHeart(p, radius);
    
    vec3 col = sign(-d)*vec3(1.0,0.0,0.0);
    col = mix( col, vec3(1.0), 1.0-smoothstep(0.0,0.010,abs(d)));

    //col = mix( col, vec3(1.0), 1.0-smoothstep(0.0,0.010,abs(sdCircle(p, 0.01))));
    //col = mix( col, vec3(1.0), 1.0-smoothstep(0.0,0.010,abs(sdCircle(p, radius))));
    //col *= 0.8 + 0.2*cos(128.0*abs(d));

    glFragColor = vec4(col,1.0);
}
