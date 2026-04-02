#version 420

// original https://www.shadertoy.com/view/3sjXDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Per Bloksgaard/2019
// Analytical solution for ray tracing 3D quadratic bezier curves.

precision highp float;
#define PI 3.14159265358979
const float thickness = 35e-3;

//Find roots using Cardano's method. http://en.wikipedia.org/wiki/Cubic_function#Cardano.27s_method
vec2 solveCubic2(float a, float b, float c)
{
    float p = b-a*a/3., p3 = p*p*p;
    float q = a*(2.*a*a-9.*b)/27.+ c;
    float d = q*q+4.*p3/27.;
    float offset = -a / 3.;
    if(d>0.)
    { 
        float z = sqrt(d);
        vec2 x = (vec2(z,-z)-q)*0.5;
        vec2 uv = sign(x)*pow(abs(x), vec2(1./3.));
        return vec2(offset + uv.x + uv.y);
    }
    float v = acos(-sqrt(-27./p3)*q/2.)/3.;
    float m = cos(v), n = sin(v)*1.732050808;
    return vec2(m + m, -n - m) * sqrt(-p / 3.0) + offset;
}

// How to resolve the equation below can be seen on this image.
// http://www.perbloksgaard.dk/research/DistanceToQuadraticBezier.jpg
vec3 intersectQuadraticBezier2(vec3 p0, vec3 p1, vec3 p2) 
{
    vec2 A2 = p1.xy - p0.xy;
    vec2 B2 = p2.xy - p1.xy - A2;
    vec3 r = vec3(-3.*dot(A2,B2), dot(-p0.xy,B2)-2.*dot(A2,A2), dot(-p0.xy,A2)) / -dot(B2,B2);
    vec2 t = clamp(solveCubic2(r.x, r.y, r.z), 0., 1.);
    vec3 A3 = p1 - p0;
    vec3 B3 = p2 - p1 - A3;
    vec3 D3 = A3 * 2.;
    vec3 pos1 = (D3+B3*t.x)*t.x+p0;
    vec3 pos2 = (D3+B3*t.y)*t.y+p0;
    pos1.xy /= thickness;
    pos2.xy /= thickness;
    float pos1Len = length(pos1.xy);
    float pos2Len = length(pos2.xy);
    pos1.z -= cos(pos1Len)*thickness;
    pos2.z -= cos(pos2Len)*thickness;
    if (pos1Len < 1.0 && pos2Len < 1.0)
    {
        return (pos1.z < pos2.z) ? vec3(pos1Len,pos1.z,t.x) : vec3(pos2Len,pos2.z,t.y);
    }
    else
    {
        if (pos1Len < 1.0)
        {
            return vec3(pos1Len,pos1.z,t.x);
        }
        if (pos2Len < 1.0)
        {
            return vec3(pos2Len,pos2.z,t.y);
        }
        return vec3(1e8,1e8,0.0);
    }
}

// Convert HSL colorspace to RGB. http://en.wikipedia.org/wiki/HSL_and_HSV
vec3 HSLtoRGB(in float h, in float s, in float l)
{
    vec3 rgb = clamp(abs(mod(h+vec3(0.,4.,2.),6.)-3.)-1.,0.,1.);
    return l+s*(rgb-0.5)*(1.-abs(2.*l-1.));
}

mat3 inverseViewRotation(vec3 ww)
{
    vec3 uu = normalize(cross(ww,vec3(0.,1.,0.)));
    vec3 vv = normalize(cross(uu,ww));
    return mat3(uu,vv,ww);
}

void main(void)
{
    vec2 s = -1.0+2.0*gl_FragCoord.xy/resolution.xy;
    s.x *= resolution.x/resolution.y;
    vec3 vCamPos = vec3(0.0,1.1,-1.2-sin(time*0.35)*0.5);
    vec3 vCamTarget = vec3(0.0,0.5,0.0);
    vec3 vCamForward = normalize(vCamTarget-vCamPos);

    vec3 vCamRight = normalize(cross(vCamForward,vec3(0.,1.,0.)));
    vec3 vCamUp = normalize(cross(vCamRight,vCamForward));
    vec3 vRayDir = normalize(s.x*vCamRight+s.y*vCamUp+vCamForward*1.5);
    mat3 m = inverseViewRotation(vRayDir);

    vec3 bRes = vec3(1e4,1e4,0.);
    float bI = 0.;
    for (float i=1.; i<19.; i+=1.)
    {
        float t = (time+i*0.15+11.)*0.5;
        vec3 p0 = vec3(sin(0.15-t*0.74)*2.0,cos(t*-1.17)*2.0,0.61+sin(0.3+t*1.71)*0.5);
        vec3 p1 = vec3(cos(t*-0.85)*2.13,sin(-t*0.432)*2.134,0.61+cos(0.2+-t*0.64)*0.5);
        vec3 p2 = vec3(sin(0.45-t*1.72)*2.,cos(t*1.331)*1.972,0.61+sin(0.9-t*0.53)*0.5);
        p1 += vec3(1e-1)*(1.-abs(sign(p1*2.-p0-p2)));
        vec3 lRes = intersectQuadraticBezier2((p0-vCamPos)*m, (p1-vCamPos)*m, (p2-vCamPos)*m);
        if (lRes.y > 0.0 && bRes.y > lRes.y)
        {
            bRes = lRes;
            bI = i;
        }        
    }
    float alpha = 1.-clamp(bRes.x*0.9,0.,1.);
    vec3 color = HSLtoRGB(bRes.z*2.+bI/19.*6.,1.,alpha);
    float t = max(-2./vRayDir.y,0.);
    if (t < bRes.y && vRayDir.y < 0.)
    {
        vec3 pos = vCamPos + vRayDir*t;
        vec2 grid = 5.7-pow(vec2(1.4),abs(vec2(0.5)-fract(pos.xz*4.))*10.2);
        vec3 c = vec3(clamp(min(grid.x,grid.y),0.,1.));
        color = mix(c*clamp(1.-t*0.15,0.,1.),color*0.5,alpha);
    }
    glFragColor = vec4(color,1.);
}
