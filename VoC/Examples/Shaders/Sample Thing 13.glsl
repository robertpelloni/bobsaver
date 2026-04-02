#version 420

// original https://www.shadertoy.com/view/MtKBzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
* License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
* Created by bal-khan
*/

#define E .000001

void rotate(inout vec2 p, float a)
{
    p = (vec2(cos(a)*p.x+sin(a)*p.y, -sin(a)*p.x+cos(a)*p.y));
}

vec3 h;

float mylength(vec2 p) {return max(abs(p.x), abs(p.y));}
float map(vec3 p)
{
    float mind = 1e5;
    
    mind = length(p.yz)-.5;
    float id = floor(p.z*1.)/1.;

    rotate(p.xz, sin(time*.125)*6.528);
    vec3 pp = p;

    mind = mix(length(vec2(length(p.xy)-.5, p.z))-.205, mylength(vec2(length(p.xy)-.5, p.z))-.205, .5 + .5*sin(time*6.));
    
    mind = min(mind, length(min(abs(p.yx),abs(p.xy))-.2)-.0251);
    mind = max(mind, (length(p.xy)-.9));
    rotate(pp.xy, pp.z*1.0+time*2.+-(pp.z*.5+time*1.5)*3.28);
    p.xyz = fract(pp.xyz*4.)-.5;
//    mind = mix(mind, abs(mind)+.10101, .5+.5*sin(time*.125));
    float ming = max(length(p.xy)-.1, (length(pp.xy)-.42*2.));
    ming = min(ming,
              max(length(p.xz)-.1, (length(pp.xz)-.3*2.))
              );
    ming = min(ming,
              max(length(p.yz)-.1, (length(pp.yz)-.3*2.))
              );
    ming = max(ming, (length(pp.xy)-.5*2.));
    mind = mix(mind, ming, .5+.50*sin(time*.25));
    
    h += 1.*vec3(1.5, .5, .2)/max(.01, mind*mind*10000.+100.51 );
    
    return mind;
}

void main(void)
{
    vec2 u = (gl_FragCoord.xy-resolution.xy*.5)/resolution.y;
    vec3 ro = vec3(.0, .0, 2.);
    vec3 rd = vec3(u.xy,-1.);
    vec3 p;
    vec2 md; vec2(.0,0.);
    h -= h;
    for(float d = 1.; d < 250.; d++)
    {
        p = ro + rd * md.y;
        
        md.x = map(p)*.25;
        md.y += md.x;
        if (md.x <= E || md.y > 200.)
            break;
    }
    vec3 o = vec3(0.,0.,0.);
    o.x = md.x/50.;
    o.xyz = o.xxx*.0+h;

    o.xyz += .251*vec3(.12, .2385, .351)*.5/max(md.x,.205);
    glFragColor = vec4(o,1.0);
}
