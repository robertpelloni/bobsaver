#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// visualizing warping space --joltz0r

float check(in vec2 p) {
    const float size = 2.0;
    if (fract(p.x*size) > 0.5 ^^ fract(p.y*size) > 0.5) {
        return 1.;
    }
    return .0;
}

void main( void ) {

    vec2 p = (( gl_FragCoord.xy / resolution.xy ) - 0.5) * 4.0;
    p.x *= resolution.x/resolution.y;
    
    vec2 rot_t = vec2(time + cos(time*0.33) - length( p *sin(time*0.21)));
    mat2 rot_x = mat2(cos(rot_t.y), -sin(rot_t.x),
              sin(rot_t.x), cos(rot_t.y)) * 2.0;
    float c = check(p*rot_x);

    glFragColor = vec4( vec3(c), 1.0 );

}
