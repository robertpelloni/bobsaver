#version 420

// original https://www.shadertoy.com/view/wstyWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Based on https://www.shadertoy.com/view/wtXfRH

vec3 fcos( vec3 x )
{
    vec3 w = fwidth(x);
    #if 0
    return cos(x) * sin(0.5*w)/(0.5*w);     // filtered-exact
    #else
    return cos(x) * smoothstep(6.28,0.0,w); // filtered-approx
    #endif  
}

vec2 fcos(vec2 x)
{
    vec2 w = fwidth(x);
    return cos(x) * sin(0.5*w)/(0.5*w);
}

vec3 getColor( in vec2 p )
{
    vec3 col = vec3(0.4,0.4,0.4);
    
    col += 0.12*fcos(6.28318*p.x*  1.1+vec3(+1.0,1.0,0.0));
    col += 0.11*fcos(6.28318*p.y*  3.1+vec3(-1.0,0.0,1.0));
    col += 0.10*fcos(6.28318*p.x*  5.1+vec3(+1.0,1.0,0.0));
    col += 0.09*fcos(6.28318*p.y*  9.1+vec3(-1.0,0.0,1.0));
    col += 0.08*fcos(6.28318*p.x* 17.1+vec3(+1.0,1.0,0.0));
    col += 0.07*fcos(6.28318*p.y* 33.1+vec3(-1.0,0.0,1.0));
    col += 0.06*fcos(6.28318*p.x* 65.1+vec3(+1.0,1.0,0.0));
    col += 0.05*fcos(6.28318*p.y*129.1+vec3(-1.0,0.0,1.0));
    col += 0.04*fcos(6.28318*p.x*257.1+vec3(+1.0,1.0,0.0));
    return col;
}

void main(void)
{
    // coordinates
    vec2 p = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;

    p *= 2.0;
    //p += 100.0;
    vec2 q = p;
    
    // deform
    float a = 1.5;
    float b = 0.5;
    float c = 0.0;
    
    vec2 o1 = vec2(1.0, 1.0);
    vec2 o2 = vec2(1.0, 2.0);
    for (int i = 0; i < 16; i++){
        p += clamp(1.0, 0.0, a)*cos(b*p.yx + c*time + o1);
        a *= 0.502357;
        b *= 2.02357;
        c += 0.05;
        
        vec2 ot = o1;
        o1 += o2;
        o2 = ot;
    }

    // base color pattern
    vec3 col = getColor(p*0.1);
    
    
    //b = dot(p-q,p-q);
    //col *= clamp(1.0, 0.0, 1.0-b*8.0);
 
   glFragColor = vec4(col, 1.0);
}
