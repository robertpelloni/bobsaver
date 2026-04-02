#version 420

// original https://www.shadertoy.com/view/3dVGDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PARTITIONS = 14.;

vec3 dtoa(float d, vec3 amount){
    return vec3(1. / clamp(d*amount, vec3(1), amount));
}

vec4 hash42(vec2 p)
{
    vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

mat2 rot2D(float r){
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}
void main(void)
{
    vec4 o = glFragColor;

    float t = (time+1e2)*.2;
    vec2 uv = gl_FragCoord.xy/resolution.xy-.5;
    vec2 N = uv;
    uv.x += t*.2;
    vec2 R = resolution.xy;
    uv.x *= R.x / R.y;
    uv.y -= .5;
    
    vec2 cellUL = vec2(-1);
    vec2 cellBR = vec2(1);
    vec2 seed = floor(uv);// cell ID
    uv = fract(uv);
    o = vec4(1);
    N *= .99;// attempt to reduce some artifacting around edges

    for(float i = 1.; i <= PARTITIONS; ++ i) {
        vec4 h = hash42(seed+1e2*(vec2(cellBR.x, cellUL.y)+10.));
        vec2 test = abs(cellUL - cellBR);
        vec2 uv2 = uv;
        float dl = abs(uv2.x - cellUL.x);
        dl = min(dl, length(uv2.y - cellUL.y));
        dl = min(dl, length(uv2.x - cellBR.x));
        dl = min(dl, length(uv2.y - cellBR.y));

        vec3 col = h.rgb;
        col.rb = clamp((col.rg-.5)*rot2D(t*(h.z+i+1.))+.5,0.,1.);
        float r = max(fract(N.x-.5), fract(.5-N.x));
        //r = max(r, fract(.5-N.y));
        //r = max(r, fract(N.y-.5));
        r = 1.-r;
        vec3 col2 = 1.1-dtoa(dl, (h.z+.05)*vec3(10000)*pow(r, 1.5));
        o.rgb *= col2;
        if (h.w < .1)
            o.rgb *= mix(col, vec3(col.r+col.g+col.b)/3.,.6);
        vec2 pt = mix(cellUL, cellBR, h.y);
        if (uv2.x < pt.x) {// descend into quadrant. is there a more elegant way to do this?
            if (uv2.y < pt.y) {
                cellBR = pt.xy;
            } else {
                  cellUL.y = pt.y;
                  cellBR.x = pt.x;
            }
        } else {
            if (uv2.y > pt.y) {
                cellUL = pt.xy;
            } else {
                cellUL.x = pt.x;
                cellBR.y = pt.y;
            }
        }
    }
    
    o = clamp(o,0.,1.);
    o = pow(o,o-o+.2);
    o *= 1.-dot(N,N);
    o.a = 1.;

    glFragColor = o;
}

