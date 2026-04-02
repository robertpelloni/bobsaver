#version 420

// original https://www.shadertoy.com/view/XtcSRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// This shows the multiplication table modulo 200 represented as lines connecting points
//    on the unit circle, as explained in the Mathologer video https://www.youtube.com/watch?v=qhbuKbxJsk8
//
// I also inverted the positions outside the unit disk to reflect the inside so the look
//    is even more interesting :D
//
// EDIT: Fixed smoothstep not working with singularity when start and end angles are both 0 (obviously gave a 0/0 NaN)
//
const float    TWOPI = 6.283185307179586476925286766559;
    
const float    MODULO = 200.0;    // Amount of subdivisions of the circle

vec3 ComputeInnerColor( vec2 _uv, float _mul ) {

    float    isOnLine = 0.0;
    
    vec2    scStart, scEnd;

    // Compute start and end anglse based on multiplier
    float    dStartAngle = TWOPI / MODULO;
    float    dEndAngle = _mul * dStartAngle;
    float    startAngle = dStartAngle;
    float    endAngle = dEndAngle;

    for ( float i=1.0; i < MODULO; i++ ) {
        // Compute start and end position on the unit circle, forming a line
        scStart.x = sin( startAngle );
        scStart.y = cos( startAngle );
        scEnd.x = sin( endAngle );
        scEnd.y = cos( endAngle );
        
        // Compute line normal
        vec2    normal = normalize( vec2( scEnd.y - scStart.y, scStart.x - scEnd.x ) );
        
        // Compute distance to line
        vec2    delta = _uv - scStart;
        float    orthoDistance = abs( dot( delta, normal ) );
        
        // Check if the current position is on the line or not
        isOnLine += smoothstep( 0.005, 0.0, orthoDistance );
        
        startAngle += dStartAngle;
        endAngle += dEndAngle;
    }

    return vec3( 1.0 - clamp( isOnLine, 0.0, 1.0 ) );
}

void main(void) {
    vec2    R = resolution.xy;
    vec2    uv = ( 2. * gl_FragCoord.xy - R ) / R.y;
    
uv *= 2.0 + sin( time );
    
    float    mul = 1.0 + 99.0 * (1.0 - cos( 0.02 * time ));

    float    radius = length( uv );
//    float    D = radius < 1. ? 1. :  1. / (radius * radius);
    float    D = mix( 1.0, 1.0 / (radius*radius), smoothstep( 0.95, 1.0, radius ) );    // Smoother joint between regular and reciprocal space
    glFragColor = vec4( ComputeInnerColor( D*uv, mul ), 1.0 );
}

