#version 420

// original https://www.shadertoy.com/view/3sVGDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define POINTS 9.
#define PARTITIONS 7.

const float PI2 = 6.28;

vec4 hash41(float p)
{
    vec4 p4 = fract(vec4(p) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

void main(void)
{
    vec2 C = gl_FragCoord.xy;
    vec4 o = glFragColor;

    vec2 R = resolution.xy;
    vec2 N = C/R-.5;
    vec2 uv = N;
    uv.x *= R.x/R.y;
    float t = time  *.5;
    uv *= 1.7;

    vec4 nearestPt = vec4(1e4);//xy=pt, z = seed, w=dist
    vec4 nearestPt2;// second-nearest point. xy=pt, z = seed, w=dist
    o = vec4(1.);
    float ipartition = 0.;
    for (; ipartition < PARTITIONS; ++ ipartition) {
        vec4 hpart = hash41(1e2+ipartition);
        for (float i = 0.; i < POINTS; ++ i) {
            vec4 h = hash41((i+1.)*PARTITIONS+(ipartition+1.));
            vec4 pt = vec4(
                sin((h.x)*PI2+t*h.z)*.5,// generating points could be improved; this is pretty bad 4real
                cos((h.y)*PI2+t*h.w)*.5,
                h.z,// some kind of random seed
                0);

            pt.w = length(uv - pt.xy);
            o.rgb /= clamp(pt.w*3.,0.1,1.);

               pt.w *= pt.w;
            if (pt.w < nearestPt.w) {
                nearestPt2 = nearestPt;
                nearestPt = pt;
            } else if (pt.w < nearestPt2.w) {
                nearestPt2 = pt;
            }
        }

        // just for performance, trying to avoid a 2nd hash here. but it means
        // certain colors will be favored visually. i don't mind, that's an opportunity
        // to stylize
        //o *= hash41(nearestPt.z*1e2);
        o.rgb *= nearestPt.zxy;
        float d = nearestPt2.w - nearestPt.w;
        if (d < 0.02) {
            // if dist to 2nd-nearest point is small, then we're on a border
            break;
        }
        
        uv -= nearestPt.xy*(sin(t*1.5)+.2);// blossom effect
        uv *= 1.1;
        uv = uv.yx; // cheap attempt to reduce regularity
    }
    
    o /= ipartition + 1.;
    o = clamp(o,0.,1.);
    o = pow(o, o-o+.5);

    glFragColor = o;
}

