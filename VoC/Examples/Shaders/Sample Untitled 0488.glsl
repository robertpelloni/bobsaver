#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

float size = 30.0;
float speed= .75;

float random(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}
vec3 random_color(vec2 coords){
    float a = floor(random(coords.xy*6.896)*7.);
    if (a == 0.) { return vec3(1.,0.1,0.1); } //RED
    if (a == 1.) { return vec3(0.1,1.,0.1); } //GREEN
    if (a == 2.) { return vec3(1.1,1.1,0.1); } //YELLOW
    if (a == 3.) { return vec3(0.1,0.1,1.1); } //BLUE
    if (a == 4.) { return vec3(1.1,0.1,1.1); } //MAGENTA
    if (a == 5.) { return vec3(0.1,1.1,1.1); } //CYAN
    else         { return vec3(1.1,1.1,1.1); } //WHITE
}
float tri(float x){
    x = mod(x,2.0);
    if (x > 1.0) x = -x+2.0;
    return x;
}
float chess_dist(vec2 uv) {
    return max(abs(uv.x),abs(uv.y));
}
void main( void ) {
    vec2 uv = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy;
    uv.y *= resolution.y/resolution.x;
    uv.x += sin(time+uv.x*uv.y)*0.2;
    uv.y += sin(time+uv.y*uv.x)*0.2;
    vec3 colors = random_color(floor(uv*size))*step(chess_dist((fract(uv*size)-.5)*2.),tri((((time*speed)+((random(floor(uv*size)))*2.)))));
    colors*=0.9+sin(time*2.2+uv.x*22.0*uv.y*3.0)*0.5;
    colors*=1.2-abs(uv.y);
    glFragColor = vec4(colors, 1.0 );

}
