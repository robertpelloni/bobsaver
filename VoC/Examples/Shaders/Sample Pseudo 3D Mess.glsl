#version 420

// original https://www.shadertoy.com/view/st3GzM

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

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy)/resolution.y;
    //uv += 0.5 * (.5 + .5 * tanh(2. * sin(0.2 * time))) * tanh(3. * vec2(cos(uv.x + time), sin(uv.y + time)));
    uv = rot(uv, 0.21 * time);
    uv.y +=  0.1 * tanh(4. * cos(10. * uv.x + time));
    uv += 0.5 * vec2(tanh(4. * cos(0.1 * time)), tanh(4. * sin(0.1 * time)));
    
    float r = length(uv);
    float a = atan(uv.y, uv.x);
    float sc = 20. * tanh(0.2 * time) + 3. * tanh(2. * cos(.5 * r + sin(1. * time + tanh(2. * cos(8. * r + 2. * a - 4.* time))) + 0. * h21(uv) - time));
    vec2 fpos = fract(sc * uv) - 0.5;
    vec2 ipos = floor(sc * uv) + 0.5;

   // fpos.y += 0.1 * cos(100. * uv.x + time);

    float d = length(fpos) * max(1.6 * r, 0.8 * length(fpos));
    d *= 1.5;
    d *= .5 + .5 * sc * tanh(2. * cos(1.5 * h21(ipos) + 1./(1. + length(uv)) * 10. * d - 4. * time));
    float s = step(d, 0.2 + (sc - 7. )/3. * 0.15);// + 0.18 * tanh(4. * cos(11. * h21(ipos) + time)));
    
    vec3 e = vec3(.5);
    vec3 al = pal(h21(10. * ipos)+ 0.1 * time,e*1.2,e,e*2.0, vec3(0,0.33,0.66));
    vec3 col = clamp(al,0.,1.);
    col = mix(col, vec3(step(col.x,0.9)), .5 + .5 * tanh(10. * cos(8. * tanh(4. * cos(1. * time)) + time +  10.*r + a)));
    col *= vec3(s);
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
