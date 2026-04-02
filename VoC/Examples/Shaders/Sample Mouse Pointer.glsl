#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void mousepointer( void ){
    vec2 r = ( gl_FragCoord.xy / resolution.xy );
    vec2 d = r-mouse;
    if(d.x > 0. && d.y < -d.x*1.5){
        glFragColor = vec4(1);
        float s = length(d);
        float t = atan(d.x, d.y);
        if(s > 0.027) glFragColor = vec4(0);
        if(s > 0.02 && (t > 2.93 || t < 2.78)){
            glFragColor = vec4(0);
        }
    }
}

void main( void ) {
    glFragColor = vec4(0);
    mousepointer();
}
