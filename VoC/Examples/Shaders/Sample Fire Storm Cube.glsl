#version 420

// original https://www.shadertoy.com/view/ldyyWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float burn;

mat2 rot(float a)
{
    float s=sin(a), c=cos(a);
    return mat2(s, c, -c, s);
}

float map(vec3 p)
{
    float d = max(max(abs(p.x), abs(p.y)), abs(p.z)) - .5;
    burn = d;
    
    mat2 rm = rot(-time/3. + length(p));
    p.xy *= rm, p.zy *= rm;
    
    vec3 q = abs(p) - time;
    q = abs(q - round(q));
    
    rm = rot(time);
    q.xy *= rm, q.xz *= rm;
    
    d = min(d, min(min(length(q.xy), length(q.yz)), length(q.xz)) + .01);
    
    burn = pow(d - burn, 2.);
    
    return d;
    
}

void main(void)
{
    vec3 rd = normalize(vec3(2.*gl_FragCoord.xy-resolution.xy, resolution.y)), 
         ro = vec2(0, -2).xxy;

    mat2 r1 = rot(time/4.), r2 = rot(time/2.);
    rd.xz *= r1, ro.xz *= r1, rd.yz *= r2, ro.yz *= r2;
    
    float t=0.;
    for(int i=0; i<int( 32.*(1.-exp(-time/4.-.1)) ); i++)t += map(ro+rd*t) / 2.;
    
    glFragColor = vec4(1.-burn, 2.*exp(-t/4.-1.), exp(-t), 1);
}
