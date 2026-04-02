#version 420

/*
CREDITS: /u/slackermanz
https://github.com/SyntheticSearchSpace/WebGL-Automata
*/

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

uniform sampler2D backbuffer;

out vec4 glFragColor;

float getR(vec2 offset) {
    return (texture2D(backbuffer, (gl_FragCoord.xy + offset) / resolution).r);
}

float getG(vec2 offset) {
    return (texture2D(backbuffer, (gl_FragCoord.xy + offset) / resolution).g);
}

float getB(vec2 offset) {
    return (texture2D(backbuffer, (gl_FragCoord.xy + offset) / resolution).b);
}

float checkR(vec2 offset) {
    if ((texture2D(backbuffer, (gl_FragCoord.xy + offset) / resolution).r) > 0.0) {return 1.0;}
    else {return 0.0;}
}

float checkG(vec2 offset) {
    if ((texture2D(backbuffer, (gl_FragCoord.xy + offset) / resolution).g) > 0.0) {return 1.0;}
    else {return 0.0;}
}

float checkB(vec2 offset) {
    if ((texture2D(backbuffer, (gl_FragCoord.xy + offset) / resolution).b) > 0.0) {return 1.0;}
    else {return 0.0;}
}

#define mousetreshold 5.0
vec2 scaledmouse = mouse * resolution;

bool check_mouse(){
    return gl_FragCoord.x > scaledmouse.x - mousetreshold &&
        gl_FragCoord.x < scaledmouse.x + mousetreshold &&
        gl_FragCoord.y > scaledmouse.y - mousetreshold &&
        gl_FragCoord.y < scaledmouse.y + mousetreshold;
}

void main() {
    if(check_mouse()){
        glFragColor = vec4(1.0);
        return;
    }

    //Set the default values

    float cR = getR(vec2(0.0, 0.0));
    float cG = getG(vec2(0.0, 0.0));
    float cB = getB(vec2(0.0, 0.0));

    glFragColor = vec4(cR, cR, cR, 1.0);

    //Sum the values of the Red Channel for
    //each of the neighbourhood coordinate groups
