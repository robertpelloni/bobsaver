#version 420

// original https://www.shadertoy.com/view/sdB3Dz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random2f(in vec2 q)
{
    return fract(cos(dot(q,vec2(143.543,56.32131)))*46231.56432);
}

float noise(vec2 st)
{
    vec2 i = floor(st);
    vec2 f = fract(st);
    
    float a = random2f(i);
    float b = random2f(i + vec2(1.,0.));
    float c = random2f(i + vec2(0., 1.));
    float d = random2f(i + vec2(1., 1.));
    
    vec2 u = f * f * (3. - 2. * f);
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// From Inigo Quilez
float value_noise(in vec2 uv)
{
    float f = 0.;
    uv *= 8.0;
    mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );
    f  = 0.5000*noise( uv ); uv = m*uv;
    f += 0.2500*noise( uv ); uv = m*uv;
    f += 0.1250*noise( uv ); uv = m*uv;
    f += 0.0625*noise( uv ); uv = m*uv;
    return f;
}

#define AA 1

const vec3 mount1col = vec3(0.3,0.2,0.15);
const vec3 mount2col = vec3(0.6,0.3,0.15);
const vec3 bgcol1 = vec3(0.6,0.4,0.4);
const vec3 bgcol2 = vec3(0.9,0.5,0.3);
const vec3 suncol1 = vec3(0.9,0.3,0.2);
const vec3 suncol2 = vec3(1.,0.9,0.5);
const vec3 cloudcol = vec3(0.9,0.7,0.6);

vec3 render(in vec2 uv)
{
    vec3 color = vec3(0.);
    
    float mount1 = 0.7+0.09*sin(uv.x*10.)*sin(uv.x*10.)+sin(uv.x*50.618+53.)*.015+sin(uv.x*123.618+12.)*.005+sin(uv.x*54.)*sin(uv.x*54.)*0.01;
    float m1ss = (smoothstep(mount1,mount1+0.003, 1.-uv.y));
    
    float mount2 = 0.8+0.09*sin(uv.x*6.+0.5)*sin(uv.x*6.+0.5)+sin(uv.x*50.618+25.)*.015+sin(uv.x*123.618+12.)*.005;
    float m2ss = (smoothstep(mount2,mount2+0.002, 1.-uv.y));
    
    float sun = sqrt(pow(uv.x-0.85,2.)+pow(uv.y-0.1,2.));
    float sunr = 0.45;
    float sunss = smoothstep(sun, sun+0.0, sunr);
    vec3 suncol = mix(suncol2, suncol1, 0.8-(uv.y));
    
    float cloudss = smoothstep(0.75,0.2,1.-uv.y);
    vec3 cloudcolor = mix(cloudcol, suncol1, 0.7*(1.-uv.y+0.3));
    
    float cloud_val1 = (value_noise(uv*vec2(1.,7.)+vec2(1.,0.)*-time*0.010));
    float cloud_val2 = (value_noise(uv*vec2(2.,8.)+vec2(2.,.2)*-(time)*0.02));
    float cloud_val3 = (value_noise(uv*vec2(1.,5.)+vec2(1.,0.)*-(time)*0.005));
    float cloud_val = sqrt(cloud_val2*cloud_val1);
    cloud_val = sqrt(cloud_val3*cloud_val);
    
    // Hard(er)-edged clouds
    cloud_val = smoothstep(0.48,0.5,cloud_val);
    
    color = (bgcol1*uv.y+bgcol2*(1.-uv.y));
    color = mix(color, suncol, sunss);
    color = mix(color, mount1col, m1ss);
    color = mix(color, mount2col, m2ss);
    color = mix(color, cloudcolor, cloud_val*cloudss);
    
    return color;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x/resolution.y;
    
    vec3 color = vec3(0.);
    for (int i = -AA; i < AA + 1; ++i)
    {
        for (int j = -AA; j < AA + 1; ++j)
        {
            vec2 p = vec2(float(i),float(j))/(resolution.xy*float(2*AA+1));
            color += render(uv+p);
        }
    
    }
    color /= pow(float(2*AA+1),2.);
    
    glFragColor.rgb = color;
}
