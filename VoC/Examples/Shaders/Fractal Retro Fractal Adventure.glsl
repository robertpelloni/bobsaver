#version 420

// original https://www.shadertoy.com/view/4l3GRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TIME (time)

// returns average value from kaliset
vec3 kali_trees(in vec2 uv)
{
    uv = uv.yx / 100. - vec2(0.022,0.04);
    uv.x += 0.001*sin(TIME/33.);
    uv.y += 0.003*sin(TIME/17.3);
    vec3 p = vec3(uv, .03);
    
    vec3 col = vec3(0.);
    const int num_iter = 67;
    for (int i=0; i<num_iter; ++i)
    {
        p = abs(p) / dot(p, p);
        col += exp(-p*22.);
        p -= vec3(1.+0.005*sin(TIME/11.), 0.585, .03);
    }
    col /= float(num_iter);
    col *= 4.;
    
    //col = pow(clamp(col, 0., 1.), vec3(2.));
    
    return col;
}

vec3 kali_stars(in vec2 uv)
{
    uv = (uv+vec2(2.,1.)) / 14.;
    uv.x += sin(TIME/150.);
    vec3 p = vec3(uv, .03);
    
    vec3 col = vec3(0.);
    const int num_iter = 50;
    for (int i=0; i<num_iter; ++i)
    {
        p = abs(p) / dot(p, p);
        col += exp(-p*32.);
        p -= vec3(.285, .409, .874);
    }
    col /= float(num_iter);
    col *= 4.;
    
    //col = pow(clamp(col, 0., 1.), vec3(2.));
    
    return col;
}

void main(void)
{
    vec2 suv = gl_FragCoord.xy / resolution.xy;
    vec2 uv = (gl_FragCoord.xy - .5*resolution.xy) / resolution.y * 2.;
    
    vec3 kt = kali_trees(uv);
    vec3 ks = kali_stars(uv);
    
    vec3 col = mix(vec3(.9,.3+.2*cos(suv.y*8.),.1), vec3(.5,.2+ks.x, 1.), suv.y-ks.z);
    
    col *= smoothstep(0.0, .2, kt.y-.6-suv.y*.1);
    
    
    glFragColor = vec4(col,1.0);
}
