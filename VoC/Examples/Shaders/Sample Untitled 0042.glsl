#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 getPattern(vec2 p) {
    vec3 col = vec3(0.0);
    col += vec3(step(0.5,mod(-p,1.0))*0.5,0);
    col += vec3(0,0,step(0.,mod(p.y,0.5)-mod(-p.x,0.5))*0.5);
    return col;
}
vec2 rot(vec2 p, float a) {
    return vec2(p.x*cos(a),p.y*sin(a));
}
void main( void ) {

    vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= resolution.x/resolution.y;
    vec3 col = vec3(0.0);
    float a = atan(p.x,p.y);
    float r = length(p);
    
    col += cos(a*4.0+time)*0.5; //dark&light
    
    vec2 p2 = p;
    float r1 = 0.;
    for (int i=0; i<14;i++) {
        float r2 = 1./dot(p2,p2);
        p2 = rot(p2*r2+sign(p2.yx),2.4)*0.3;
        col += vec3(getPattern(p2)*0.2);
    }
    //tests:
    //col = getPattern(p);
    //col = vec3(sin(a*4.0));
    glFragColor = vec4(col,1.);
}
