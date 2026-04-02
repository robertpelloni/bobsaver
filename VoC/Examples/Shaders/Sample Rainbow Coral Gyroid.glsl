#version 420

// original https://www.shadertoy.com/view/wssBDn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 march(vec3, vec3, vec2);
vec3 march(vec3, vec3, vec2, float);

float DE(vec3);

vec3 color(vec3);

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-resolution.xy/2.)/min(resolution.x, resolution.y);
    vec2 p = uv*2.;
    // Time varying pixel color
    vec3 col = vec3(p,0);
    
    vec3 cam = vec3(1);
    vec3 tar = normalize(vec3(1,1,1.2))+vec3(cos(time/10.),sin(time/10.),0) ;
    
    vec3 hit = march(cam, tar, p);
    col = vec3(mod(DE(hit),.1)*10.);
    col = color(hit);
    
    glFragColor = vec4(col,1.0);
}

float squiggly(vec3 pos)
{
    pos.x += time*.2;
    pos *= 5.;
    float res = 1.-abs(cos(pos.x)*sin(pos.y) + cos(pos.y)*sin(pos.z) + cos(pos.z)*sin(pos.x));
    pos *= -2.;
    res += .5*(1.-abs(cos(pos.x)*sin(pos.y) + cos(pos.y)*sin(pos.z) + cos(pos.z)*sin(pos.x)));
    pos *= -1.3;
    res += .25*(1.-abs(cos(pos.x)*sin(pos.y) + cos(pos.y)*sin(pos.z) + cos(pos.z)*sin(pos.x)));
    pos *= -3.;
    res += .4*(1.-abs(cos(pos.x)*sin(pos.y) + cos(pos.y)*sin(pos.z) + cos(pos.z)*sin(pos.x)));
    return res;
}

float DE(vec3 p)
{
    float tmp = (cos(p.x)*sin(p.y) + cos(p.y)*sin(p.z) + cos(p.z)*sin(p.x))*.5;
    float def = squiggly(p)*.025;
    return tmp-exp(-tmp*tmp)*def;
}

vec3 march(vec3 cam, vec3 tar, vec2 p)
{
    return march(cam, tar, p, 1.);
}

vec3 march(vec3 cam, vec3 tar, vec2 p, float f)
{
    mat3 camcoord;
    camcoord[2] = normalize(tar-cam);
    camcoord[0] = cross(camcoord[2],vec3(0,0,1));
    camcoord[1] = cross(camcoord[0], camcoord[2]);
    vec3 dir = camcoord*vec3(p,f);
    
    float l = 0.;
    float d;
    for (int i = 0; i < 100; i++)
    {
        d = DE(cam+dir*l)*.9;
        if (abs(d)<.0000001 || d>50.) break;
        l+=d;
    }
    return cam+dir*l;
}

vec3 color(vec3 pos)
{
    if (length(pos)>50.) return vec3(0);
    vec3 de = vec3(.0001,0,0);
    vec3 norm = normalize(vec3(
        DE(pos+de.xyz)-DE(pos-de.xyz),
        DE(pos+de.zxy)-DE(pos-de.zxy),
        DE(pos+de.yzx)-DE(pos-de.yzx)));
    float rot = -time;
    norm.xy *= mat2(cos(rot), sin(rot), -sin(rot), cos(rot));
    return mix(vec3(.1),.5*(norm+1.),squiggly(pos));
}
