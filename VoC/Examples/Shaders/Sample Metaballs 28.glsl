#version 420

// original https://www.shadertoy.com/view/tdffWX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define Iterations 100
#define SafeDist 0.01
#define MaxDist 50.
#define NumberOfObj 19
#define CamPos vec3(0, 2.5, -12)
//#define LightPos vec3(cos(time*2.)*10. ,5, sin(time*2.)*10.)
#define LightPos vec3(0., sin(time)*2.+5., -10.)
//#define CamRotate vec3(1, 2, 1);

float DistCube(vec3 p, vec4 s)
{
    vec3 q = abs(p - s.xyz) - s.w;
    return length(max(q, 0.)) + min(max(q.x, max(q.y, q.z)), 0.);
}

float DistSphere(vec3 p, vec4 sphere/*x pos, y pos, z pos, r*/)
{
    return length(p-sphere.xyz)-sphere.w;
}

float DistPlane(vec3 p, float y)
{
     return p.y - y;   
}

float Soft_min(float a, float b, float r)
{
    float e = max(r - abs(a - b), 0.0);
    return min(a, b) - e*e*0.25 / r;
}

float Dist(vec3 p)
{
    float Dists[NumberOfObj];
    Dists[0] = DistPlane(p, 0.);
    Dists[1] = DistSphere(p, vec4(sin(time)*3., sin(time*3.), cos(time)*3., 1));
    Dists[2] = DistSphere(p, vec4(sin(time+1.0472)*3., sin(time*3.+1.0472) +1., cos(time+1.0472)*3.  ,1));
    Dists[3] = DistSphere(p, vec4(sin(time+2.0944)*3., sin(time*3.+2.0944)+1., cos(time+ 2.0944)*3. ,1));
    Dists[4] = DistSphere(p, vec4(sin(time+3.14159)*3.,sin(time*3.+3.14159)+1.,cos(time+ 3.14159)*3.,1));
    Dists[5] = DistSphere(p, vec4(sin(time+4.18879)*3.,sin(time*3.+4.18879)+1.,cos(time+ 4.18879)*3.,1));
    Dists[6] = DistSphere(p, vec4(sin(time+5.23599)*3.,sin(time*3.+5.23599)+1.,cos(time+ 5.23599)*3.,1));
    Dists[7] = DistSphere(p, vec4(cos(time)*3., cos(time*3.) + 2., sin(time)*3., 1));
    Dists[8] = DistSphere(p, vec4(cos(time+1.0472)*3., cos(time*3.+1.0472)+ 3., sin(time+1.0472)*3.  ,1));
    Dists[9] = DistSphere(p, vec4(cos(time+2.0944)*3., cos(time*3.+2.0944)+ 3., sin(time+ 2.0944)*3. ,1));
    Dists[10] =DistSphere(p, vec4(cos(time+3.14159)*3.,cos(time*3.+3.14159)+ 3.,sin(time+ 3.14159)*3.,1));
    Dists[11] =DistSphere(p, vec4(cos(time+4.18879)*3.,cos(time*3.+4.18879)+ 3.,sin(time+ 4.18879)*3.,1));
    Dists[12] =DistSphere(p, vec4(cos(time+5.23599)*3.,cos(time*3.+5.23599)+ 3.,sin(time+ 5.23599)*3.,1));
    Dists[13] = DistSphere(p, vec4(sin(time)*3., sin(time*3.), cos(time)*3., 1));
    Dists[14] = DistSphere(p, vec4(sin(time+1.0472)*3., sin(time*3.+1.0472) +5., cos(time+1.0472)*3.  ,1));
    Dists[15] = DistSphere(p, vec4(sin(time+2.0944)*3., sin(time*3.+2.0944)+5., cos(time+ 2.0944)*3. ,1));
    Dists[16] = DistSphere(p, vec4(sin(time+3.14159)*3.,sin(time*3.+3.14159)+5.,cos(time+ 3.14159)*3.,1));
    Dists[17] = DistSphere(p, vec4(sin(time+4.18879)*3.,sin(time*3.+4.18879)+5.,cos(time+ 4.18879)*3.,1));
    Dists[18] = DistSphere(p, vec4(sin(time+5.23599)*3.,sin(time*3.+5.23599)+5.,cos(time+ 5.23599)*3.,1));
    
    float minD = Dists[0];
    for(int i = 0; i < NumberOfObj - 1; i++)
    {
        minD = Soft_min(minD, Dists[i + 1],1.);
    }
    return minD;
}

float RayMarch(vec3 ro, vec3 rd)
{
    float dO = 0.;
    for(int i = 0; i < Iterations; i++)
    {
        vec3 p = ro + dO*rd;
        float ds = Dist(p);
        dO += ds;
        if(ds < SafeDist || dO > MaxDist)
        {
            break;
        }
    }
    return dO;
    
}
vec3 GetNormal(vec3 p) {
    float d = Dist(p);
    vec2 e = vec2(.01, 0);
    
    vec3 n = d - vec3(
        Dist(p-e.xyy),
        Dist(p-e.yxy),
        Dist(p-e.yyx));
    
    return normalize(n);
}

float GetLight(vec3 p) {
    vec3 lightPos = LightPos;
    vec3 l = normalize(lightPos-p);
    vec3 n = GetNormal(p);
    
    float dif = clamp(dot(n, l), 0., 1.);
    float d = RayMarch(p+n*SafeDist*2., l);
    if(d<length(lightPos-p)) dif *= .5;
    return dif;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
    vec3 col = vec3(0);
    vec3 ro = CamPos;
    vec3 rd = normalize(vec3(uv.x, uv.y, 1));
    float d = RayMarch(ro, rd);
    vec3 p = ro+d*rd;
    float dif = GetLight(p);
    col = vec3(dif);
    glFragColor = vec4(col,1.0);

}
