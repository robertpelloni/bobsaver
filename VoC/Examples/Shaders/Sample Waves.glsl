#version 420

// original https://www.shadertoy.com/view/WdfBR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 rgbToFragCol(vec3 rgb) {
    return rgb/255.0;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float ux = uv[0];
    float uy = uv[1];
    
    vec3 col = rgbToFragCol(vec3(39,60,117));
    glFragColor = vec4(col,1.0)*0.0;
    
    for (float i=1.0; i >= 0.0; i-=0.1) {
        float inv = 1.0-i;
        vec3 col = vec3(1.0-i)*col;
        float pos;
        if (mod(inv, 0.2) > 0.01) {
            pos = sin(ux*100.0/(7.5+i*5.0)-(time*inv*5.0))/80.0;
        } else {
            pos = sin(ux*100.0/(7.5+i*5.0)+(time*inv*5.0))/80.0;
        }
        if (uy-0.05-i+sin(time)*0.01 < pos) {
            glFragColor = vec4(col, 1.0);
        }
 
    }
}
