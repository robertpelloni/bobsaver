#version 420

// original https://www.shadertoy.com/view/NdGcDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float h41(vec3 pos, float s)
{
    vec4 p = fract(vec4(pos,s)*64.23);
    p += dot(p, p.xywz*36.5);
    return fract(p.z-(p.x-p.y)*p.w);
}

float cubicSp (float x, float a, float b, float c, float d) 
{
    float p = d-c-(a-b);
    return p*x*x*x + (a-b-p)*x*x + (c-a)*x + b;
}

float cubicSpNoise3d(vec3 pos, float size, float seed)
{
    vec3 v = floor(pos*size), c = fract(pos*size);
    vec3 b[4];
    for (int z = 0; z < 4; z++)
    {
        for (int y = 0; y < 4; y++)
        {
            for (int x = 0; x < 4; x++)
            {
                b[x].x = h41(v+vec3(x,y,z),seed);
            }
            b[y].y = cubicSp(c.x,b[0].x,b[1].x,b[2].x,b[3].x);
        }
        b[z].z = cubicSp(c.y,b[0].y,b[1].y,b[2].y,b[3].y);
    }
    return cubicSp(c.z,b[0].z,b[1].z,b[2].z,b[3].z);
}

vec2 rot(vec2 uv, in float r, in vec2 o)
{
    return (uv-0.5+o) * mat2(cos(r),-sin(r),sin(r),cos(r)) + 0.5-o;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec2 rc = uv;
    
    float rp = 0.;
    float fAmt = 1., fade = 0.56, scale = 1., shrink = 1.4,
        dspeed = 1.2, speed = 2., spin = 2.6;
    
    for (int i = 0; i < 15; i ++)
    {
        rp = mix(rp, cubicSpNoise3d(
            vec3(rc,(time*speed)/20.),
            scale, float(i)+0.374*3.57),fAmt);
        
        fAmt *= fade; scale *= shrink; speed /= dspeed;
        rc = rot(rc,spin,vec2(0.5));
    }
    
    rc = uv;
    float n = 0.;
    fAmt = 1., fade = 0.39, scale = 10., shrink = 1.9,
        dspeed = 1.2, speed = 2., spin = 2.6;
    
    for (int i = 0; i < 8; i ++)
    {
        n = mix(n, cubicSpNoise3d(
            vec3(rc,(time*speed)/20.+rp*9.),
            scale, float(i)+0.345*3.56),fAmt);
        
        fAmt *= fade; scale *= shrink; speed /= dspeed;
        rc = rot(rc,spin,vec2(0.5));
    } n = n*0.8+0.1;
    
    n = smoothstep(0.,0.9,pow(n,1.2));
    
    vec3 col = mix(vec3(0.05,0.04,0.),vec3(0.4,0.6,0.4),n);
    col = mix(col,vec3(0.5,0.4,0.6),
        clamp(smoothstep(0.4,0.6,n)-smoothstep(0.7,0.6,n),0.,1.));
    col *= vec3(1.3,0.5,0.6)*n;
    col += vec3(0.4,0.6,1.)*pow(1.-n,4.);
    col = mix(col,vec3(1.,0.9,0.6),n/2.);
    col = pow(col,vec3(2.8,2.5,1.9))*4.5;
    
    col += max(0.,sin(n*30.)-0.5)*1.2;
    
    glFragColor = vec4(col,1.0);
}
