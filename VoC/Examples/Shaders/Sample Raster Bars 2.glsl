#version 420

// original https://www.shadertoy.com/view/MlSSR3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) //WARNING - variables void ( inout vec4 c, vec2 r ) need changing to glFragColor and gl_FragCoord
{
    float 
        y = (gl_FragCoord.xy / resolution.xy + 0.75).y,
        t = time * 3.,
        s;
    vec4 c=glFragColor;
    c.b += cos(y * 4. - 5.0);
    
    for (float k = 0.; k < 18.; k += 1.) {        
        s = (sin(t + k / 3.4)) / 6. + 1.25;;        
        if (y > s && y < s + .05) {
            glFragColor = vec4(s, sin(y + t * .3), k / 16., 1.) * (y - s) * sin((y - s) * 20. * 3.14) * 38.;
        }
    }
}
