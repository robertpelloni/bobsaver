#version 420

// original https://www.shadertoy.com/view/tlByDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// (CC BY 4.0) Kristian Sivonen 2020

float hash13(vec3 p)
{
    p = fract(p * vec3(3.131, 5.411, 4.321));
    p += dot(p.yzx, p + 51.23);
    return fract(p.x*p.y*p.z);
}

vec3 hash33(vec3 p)
{
    p = fract(p * vec3(3.131, 5.411, 4.321));
    p.xy += dot(p.yzx, p + 51.23);
    p.z = dot(p.xy, vec2(2.13, 5.21));
    return fract(p*p);
}

float hair(vec3 p, vec3 i, float t)
{
    float h = hash13(i);
    float dir = dot(p , hash33(i) * 2. - 1.);
    return sin(dir * (5. + sin(h * 431.52) * 3.) + t);
}

const vec2 o = vec2(1.,0.);

float noise(vec3 p, float t)
{
    vec3 i = floor(p);
    vec3 f = smoothstep(0.,1.,p-i);
    return 
        mix(
            mix(
                mix(hair(p,i,t),hair(p,i+o.xyy,t),f.x),
                mix(hair(p,i+o.yxy,t),hair(p,i+o.xxy,t),f.x),
                f.y),
            mix(
                mix(hair(p,i+o.yyx,t),hair(p,i+o.xyx,t),f.x),
                mix(hair(p,i+o.yxx,t),hair(p,i+o.xxx,t),f.x),
                f.y),
            f.z);
}

float fbm(vec3 p, float t)
{
    float res = 0.;
    for (float i = 1.; i < 32.; i += i)
    {
        res += noise(p*i,t*i) / i;
    }
    return res * .25 + .5;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.y;

    vec3 p = vec3(uv * 20., time * .125);

    float noise = fbm(p, time * .5);
    
    vec3 col = mix(vec3(0.), vec3(.8, .5, .3), noise);
    
    // lazy, grainy lighting
    p.z = noise;
    vec3 n = normalize(cross(dFdx(p), dFdy(p)));
    col += smoothstep(.2, 1., dot(n, normalize(vec3(-.4, .5, .8)))) * vec3(.04, .03, .05);

    glFragColor = vec4(col,1.0);
}
