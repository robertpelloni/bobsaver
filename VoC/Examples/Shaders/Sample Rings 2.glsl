#version 420

// original https://www.shadertoy.com/view/MtS3Dt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat3 rotX(float a);
mat3 rotY(float a);
mat3 rotZ(float a);
mat3 rot(vec3 z,float a);
float dist(vec3 p);
vec3 normal(vec3 p);
vec3 myRefract(vec3 i, vec3 n, float r);
vec4 background(vec3 v);

vec4 background(vec3 v)
{
    vec4 c1 = vec4(0.0);
    vec4 c2 = vec4(1.0);
    if(fract(v.y*10.0) < 0.5){
        if(fract(5.0*atan(v.x/v.z)+0.5) < 0.5)
        {
            return c1;
        }
        else
        {
            return c2;
        }
    }
    else
    {
        if(fract(5.0*atan(v.x/v.z)+0.5) < 0.5)
        {
            return c2;
        }
        else
        {
            return c1;
        }
    }
}

mat3 rotX(float a)
{
    float c=cos(a);
    float s=sin(a);
    return mat3(1.0,0.0,0.0,0.0,c,-s,0.0,s,c);
}

mat3 rotY(float a)
{
    float c=cos(a);
    float s=sin(a);
    return mat3(c,0.0,s,0.0,1.0,0.0,-s,0.0,c);
}

mat3 rotZ(float a)
{
    float c=cos(a);
    float s=sin(a);
    return mat3(c,-s,0.0,s,c,0.0,0.0,0.0,1.0);
}

mat3 rot(vec3 z,float a)
{
    float c=cos(a);
    float s=sin(a);
    float ic=1.0-c;
    return mat3(
        ic*z.x*z.x+c,ic*z.x*z.y-z.z*s,ic*z.z*z.x+z.y*s,
        ic*z.x*z.y+z.z*s,ic*z.y*z.y+c,ic*z.y*z.z-z.x*s,
        ic*z.z*z.x-z.y*s,ic*z.y*z.z+z.x*s,ic*z.z*z.z+c);
}

float dist(vec3 p)
{
    float d = 100.0;
    vec3 tp; /*temp point*/
    for(int i = 0; i < 4; i++)
    {
        tp = p*rotX(time/float(i+1));
        tp *=rotZ(2.0*time/float(i+1));
        d = min(d,length(vec2(length(tp.xz)-0.5*float(i)-0.3, tp.y))-0.2);
    }
    return d;
}

vec3 normal(vec3 p, float d)
{
    vec3 s=vec3(0.1,0.0,0.0);
    return normalize(vec3(
        dist(p+s.xyy-d),
        dist(p+s.yxy-d),
        dist(p+s.yyx-d)));
}

vec3 myRefract(vec3 i, vec3 n, vec3 r)
{
    float d = abs(dot(i,n));
    return normalize(i+n*abs(dot(i,n))*0.1);
}

void main(void)
{
    /*screen coordinates (sc)*/
    vec2 sc = vec2(gl_FragCoord.x-0.5*resolution.x,gl_FragCoord.y-0.5*resolution.y);
    sc /= resolution.xy;
    sc.x *= resolution.x/resolution.y;
    
    /*calculate vectors for raymarching*/
    vec3 upVec = vec3(0.0,-1.0,0.0);/*up vector is on y-axis*/
    vec3 lookPos = vec3(0.0,0.0,0.0); /*eye looking at origin*/
    vec3 eyePos = vec3(0.0,0.0,-5.0); /*eye offset on z-axis*/
    
    /*animate camera*/
    eyePos *= rotX(sin(0.1*time));
    eyePos *= rotY(sin(0.2*time));
    
    vec3 rayVec = normalize(lookPos - eyePos); /*direction of ray*/
    
    /*calculate a vector pointing directly to the left of the eye*/
    vec3 leftVec = normalize(cross(upVec,rayVec));
    /*calculate the up for the eye*/
    vec3 eyeUpVec = normalize(cross(rayVec,leftVec));
    
    rayVec *= rot(eyeUpVec,sc.x*0.8);
    rayVec *= rot(leftVec,sc.y*0.8);
    
    /*march ray*/
    float d;
    float marchLen;
    vec3 rayPos = eyePos;
    vec4 attenuation = vec4(1.0);
    vec4 color = vec4(1.0,0.95,1.0,1.0);
    bool hit = false;
    for(int i = 0; i < 50; i++)
    {
        d = dist(rayPos);
        if(d < 0.0 && hit == false)
        {
            hit = true;
            vec3 n = normal(rayPos, d);
            rayVec = refract(rayVec, n, 1.0/1.5);
            attenuation *= color*abs(dot(rayVec,n));
        }
        else if(d > 0.0 && hit == true)
        {
            hit = false;
            vec3 n = normal(rayPos, d);
            rayVec = refract(rayVec, -n, 1.0/1.5);
            attenuation *= color*abs(dot(rayVec,n));
        }
        marchLen = max(0.001,abs(d));
        rayPos += rayVec*marchLen;
    }
    
    
    glFragColor = background(rayVec)*attenuation;

}
