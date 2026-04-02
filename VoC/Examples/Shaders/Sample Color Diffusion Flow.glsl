#version 420

// original https://www.shadertoy.com/view/4sGczR

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*{
  "CREDIT": "by mojovideotech",
  "DESCRIPTION": "from http://glslsandbox.com/e#35553.0",
  "CATEGORIES": [
    "fluid",
    "liquid"
  ],
  "INPUTS": [
      {
            "NAME" :    "rate1",
            "TYPE" :    "float",
            "DEFAULT" :    1.9,
            "MIN" :    -3.0,
            "MAX" :    3.0
    },

     {
            "NAME" :    "rate2",
            "TYPE" :    "float",
            "DEFAULT" :    0.6,
            "MIN" :    -3.0,
            "MAX" :    3.0
    },
    {
            "NAME" :    "loopcycle",
            "TYPE" :    "float",
            "DEFAULT" :    85.0,
            "MIN" :    20.0,
            "MAX" :    100.0
    },
    {
            "NAME" :    "color1",
            "TYPE" :    "float",
            "DEFAULT" :    0.45,
            "MIN" :    -2.5,
            "MAX" :    2.5
    },
    {
            "NAME" :    "color2",
            "TYPE" :    "float",
            "DEFAULT" :    1.0,
            "MIN" :    -1.25,
            "MAX" :    1.125
    },
    {
            "NAME" :    "cycle1",
            "TYPE" :    "float",
            "DEFAULT" :    1.33,
            "MIN" :    0.01,
            "MAX" :    3.1459
    },
    {
            "NAME" :    "cycle2",
            "TYPE" :    "float",
            "DEFAULT" :    0.22,
            "MIN" :    -0.497,
            "MAX" :    0.497
    },
    {
            "NAME" :    "nudge",
            "TYPE" :    "float",
            "DEFAULT" :    0.095,
            "MIN" :    0.001,
            "MAX" :    0.01
    },
    {
                  "NAME" :    "depthX",
                  "TYPE" :     "float",
                  "DEFAULT" :    0.85,
                  "MIN" :     0.001,
                  "MAX" :        0.9
        },
        {
                  "NAME" :    "depthY",
                  "TYPE" :    "float",
                  "DEFAULT" :    0.25,
                  "MIN" :     0.001,
                  "MAX" :        0.9
        }
  ]
}*/

///////////////////////////////////////////
// ColorDiffusionFlow  by mojovideotech
//
// based on :
// glslsandbox.com/\e#35553.0
//
// Creative Commons Attribution-NonCommercial-ShareAlike 3.0
///////////////////////////////////////////

float rate1 =1.9;
float rate2 =0.6;
float loopcycle =85.0;
float color1 =0.45;
float color2 =1.0;
float cycle1=1.33;
float cycle2=0.22;
float nudge=0.095;
float depthX=0.85;
float depthY=0.25;
 
float    pi   =    3.141592653589793;    // pi

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    
    float T = time * rate1;
    float TT = time * rate2;
    //vec2 p=(2.*isf_FragNormCoord);
    vec2 p=(2.*uv);
    
    for(int i=1;i<11;i++) {
        vec2 newp=p;
        float ii = float(i);  
        newp.x+=depthX/ii*sin(ii*pi*p.y+T*nudge+cos((TT/(5.0*ii))*ii));
        newp.y+=depthY/ii*cos(ii*pi*p.x+TT+nudge+sin((T/(5.0*ii))*ii));
        p=newp+log(date.w)/loopcycle;
  }
    
    
    vec3 col=vec3(cos(p.x+p.y+3.0*color1)*0.5+0.5,sin(p.x+p.y+6.0*cycle1)*0.5+0.5,(sin(p.x+p.y+9.0*color2)+cos(p.x+p.y+12.0*cycle2))*0.25+.5);
    

    // Output to screen
    glFragColor = vec4(col*col, 1.0);
}
