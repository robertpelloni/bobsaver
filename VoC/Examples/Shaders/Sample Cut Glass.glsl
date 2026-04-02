#version 420

// original https://www.shadertoy.com/view/ddBXDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution.xy
#define M mouse*resolution.xy
#define HUE(a) (sin(vec3(0, 1.047, 2.094)+vec3(a*6.3))*.5+.5)
mat2 rot(float a) { float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }
float boxes(vec3 p) { p = abs(fract(p+.5)-.5); return max(p.x, max(p.y, p.z)); }
void main(void)
{
    float t = time/4.;
    vec2 m = (M.xy/R*4.)-2.; // mouse coords
    vec3 bg = vec3(0); // background
    float aa = 2.; // anti-aliasing (1 = off)
    for (float j = 0.; j < aa; j++)
    for (float k = 0.; k < aa; k++)
    {
        vec2 o = vec2(j, k)/aa; // offset
        vec2 uv = (gl_FragCoord.xy-.5*R+o)/R.y; // 2d screen coords
        vec3 rd = normalize(vec3(uv, .7)); // 3d uv (ray direction)
        vec3 ro = vec3(vec2(.5), t); // camera (ray origin)
        //if (M.z < 1.) m = vec2(cos(t/2.)*.5+.5); // rotate with time when not clicking
        m = vec2(cos(t/2.)*.5+.5); // rotate with time when not clicking
        rd.yz *= rot(m.y*1.57); // pitch
        rd.xz *= rot(m.x*1.57); // yaw
        float d = 0.; // step dist for raymarch
        for (int i = 0; i < 50; i++)
        {
            vec3 p = ro+rd*d;
            d += smoothstep(.2, .25, boxes(p)-.05);
        }
        vec3 c = vec3(0);
        c += d*.01; // objects
        c *= HUE(length(rd.xy)); // background color
        c += max(c, .5-HUE(d)); // rainbow fringe
        bg += c;
    }
    bg /= aa*aa;
    glFragColor = vec4(pow(bg, vec3(.4545)), 1.);
}
