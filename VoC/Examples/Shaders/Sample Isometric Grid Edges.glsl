#version 420

// original https://www.shadertoy.com/view/WlySDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-resolution.xy*.5)/resolution.y + time*vec2(-.2,.1);
    vec3 col = vec3(0);

    float tSize = 5.;

    vec2 a = fract(uv*vec2(tSize,tSize*2.))-.5;
    vec2 gi = floor(uv*vec2(tSize,tSize*2.))+vec2(0, 1.);
    gi = vec2(gi.x - gi.y, gi.y + gi.x);

    if(abs(a.x) > .5-abs(a.y)) {
        if(a.x < 0. && a.y < 0.) { 
            gi += vec2( 0., -1.);
        } else if(a.x > 0. && a.y < 0.) { 
            gi += vec2( 1., 0.);
        } else if(a.x < 0. && a.y > 0.) { 
            gi += vec2( -1., 0.);
        } else { 
            gi += vec2( 0., 1.);
        }
    } 

    col.rgb = vec3(fract(fract(gi.x * 5123.4141) + gi.y * 128.55),
                   fract(fract(gi.x * 34.234) * gi.y * 234.21366),
                   fract(fract(gi.x * 42.56) - gi.y * 65.234)) * 0.75 + 0.2;

    col.rgb += vec3(mod(20.-gi.y - time*10., 20.)/20.);

    glFragColor = vec4(col,1.0);
}
