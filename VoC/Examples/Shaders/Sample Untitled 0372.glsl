#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {

    vec2 p = ( gl_FragCoord.xy / resolution.xy );
    p = 2.0 * p - 1.0;
    p.x *= resolution.x / resolution.y;
    p*=0.07;
    float color = 0.0;

    float dp = length(p);
    float a = atan(p.y,p.x);
    vec2 q = mod(sin(p * 3.141592 * 2.0) - 0.5, 1.0) - 0.5;
    
    vec2 r = mod(cos(q * 15.0+(vec2(sin(a*3.-time),cos(a*3.+time*0.3)))) - 0.5, 1.0) - 0.5;
    
    float dq = length(q);
    float dr = length(r);
    float w1 = sin(time*1.5 + 5.0 * dq * 3.141592) * 1. ;
    float w2 = cos(8.2 * dr * 3.141592*sin(dq*33. - dr*w1*1.3 + w1*dp*3. + time*1.1)+time*4.) * 1. ;
    
    color = w1*dr - w2*dq + dp*dr*sin(time)*5.;

    //glFragColor = vec4( vec3( -color*color*color*2., abs(color) * 0.5, sin( color + time / 3.0 ) * 0.75 ), 1.0 );
    
    vec3 c;
    
    c.r = color;
    c.g = color*(w1*dr*cos(w2*dq));
    c.b = c.g - (color-(w1-w2)*dq);
    
    
    glFragColor = vec4( c, 1.0 );
}
