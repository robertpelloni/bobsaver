#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159
#define TWO_PI (PI*2.0)
#define N 17.0

void main( void ) {

    vec2 position = ( gl_FragCoord.xy) * 1.0;// * resolution;

    float r = 0.0, g = 0.0, b = 0.0;
    
    for(float i = 0.0; i < N; i++) {
          float a = i * (TWO_PI/N) *(time+200.0)*0.02;
        r+= cos( ((position.x-resolution.x/2.0) * cos(a) + (position.y-resolution.y/2.0) * sin(a) + time*1.0) * 0.2);
        g+= cos( ((position.x-2.0-resolution.x/2.0) * cos(a) + (position.y-resolution.y/2.0) * sin(a) + time*1.1) * 0.21);
        b+= cos( ((position.x-20.0-resolution.x/2.0) * cos(a) + (position.y-resolution.y/2.0) * sin(a) + time*1.2) * 0.22);
    }
    
    float d = 0.8;
    r/= N*d; g/= N*d; b/= N*0.5;
    //color = position.x *cos(time);
    glFragColor = vec4( vec3( b, g, r), 1.0 );

}
