#version 420

// original https://www.shadertoy.com/view/NssSDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
float bx(vec3 p,vec3 s)
{
    vec3 q = abs(p) - s;
    return min(max(q.x, max(q.y, q.z)), 0.) + length(max(q, 0.));
}
vec2 mp1(vec3 p)
{
    float b1 = bx(p, vec3(1)) - 0.05;
    float b2 = bx(p + vec3(0.,0.,0.4), vec3(0.8)) - 0.03;
    float b3 = length(p) - 1.2;
    vec2 r = vec2(0);
    r.x = min(b1, min(b2, b3));
    r.y = b1 < b2 ? 1. : 2.;
    r.y = r.x < b3 ? r.y : 3.;
    return r;
}
vec2 mp(vec3 p,vec3 ro)
{
    vec3 bxp = abs(p) - vec3(2, 2, 0);
    bxp.z = mod(p.z, 8.) - 5.;
   
    //this line creates the "static" further back. Remove if you want the reflections to work all the way
    bxp.z += cos(time * fract(bxp.x * bxp.y)) * smoothstep(ro.z + 32.,ro.z + 128.,p.z) * 0.2;
    bxp.xy = mod(p.xy, 4.) - 2.;
    bxp.xz *= rot(-time * 0.1);
    bxp.yz *= rot(time * 0.1);  
    return mp1(bxp);
}
vec2 rm(vec3 ro, vec3 rd)
{
    vec2 d = vec2(0.);
    for(int i=0;i<256;i++)
    {
        vec3 p=ro+rd*d.x;
        vec2 s=mp(p,ro);
        d.y=s.y;d.x+=s.x;
        if(s.x<0.01||d.x>128.)break;
    }
    if(d.x>128.)d.y=0.;
    return d;
}
void main(void)
{
    vec2 uv=(gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    uv *= rot(time/4. - length(uv) * sin(time));
    vec3 ro=vec3(0,1,time * 4. + sin(time * 4.)),rd=normalize(vec3(uv.x + cos(time) * 0.1,uv.y + sin(time) * 0.1,1)),
    col=vec3(clamp(sin(time/2.) + 0.5,0.,1.));
    
    //uncomment this line for just dark mode
    //col=vec3(clamp(-abs(sin(time/4.) + 0.5),0.,1.));
    
    vec2 s=rm(ro,rd);
    vec3 p=ro+rd*s.x;
    vec2 e=vec2(0.02,0.);
    vec3 n=normalize(mp(p,ro).x - vec3(mp(p-e.xyy,ro).x,mp(p-e.yxy,ro).x,mp(p-e.yyx,ro).x));
    if(s.y > 0.)
    {
        vec3 al= s.y == 1. ? vec3(0.,0.3,sin(time + s.x) * 0.5 + 0.5) : (s.y == 2. ? vec3(sin(time + s.x) * 0.5 + 0.5,0.,0.8) :
        vec3(cos(-time),0.2,sin(-time)));
        al.xy *= rot(time/10.);
        al.xz *= rot(-time/10.);
        al.zy *= rot(time/15.);
        vec3 sss = vec3(0.5)*smoothstep(0.,1.,mp(p+-rd*0.2,ro).x/0.2);
        float d = dot(n, -rd);
        float diff = max(d, 0.);
        float fres = pow(1. - d, 3.);
        float spec = pow(abs(dot(reflect(rd,n),-rd)),20.);
        float disf = pow(smoothstep(0., 128., s.x),3.);
        float smx = mix(s.x, -s.x, sin(time));
        float mx = mix(1. - disf, disf, smoothstep(0., 128., smx));
        col = mix(al*(diff+fres+sss)+spec,col,mx);
            vec3 rfd = reflect(rd, n);
    vec3 rfo = p + n * 0.05;
    vec2 s2=rm(rfo, rfd);
    p=ro+rd*s2.x;
    n=normalize(mp(p,rfo).x - vec3(mp(p-e.xyy,rfo).x,mp(p-e.yxy,rfo).x,mp(p-e.yyx,rfo).x));
    if(s2.y > 0.)
    {
        vec3 al1= s2.y == 1. ? vec3(0.,0.3,sin(time + s2.x) * 0.5 + 0.5) : (s2.y == 2. ? vec3(sin(time + s2.x) * 0.5 + 0.5,0.,0.8) :
        vec3(cos(-time),0.2,sin(-time)));
        al1.xy *= rot(time/10.);
        al1.xz *= rot(-time/10.);
        al1.zy *= rot(time/15.);
        vec3 sss1 = vec3(0.5)*smoothstep(0.,1.,mp(p+-rfd*0.2,rfo).x/0.2);
        float d = dot(n, -rfd);
        float diff1 = max(d, 0.);
        float fres1 = pow(1. - d, 3.);
        float spec1 = pow(abs(dot(reflect(rfd,n),-rfd)),20.);
        float disf1 = pow(smoothstep(0., 128., s2.x),3.);
        float smx1 = mix(s2.x, -s2.x, sin(time));
        float mx1 = mix(1. - disf1, disf1, smoothstep(0., 128., smx));
        vec3 refcol = mix(al1*(diff1+fres1+sss1)+spec1,col,mx);
        col = mix(col, refcol, 0.3);
    }
    }
   

    glFragColor = vec4(col * min(time * 0.1, 1.), 1.);
}

