#version 420

// original https://www.shadertoy.com/view/3dcXRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy/vec2(resolution.y);
    int i = 0;
    const int SquarCount = 5;
    float freq = 50.0;
    float yCal = 0.0;
    float Fade = 1.48;
    
    yCal = resolution.x/resolution.y;
    
    vec2 CirCen0[9];
    CirCen0[0] = vec2(0.9-(cos((time+5.0)*0.27)*0.9),0.5+(0.5*cos(time*.33)));
    CirCen0[1] = vec2(1,-1) * CirCen0[0];
    CirCen0[2] = CirCen0[1]+vec2(0,2);
    CirCen0[3] = vec2(-1,1) * CirCen0[0];
    CirCen0[4] = CirCen0[3]+vec2((yCal)*2.0,0);

    vec2 CirCen1[9];
    CirCen1[0] = vec2(0.9-(cos(time*0.59)*0.9),0.5+(0.5*cos((time+5.0)*.41)));
    CirCen1[1] = vec2(1,-1) * CirCen1[0];
    CirCen1[2] = CirCen1[1]+vec2(0,2);
    CirCen1[3] = vec2(-1,1) * CirCen1[0];
    CirCen1[4] = CirCen1[3]+vec2((yCal)*2.0,0);
    
    float MyDist = 0.0;
    float Darkness = 0.0;
    float Adj = float(SquarCount) * 2.0;
    
    for(int i=0;i<SquarCount;i++)
    {
        MyDist = distance(CirCen0[i],uv);
        if (MyDist < Fade)
        {    
            Darkness += (cos((MyDist*freq)-time*10.0)/(Adj))*(Fade-MyDist);
        }
    }
    for(int i=0;i<SquarCount;i++)
    {
        MyDist = distance(CirCen1[i],uv);
        if (MyDist < Fade)
        {    
            Darkness += (cos((MyDist*freq)-time*10.0)/(Adj))*(Fade-MyDist);
        }
    
    }
    
    Darkness = Darkness+0.5;
    glFragColor = vec4(vec3(Darkness),1.0);
}
