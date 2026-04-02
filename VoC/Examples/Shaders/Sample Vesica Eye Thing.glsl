#version 420

// original https://www.shadertoy.com/view/slK3Wz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float thc(float a, float b) {
    return tanh(a * cos(b)) / tanh(a);
}

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

float h21 (vec2 a) {
    return fract(sin(dot(a.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    float r = length(uv);
    //float a = atan(uv.y, uv.x);
    //uv = vec2(0.2 * cos(a + 0.2 * time),r);
   
    float k = 10. + 8. * thc(3., r + time);
    float sc = 6. * ceil(k * fract(abs(uv.y) + r - 0.2 * time));
    float d = length(floor(sc * uv) + 0.5)/sc;
    float s = smoothstep(-1., 0.5, 0.1 + 0.5 * h21(uv));
    
    // 33333. is super hacky
    vec3 col = 1.1 * s * pal(d * 33333. + r - time * 0.1, 
               vec3(1.), vec3(1.), vec3(1.), vec3(0.,0.33,0.66));

    glFragColor = vec4(col,1.0);
}
