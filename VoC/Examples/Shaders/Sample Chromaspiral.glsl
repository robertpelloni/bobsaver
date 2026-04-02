#version 420

// original https://www.shadertoy.com/view/tdsyRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time time*0.05

vec2 rotate2d(vec2 uv, float a) {
    uv -= 0.5;
    uv *= mat2(sin(a),cos(a),-cos(a),sin(a));
    uv += 0.5;
    return uv;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    vec3 col = vec3(0.);
    float loop = 30.*0.1;
    float it = abs(mod(time+loop,loop*2.)-loop);
    float a = it*it*it*length(uv-0.5);
    for (int i=0;i<6;i++) {
        
        float fi = float(i);
        uv -= 0.5+fi*0.005;
        uv += vec2(sin(time*3.+fi*15.),cos(time*2.+fi*15.))*cos(time*0.1);
        uv += 0.5-fi*0.005;
        uv = rotate2d(uv,-time+length(uv-0.5));
    }
    uv *= 0.5;
    float sint = cos(time*1.5)*20.;
    col.r += sin(uv.x*11.+sint)+sin(uv.y*90.);
    uv += 0.1;
    uv += time*0.01;
    col.g += sin(uv.x*11.+sint)+sin(uv.y*99.);
    uv += 0.1;
    uv -= time*0.012;
    col.b += sin(uv.x*11.+sint)+sin(uv.y*91.);
    col = sin(col*1.4);
    glFragColor = vec4(col,1.0);
}
