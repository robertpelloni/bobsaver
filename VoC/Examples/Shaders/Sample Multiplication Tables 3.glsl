#version 420

// original https://www.shadertoy.com/view/WlsSRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int pointsCount = 99;
float radius    = .45;
const float thickness = .0005;
float timesTableSubject = 1.;
const float colorIntensity = 2.;
const float TAU = 6.28318530718;
const float speed = .8;

float Circle( in vec2 c, in float r ) {
    return length( c ) - r;
}

float Union( in float a, in float b ) {
    return min( a, b );
}

float sdLine( in vec2 p, in vec2 a, in vec2 b ) {
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

void main(void) {
    vec2 uv     = gl_FragCoord.xy / resolution.xy;    
    vec2 center = ( uv - .5 );
    float angle = TAU / float( pointsCount );
    
    timesTableSubject += time * speed;
    
    center.x *= resolution.x / resolution.y;   
    
    radius += abs(sin(time)) * .05;
    float sdf = Circle( center, radius );
    sdf       = abs( sdf ) - thickness;
    
    for( int i = 0; i < pointsCount; i++ ) {
        vec2 sPoint = vec2( cos( angle * float(i) ) * radius + center.x, sin( angle * float(i) ) * radius + center.y );
        int targetPointIndex = int( mod( ( float( i + 1 ) ) * timesTableSubject, float( pointsCount ) ) );
        vec2 tPoint = vec2( cos( angle * float(targetPointIndex) ) * radius + center.x, sin( angle * float(targetPointIndex) ) * radius + center.y );
        sdf = Union( sdf, sdLine( vec2(0.,0.), sPoint, tPoint) );
    }
    
    float pulseCircle = abs( Circle(center, fract(time*.8))) - thickness;
    sdf = min(sdf, pulseCircle);
    sdf = smoothstep(0.005, 0.0, sdf);
    float bg = sin(Circle(center,radius));
    bg = min(bg, sin(bg*130.*sin(time)));
    sdf = max(bg, sdf);
    
    glFragColor = vec4( vec3( sin(time)*.5+.5,sin(time+TAU/3.)*.5+.5,sin(time+TAU*2./3.)*.5+.5) * sdf * colorIntensity, 1 );
}
