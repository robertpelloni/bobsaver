#version 420

// original https://www.shadertoy.com/view/Wd3BRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define NUM_CLOUDS 10
#define CLOUD_PARTS 10
#define SPEED 0.008

#define saturate(x) clamp(x,0.,1.)
#define rgb(r,g,b) (vec3(r,g,b)/255.)

float rand(float x) { return fract(sin(x) * 71.5413); }

float rand(vec3 x) { return rand(dot(x, vec3(1.4251, 1.5128, 1.7133))); }

float noise(vec3 x)
{
    vec3 i = floor(x);
    vec3 f = x-i;
    f *= f*(3.-2.*f);
    return mix(
        mix(
            mix(rand(i+vec3(0,0,0)), rand(i+vec3(1,0,0)), f.x),
            mix(rand(i+vec3(0,1,0)), rand(i+vec3(1,1,0)), f.x),
            f.y),
        mix(
            mix(rand(i+vec3(0,0,1)), rand(i+vec3(1,0,1)), f.x),
            mix(rand(i+vec3(0,1,1)), rand(i+vec3(1,1,1)), f.x),
            f.y),
        f.z);
}

float fbm(vec3 x)
{
    float r = 0.0, s = 1.0, w = 1.0;
    for (int i=0; i<5; i++)
    {
        s *= 2.0;
        w *= 0.5;
        r += w * noise(s * x);
    }
    return r;
}

float cloud(int i, vec2 c, float r, vec2 p, float ch)
{
    vec2 x = p - c;
    x.y *= 3.;
    float l = length(x);
    float n = 0.1 + 0.9*fbm(vec3(x.x*ch,x.y*ch, float(i) + time*SPEED*5.));
    
    return l*n - r;
}

vec3 render(vec2 uv)
{
    // sky
    vec3 sky = mix(rgb(186, 240, 255), rgb(59, 182, 217), uv.y);
    vec3 color = sky;
    // clouds
    float dmin = 1.;
    for (int i=0; i<NUM_CLOUDS; i++) {
        vec2 pos0 = vec2(-1, -1) + vec2(2, 2) * vec2(rand(float(i)+234.230), rand(float(i)+173.1523));
        pos0.x += SPEED * time * (1. + rand(float(float(i)*34.35)));
        pos0.x = mod(pos0.x + 1.0, 2.0) - 1.0;
        pos0.x *= 3.;
        pos0.y = pos0.y * 0.8 + 0.2;
        for (int j=0; j<CLOUD_PARTS; j++) {
            vec2 pos = pos0;
            int id = i*CLOUD_PARTS+j;
            float s = 0.7;
            pos.x += (rand(float(id)+5.3451)-0.5)*0.5*s;
            pos.y += (rand(float(id)+11.7013)-0.5)*0.2*s;
            float d = cloud(id, pos, s*0.15*(rand(float(id))+1.), uv, 2.5/s);
            if (d<dmin) dmin = d;
        }
    }
    if (dmin<0.) {
        float a1 = smoothstep(0.0, -0.03, dmin);
        float a2 = smoothstep(-0.02, -0.12, dmin);
        vec3 col = mix(vec3(1,1,1), sky*0.4+0.6, a2);
        color = mix(color, col, a1);
    }
    
    return color;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv.x -= 0.5;
    uv.x *= resolution.x / resolution.y;
    
    glFragColor = vec4(render(uv),1.0);
}
