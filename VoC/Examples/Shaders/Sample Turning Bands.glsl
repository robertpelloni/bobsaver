#version 420

// original https://www.shadertoy.com/view/4dlfW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define I_MAX 12.

float    t;
vec2     cmult(vec2 a, vec2 b);
vec2    cadd(vec2 a, vec2 b);

void main(void)
{
    t = time*.05125;
    vec2 R = resolution.xy,
          uv  = vec2(gl_FragCoord.xy-R/2.) / R.y;
    vec2    z = vec2(0.0, 0.0);
    vec2    of = vec2( (uv.x )/0.125, (uv.y )/0.125);
    vec3    col = vec3(0.0);
    float    dist = 0.;
    z.xy = of;
    for (float i = -1.; i < I_MAX; ++i)
    {
        z.xy = i*.1251 + cmult(z.xy, vec2(sin(t), cos(t)) ).xy;

        z.xy = cmult(z.xy, vec2(sin(t), cos(t) ) );    
        dist = dot(z.xy,z.xy);
        if ( i > 0.
            &&
            (
             sqrt(z.x*z.x*z.x+z.x*z.x-abs(z.x) ) < .51
            ||
             sqrt(z.y*z.y*z.y+z.y*z.y-abs(z.y) ) < .51
            )
           )
        {
            col.x = exp(-abs(z.x*z.x*z.y) );
            col.y = exp(-abs(z.y*z.x*z.y) );
            col.z = exp(-abs(min(z.x,z.y) ));
            break;
        }
        z.xy = cmult(z.xy, -vec2(sin(t), cos(t) ) );    
         col.x += .2*exp(-abs(-z.x/i+i/z.x));
        col.y += .2*exp(-abs(-z.y/i+i/z.y));
        col.z += .2*exp(-abs((-z.x-z.y)/i+i/(z.x+z.y)));
        if (dist > 10000.0)
            break;
    }
    glFragColor = vec4(col, 1.0);
}

vec2     cmult(vec2 a, vec2 b)
{
    return (vec2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x));
}

vec2    cadd(vec2 a, vec2 b)
{
    return (vec2(a.x + b.x, a.y + b.y));
}
