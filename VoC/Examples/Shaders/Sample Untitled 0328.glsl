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
    uv*=2.;
    vec3 color = vec3(0.);
    vec3 rd = vec3(uv, -1.);
        
    float s = .5;
    for (int i = 0; i < 8; i++) {
        rd = abs(rd) / dot(rd, rd); // kali iteration!! Thanks Kali
        rd -= s;
        rd.xy *= rotate(0. + time*0.11);
        rd.xz *= rotate(0. - time *0.231);
        rd.zy *= rotate(0.3 + time *0.131);
        s *= .8;
        float b = .005;
        color.gb += .014 / max(abs(rd.x*.8), abs(rd.y*.8));
        color.rb += .015 / max(abs(rd.y*0.6), abs(rd.z*0.6));
        color.rg += .01 / max(abs(rd.x), abs(rd.z));
        /*color.gb += smoothstep(.5 + b, .5, max(abs(uv.x), abs(uv.y))) * 
            smoothstep(.45, .45 + b, max(abs(uv.x), abs(uv.y)));*/
    }
    color *= 0.4;
    glFragColor = vec4(color, 1.);

}
