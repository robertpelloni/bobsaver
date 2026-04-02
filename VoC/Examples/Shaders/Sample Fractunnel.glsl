#version 420

// original https://www.shadertoy.com/view/7dX3Wf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float eps = 0.001;
vec2 eps2 = vec2(eps);

vec3 color(vec2 p) {
    float x = atan(p.y,p.x)/4.-.57;
    float y = mod(time*.2+.5/sqrt(length(p))-1.2, 1.);

    float bail=100.;
    vec2 a = vec2(x,y);
    vec3 col = vec3(0.);
    for (int i=0; i < 75; i++)
    {
        a += vec2(a.x*a.x-a.y*a.y,a.x*a.y*2.)+vec2(.123, .134);
        float af = clamp(0., 1., length(a));
        vec2 ac = normalize(a);
        col = 1.*vec3(.55*ac.x+0.2*ac.y+0.3*p.x, .47*ac.y, af);
        col += vec3(1.-length(p));
        col = sqrt(col);
        if (length(a) > bail)
        {
            col = vec3(1.);
            break;
        }
    }
    
    return col;
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy-.5*resolution.xy) / resolution.y;
    
    vec3 col = (color(p) + 
                color(p+eps2))/2.;
                
    col = pow(col-.0, vec3(8.));
                
    glFragColor = vec4(col,1.0);
}
