#version 420

// original https://www.shadertoy.com/view/fdjfDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI radians(180.0)
#define TAU (PI*2.0)
const int CHARACTERS[14] = int[14](31599,9362,31183,31207,23524,29671,29679,30994,31727,31719,1488,448,2,3640); float digitIsOn( int digit, vec2 id ) { if ( id.x < .0 || id.y < .0 || id.x > 2. || id.y > 4. ) return .0; return floor( mod( float( CHARACTERS[ int( digit ) ] ) / pow( 2., id.x + id.y * 3. ), 2. ) ); } float digitSign( float v, vec2 id ) { return digitIsOn( 10 - int( ( sign( v ) - 1. ) * .5 ), id ); } int digitCount( float v ) { return int( floor( log( max( v, 1. ) ) / log( 10. ) ) ); } float digitFirst( vec2 uv, float scale, float v, int decimalPlaces ) { vec2 id = floor( uv * scale ); if ( .0 < digitSign( v, id ) ) return 1.; v = abs( v ); int digits = digitCount( v ); float power = pow( 10., float( digits ) ); float offset = floor( .1 * scale ); id.x -= offset; float n; for ( int i = 0 ; i < 33 ; i++, id.x -= offset, v -= power * n, power /= 10. ) { n = floor( v / power ); if ( .0 < digitIsOn( int( n ), id ) ) return 1.; if ( i == digits ) { id.x -= offset; if ( .0 < digitIsOn( int( 12 ), id ) ) return 1.; } if ( i >= digits + decimalPlaces ) return .0; } return .0; } float digitFirst( vec2 uv, float scale, float v ) { return digitFirst( uv, scale, v, 3 ); } vec3 digitIn( vec3 color, vec3 fontColor, vec2 uv, float scale, float v ) { float f = digitFirst( uv, scale, v ); return mix( color, fontColor, f ); } vec3 digitIn( vec3 color, vec2 uv, float scale, float v ) { return digitIn( color, vec3(1.), uv, scale, v ); } 
void main(void)
{
    vec2 m = vec2((mouse*resolution.xy.xy-0.5*resolution.xy)*2.0/resolution.y);
    float t = time/360.0-.55; // arc radian from mouse or time
    float n = (cos(t) > 0.0) ? sin(t): 1.0/sin(t); // arc to sin/csc
    float zoom = clamp(pow(500.0, n), 1e-17, 1e+17);
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y*TAU*zoom;
    float a = atan(uv.x, -uv.y); // screen arc radian
    float i = a/TAU; // arc to range between +/-0.5 used as increment
    float r = pow(length(uv)/PI, 0.5/n)-i; // spiral radius (archimedean at 0.5)
    float cr = ceil(r);
    float ls = time*TAU; // light animation speed
    float vd = (cr*TAU+a) / (n*2.0); // visual denominator
    float wr = cr+i; // winding ratio
    vec3 col = vec3(sin(vd*wr+ls)); // blend it
    col *= pow(sin(fract(r)*PI), floor(abs(n*2.0))+5.0); // smooth edges
    col *= sin(vd*2.0*wr+PI/2.0+ls*2.0); // this looks nice
    col *= 0.2+abs(cos(vd*2.0)); // dark spirals
    vec3 g = mix(vec3(0), vec3(1), pow(length(uv)*2.0/TAU/zoom, -1.0/n)); // dark gradient
    col = min(col, g); // blend gradient with spiral
    vec3 rgb = vec3( cos(vd*2.0)+1.0, abs(sin(t)), cos(PI+vd*2.0)+1.0 );
    col += (col*2.0)-(rgb*0.4); // add color
    glFragColor = vec4(col, 1.0);
}
