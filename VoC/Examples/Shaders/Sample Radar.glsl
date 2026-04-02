#version 420

// Simple radar simulation with random generated Perlin map using the render buffer
// practical demo coded by Twareintor (2017) mailto=>ciutacu(o]gmail:com
// copyright (c) 2017 "Twareintor" Claudiu Ciutacu

#extension GL_OES_standard_derivatives : enable

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D renderbuffer;

out vec4 glFragColor;

#define PI 3.14159265359

#define OMEGA 0.72     // <0.8 upto GPU
#define RADIUS 210. // 
#define DECAY .975 // max.0.98
#define GRIDON true // 
#define DIRECTION -1. // 1. (right) or -1. 

float circleA(vec3 p0, float rad, float size)
{
    float q;
    vec3 p = gl_FragCoord.xyz-p0;
    q = clamp(size/2./abs((abs(length(gl_FragCoord.xyz-p0)-rad))), 0., 1.);
    return q;
}

float point(vec3 p0, float size)
{
    float q = clamp(1.-float(length(gl_FragCoord.xyz-p0)/size), 0., 1.);
    return q;
}

float line(vec3 p0, vec3 p1, float size)
{
    vec3 pos = p0+normalize(p1-p0)*length(gl_FragCoord.xyz-p0)*dot(normalize(p1-p0), normalize(gl_FragCoord.xyz-p0));
    float q = clamp(1.-float(length(gl_FragCoord.xyz-pos)/size), 0., 1.); 
    return q;
}

float segment(vec3 p0, vec3 p1, float size, bool ends)
{
    float q = line(p0, p1, size);
    // limit the line at its ends:
    q*=float(0.0>=dot(normalize(gl_FragCoord.xyz-p0), normalize(gl_FragCoord.xyz-p1)));
    if(ends) q = max(q, point(p0, size)); // adding points same size at ends
    return q;
}

/** block from: "http://www.glslsandbox.com/e#40767.0" */
float r(vec2 n) {
    return fract(cos(dot(n,vec2(36.26,73.12)))*354.63);
}

float noise(vec2 n) 
{
    vec2 fn = floor(n);
    vec2 sn = smoothstep(0.,1.,fract(n));
    
    float h1 = mix(r(fn),           r(fn+vec2(1,0)), sn.x);
    float h2 = mix(r(fn+vec2(0,1)), r(fn+1.)       , sn.x);
    return mix(h1,h2,sn.y);
}

float perlin(vec2 n) {  
    return noise(n/32.)*0.5875+noise(n/16.)/5.+noise(n/8.)/10.+noise(n/4.)/20.+noise(n/2.)/40.+noise(n)/80.;
}

/** ~block from: */

void main()
{
    vec3 cen = vec3(resolution/2., 0.);
    vec4 outColor;
    vec3 outer[3];
    for(int i=0; i<3; i++)
    {
        float phase = PI*2./3.*float(i);    
        outer[i] = RADIUS*vec3(+cos(OMEGA*time+phase), DIRECTION*sin(OMEGA*time+phase), 0.);
    }
    // float lr = segment(cen, cen+outer[0], 3.0, true);
    float lg = segment(cen, cen+outer[1], 3.0, true);
    float lg2 = segment(cen, cen+outer[1], 1.0, true);
    lg2*=.15;
    // float lb = segment(cen, cen+outer[2], 3.0, true);
    float green = lg;    
    /** */
    if((lg)>.05)
    {
    float map = perlin(gl_FragCoord.xy+vec2(0., time));
        green*=float(map>.29 && map<.30);
    }
    green+=lg2;
    /**   */
    float grid, grid2;
    if(GRIDON)    /** the grid  */
    {
        grid = circleA(cen, RADIUS+1., .015);
        grid+=circleA(cen, RADIUS/2., .01);
        grid+=circleA(cen, RADIUS/4., .01);
        for(int i=0; i<8; i++)
        {
            float phase = 2.*PI/8.*float(i);
            vec3 p0 = cen+RADIUS/4.*vec3(cos(phase), sin(phase), -0.003);
            vec3 p1 = cen+RADIUS*vec3(cos(phase), sin(phase), 0.0005);
            grid2+=segment(p0, p1, .75, false);
        /**** removed peripherial grid ****/
            p0 = cen+RADIUS/1.25*vec3(cos(phase+PI/8.), sin(phase+PI/8.), -0.003);
            p1 = cen+RADIUS*vec3(cos(phase+PI/8.), sin(phase+PI/8.), 0.001);        
            grid2+=segment(p0, p1, .75, false);
            
        }
        
    }
    outColor = vec4(mix(grid, grid2, 0.15), green, 0., 1.0);
    vec2 uv=gl_FragCoord.xy/resolution.xy;
    outColor+=texture2D(renderbuffer, uv)*DECAY;
    glFragColor = outColor;

}

