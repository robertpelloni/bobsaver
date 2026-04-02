#version 420

// original https://www.shadertoy.com/view/ltGfzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S(a,b,t) smoothstep(a,b,t)
#define nTime (time+9000.)/12.

float DDot(vec2 p1,vec2 p2, float blr) {
    return 1.-(distance(p1,p2)*blr);
}
    

float N21(vec2 p)
{    // Dave Hoskins - https://www.shadertoy.com/view/4djSRW
    vec3 p3  = fract(vec3(p.xyx) * vec3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    
    vec3 col=vec3(0.,0.,0.);
    vec3 colmask;
    vec2 pos;
    
    //rotate screen (from Martijn Steinrucken aka BigWings)
    float s = sin(nTime);
    float c = cos(nTime);
    uv*=mat2(c, -s, s, c);             
    
    for(float i=1.0;i<=350.;i++)
    {
        float t=N21(vec2(i,i));
        float tt=N21(vec2(i+i,i+9.));
        pos = vec2(sin(nTime+i*t)+tt, cos(nTime+i)+tt);
        float blur=300.-(180.*(sin(nTime*tt)+0.5));
             
        // blob colour
        float cc=N21(vec2(i+2.,i+3.));
        colmask=vec3(1.+sin(time*t)/2.,1.+sin(time*cc)/2.,1.+cos(time)/2.);
        col=max(colmask*vec3(DDot(uv,pos,blur)),col);
        col=max(colmask*vec3(DDot(uv,pos*vec2(-1.,1.),blur)),col);
        col=max(colmask*vec3(DDot(uv,pos*vec2(-1.,-1.),blur)),col);
        col=max(colmask*vec3(DDot(uv,pos*vec2(1.,-1.),blur)),col);
    }
    
    glFragColor = vec4(col,1.0);
    
}
