#version 420

// original https://www.shadertoy.com/view/sd2XWV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
    vec2 uv =  (2.0 * gl_FragCoord.xy - resolution.xy) / min(resolution.x, resolution.y);

    for(float i = 1.0; i < 10.0; i++){
        uv.x += 0.6 / i * cos(i * 2.5* uv.y + time);
        uv.y += 0.6 / i * cos(i * 1.5 * uv.x + time);
    }
    vec3 col = 0.5 + 0.5*sin(time+uv.xyx+vec3(0,2,4));
    glFragColor = vec4(col/(2.1*abs(cos(time-uv.y-uv.x))),1.0);
    //https://www.shadertoy.com/view/WtdXR8
    //glFragColor = vec4(vec3(0.1)/abs(sin(time-uv.y-uv.x)),1.0);
}
