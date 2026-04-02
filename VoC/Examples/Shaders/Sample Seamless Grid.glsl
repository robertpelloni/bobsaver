#version 420

// original https://www.shadertoy.com/view/wlScR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float board(vec2 uv, float dx, float width, float one_in_pixels) {
    uv /= dx;
    uv = 0.5 - abs(uv-floor(uv)-0.5);
    uv *= dx;
    float dist = min(uv.x,uv.y);
    return smoothstep(1.,-1., dist*one_in_pixels-width*0.5);
}

float boardauto(vec2 uv, float one_in_pixels) {
    float mask = 0.;
    float dx = exp(2.30258509299*ceil(-log(one_in_pixels)/2.30258509299));
    float dxpixels = dx*one_in_pixels;
    float alpha = (dxpixels-1.)/9.;
    mask = max(mask, board(uv, dx * 1., 1., one_in_pixels) * alpha);
    mask = max(mask, board(uv, dx * 5., 1.+alpha, one_in_pixels) * alpha);
    mask = max(mask, board(uv, dx * 10., 1.+alpha*2., one_in_pixels));
    mask = max(mask, board(uv, dx * 50., 2., one_in_pixels));
    mask = max(mask, board(uv, dx * 100., 3., one_in_pixels));
    return mask;
}

void main(void) {
    vec2 coord = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.y;
    float scale = exp(sin(.1*time)*0.5/.1);
    vec3 col = vec3(1.-boardauto(coord*scale+vec2(1,0), resolution.y/scale));
    glFragColor = vec4(col,1.0);
}
