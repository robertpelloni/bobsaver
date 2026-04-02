#version 420

// original https://www.shadertoy.com/view/fld3D8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rot (vec2 vec, float a) {
    float m = 3.;
    mat2 mat = mat2(tanh(m * cos(a)), -tanh(m * sin(a)) , tanh(m * sin(a)), tanh(m * cos(a)));
    return mat * vec;
}

float h21 (vec2 a) {
    return fract(sin(dot(a.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ) {
    return a + b*cos( 6.28318*(c*t+d) );
}

float thc(float a, float b) {
    return tanh(a * cos(b));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    
    float sc = 250.;   
    vec2 fpos = fract(sc * uv) - 0.5;
    vec2 ipos = floor(sc * uv) + 0.5;
    
    float a = atan(ipos.y, ipos.x);
    
    float k = length(ipos) + 4. * thc(4., length(uv) + 10. * a + time);
    float r = log(k + 3. * thc(4., length(uv) * 100. + 4. * time));
    r *= .5 + .5 * thc(1.5, 4. * r + a - time);
  
    vec2 v = r * vec2(cos(a), sin(a));
    ipos = floor(v) + 0.5;
    
    float d = length(fpos) + cos(length(ipos) + time);

    glFragColor = vec4(d);
}
