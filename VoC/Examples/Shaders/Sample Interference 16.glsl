#version 420

// original https://www.shadertoy.com/view/3sV3Rd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy/vec2(resolution.y);
    float freq = 30.0;
    float Fade = 20.0;
    float i = 0.07;
    //float i = 0.0;
    float AddBri = 1.0;
    vec2 CirCen0 = vec2(0.9-(cos((time+5.0)*0.27)*0.9),0.5+(0.5*cos(time*.33)));
    vec2 CirCen1 = vec2(0.9-(cos(time*0.59)*0.9),0.5+(0.5*cos((time+5.0)*.41)));
    float MyDist0 = distance(CirCen0,uv);   
    float MyDist1 = distance(CirCen1,uv);

    float DarknessR = 0.0;
    float DarknessY = 0.0;
    float DarknessG = 0.0;
    float DarknessB = 0.0;
    float DarknessV = 0.0;
    
    DarknessR += cos(MyDist0*freq)/((MyDist0*MyDist0*Fade)+1.0);
    MyDist0 += i;
    DarknessY += cos(MyDist0*freq)/((MyDist0*MyDist0*Fade)+1.0);
    MyDist0 += i;
    DarknessG += cos(MyDist0*freq)/((MyDist0*MyDist0*Fade)+1.0);
    MyDist0 += i;
    DarknessB += cos(MyDist0*freq)/((MyDist0*MyDist0*Fade)+1.0);
    MyDist0 += i;
    DarknessV += cos(MyDist0*freq)/((MyDist0*MyDist0*Fade)+1.0);    
    
    DarknessR += cos(MyDist1*freq)/((MyDist1*MyDist1*Fade)+1.0);
    MyDist1 += i;
    DarknessY += cos(MyDist1*freq)/((MyDist1*MyDist1*Fade)+1.0);
    MyDist1 += i;
    DarknessG += cos(MyDist1*freq)/((MyDist1*MyDist1*Fade)+1.0);
    MyDist1 += i;
    DarknessB += cos(MyDist1*freq)/((MyDist1*MyDist1*Fade)+1.0);
    MyDist1 += i;
    DarknessV += cos(MyDist1*freq)/((MyDist1*MyDist1*Fade)+1.0);    
    
    DarknessY *= 2.0;
    DarknessB *= 2.0;
    
    DarknessR = DarknessR + DarknessY + DarknessV;
    DarknessG = DarknessG + DarknessY;
    DarknessB = DarknessB + DarknessV;
    
    vec3 col = vec3(DarknessR,DarknessG,DarknessB);
    
    glFragColor = vec4(col,1.0);
}
