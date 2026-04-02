#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {
    
    float uTime = time;
    
    float x =  gl_FragCoord.x / resolution.x;
    float y =  gl_FragCoord.y / resolution.y;
    
    x *= 10.0+sin(uTime);
    x -= 5.0;
    
    float color1 = 0.1-abs(sin(uTime+1.0*3.1415*y)-x-1.0)*1.0;
    float color2 = 0.1-abs(sin(uTime+1.0*3.1415+y)-x-0.5)*1.0;
    float color3 = 0.1-abs(sin(uTime+1.0*3.1415*y)-x-0.0)*1.0;
    float color4 = 0.1-abs(sin(uTime+1.0*3.1415+y)-x+0.5)*1.0;
    float color5 = 0.1-abs(sin(uTime+1.0*3.1415*y)-x+1.0)*1.0;
    float color6 = 0.1-abs(sin(uTime+1.0*3.1415+y)-x+1.5)*1.0;
    
    glFragColor = 1.0-vec4( (vec3( color1, color2, color3 ) * 
                        vec3( color4, color5, color6)), 1.0 );
}
