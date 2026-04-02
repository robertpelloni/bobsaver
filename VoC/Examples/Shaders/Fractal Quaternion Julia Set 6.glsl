#version 420

// original https://www.shadertoy.com/view/ws2fDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float Sq(float x)
{
    return x*x;
}
vec4 QuaternionMultiply(vec4 Q1, vec4 Q2)
{
    return vec4(
    Q1.x*Q2.x-Q1.y*Q2.y-Q1.z*Q2.z-Q1.w*Q2.w,
    Q1.x*Q2.y+Q1.y*Q2.x+Q1.z*Q2.w-Q1.w*Q2.z,
    Q1.x*Q2.z-Q1.y*Q2.w+Q1.z*Q2.x+Q1.w*Q2.y,
    Q1.x*Q2.w+Q1.y*Q2.z-Q1.z*Q2.y+Q1.w*Q2.x 
    );
}
vec2 DistanceEstimate(vec4 A)
{
    //change this 4d vector to change the shape of the julia set, or add some time based changes aswell if you want ;)
    vec4 C = vec4(-0.76,0,-0.14,0);
    vec4 DZ = vec4(1,0,0,0);
    vec4 Z = A;
    for(int i =0;i<100;i++)
    {
        DZ = 2.0*QuaternionMultiply(Z,DZ)+vec4(0.7,0,0,0);
        Z = QuaternionMultiply(Z,Z)+C;
        
        if(length(Z)>100.0)
        {
            float r = length(Z);
            float dr = length(DZ);
            return vec2(r*log(r)/(dr),i);
            
        }
    }
    return vec2(-1.0,0);
    
}
vec4 GetQuat(vec3 V)
{
    return vec4(V.y,V.x,V.z,0.0);
}
vec3 HueColor(float H)
{
    return 0.5*(sin(H+vec3(0,2.094,4.188))+1.0);
}
vec3 GetColor(float Iter,float Hit,vec3 BaseColor)
{
    Iter-=0.0;
    Iter=max(0.0,Iter);
    vec3 Col = vec3(0.2,0.4,0.7)*(1.0-Hit)*0.8;
    Col+=BaseColor*Hit;
    Col+=vec3(1,1,1)*(1.0-exp(-Iter*0.004))*0.8;
    return Col;
}
vec3 Ray(vec3 Pos,vec3 Vel)
{
    Pos+=Vel*(-Pos.x/Vel.x);//comment out this line to see the full 3d shape without the cross section in the middle
    vec3 Background=vec3(0,0,0);
    vec3 Color=vec3(0,0,0);
    float CloudDensity=0.0;
    float iter=0.0;
    for(int i =0;i<400;i++)
    {
        vec4 Quat = GetQuat(Pos);
        vec2 Output = DistanceEstimate(Quat);
        float Dist = Output.x;
        Dist = min(4.0,Dist)*0.5;
        if(Dist<0.0004)
        {
            return GetColor(iter,1.0,HueColor(Output.y*0.06)*0.7);
        }
        if(length(Pos)>10.0)
        {
            return GetColor(iter,0.0,vec3(0,0,0));
        }
        iter+=exp(-4.0*Dist);
        Pos+=Vel*Dist;
    }
    return GetColor(iter,0.0,vec3(0,0,0));
}
void RotateCamera(float Angle1,float Angle2,inout vec3 V)
{
    vec3 Out=vec3(0,0,0);
    float Cos1=cos(Angle1);
    float Sin1=sin(Angle1);
    float Cos2=cos(Angle2);
    float Sin2=sin(Angle2);
    //camera rotations
    V.yz = mat2(Cos2, Sin2, -Sin2, Cos2)*V.yz;
    V.xz = mat2(Cos1, Sin1, -Sin1, Cos1)*V.xz;
}
void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    
    uv*=1.0;
    vec3 RayHeading=vec3(uv.y,uv.x,1);
    
    float Angle1=time/3.0;
    float Angle2=0.7;
    
    RotateCamera(Angle2,0.0,RayHeading);
    RotateCamera(0.0,Angle1,RayHeading);
    
    vec3 CameraPos=vec3(0,0,-2.0);
    
    RotateCamera(Angle2,0.0,CameraPos);
    RotateCamera(0.0,Angle1,CameraPos);
    
    
    vec3 RayPos=CameraPos+vec3(-0.2,0,0);
    
    RayHeading/=length(RayHeading);
    vec3 col = Ray(RayPos,RayHeading);
    
    glFragColor = vec4(col,1.0);
}
