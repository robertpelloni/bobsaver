#version 420

// original https://www.shadertoy.com/view/WtKSDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sphere(vec3 ro, vec3 rd, vec4 sph)
{
    vec3 oc = sph.xyz-ro;
    float b = dot(rd, oc);
    float d2 = dot(oc,oc) - b*b;
    float h2 = sph.w*sph.w-d2;
    if (h2 <= 0.0) {
        return -1.0;
    }
    return b - sqrt(h2);
}

int mandelbrot(vec2 z, vec2 c)
{
    int i;
    for(i=0; i<50; i++) {
        if (z.x*z.x+z.y*z.y >= 4.0)
            return i;
        z = vec2(z.x*z.x - z.y*z.y + c.x, 2.*z.x*z.y + c.y);
    }
    return -1;
}

void main(void)
{
    vec2 xy = (2.0*gl_FragCoord.xy - resolution.xy)/resolution.y;

    vec3 ro = vec3(0.0, 0.0, 0.0);
    vec3 rd = normalize(vec3(xy, 4.0));
    vec4 sph = vec4(0.0, 0.0, 5.0, 1.0);
    vec3 illum = normalize(vec3(3.0, 4.0, -5.0));

    mat3 rot = mat3( 
        vec3(+cos(time),  0.0, +sin(time)),
        vec3(+0.0,        +1.0, 0.0),
        vec3(-sin(time),  0.0, +cos(time))
    );

    vec3 col = vec3(float(0.0));
    float d_sph = sphere(ro, rd, sph);
    if (d_sph >= 0.0) {
        vec3 n = normalize(ro + d_sph*rd - sph.xyz);
        vec2 z = vec2(0.0);
        vec3 c3 = rot*n-vec3(0.0,0.0,0.0);
        vec2 c = 1.0*c3.xy/c3.z;
        int i = mandelbrot(z, c);
        vec3 m_col = vec3(0.0, 0.0, 0.0);
        if (i >= 0) {
            m_col = 0.5-0.5*cos(vec3(1.0,2.0,3.0)*float(i));
        }
        float b = clamp(dot(illum, n),0.0,1.0);
        col = m_col*(b*0.75+0.25);
    }

    // Output to screen
    glFragColor = vec4(col,1.0);
}
