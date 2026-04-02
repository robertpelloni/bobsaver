#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rotate(float a) {
    float c = cos(a),
        s = sin(a);
    return mat2(c, -s, s, c);
}

void main() {
    vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;
    vec3 color = vec3(0.);
        
    float s = .5;
    for (int i = 0; i < 8; i++) {
        uv = abs(uv) / dot(uv, uv); // kali iteration!! Thanks Kali
        uv -= s;
        uv *= rotate(time);
        s *= .8;
        float b = .005;
        color.gb += .01 / max(abs(uv.x), abs(uv.y));
        /*color.gb += smoothstep(.5 + b, .5, max(abs(uv.x), abs(uv.y))) * 
            smoothstep(.45, .45 + b, max(abs(uv.x), abs(uv.y)));*/
    }
    //color /= 10.;
    glFragColor = vec4(color, 1.);

}
