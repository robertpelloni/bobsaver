#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {

    vec2 position = gl_FragCoord.xy;
    float x = position.x;
    float y = position.y;
    
    float r=-1., g=-1., b=-1.;
    
    r = sin(x/40. + time + sin(y/40.)) * sin(y/25. + time + sin(x/20. - time)); // it's an rob plasma!
    g = sin(x/80. - time + sin(y/20.)) * sin(y/50. - time + sin(x/40. + time));
    b = sin(x/60. + time + sin(y/30.)) * sin(y/25. + time + sin(x/40. - time));
    
    //r = sin(x/8.) * sin(time);
    vec3 rgb = vec3(r,g,b)*.5+.5;
    rgb = floor(rgb*5.)/5.;
    //rgb.gb *= 0.;
    glFragColor = vec4(rgb, 1.);

}
