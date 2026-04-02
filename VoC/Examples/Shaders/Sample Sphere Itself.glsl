#version 420

// original https://www.shadertoy.com/view/dtd3DH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float gStep = .4;
vec4 hash42(vec2 p)
{
    vec4 p4 = fract(p.xyxy * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

void main(void) //WARNING - variables void ( out vec4 o, in vec2 gl_FragCoord.xy ) need changing to glFragColor and gl_gl_FragCoord.xy
{
    vec4 o = vec4(0.0);
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 uvo = uv-.5;
    uv.x *= resolution.x / resolution.y;
    uv += vec2(uv.y,-uv.x)*.2;
    uv *= 2.5;
    uv += 100.+time*.2;
    o = vec4(0);
    float od = 1.;

    vec2 id = floor(uv);
    uv.y += (fract(id.x/3.)-.5)*time;
    
    for (float i = 0.; i < 1.; i += gStep)
    {
        id = floor(uv);
        vec4 h = hash42(id);
        uv.x += (fract(id.y/3.)-.5)*(10.+time)*i*(.5+h.z)*2.;
        id = floor(uv);

        h = hash42(id);

        vec2 p = uv-id;
        //float d = .5-max(abs(p.x-.5),abs(p.y-.5));
        float d = (max(0.,.5-length(p-.5)));

        o = h;

        uv -= id+.5;
        uv /= max(.02,sqrt(d)*(3.+h.a));
        uv += id+.5;
        od *= (d);
    }
    o *= gStep*pow(od,.4)*20.;
    o = clamp(o,0.,1.);
    o *= 1.-dot(uvo,2.*uvo);
    glFragColor=o;    
}