#version 420

// spiral with lots of pi, by the very bored ninnghazad

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float angle) {
    return mat2( cos( angle ), -sin( angle ),sin( angle ),  cos( angle ));
}
#define PI2 6.28318530718
void main( void ) {
    vec2 position = (sin(time)*PI2+PI2*PI2) * ((PI2 * gl_FragCoord.xy - resolution) / resolution.xx) * rot(-time*PI2+(-PI2*(sin(time))))/PI2;
    float a = atan(position.y, position.x);
    a = a + PI2 * float(floor(((PI2*length(position)) - a + PI2) / PI2));
    glFragColor.rgb = vec3(sin(-a/PI2+time*PI2))*normalize(vec3(sin(time),cos(time),sin(time)*cos(time)));
}
