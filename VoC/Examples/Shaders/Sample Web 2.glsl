#version 420

// original https://www.shadertoy.com/view/3djyWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// based on the shader of notargs
// https://www.shadertoy.com/view/3d2cRV

// Web 1 : https://www.shadertoy.com/view/WdSyWV
// Web 2 : https://www.shadertoy.com/view/3djyWG#

// final
const vec4 colorBalance = vec4(0.3,0.7,0.5,0.3);
const vec3 uColor = vec3(0.5,1,0);
const vec3 uFog = vec3(0.005,0.001,0.0035);
const vec3 uLightDir = vec3(-1,-1,1);

// shape
const vec3 uRatio = vec3(-0.37762,0.36364,0);
const float uRot = 0.1;
const vec2 uvOffset = vec2(2.69231,1.71329);

float camZ = 0.0;

vec2 path(float t)
{
    return vec2(cos(t * uRot) * 0.7, 
                sin(t * uRot) * 0.5) * uvOffset;    
}

float map(vec3 p)
{
    float a = p.z * uRot;
    p.xy *= mat2(cos(a),sin(a),-sin(a),cos(a));
    float th = mix(0.001, 0.06, cos(camZ - p.z)*0.5+0.5);
    return th-length(
        sin(p.xyz)*uRatio.x+
        sin(p.zxy)*uRatio.y+
        sin(p.yzx)*uRatio.z);
}

vec3 nor(vec3 p, float prec)
{
    vec3 e = vec3(prec,0,0);
    return normalize(vec3(
        map(p+e)-map(p-e),
        map(p+e.yxz)-map(p-e.yxz),
        map(p+e.zyx)-map(p-e.zyx)));
}

void main(void)
{
    vec2 v = gl_FragCoord.xy;
    vec3 rd = normalize(.5 - vec3(v,1)/resolution.y);
    camZ = time * -5.0;
    vec3 ro = vec3(uvOffset + path(camZ),camZ);
    vec3 p = vec3(0);
    
    float d = 0.0, s = d;
    for(int i=0;i<250;i++)
    {
        if (abs(s)<d*d*1e-6) break;
        d += s = map(p);
        p = ro + rd * d;
    }
    
    vec3 ld = normalize(uLightDir);
    vec3 n = nor(p, 0.01);
    float diff = max(dot(n,-ld),0.0);
    float spec = max(dot(reflect(ld,n), rd),0.0);
    vec3 col = sin(d*uColor)*0.5+0.5;
    vec3 fog = exp(-uFog*d*d);
    vec3 c = 
        diff * colorBalance.x * fog.x + 
        col * colorBalance.y * fog.y + 
        sqrt(spec * colorBalance.z * 10.0) * colorBalance.w * fog.z;
    
    glFragColor = vec4(c, 1);
}
