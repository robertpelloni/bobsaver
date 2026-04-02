#version 420

// original https://www.shadertoy.com/view/3dcGWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 p)
{
    p = fract(p*vec2(234.51,124.89));
    p += dot(p,p+54.23);
    return fract(p.x);
}

float width = 0.1;

void main(void)
{    
    int i;
    for(i=0;i<3;i+=1) // Loop over time-shifted color channels
    {
        float t = time + 0.1*float(i);
        vec2 pos = 5.*vec2(sin(t*0.2)+0.1*t,cos(t*0.2)+0.1*t);
        vec3 col = 0.1 + 0.3*cos(t+(gl_FragCoord.xy/resolution.xy).xyx+vec3(0,2,4));

        vec2 uv1 = pos+(5.*(gl_FragCoord.xy-.5*resolution.xy)/resolution.y);
        vec2 gv1 = (fract(uv1)-0.5);
        vec2 id1 = floor(uv1);
        vec2 uv2 = pos+2.5*(gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
        vec2 gv2 = (fract(uv2)-0.5);
        vec2 id2 = floor(uv2);

        gv1.x *= (float(rand(id1)>0.5)-0.5)*2.;
        gv2.x *= (float(rand(id2+3.)>0.5)-0.5)*2.;

        float mask1 = smoothstep(-0.2,0.2,width-abs(gv1.x+gv1.y-0.5*sign(gv1.x+gv1.y+0.01)));
        float mask2 = smoothstep(-0.2,0.2,width*2.-abs(gv2.x+gv2.y-0.5*sign(gv2.x+gv2.y+0.01)));

        col += mask1;
        col += mask2;
        glFragColor[i] = col[i];
    }
    glFragColor *= 0.5*dot(glFragColor.xyz,glFragColor.xyz);
}
