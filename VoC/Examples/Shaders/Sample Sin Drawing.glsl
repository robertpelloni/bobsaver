#version 420

// original https://www.shadertoy.com/view/XdKfRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TWO_PI 6.28318530718

float plotX(vec2 st, float pct){
  return  smoothstep( pct-0.01, pct, st.y) -
          smoothstep( pct, pct+0.01, st.y);
}

float plotY(vec2 st, float pct){
  return  smoothstep( pct-0.01, pct, st.x) -
          smoothstep( pct, pct+0.01, st.x);
}

vec3 hsb2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix( vec3(1.0), rgb, c.y);
}

float tentacule(in vec2 st, in float freq, bool isVertical, bool isLfromR)
{
    float coord;
    if(isVertical)
    {
        coord = st.y;
    }
    else
    {
        coord = st.x;
    }
    
    float amplitude = 1.0 - coord;
    float pct;
    if(isLfromR)
    {
        pct = cos((coord + time) * freq) / 2.0 + 0.5;
        pct = 0.5 * coord + pct * amplitude ;
    }
    else
    {
        pct = cos((amplitude + time) * freq) / 2.0 + 0.5;
        pct = 0.5 * amplitude + pct * coord ;
    }
    
    
    if(isVertical)
    {
        float pos =plotY(st, pct);
        return pos;
    }
    else
    {
        float pos =plotX(st, pct);
        return pos;
    }
}

void main(void)
{
    vec2 st = gl_FragCoord.xy/resolution.xy;
    
    float freq = 0.5;
    
    vec2 toCenter = vec2(0.5)-st;
    float angle = atan(toCenter.y,toCenter.x);
    float radius = length(toCenter)*2.0;

    vec3 color = hsb2rgb(vec3((angle/TWO_PI)+0.5,radius,1.0));    
    
    float ten;
    
    for(int i = 0; i < 40; i++)
    {
        if(i < 20)
        {
            if(i <= 10)
            {
                ten = ten + tentacule(st,freq * float(i),false,false);
            }
            else
            {
                ten = ten + tentacule(st,freq * float(i - 10),false,true);
            }
        }
        else
        {
            if(i <= 30)
            {
                ten = ten + tentacule(st,freq * float(i - 20),true,false);
            }
            else
            {
                ten = ten + tentacule(st,freq * float(i - 30),true,true);
            }
        }
        
    }
    
    
    vec3 res;
    res = res + vec3(ten) * color;

    // Output to screen
    glFragColor = vec4(res,1.0);
}
