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
    float s0 =
        getR(vec2(-14.0, -1.0)) +
        getR(vec2(-14.0, 0.0)) +
        getR(vec2(-14.0, 1.0)) +
        getR(vec2(-13.0, -4.0)) +
        getR(vec2(-13.0, -3.0)) +
        getR(vec2(-13.0, -2.0)) +
        getR(vec2(-13.0, 2.0)) +
        getR(vec2(-13.0, 3.0)) +
        getR(vec2(-13.0, 4.0)) +
        getR(vec2(-12.0, -6.0)) +
        getR(vec2(-12.0, -5.0)) +
        getR(vec2(-12.0, 5.0)) +
        getR(vec2(-12.0, 6.0)) +
        getR(vec2(-11.0, -8.0)) +
        getR(vec2(-11.0, -7.0)) +
        getR(vec2(-11.0, 7.0)) +
        getR(vec2(-11.0, 8.0)) +
        getR(vec2(-10.0, -9.0)) +
        getR(vec2(-10.0, -1.0)) +
        getR(vec2(-10.0, 0.0)) +
        getR(vec2(-10.0, 1.0)) +
        getR(vec2(-10.0, 9.0)) +
        getR(vec2(-9.0, -10.0)) +
        getR(vec2(-9.0, -4.0)) +
        getR(vec2(-9.0, -3.0)) +
        getR(vec2(-9.0, -2.0)) +
        getR(vec2(-9.0, 2.0)) +
        getR(vec2(-9.0, 3.0)) +
        getR(vec2(-9.0, 4.0)) +
        getR(vec2(-9.0, 10.0)) +
        getR(vec2(-8.0, -11.0)) +
        getR(vec2(-8.0, -6.0)) +
        getR(vec2(-8.0, -5.0)) +
        getR(vec2(-8.0, 5.0)) +
        getR(vec2(-8.0, 6.0)) +
        getR(vec2(-8.0, 11.0)) +
        getR(vec2(-7.0, -11.0)) +
        getR(vec2(-7.0, -7.0)) +
        getR(vec2(-7.0, -2.0)) +
        getR(vec2(-7.0, -1.0)) +
        getR(vec2(-7.0, 0.0)) +
        getR(vec2(-7.0, 1.0)) +
        getR(vec2(-7.0, 2.0)) +
        getR(vec2(-7.0, 7.0)) +
        getR(vec2(-7.0, 11.0)) +
        getR(vec2(-6.0, -12.0)) +
        getR(vec2(-6.0, -8.0)) +
        getR(vec2(-6.0, -4.0)) +
        getR(vec2(-6.0, -3.0)) +
        getR(vec2(-6.0, 3.0)) +
        getR(vec2(-6.0, 4.0)) +
        getR(vec2(-6.0, 8.0)) +
        getR(vec2(-6.0, 12.0)) +
        getR(vec2(-5.0, -12.0)) +
        getR(vec2(-5.0, -8.0)) +
        getR(vec2(-5.0, -5.0)) +
        getR(vec2(-5.0, -1.0)) +
        getR(vec2(-5.0, 0.0)) +
        getR(vec2(-5.0, 1.0)) +
        getR(vec2(-5.0, 5.0)) +
        getR(vec2(-5.0, 8.0)) +
        getR(vec2(-5.0, 12.0)) +
        getR(vec2(-4.0, -13.0)) +
        getR(vec2(-4.0, -9.0)) +
        getR(vec2(-4.0, -6.0)) +
        getR(vec2(-4.0, -3.0)) +
        getR(vec2(-4.0, -2.0)) +
        getR(vec2(-4.0, 2.0)) +
        getR(vec2(-4.0, 3.0)) +
        getR(vec2(-4.0, 6.0)) +
        getR(vec2(-4.0, 9.0)) +
        getR(vec2(-4.0, 13.0)) +
        getR(vec2(-3.0, -13.0)) +
        getR(vec2(-3.0, -9.0)) +
        getR(vec2(-3.0, -6.0)) +
        getR(vec2(-3.0, -4.0)) +
        getR(vec2(-3.0, -1.0)) +
        getR(vec2(-3.0, 0.0)) +
        getR(vec2(-3.0, 1.0)) +
        getR(vec2(-3.0, 4.0)) +
        getR(vec2(-3.0, 6.0)) +
        getR(vec2(-3.0, 9.0)) +
        getR(vec2(-3.0, 13.0)) +
        getR(vec2(-2.0, -13.0)) +
        getR(vec2(-2.0, -9.0)) +
        getR(vec2(-2.0, -7.0)) +
        getR(vec2(-2.0, -4.0)) +
        getR(vec2(-2.0, -2.0)) +
        getR(vec2(-2.0, 2.0)) +
        getR(vec2(-2.0, 4.0)) +
        getR(vec2(-2.0, 7.0)) +
        getR(vec2(-2.0, 9.0)) +
        getR(vec2(-2.0, 13.0)) +
        getR(vec2(-1.0, -14.0)) +
        getR(vec2(-1.0, -10.0)) +
        getR(vec2(-1.0, -7.0)) +
        getR(vec2(-1.0, -5.0)) +
        getR(vec2(-1.0, -3.0)) +
        getR(vec2(-1.0, -1.0)) +
        getR(vec2(-1.0, 0.0)) +
        getR(vec2(-1.0, 1.0)) +
        getR(vec2(-1.0, 3.0)) +
        getR(vec2(-1.0, 5.0)) +
        getR(vec2(-1.0, 7.0)) +
        getR(vec2(-1.0, 10.0)) +
        getR(vec2(-1.0, 14.0)) +
        getR(vec2(0.0, -14.0)) +
        getR(vec2(0.0, -10.0)) +
        getR(vec2(0.0, -7.0)) +
        getR(vec2(0.0, -5.0)) +
        getR(vec2(0.0, -3.0)) +
        getR(vec2(0.0, -1.0)) +
        getR(vec2(0.0, 0.0)) +
        getR(vec2(0.0, 1.0)) +
        getR(vec2(0.0, 3.0)) +
        getR(vec2(0.0, 5.0)) +
        getR(vec2(0.0, 7.0)) +
        getR(vec2(0.0, 10.0)) +
        getR(vec2(0.0, 14.0)) +
        getR(vec2(1.0, -14.0)) +
        getR(vec2(1.0, -10.0)) +
        getR(vec2(1.0, -7.0)) +
        getR(vec2(1.0, -5.0)) +
        getR(vec2(1.0, -3.0)) +
        getR(vec2(1.0, -1.0)) +
        getR(vec2(1.0, 0.0)) +
        getR(vec2(1.0, 1.0)) +
        getR(vec2(1.0, 3.0)) +
        getR(vec2(1.0, 5.0)) +
        getR(vec2(1.0, 7.0)) +
        getR(vec2(1.0, 10.0)) +
        getR(vec2(1.0, 14.0)) +
        getR(vec2(2.0, -13.0)) +
        getR(vec2(2.0, -9.0)) +
        getR(vec2(2.0, -7.0)) +
        getR(vec2(2.0, -4.0)) +
        getR(vec2(2.0, -2.0)) +
        getR(vec2(2.0, 2.0)) +
        getR(vec2(2.0, 4.0)) +
        getR(vec2(2.0, 7.0)) +
        getR(vec2(2.0, 9.0)) +
        getR(vec2(2.0, 13.0)) +
        getR(vec2(3.0, -13.0)) +
        getR(vec2(3.0, -9.0)) +
        getR(vec2(3.0, -6.0)) +
        getR(vec2(3.0, -4.0)) +
        getR(vec2(3.0, -1.0)) +
        getR(vec2(3.0, 0.0)) +
        getR(vec2(3.0, 1.0)) +
        getR(vec2(3.0, 4.0)) +
        getR(vec2(3.0, 6.0)) +
        getR(vec2(3.0, 9.0)) +
        getR(vec2(3.0, 13.0)) +
        getR(vec2(4.0, -13.0)) +
        getR(vec2(4.0, -9.0)) +
        getR(vec2(4.0, -6.0)) +
        getR(vec2(4.0, -3.0)) +
        getR(vec2(4.0, -2.0)) +
        getR(vec2(4.0, 2.0)) +
        getR(vec2(4.0, 3.0)) +
        getR(vec2(4.0, 6.0)) +
        getR(vec2(4.0, 9.0)) +
        getR(vec2(4.0, 13.0)) +
        getR(vec2(5.0, -12.0)) +
        getR(vec2(5.0, -8.0)) +
        getR(vec2(5.0, -5.0)) +
        getR(vec2(5.0, -1.0)) +
        getR(vec2(5.0, 0.0)) +
        getR(vec2(5.0, 1.0)) +
        getR(vec2(5.0, 5.0)) +
        getR(vec2(5.0, 8.0)) +
        getR(vec2(5.0, 12.0)) +
        getR(vec2(6.0, -12.0)) +
        getR(vec2(6.0, -8.0)) +
        getR(vec2(6.0, -4.0)) +
        getR(vec2(6.0, -3.0)) +
        getR(vec2(6.0, 3.0)) +
        getR(vec2(6.0, 4.0)) +
        getR(vec2(6.0, 8.0)) +
        getR(vec2(6.0, 12.0)) +
        getR(vec2(7.0, -11.0)) +
        getR(vec2(7.0, -7.0)) +
        getR(vec2(7.0, -2.0)) +
        getR(vec2(7.0, -1.0)) +
        getR(vec2(7.0, 0.0)) +
        getR(vec2(7.0, 1.0)) +
        getR(vec2(7.0, 2.0)) +
        getR(vec2(7.0, 7.0)) +
        getR(vec2(7.0, 11.0)) +
        getR(vec2(8.0, -11.0)) +
        getR(vec2(8.0, -6.0)) +
        getR(vec2(8.0, -5.0)) +
        getR(vec2(8.0, 5.0)) +
        getR(vec2(8.0, 6.0)) +
        getR(vec2(8.0, 11.0)) +
        getR(vec2(9.0, -10.0)) +
        getR(vec2(9.0, -4.0)) +
        getR(vec2(9.0, -3.0)) +
        getR(vec2(9.0, -2.0)) +
        getR(vec2(9.0, 2.0)) +
        getR(vec2(9.0, 3.0)) +
        getR(vec2(9.0, 4.0)) +
        getR(vec2(9.0, 10.0)) +
        getR(vec2(10.0, -9.0)) +
        getR(vec2(10.0, -1.0)) +
        getR(vec2(10.0, 0.0)) +
        getR(vec2(10.0, 1.0)) +
        getR(vec2(10.0, 9.0)) +
        getR(vec2(11.0, -8.0)) +
        getR(vec2(11.0, -7.0)) +
        getR(vec2(11.0, 7.0)) +
        getR(vec2(11.0, 8.0)) +
        getR(vec2(12.0, -6.0)) +
        getR(vec2(12.0, -5.0)) +
        getR(vec2(12.0, 5.0)) +
        getR(vec2(12.0, 6.0)) +
        getR(vec2(13.0, -4.0)) +
        getR(vec2(13.0, -3.0)) +
        getR(vec2(13.0, -2.0)) +
        getR(vec2(13.0, 2.0)) +
        getR(vec2(13.0, 3.0)) +
        getR(vec2(13.0, 4.0)) +
        getR(vec2(14.0, -1.0)) +
        getR(vec2(14.0, 0.0)) +
        getR(vec2(14.0, 1.0)) ;
    float s1 =
        getR(vec2(-3.0, -1.0)) +
        getR(vec2(-3.0, 0.0)) +
        getR(vec2(-3.0, 1.0)) +
        getR(vec2(-2.0, -2.0)) +
        getR(vec2(-2.0, 2.0)) +
        getR(vec2(-1.0, -3.0)) +
        getR(vec2(-1.0, -1.0)) +
        getR(vec2(-1.0, 0.0)) +
        getR(vec2(-1.0, 1.0)) +
        getR(vec2(-1.0, 3.0)) +
        getR(vec2(0.0, -3.0)) +
        getR(vec2(0.0, -1.0)) +
        getR(vec2(0.0, 1.0)) +
        getR(vec2(0.0, 3.0)) +
        getR(vec2(1.0, -3.0)) +
        getR(vec2(1.0, -1.0)) +
        getR(vec2(1.0, 0.0)) +
        getR(vec2(1.0, 1.0)) +
        getR(vec2(1.0, 3.0)) +
        getR(vec2(2.0, -2.0)) +
        getR(vec2(2.0, 2.0)) +
        getR(vec2(3.0, -1.0)) +
        getR(vec2(3.0, 0.0)) +
        getR(vec2(3.0, 1.0)) ;
    float s2 =
        getR(vec2(-6.0, -1.0)) +
        getR(vec2(-6.0, 0.0)) +
        getR(vec2(-6.0, 1.0)) +
        getR(vec2(-5.0, -3.0)) +
        getR(vec2(-5.0, -2.0)) +
        getR(vec2(-5.0, -1.0)) +
        getR(vec2(-5.0, 0.0)) +
        getR(vec2(-5.0, 1.0)) +
        getR(vec2(-5.0, 2.0)) +
        getR(vec2(-5.0, 3.0)) +
        getR(vec2(-4.0, -4.0)) +
        getR(vec2(-4.0, -3.0)) +
        getR(vec2(-4.0, -2.0)) +
        getR(vec2(-4.0, -1.0)) +
        getR(vec2(-4.0, 0.0)) +
        getR(vec2(-4.0, 1.0)) +
        getR(vec2(-4.0, 2.0)) +
        getR(vec2(-4.0, 3.0)) +
        getR(vec2(-4.0, 4.0)) +
        getR(vec2(-3.0, -5.0)) +
        getR(vec2(-3.0, -4.0)) +
        getR(vec2(-3.0, -3.0)) +
        getR(vec2(-3.0, -2.0)) +
        getR(vec2(-3.0, 2.0)) +
        getR(vec2(-3.0, 3.0)) +
        getR(vec2(-3.0, 4.0)) +
        getR(vec2(-3.0, 5.0)) +
        getR(vec2(-2.0, -5.0)) +
        getR(vec2(-2.0, -4.0)) +
        getR(vec2(-2.0, -3.0)) +
        getR(vec2(-2.0, 3.0)) +
        getR(vec2(-2.0, 4.0)) +
        getR(vec2(-2.0, 5.0)) +
        getR(vec2(-1.0, -6.0)) +
        getR(vec2(-1.0, -5.0)) +
        getR(vec2(-1.0, -4.0)) +
        getR(vec2(-1.0, 4.0)) +
        getR(vec2(-1.0, 5.0)) +
        getR(vec2(-1.0, 6.0)) +
        getR(vec2(0.0, -6.0)) +
        getR(vec2(0.0, -5.0)) +
        getR(vec2(0.0, -4.0)) +
        getR(vec2(0.0, 4.0)) +
        getR(vec2(0.0, 5.0)) +
        getR(vec2(0.0, 6.0)) +
        getR(vec2(1.0, -6.0)) +
        getR(vec2(1.0, -5.0)) +
        getR(vec2(1.0, -4.0)) +
        getR(vec2(1.0, 4.0)) +
        getR(vec2(1.0, 5.0)) +
        getR(vec2(1.0, 6.0)) +
        getR(vec2(2.0, -5.0)) +
        getR(vec2(2.0, -4.0)) +
        getR(vec2(2.0, -3.0)) +
        getR(vec2(2.0, 3.0)) +
        getR(vec2(2.0, 4.0)) +
        getR(vec2(2.0, 5.0)) +
        getR(vec2(3.0, -5.0)) +
        getR(vec2(3.0, -4.0)) +
        getR(vec2(3.0, -3.0)) +
        getR(vec2(3.0, -2.0)) +
        getR(vec2(3.0, 2.0)) +
        getR(vec2(3.0, 3.0)) +
        getR(vec2(3.0, 4.0)) +
        getR(vec2(3.0, 5.0)) +
        getR(vec2(4.0, -4.0)) +
        getR(vec2(4.0, -3.0)) +
        getR(vec2(4.0, -2.0)) +
        getR(vec2(4.0, -1.0)) +
        getR(vec2(4.0, 0.0)) +
        getR(vec2(4.0, 1.0)) +
        getR(vec2(4.0, 2.0)) +
        getR(vec2(4.0, 3.0)) +
        getR(vec2(4.0, 4.0)) +
        getR(vec2(5.0, -3.0)) +
        getR(vec2(5.0, -2.0)) +
        getR(vec2(5.0, -1.0)) +
        getR(vec2(5.0, 0.0)) +
        getR(vec2(5.0, 1.0)) +
        getR(vec2(5.0, 2.0)) +
        getR(vec2(5.0, 3.0)) +
        getR(vec2(6.0, -1.0)) +
        getR(vec2(6.0, 0.0)) +
        getR(vec2(6.0, 1.0)) ;
    float s3 =
        getR(vec2(-14.0, -3.0)) +
        getR(vec2(-14.0, -2.0)) +
        getR(vec2(-14.0, -1.0)) +
        getR(vec2(-14.0, 0.0)) +
        getR(vec2(-14.0, 1.0)) +
        getR(vec2(-14.0, 2.0)) +
        getR(vec2(-14.0, 3.0)) +
        getR(vec2(-13.0, -6.0)) +
        getR(vec2(-13.0, -5.0)) +
        getR(vec2(-13.0, -4.0)) +
        getR(vec2(-13.0, -3.0)) +
        getR(vec2(-13.0, -2.0)) +
        getR(vec2(-13.0, -1.0)) +
        getR(vec2(-13.0, 0.0)) +
        getR(vec2(-13.0, 1.0)) +
        getR(vec2(-13.0, 2.0)) +
        getR(vec2(-13.0, 3.0)) +
        getR(vec2(-13.0, 4.0)) +
        getR(vec2(-13.0, 5.0)) +
        getR(vec2(-13.0, 6.0)) +
        getR(vec2(-12.0, -8.0)) +
        getR(vec2(-12.0, -7.0)) +
        getR(vec2(-12.0, -6.0)) +
        getR(vec2(-12.0, -5.0)) +
        getR(vec2(-12.0, -4.0)) +
        getR(vec2(-12.0, -3.0)) +
        getR(vec2(-12.0, -2.0)) +
        getR(vec2(-12.0, -1.0)) +
        getR(vec2(-12.0, 0.0)) +
        getR(vec2(-12.0, 1.0)) +
        getR(vec2(-12.0, 2.0)) +
        getR(vec2(-12.0, 3.0)) +
        getR(vec2(-12.0, 4.0)) +
        getR(vec2(-12.0, 5.0)) +
        getR(vec2(-12.0, 6.0)) +
        getR(vec2(-12.0, 7.0)) +
        getR(vec2(-12.0, 8.0)) +
        getR(vec2(-11.0, -9.0)) +
        getR(vec2(-11.0, -8.0)) +
        getR(vec2(-11.0, -7.0)) +
        getR(vec2(-11.0, -6.0)) +
        getR(vec2(-11.0, -5.0)) +
        getR(vec2(-11.0, -4.0)) +
        getR(vec2(-11.0, -3.0)) +
        getR(vec2(-11.0, -2.0)) +
        getR(vec2(-11.0, -1.0)) +
        getR(vec2(-11.0, 0.0)) +
        getR(vec2(-11.0, 1.0)) +
        getR(vec2(-11.0, 2.0)) +
        getR(vec2(-11.0, 3.0)) +
        getR(vec2(-11.0, 4.0)) +
        getR(vec2(-11.0, 5.0)) +
        getR(vec2(-11.0, 6.0)) +
        getR(vec2(-11.0, 7.0)) +
        getR(vec2(-11.0, 8.0)) +
        getR(vec2(-11.0, 9.0)) +
        getR(vec2(-10.0, -10.0)) +
        getR(vec2(-10.0, -9.0)) +
        getR(vec2(-10.0, -8.0)) +
        getR(vec2(-10.0, -7.0)) +
        getR(vec2(-10.0, -6.0)) +
        getR(vec2(-10.0, -5.0)) +
        getR(vec2(-10.0, 5.0)) +
        getR(vec2(-10.0, 6.0)) +
        getR(vec2(-10.0, 7.0)) +
        getR(vec2(-10.0, 8.0)) +
        getR(vec2(-10.0, 9.0)) +
        getR(vec2(-10.0, 10.0)) +
        getR(vec2(-9.0, -11.0)) +
        getR(vec2(-9.0, -10.0)) +
        getR(vec2(-9.0, -9.0)) +
        getR(vec2(-9.0, -8.0)) +
        getR(vec2(-9.0, -7.0)) +
        getR(vec2(-9.0, 7.0)) +
        getR(vec2(-9.0, 8.0)) +
        getR(vec2(-9.0, 9.0)) +
        getR(vec2(-9.0, 10.0)) +
        getR(vec2(-9.0, 11.0)) +
        getR(vec2(-8.0, -12.0)) +
        getR(vec2(-8.0, -11.0)) +
        getR(vec2(-8.0, -10.0)) +
        getR(vec2(-8.0, -9.0)) +
        getR(vec2(-8.0, -8.0)) +
        getR(vec2(-8.0, 8.0)) +
        getR(vec2(-8.0, 9.0)) +
        getR(vec2(-8.0, 10.0)) +
        getR(vec2(-8.0, 11.0)) +
        getR(vec2(-8.0, 12.0)) +
        getR(vec2(-7.0, -12.0)) +
        getR(vec2(-7.0, -11.0)) +
        getR(vec2(-7.0, -10.0)) +
        getR(vec2(-7.0, -9.0)) +
        getR(vec2(-7.0, -2.0)) +
        getR(vec2(-7.0, -1.0)) +
        getR(vec2(-7.0, 0.0)) +
        getR(vec2(-7.0, 1.0)) +
        getR(vec2(-7.0, 2.0)) +
        getR(vec2(-7.0, 9.0)) +
        getR(vec2(-7.0, 10.0)) +
        getR(vec2(-7.0, 11.0)) +
        getR(vec2(-7.0, 12.0)) +
        getR(vec2(-6.0, -13.0)) +
        getR(vec2(-6.0, -12.0)) +
        getR(vec2(-6.0, -11.0)) +
        getR(vec2(-6.0, -10.0)) +
        getR(vec2(-6.0, -4.0)) +
        getR(vec2(-6.0, -3.0)) +
        getR(vec2(-6.0, 3.0)) +
        getR(vec2(-6.0, 4.0)) +
        getR(vec2(-6.0, 10.0)) +
        getR(vec2(-6.0, 11.0)) +
        getR(vec2(-6.0, 12.0)) +
        getR(vec2(-6.0, 13.0)) +
        getR(vec2(-5.0, -13.0)) +
        getR(vec2(-5.0, -12.0)) +
        getR(vec2(-5.0, -11.0)) +
        getR(vec2(-5.0, -10.0)) +
        getR(vec2(-5.0, -5.0)) +
        getR(vec2(-5.0, 5.0)) +
        getR(vec2(-5.0, 10.0)) +
        getR(vec2(-5.0, 11.0)) +
        getR(vec2(-5.0, 12.0)) +
        getR(vec2(-5.0, 13.0)) +
        getR(vec2(-4.0, -13.0)) +
        getR(vec2(-4.0, -12.0)) +
        getR(vec2(-4.0, -11.0)) +
        getR(vec2(-4.0, -6.0)) +
        getR(vec2(-4.0, -1.0)) +
        getR(vec2(-4.0, 0.0)) +
        getR(vec2(-4.0, 1.0)) +
        getR(vec2(-4.0, 6.0)) +
        getR(vec2(-4.0, 11.0)) +
        getR(vec2(-4.0, 12.0)) +
        getR(vec2(-4.0, 13.0)) +
        getR(vec2(-3.0, -14.0)) +
        getR(vec2(-3.0, -13.0)) +
        getR(vec2(-3.0, -12.0)) +
        getR(vec2(-3.0, -11.0)) +
        getR(vec2(-3.0, -6.0)) +
        getR(vec2(-3.0, -2.0)) +
        getR(vec2(-3.0, 2.0)) +
        getR(vec2(-3.0, 6.0)) +
        getR(vec2(-3.0, 11.0)) +
        getR(vec2(-3.0, 12.0)) +
        getR(vec2(-3.0, 13.0)) +
        getR(vec2(-3.0, 14.0)) +
        getR(vec2(-2.0, -14.0)) +
        getR(vec2(-2.0, -13.0)) +
        getR(vec2(-2.0, -12.0)) +
        getR(vec2(-2.0, -11.0)) +
        getR(vec2(-2.0, -7.0)) +
        getR(vec2(-2.0, -3.0)) +
        getR(vec2(-2.0, 3.0)) +
        getR(vec2(-2.0, 7.0)) +
        getR(vec2(-2.0, 11.0)) +
        getR(vec2(-2.0, 12.0)) +
        getR(vec2(-2.0, 13.0)) +
        getR(vec2(-2.0, 14.0)) +
        getR(vec2(-1.0, -14.0)) +
        getR(vec2(-1.0, -13.0)) +
        getR(vec2(-1.0, -12.0)) +
        getR(vec2(-1.0, -11.0)) +
        getR(vec2(-1.0, -7.0)) +
        getR(vec2(-1.0, -4.0)) +
        getR(vec2(-1.0, -1.0)) +
        getR(vec2(-1.0, 0.0)) +
        getR(vec2(-1.0, 1.0)) +
        getR(vec2(-1.0, 4.0)) +
        getR(vec2(-1.0, 7.0)) +
        getR(vec2(-1.0, 11.0)) +
        getR(vec2(-1.0, 12.0)) +
        getR(vec2(-1.0, 13.0)) +
        getR(vec2(-1.0, 14.0)) +
        getR(vec2(0.0, -14.0)) +
        getR(vec2(0.0, -13.0)) +
        getR(vec2(0.0, -12.0)) +
        getR(vec2(0.0, -11.0)) +
        getR(vec2(0.0, -7.0)) +
        getR(vec2(0.0, -4.0)) +
        getR(vec2(0.0, -1.0)) +
        getR(vec2(0.0, 1.0)) +
        getR(vec2(0.0, 4.0)) +
        getR(vec2(0.0, 7.0)) +
        getR(vec2(0.0, 11.0)) +
        getR(vec2(0.0, 12.0)) +
        getR(vec2(0.0, 13.0)) +
        getR(vec2(0.0, 14.0)) +
        getR(vec2(1.0, -14.0)) +
        getR(vec2(1.0, -13.0)) +
        getR(vec2(1.0, -12.0)) +
        getR(vec2(1.0, -11.0)) +
        getR(vec2(1.0, -7.0)) +
        getR(vec2(1.0, -4.0)) +
        getR(vec2(1.0, -1.0)) +
        getR(vec2(1.0, 0.0)) +
        getR(vec2(1.0, 1.0)) +
        getR(vec2(1.0, 4.0)) +
        getR(vec2(1.0, 7.0)) +
        getR(vec2(1.0, 11.0)) +
        getR(vec2(1.0, 12.0)) +
        getR(vec2(1.0, 13.0)) +
        getR(vec2(1.0, 14.0)) +
        getR(vec2(2.0, -14.0)) +
        getR(vec2(2.0, -13.0)) +
        getR(vec2(2.0, -12.0)) +
        getR(vec2(2.0, -11.0)) +
        getR(vec2(2.0, -7.0)) +
        getR(vec2(2.0, -3.0)) +
        getR(vec2(2.0, 3.0)) +
        getR(vec2(2.0, 7.0)) +
        getR(vec2(2.0, 11.0)) +
        getR(vec2(2.0, 12.0)) +
        getR(vec2(2.0, 13.0)) +
        getR(vec2(2.0, 14.0)) +
        getR(vec2(3.0, -14.0)) +
        getR(vec2(3.0, -13.0)) +
        getR(vec2(3.0, -12.0)) +
        getR(vec2(3.0, -11.0)) +
        getR(vec2(3.0, -6.0)) +
        getR(vec2(3.0, -2.0)) +
        getR(vec2(3.0, 2.0)) +
        getR(vec2(3.0, 6.0)) +
        getR(vec2(3.0, 11.0)) +
        getR(vec2(3.0, 12.0)) +
        getR(vec2(3.0, 13.0)) +
        getR(vec2(3.0, 14.0)) +
        getR(vec2(4.0, -13.0)) +
        getR(vec2(4.0, -12.0)) +
        getR(vec2(4.0, -11.0)) +
        getR(vec2(4.0, -6.0)) +
        getR(vec2(4.0, -1.0)) +
        getR(vec2(4.0, 0.0)) +
        getR(vec2(4.0, 1.0)) +
        getR(vec2(4.0, 6.0)) +
        getR(vec2(4.0, 11.0)) +
        getR(vec2(4.0, 12.0)) +
        getR(vec2(4.0, 13.0)) +
        getR(vec2(5.0, -13.0)) +
        getR(vec2(5.0, -12.0)) +
        getR(vec2(5.0, -11.0)) +
        getR(vec2(5.0, -10.0)) +
        getR(vec2(5.0, -5.0)) +
        getR(vec2(5.0, 5.0)) +
        getR(vec2(5.0, 10.0)) +
        getR(vec2(5.0, 11.0)) +
        getR(vec2(5.0, 12.0)) +
        getR(vec2(5.0, 13.0)) +
        getR(vec2(6.0, -13.0)) +
        getR(vec2(6.0, -12.0)) +
        getR(vec2(6.0, -11.0)) +
        getR(vec2(6.0, -10.0)) +
        getR(vec2(6.0, -4.0)) +
        getR(vec2(6.0, -3.0)) +
        getR(vec2(6.0, 3.0)) +
        getR(vec2(6.0, 4.0)) +
        getR(vec2(6.0, 10.0)) +
        getR(vec2(6.0, 11.0)) +
        getR(vec2(6.0, 12.0)) +
        getR(vec2(6.0, 13.0)) +
        getR(vec2(7.0, -12.0)) +
        getR(vec2(7.0, -11.0)) +
        getR(vec2(7.0, -10.0)) +
        getR(vec2(7.0, -9.0)) +
        getR(vec2(7.0, -2.0)) +
        getR(vec2(7.0, -1.0)) +
        getR(vec2(7.0, 0.0)) +
        getR(vec2(7.0, 1.0)) +
        getR(vec2(7.0, 2.0)) +
        getR(vec2(7.0, 9.0)) +
        getR(vec2(7.0, 10.0)) +
        getR(vec2(7.0, 11.0)) +
        getR(vec2(7.0, 12.0)) +
        getR(vec2(8.0, -12.0)) +
        getR(vec2(8.0, -11.0)) +
        getR(vec2(8.0, -10.0)) +
        getR(vec2(8.0, -9.0)) +
        getR(vec2(8.0, -8.0)) +
        getR(vec2(8.0, 8.0)) +
        getR(vec2(8.0, 9.0)) +
        getR(vec2(8.0, 10.0)) +
        getR(vec2(8.0, 11.0)) +
        getR(vec2(8.0, 12.0)) +
        getR(vec2(9.0, -11.0)) +
        getR(vec2(9.0, -10.0)) +
        getR(vec2(9.0, -9.0)) +
        getR(vec2(9.0, -8.0)) +
        getR(vec2(9.0, -7.0)) +
        getR(vec2(9.0, 7.0)) +
        getR(vec2(9.0, 8.0)) +
        getR(vec2(9.0, 9.0)) +
        getR(vec2(9.0, 10.0)) +
        getR(vec2(9.0, 11.0)) +
        getR(vec2(10.0, -10.0)) +
        getR(vec2(10.0, -9.0)) +
        getR(vec2(10.0, -8.0)) +
        getR(vec2(10.0, -7.0)) +
        getR(vec2(10.0, -6.0)) +
        getR(vec2(10.0, -5.0)) +
        getR(vec2(10.0, 5.0)) +
        getR(vec2(10.0, 6.0)) +
        getR(vec2(10.0, 7.0)) +
        getR(vec2(10.0, 8.0)) +
        getR(vec2(10.0, 9.0)) +
        getR(vec2(10.0, 10.0)) +
        getR(vec2(11.0, -9.0)) +
        getR(vec2(11.0, -8.0)) +
        getR(vec2(11.0, -7.0)) +
        getR(vec2(11.0, -6.0)) +
        getR(vec2(11.0, -5.0)) +
        getR(vec2(11.0, -4.0)) +
        getR(vec2(11.0, -3.0)) +
        getR(vec2(11.0, -2.0)) +
        getR(vec2(11.0, -1.0)) +
        getR(vec2(11.0, 0.0)) +
        getR(vec2(11.0, 1.0)) +
        getR(vec2(11.0, 2.0)) +
        getR(vec2(11.0, 3.0)) +
        getR(vec2(11.0, 4.0)) +
        getR(vec2(11.0, 5.0)) +
        getR(vec2(11.0, 6.0)) +
        getR(vec2(11.0, 7.0)) +
        getR(vec2(11.0, 8.0)) +
        getR(vec2(11.0, 9.0)) +
        getR(vec2(12.0, -8.0)) +
        getR(vec2(12.0, -7.0)) +
        getR(vec2(12.0, -6.0)) +
        getR(vec2(12.0, -5.0)) +
        getR(vec2(12.0, -4.0)) +
        getR(vec2(12.0, -3.0)) +
        getR(vec2(12.0, -2.0)) +
        getR(vec2(12.0, -1.0)) +
        getR(vec2(12.0, 0.0)) +
        getR(vec2(12.0, 1.0)) +
        getR(vec2(12.0, 2.0)) +
        getR(vec2(12.0, 3.0)) +
        getR(vec2(12.0, 4.0)) +
        getR(vec2(12.0, 5.0)) +
        getR(vec2(12.0, 6.0)) +
        getR(vec2(12.0, 7.0)) +
        getR(vec2(12.0, 8.0)) +
        getR(vec2(13.0, -6.0)) +
        getR(vec2(13.0, -5.0)) +
        getR(vec2(13.0, -4.0)) +
        getR(vec2(13.0, -3.0)) +
        getR(vec2(13.0, -2.0)) +
        getR(vec2(13.0, -1.0)) +
        getR(vec2(13.0, 0.0)) +
        getR(vec2(13.0, 1.0)) +
        getR(vec2(13.0, 2.0)) +
        getR(vec2(13.0, 3.0)) +
        getR(vec2(13.0, 4.0)) +
        getR(vec2(13.0, 5.0)) +
        getR(vec2(13.0, 6.0)) +
        getR(vec2(14.0, -3.0)) +
        getR(vec2(14.0, -2.0)) +
        getR(vec2(14.0, -1.0)) +
        getR(vec2(14.0, 0.0)) +
        getR(vec2(14.0, 1.0)) +
        getR(vec2(14.0, 2.0)) +
        getR(vec2(14.0, 3.0)) ;
//Consolidate the neighbourhood checks
int sum_0 = int(s0);
int sum_1 = int(s1);
int sum_2 = int(s2);
int sum_3 = int(s3);
//Apply conditional transition functions
//
//  [LIVING]: Red channel = 1.0
//  [ DEAD ]: Red channel = 0.0

if(sum_0 >= 0 && sum_0 <= 17)         { glFragColor = vec4(0.0, 0.0, 0.0, 1.0); }
if(sum_0 >= 40 && sum_0 <= 42)         { glFragColor = vec4(1.0, 0.0, 0.0, 1.0); }

if(sum_1 >= 10 && sum_1 <= 13)         { glFragColor = vec4(1.0, 0.0, 0.0, 1.0); }

if(sum_2 >= 9 && sum_2 <= 21)         { glFragColor = vec4(0.0, 0.0, 0.0, 1.0); }

if(sum_3 >= 78 && sum_3 <= 89)         { glFragColor = vec4(0.0, 0.0, 0.0, 1.0); }
if(sum_3 >= 108)                     { glFragColor = vec4(0.0, 0.0, 0.0, 1.0); }

}
