#version 420

// original https://www.shadertoy.com/view/3l2BWz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA 2

#define product(a,b) vec2(a.x*b.x-a.y*b.y, a.x*b.y+a.y*b.x)
#define divide(a,b) vec2(((a.x*b.x+a.y*b.y)/(b.x*b.x+b.y*b.y)),((a.y*b.x-a.x*b.y)/(b.x*b.x+b.y*b.y)))

vec2 calcDist(vec2 Z0,vec2 C)
{
    vec2 dC = vec2(1,0);
    vec2 Z = Z0;
    vec2 dZ = dC;
    float dotZ = 0.0;
    int i=0;
    for(; i<256; ++i)
    {
        dZ = product(Z,dZ)*2.0 + dC;
        Z = product(Z,Z) + C;
        dotZ = dot(Z,Z);
        if(dotZ>1024.0) break;
    }

    if(i>=256) return vec2(-1.0,0);

    vec2 u = normalize(divide(Z,dZ));
    vec2 v = normalize(vec2(4,1));
    float h2 = 5.0;
    float diff = clamp((dot(u,v)+h2) / (1.2+h2), 0.0, 1.0);

    float d = float(i) + 1.0 - log(log(length(Z))) / log(2.0);
    d = 1.0 - d / 600.0;
    d = pow(d,1.5);
    return vec2(d,diff);
}

vec3 colour(float d)
{
 return pow(vec3(d),vec3(0.5,5.0,5.0));
//    return vec3(pow(smoothstep(0.0,1.0,d),1.5), pow(d,5.0), pow(d,5.0));
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float ang = 5.5;
    float scl = 0.5;
    float sa = sin(ang)*scl*2.0, ca = cos(ang)*scl*2.0;
    float aspect = resolution.x/resolution.y;
    mat2 m = mat2(ca*aspect,sa*aspect,-sa,ca);
    vec3 col = vec3(0.0);
    vec2 C = vec2(-0.05+sin(time*1.37)*0.01,0.6805+cos(time)*0.01);
    for(int y=0; y<AA; y++)
    {
        for(int x=0; x<AA; x++)
        {
            vec2 offset = (vec2(x,y)+0.5)/float(AA);
            vec2 p = (uv + offset/vec2(resolution.x,resolution.y))*2.0-1.0;
            vec2 Z0 = m*p;
            vec2 d = calcDist(Z0,C);
            if(d.x>=0.0) col += colour(d.x) * d.y;
        }
    }
    glFragColor = vec4(col/float(AA*AA), 1);
}
