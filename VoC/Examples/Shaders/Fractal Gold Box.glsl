#version 420

// original https://www.shadertoy.com/view/lstXRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float T;
vec3 LIGHT;

float MAX = 120.0;
float PRE = 0.01;
//1D Noise Function
float n1(vec3 p)
{
     return fract(cos(dot(floor(p),vec3(17,51,43)))*2736.38); 
}
//Mapping Function
vec3 map(vec3 p, float s)
{
    vec3 S = vec3(8);
    vec3 A = mod(p+s/2.0,s)-s/2.0;
    //vec3 B = max(abs(p)-S,0.0) * sign(p-S);
    return A;
}
//Main Distance Field Function
float model(vec3 p)
{   
    float S = -1.0;
    for(int i = 0;i<7;i++)
    {
        float I = exp2(float(i));
        S = max(S,I/4.0-length(max(abs(map(p,I))-I/8.0,0.0)));
    }
    return S;//max(S,length(max(abs(p)-8.0,0.0)));
}
//Normal Function
vec3 normal(vec3 p)
{
     vec2 N = vec2(-1, 1) * PRE;

     return normalize(model(p+N.xyy)*N.xyy+model(p+N.yxy)*N.yxy+
                     model(p+N.yyx)*N.yyx+model(p+N.xxx)*N.xxx);
}
//Simple Raymarcher
vec4 raymarch(vec3 p, vec3 d)
{
    float S = 0.0;
    float T = S;
    vec3 D = normalize(d);
    vec3 P = p+D*S;
    for(int i = 0;i<240;i++)
    {
        S = model(P);
        T += S;
        P += D*S;
        if ((T>MAX) || (S<PRE)) {break;}
    }
    return vec4(P,min(T/MAX,1.0));
}
//Color/Material Function
vec3 color1(vec3 p, vec3 n)
{
     vec3 C = vec3(1,0.8,0.4)*(0.8+0.2*n1(p/2.0));
    vec3 D = normalize(LIGHT-p);
     float L = smoothstep(-3.0,0.0,model(p+D)-model(p-D*0.5)-model(p-D)-model(p-D*2.0));
          L *= max(dot(n,D),-0.5)*0.5+0.5;
          L *= exp2(1.0-length(LIGHT-p)/16.0);
    
    return C*L;
}
vec3 color2(vec3 p, vec3 d)
{
    vec3 N = normal(p);
    vec3 C = color1(p,N);    
    
    float A = exp2(1.0-length(LIGHT-p)/16.0);
    float R = (1.0-abs(dot(N,d)));
    vec3 D = reflect(d,N);
    return C * mix(vec3(1),color1(p+D,N),R)+pow(max(dot(D,N),0.0),64.0+64.0*n1(p))*A;
}
//Camera Variables
void camera(out vec3 P,out vec3 D, out vec3 X, out vec3 Y, out vec3 Z)
{
    //float M = float((mouse*resolution.xy.x+mouse*resolution.xy.y)>0.0);
    //vec2 A = (0.5-mouse*resolution.xy.xy/resolution.xy)*vec2(6.2831,3.1416);
    float M=0.0;
    vec2 A=vec2(0.0,0.0);
    vec3 F = mix(vec3(1,0,0),vec3(cos(-A.x)*cos(A.y),sin(-A.x)*cos(A.y),sin(A.y)),M);
    P = vec3(-T*16.0,0,0)+24.0*F;

    D = -F;

    X = normalize(D);
    Y = normalize(cross(X,vec3(0.0,0.0,1.0)));
    Z = cross(X,Y);
}

void main(void)
{
    T = time;
    LIGHT = vec3(cos(T)-1.0,sin(T),cos(T*0.5))*8.0-vec3(T*16.0,0,0);

    vec3 P,D,X,Y,Z;
    camera(P,D,X,Y,Z);
    vec2 UV = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.y;
    D = normalize(mat3(X,Y,Z) * vec3(1.0,UV));
    
    vec4 M = raymarch(P,D);
    vec3 COL = vec3(0.01,0.01,0.01)+max(color2(M.xyz,D)*sqrt(1.-M.w),0.0);
    COL += exp2(-length(cross(D,LIGHT-P)));
    glFragColor = vec4(COL,0);
}
