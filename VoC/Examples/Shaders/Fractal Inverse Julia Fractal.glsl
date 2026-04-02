#version 420

// original https://www.shadertoy.com/view/st2SRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 Mult(vec2 A,vec2 B)
{
    return vec2(A.x*B.x-A.y*B.y,A.x*B.y+A.y*B.x);
}
vec2 Div(vec2 A, vec2 B)
{
    return vec2(A.x*B.x+A.y*B.y,-A.x*B.y+A.y*B.x)/dot(B,B);
}
void main(void)
{
    vec2 uv = 4.5*(gl_FragCoord.xy-resolution.xy*0.5)/resolution.x;
    vec2 Z = vec2(uv);
    
    float angle1=time*0.2;
    float angle2=angle1*0.4;
    vec2 C = vec2(cos(angle2),sin(angle2))*0.30;
    vec2 A=vec2(cos(angle1),sin(angle1));
    vec2 B=-A*0.04;
    glFragColor = vec4(1,0,1,0);
    vec2 Der =vec2(1,0);
    for(int i =0;i<20;i++)
    {
        Z=Mult(A,Mult(Z,Z))+Div(B,Mult(Z,Z))+C;
        Der =2.0*Mult(Der,Mult(A,Z)-Div(B,Mult(Z,Mult(Z,Z))));
        float D = Z.x*Z.x+Z.y*Z.y;
        if(D>20.0)
        {
            float e=-2.0+log(log(D)/(log(2.0)*2.0))/log(2.0);
            float a=(float(i)-e)/20.0;
            a=pow(a,0.8);
            glFragColor=vec4(a*a,0,a,1);
            return;
        }
    }
    float d = Der.x*Der.x+Der.y*Der.y;
    d=pow(d,0.15);
    glFragColor = vec4(1,0,1,0)*d+vec4(0.3,0.2,0.8,0)*(1.0-d);
}
