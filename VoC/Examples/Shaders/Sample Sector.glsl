#version 420

// original https://www.shadertoy.com/view/mdXfDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 M = mat2(6,8,-8,6)*.1;
float i,t,s,j;
float D(vec3 p)
{
    for(i=1e2,t = p.y+8.; i>.1; i/=4.)
        p.zx *= M,
        p.y += i*.8,
        p = i*vec3(.9,.6,.7) - abs(mod(p,i+i)-i),
        s = min(p.x,min(p.y,p.z)),
        t<s? t=s, j=i : j;
    return t;
}

void main(void)
{
    vec2 I=gl_FragCoord.xy;
    vec4 O=vec4(0.0);
    vec3 r=vec3(resolution.xy,1.0), d=normalize(vec3(I+I,0)-r.xyy), p=2.-time/r/r/.1,n,e=vec3(1,1,-1)/1e2;
    float i=0.,t=i,s=t;
    for(d.yz *= M; r.z++<2e2; t += s)
        s = D(p),
        p += d*s;
    O = cos(j*vec4(9,17,24,0))+1.;
    n = normalize(D(p+e)*e+D(p+e.xzx)*e.xzx+D(p+e.zxx)*e.zxx+D(p+e.z)*e.z);
   
    for(s=.01; s<.2; s/=.8)
        O *= max(D(p+n*s*t)/s/t,.02),
        O *= max(D(p+s*t)/s/t,.01);
    glFragColor = pow(O/1e3,vec4(.04))+t/6e2;
}