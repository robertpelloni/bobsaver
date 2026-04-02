#version 420

// original https://www.shadertoy.com/view/ldjBRW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//---------------------------------------------------------
// SpaceGlowing2.glsl  by Antony Holzer          2017-07-11
// variantOf: https://www.shadertoy.com/view/4dyGWt
// original:  https://www.shadertoy.com/view/MtX3Ws
// see also:  https://www.shadertoy.com/view/Mlj3zW
// simplified edit: Robert 25.11.2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// tags:      raytrace, 3d, space, antialiasing, glowing, satiny
//---------------------------------------------------------

vec3 roty (vec3 pos, float angle)
{ 
    float sa = sin(angle), ca = cos(angle);
    return mat3(ca,0,-sa, 0,1,0, sa,0,ca) * pos;
}

float map (in vec3 p) 
{
    vec3 c = p; 
    float res = 0.0;
    for (int i=0; i < 4; i++) 
    {
        p = abs(p) / dot(p,p) -0.7;
        p.yz = vec2(p.y*p.y-p.z*p.z, 2.*p.y*p.z);
        res += exp(-20.0 * abs(dot(p,c)));
    }
    return res * 0.4;
}

vec3 raymarch (vec3 ro, vec3 rd)
{
    float t = 5.0;
    float c = 0.0;
    vec3 col = vec3(0.0); 
    for (int i=0; i < 6; i++)
    {
        t += exp(c * -2.0) * 0.02;
        c = map(t * rd + ro);               
        col= vec3(4.0*c, 2.0*c, 6.0*c*c*c) *0.16 + col *0.6;
        c = map(t*0.99 * rd + ro);               
        col+= vec3(4.0*c*c*c, 2.0*c*c, c) *0.16 + col *0.6;
        c = map(t*1.01 * rd + ro);               
        col+= vec3(4.0*c, 18.0*c*c*c, -33.*c*c)*0.16 + col *0.6;
        /* // blue
        col= vec3(c*c, c, 6.0*c*c*c) *0.16 + col *0.96;
        col= vec3(8.0*c*c*c, 2.0*c*c, 8.0*c) *0.16 + col *0.96;
        col= vec3(c, 18.0*c*c*c, 8.0*c*c)*0.16 + col *0.96;
        */
    }
    return col*0.2;
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy - resolution.xy*0.5) / resolution.y;
    vec3 ro = roty(vec3(3.), time*0.2 + resolution.x / resolution.x);
    vec3 uu = normalize(cross(ro, vec3(1.0, 0.0, 0.0)));
    vec3 vv = normalize(cross(uu, ro));
    vec3 rd = normalize(p.x*uu + p.y*vv - ro*0.5);
    glFragColor.rgb = log(raymarch(ro,rd) + 1.0)*0.5;
    glFragColor.a = 1.0;
}
