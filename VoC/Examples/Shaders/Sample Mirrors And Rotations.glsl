#version 420

// original https://www.shadertoy.com/view/3sVBzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy-0.5;
    uv.x *= resolution.x/resolution.y;
    float time = time;
    float a = 3.1415/6.;
    float cs = cos(a), sn = sin(a);
    mat2 rot = mat2(cs, -sn, sn, cs); 
    for (float i=0.0; i<3.; i++ )
        uv = abs(uv*rot);  
  
    for (int i = 0; i <11; i++) {
        float a = atan(uv.y, uv.x)*(0.5 + sin(time*0.2)*0.2);
        sn = sin(a);
        cs = cos(a);
        uv = uv * mat2(cs, -sn, sn, cs);
        uv.y = abs(uv.y) + sin(time)*0.04 + 0.04;
        uv.x += 0.2+ sin(time)*0.02 + 0.02;
    }
    uv /= 1.7;
    glFragColor = vec4(
        smoothstep(0.2, 0.0, fract(abs(uv.y-0.02)+time)*0.7),
        smoothstep(0.2, 0.0, fract(abs(uv.y-0.04)+time)*0.71),
        smoothstep(0.2, 0.0, fract(abs(uv.y-0.06)+time)*0.72),
    1.0);

}
