#version 420

// original https://www.shadertoy.com/view/XdlyDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Andrew Wild - akohdr/2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define CENTER(p) p -= .5*iR; p /= iR.y
#define ROT2D(p,a) p *= mat2(vec4(1,-1,1,1)*cos(vec2(a,a-1.57)).xyyx)

// m => vec4(center.xy, zoom, max its.);
//   <= vec4(inSet?, exit it., magnitude, smooth its.)
vec4 mandel(in vec2 p, vec4 m )
{
//    m.w = float(int(m.w)&~1); // ensuring even its. alleviates some flashing using smooth
    vec2 i = vec2(0), c = p / m.z + m.xy, z = c;
    for(i.x=0.;(i.y = length(z))<2. && i.x<m.w;i.x++)    // appease windoze

//    for(;(i.y = length(z))<2. && i.x++<m.w;)    // still not compile windoze
//    while((i.y = length(z))<2. && i.x++<m.w)    // not compile windoze
        z = mat2(z,-z.y,z.x)*z + c;
    
// http://iquilezles.org/www/articles/mset_smooth/mset_smooth.htm
//    i.x -= log2(log2(dot(z,z)/2.))-4.;

    return vec4(i.y < 2., i, m.w);
}

void main(void)
{
     vec2 iR = resolution.xy;
    float iT = time,
           t = pow(1.8, 7.1-7.*cos(iT/4.));
    vec2 p=gl_FragCoord.xy;
    CENTER(p);
    ROT2D(p,iT);
    
    vec2 c = vec2(-1.039532, -.34893);
    
    glFragColor = mandel(p, vec4(c,  t*log(t), t+22.));
//    k = mandel(p, vec4(-.8, 0, .5, 55.));    // whole Mset no zoom
//    k = mod(k,2.);                            // older textbook style
    glFragColor = normalize(glFragColor);
}
