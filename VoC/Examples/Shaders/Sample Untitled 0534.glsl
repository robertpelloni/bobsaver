#version 420

// original https://www.shadertoy.com/view/wsfcR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// based on...
// https://www.shadertoy.com/view/lssfW2
highp float rand(vec2 co)
{
    highp float a = 12.9898;
    highp float b = 78.233;
    highp float c = 43758.5453;
    highp float dt= dot(co.xy ,vec2(a,b));
    highp float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 p=(2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    // Time varying pixel color
    //vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));
    
    vec2 curve_p = vec2(0,0);
    float d = 10000.0;
    float di = 0.;
    for(int i = 0;i<1000;i++)
    {
        di = float(i)*.03;
        curve_p.x = .3*sin(.4*time)+.05*float(di)*sin(float(di)+.2*time) +.01*float(di)*sin(4.0*di+.2*time) + .06*sin(time*.1)*float(di)*sin(7.0*di+.4*time);
        curve_p.y = .3*cos(.4*time)+.05*float(di)*cos(float(di)+.2*time) +.01*float(di)*cos(4.0*di+.2*time) + .06*sin(time*.1)*float(di)*cos(7.0*di+.4*time);
        d = min(d, length(p-curve_p)+.4*rand(vec2(di,di)));
  
    }

    vec3 col = vec3(2.*d*d,.008 + .25*sin(.001*d*d+.1*length(p)), .25*abs(.15+.13*cos(time*.8 - 2.5*pow(d,8.0))));
    float dn = col.x + col.y + col.z;
    col /= dn;
    // Output to screen
    //glFragColor = vec4(col,1.0); 
    glFragColor = vec4( pow(col,vec3(1./2.2)),1.0);
}
