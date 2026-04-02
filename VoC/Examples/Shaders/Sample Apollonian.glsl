#version 420

// original https://www.shadertoy.com/view/Xs2cDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int ITS = 50;
const float pi = 3.1515926536;
const vec2 c1 = vec2(0, 1);
const vec2 c2 = vec2(.866, -.866);
const vec2 c3 = vec2(-.866, -.866);
const float rad1 = 1.;

vec2 circleInverse(vec2 pos, vec2 center, float rad){
    vec2 d = pos - center;
    return d * rad * rad/dot(d, d) + center;
}

vec3 gasket(vec2 pos){
    float rad2 = mouse.x*resolution.x / resolution.x + .5;
    float rad3 = mouse.y*resolution.y / resolution.y + .5;
    if(mouse*resolution.xy.xy == vec2(0.)) {rad2 = 1.; rad3 = 1.;}
    float index = 0.;
    for(int i = 0 ; i < ITS; i++){
        if(distance(pos, c1) < rad1){
            pos = circleInverse(pos, c1, rad1); index++;
        }
        else if(distance(pos, c2) < rad2){
            pos = circleInverse(pos, c2, rad2); index++;
        }
        else if(distance(pos, c3) < rad3){
            pos = circleInverse(pos, c3, rad3); index++;
        }
        else if(pos.y < 0.){
            pos = vec2(pos.x, -pos.y); index++;
        }
        else return vec3(pos, index);
    }
}

vec4 getCol(vec3 n){
    float s = 0.08 * (4.0-length(n.xy)) + n.z;
    if (n.z==50.0)return vec4(0);
    float arg = pi * s / 20. + time;
    vec3 col = sin(vec3(arg - pi / 2., arg - pi, arg - 2. * pi / 3.)) * 0.5 + 0.5;
    return vec4(col*col, 1.);
}

void main(void) {
    vec2 pos = gl_FragCoord.xy / resolution.y - .5 * vec2(resolution.x / resolution.y, 1.);
    pos.y -= .15;
    glFragColor = getCol(gasket(pos));
}
