#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

int siBinar(int a,int b) { 
    if (a < 0) a = -1-a;
    if (b < 0) b = -1-b;
    int result = int((1.-abs(1.-mod(float(a),2.)))*(1.-abs(1.-mod(float(b),2.))));
    for (int i = 0;i < 12;i++) {
        a /= 2;
        b /= 2;
        result += int((1.-abs(1.-mod(float(a),2.0)))*(1.-abs(1.-mod(float(b),2.0))))*2;
    }

    return result;
}

void main( void ) {

    vec2 position = gl_FragCoord.xy;
    position -= resolution*.5;
    float t = time*.1;
    position *= mat2(cos(t),-sin(t),sin(t),cos(t));
    
    position *= pow(2.,1.-fract(time));

    
    float color = 0.0;

    int bin = siBinar(int(floor(position.x)),int(floor(position.y)));
    if (bin == 0) {
        color = 1.0;
    } else if (bin == 1) {
        color = 1.-fract(time);
    } 
    glFragColor = vec4( color,color,color, 1.0 );

}
