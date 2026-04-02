#version 420

// original https://www.shadertoy.com/view/tlVfz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    for(float i=1.; i<9.; i++){
        uv.x += .5/i*sin(1.9 * i * uv.y + time / 2. - cos(time / 66. + uv.x))+21.;
        uv.y += .4/i*cos(1.6 * i * uv.x + time / 3. + sin(time / 55. + uv.y))+31.;
    }
    glFragColor = vec4(sin(3. * uv.x - uv.y), sin(3. * uv.y), sin(3. * uv.x), 1);
}
