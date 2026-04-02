#version 420

// original https://www.shadertoy.com/view/wlVGDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    This shader was created live on stream!
    You can watch the VOD here: https://www.twitch.tv/videos/536586403

    I use the Bonzomatic tool by Gargaj/Conspiracy:
    https://github.com/Gargaj/Bonzomatic

    I stream at https://twitch.tv/lunasorcery
    Come and watch a show!

    ~yx
*/

float phi = (1.+sqrt(5.))*.5;
#define spinSpeed (time*.5)

mat2 rotate(float a){
    float c=cos(a);
    float s=sin(a);
    return mat2(
        c,-s,
        s,c
    );
}

float sdIcosahedron(vec3 p, float r)
{
    float q = (sqrt(5.)+3.)/2.;

    vec3 n1 = normalize(vec3(q,1,0));
    vec3 n2 = vec3(sqrt(3.)/3.);

    p = abs(p/r);
    float a = dot(p, n1.xyz);
    float b = dot(p, n1.zxy);
    float c = dot(p, n1.yzx);
    float d = dot(p, n2.xyz)-n1.x;
    return max(max(max(a,b),c)-n1.x,d)*r;
}

float sdDodecahedron(vec3 p, float r)
{
    p = abs(p);
    p += phi*p.zxy;
    return (max(max(p.x,p.y),p.z)-r*phi) / sqrt(phi*phi+1.);
}

float sdRhombicTriacontahedron(vec3 p, float r)
{
    float l = phi*2.;
    
    p = abs(p);
    float a = max(max(p.x,p.y),p.z);
    p += (p+p.yzx)*phi+p.zxy;
    return max(a, max(p.x,max(p.y,p.z))/l)-r;
}

float sdHexahedron(vec3 p, float r)
{
    p = abs(p)-r;
    return max(max(p.x,p.y),p.z);
}

float sdOctahedron(vec3 p, float r)
{
    return (dot(abs(p),vec3(1))-r)/sqrt(3.);
}

float sdRhombicDodecahedron(vec3 p, float r)
{
    p = abs(p);
    p += p.yzx;
    return (max(max(p.x,p.y),p.z)-r) * sqrt(.5);
}

int mat,matHack;
float scene1(vec3 p)
{
    p.xz *= rotate(spinSpeed);
    
    float dodec = sdDodecahedron(p,1.);
    float icos = sdIcosahedron(p.zyx,1.);
    
    float unity = min(dodec,icos);
    float intersect = max(dodec,icos);
    
    float innerEdges = max(intersect-.004, -unity);
    float outerEdges = max(unity-.001, -sdRhombicTriacontahedron(p.zyx,1.));
    
    float best = unity;//min(union,min(outerEdges, innerEdges));
    if (best == dodec)
        matHack = 0;
    else if (best == icos)
        matHack = 1;
    else if (best == outerEdges)
        matHack = 2;
    else
        matHack = 3;
    return best;
}

float scene2(vec3 p)
{
    p.xz *= rotate(spinSpeed);
    
    float hexa = sdHexahedron(p,.5);
    float octa = sdOctahedron(p,1.);
    
    float unity = min(hexa, octa);
    float intersect = max(hexa, octa);
    
    float innerEdges = max(intersect-.004, -unity);
    float outerEdges = max(unity-.001, -sdRhombicDodecahedron(p.zyx,1.));
    
    float best = unity;//min(union,min(outerEdges, innerEdges));
    if (best == hexa)
        matHack = 4;
    else if (best == octa)
        matHack = 5;
    else if (best == outerEdges)
        matHack = 6;
    else
        matHack = 7;
    return best;
}

vec3 hatching(vec2 uv, vec2 dir, vec3 n, vec3 darkCol, vec3 lightCol, float density, float fade, float ao)
{
    uv *= density;
    float light = dot(n,normalize(vec3(1,3,1)))*.5+.5;
    light *= ao;
    light += fade;
    //return vec3(light);
    lightCol = mix(lightCol,vec3(1),fade);
    float p = dot(uv, normalize(dir));
    float d = abs(fract(p)-.5)+(light*.5-.5);
    float e = dFdy(uv.y);//(density/80.)*.1;
    return darkCol + smoothstep(-e,e,d) * (lightCol-darkCol);
}

float screenHatching(vec2 uv, vec2 dir, float light)
{
    float p = dot(uv, normalize(dir));
    float d = abs(fract(p)-.5)+(light*.5-.5);
    float e = dFdy(uv.y);//.1;
    return smoothstep(-e,e,d);
}

vec3 shade(vec2 uv, vec3 n, float ao)
{
    float fade = sin(time*.5)*.5+.5;
    
    if (mat == 3) {
        return mix(vec3(0),vec3(1),fade);
    } else if (mat == 2) {
        return vec3(1);
    } else if (mat == 1) {
        return hatching(uv, vec2(1,.5), n, vec3(0), vec3(1), 80., fade, ao);
    } else if (mat == 0) {
        return hatching(uv, vec2(.5,-1), n, vec3(0), vec3(1/*,.7,.5*/), 80., fade, ao);
    } else if (mat == 7) {
        return vec3(1,0,0);
    } else if (mat == 6) {
        return vec3(1,0,0);
    } else if (mat == 5) {
        return hatching(uv, vec2(1,-.1), n, vec3(1,0,0), vec3(1), 200., (1.-fade)*.3, ao);
    } else if (mat == 4) {
        return hatching(uv, vec2(.1,1), n, vec3(1,0,0), vec3(1), 200., (1.-fade)*.3, ao);
    }
}

vec3 trace1(vec3 cam, vec3 dir, vec2 uv)
{
    float t=0.;
    float k=0.;
    for(int i=0;i<100;++i) {
        k = scene1(cam+dir*t);
        t += k;
        if (abs(k)<.001)
            break;
    }
    mat = matHack;
    
    if (abs(k)<.001)
    {
        vec3 h = cam+dir*t;
        const vec2 o = vec2(0.001,0);
        vec3 n = normalize(vec3(
            scene1(h+o.xyy)-scene1(h-o.xyy),
            scene1(h+o.yxy)-scene1(h-o.yxy),
            scene1(h+o.yyx)-scene1(h-o.yyx)
        ));
        
        float aoDist = scene1(h+n*.2);
        float ao = pow(aoDist/.2,.8);
        
        return shade(uv, n, ao);
    }
    return vec3(1);
}

vec3 trace2(vec3 cam, vec3 dir, vec2 uv)
{
    float t=0.;
    float k=0.;
    for(int i=0;i<100;++i) {
        k = scene2(cam+dir*t);
        t += k;
        if (abs(k)<.001)
            break;
    }
    mat = matHack;
    
    if (abs(k)<.001)
    {
        vec3 h = cam+dir*t;
        const vec2 o = vec2(0.001,0);
        vec3 n = normalize(vec3(
            scene2(h+o.xyy)-scene2(h-o.xyy),
            scene2(h+o.yxy)-scene2(h-o.yxy),
            scene2(h+o.yyx)-scene2(h-o.yyx)
        ));
        
        float aoDist = scene2(h+n*.2);
        float ao = pow(aoDist/.2,.5);
        
        return shade(uv, n, ao);
    }
    return vec3(1);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy - .5;
    uv.x *= resolution.x / resolution.y;

    vec3 cam = vec3(0,0,-5);
    vec3 dir = normalize(vec3(uv,1.5));
    
    cam.yz *= rotate(0.2);
    dir.yz *= rotate(0.2);
    
    vec3 color1 = trace1(cam, dir, uv);
    vec3 color2 = trace2(cam, dir, uv);
    
    glFragColor.rgb = clamp(color1*color2,0.,1.);
    glFragColor.rgb *= mix(vec3(0), vec3(1), screenHatching(uv*80., vec2(1,4), 1.3-dot(uv,uv)*.5));
    glFragColor.rgb = mix(vec3(.2), vec3(1,.9,.8), glFragColor.rgb);
}
