#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tdy3DD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float RINGS = 15.;

vec4 hash42(vec2 p)
{
    vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

void main(void) //WARNING - variables void ( out vec4 o, in vec2 gl_FragCoord.xy ) need changing to glFragColor and gl_FragCoord
{
    vec4 o = glFragColor;
    
    vec2 R = resolution.xy;
    vec2 uv = gl_FragCoord.xy/R.xy-.5;
    uv.x *= R.x/R.y;
    vec2 N = uv;
    uv *= .3;
    float t = time*.2;

    o = vec4(1);
    for (float i = 1.;i <= RINGS; ++ i) {
        vec4 h = hash42(vec2(i)+3e2);
        vec4 h2 = hash42(h.zw*2e2+4e2);
        h.y -= t * (h.z-.5);
        h.x += h.y*(h2.w-.5)*2.;
        h.xy = fract(h.xy-.5)-.5;// repetition

        float sd = 1e3;
        
        // cheap variations
        for (int s = 0; s < 4; ++ s) {
            vec2 p = fract(h.xy+h2[s]-.5)-.5;
            float sdextra = length(uv - p) - h2.w*h2[(s+1)%4]*.2;
            sd = min(sd, sdextra);
        }
        
        float a = .5/clamp(sd*sd*500.*h2.w, .1,1e3);
        o = mix(o, h2, a);
    }
    float sd = abs(length(uv)-.12)-.01;// center ring
    o /= max(sd, 1e-3)*80.;
    o += (hash42(N*1e3+t)-.5)*.2;
    //remark next line for color version
    o.rgb = mix(o.rgb,(o.rrr+o.g+o.b)/3.,1.);
    glFragColor = o;
}

