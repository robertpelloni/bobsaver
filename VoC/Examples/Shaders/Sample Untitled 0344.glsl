#version 420

//  Parameter space, search again by @dennishjorth.

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 compmul(vec2 a, vec2 b) {
    return vec2(a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x);
}

vec2 compdiv(vec2 a, vec2 b) {
    return vec2(a.x*b.x + a.y*b.y, - a.x*b.y + a.y*b.x)/(dot(b, b));
}

vec2 poly(vec2 a1) {
    vec2 a2 = compmul(a1, a1);
    vec2 a3 = compmul(a2, a1);
    vec2 a4 = compmul(a3, a1);
    vec2 a5 = compmul(a4, a1);
    return vec2(cos(a3.x), sin(a3.y));
}

vec2 poly_derivative(vec2 a1) {
    vec2 a2 = compmul(a1, a1);
    vec2 a3 = compmul(a2, a1);
    vec2 a4 = compmul(a3, a1);
    vec2 a5 = compmul(a4, a1);
    return a2;
}

void main( void ) {
    // constant definition
    float pi = 3.1415926535897932384626433832795;
    float scale = 5.6+cos(sin(time*0.9)+time*0.3)*4.0;
    //vec2 delta = (mouse - vec2(0.5, 0.5));
    vec2 delta;
    delta.x = cos(time*1.9)*(0.01+cos(time*0.4)*0.05);
    delta.y = sin(time*1.9)*(0.01+cos(time*0.4)*0.05);
    
    // Newton's method
    vec2 position = (( gl_FragCoord.xy / resolution.y ) - vec2(0.5*(resolution.x/resolution.y), 0.5))*vec2(scale,scale);
    vec2 val = position;
    
    for (int i = 0; i < 50; i++) {
        val = val - compmul(delta, compdiv(poly(val),poly_derivative(val)));
    }
    
    // calculate color
    vec2 col = (vec2(atan(val.x), atan(val.y)) + (pi / 2.0)) / pi;
    
    if (col.x < 0.0 || col.y < 0.0) {
        col = vec2(0,0);
    }
    
    // output
    glFragColor = vec4( 1.0-col.x-col.y*0.2, col.y-col.x*0.3, col.x-col.y, 1.0 );
}
