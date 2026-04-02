#version 420

// original https://www.shadertoy.com/view/3sK3zy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float lineThickness = 2.5;
const float PARTITIONS = 13.;

vec4 hash42(vec2 p)
{
    vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

void main(void)
{
    vec4 o = glFragColor;

    float t = (time+1e2)*.4;
    vec2 uv = gl_FragCoord.xy/resolution.xy-.5;
    vec2 N = uv;
    vec2 R = resolution.xy;
    uv.x *= R.x / R.y;
    uv.x += t*.2;
    uv.y += sin(t)*.3;
    uv.y -= .5;
    
    vec2 cellUL = floor(uv);
    vec2 cellBR = cellUL + 1.;
    vec2 seed = cellUL;
    o = vec4(1);
    for(float i = 1.; i <= PARTITIONS; ++ i) {
        vec4 h = hash42(seed+1e2*(vec2(cellBR.x, cellUL.y)+10.));
        vec2 test = abs(cellUL - cellBR);
        vec2 uv2 = uv;
        float dl = abs(uv2.x - cellUL.x);
        dl = min(dl, length(uv2.y - cellUL.y));
        dl = min(dl, length(uv2.x - cellBR.x));
        dl = min(dl, length(uv2.y - cellBR.y));

        vec3 col = h.rgb;
        o.rgb *= smoothstep(0.,lineThickness/max(R.x,R.y),dl);
        if (h.w < .2)
            o.rgb *= mix(col, vec3(col.r+col.g+col.b)/3.,.6);
        vec2 pt = mix(cellUL, cellBR, h.y);

        vec2 p2 = pt - uv;
        float r = max(fract(p2.x-.5), fract(.5-p2.x));
        r = max(r, fract(.5-p2.y));
        r = max(r, fract(p2.y-.5));
        r = 1.-r;
        vec2 sz = cellBR - cellUL;
        if (pow(sz.x * sz.y, .1) < r * 1.5) {
            break;
        }
        vec2 thresh = sin(t*2.*h.xy)*.5+.5;
        thresh *= h.zw*.3;
        if (sz.x < thresh.x || sz.y < thresh.y)
            break;
        
        if (uv2.x < pt.x) {// descend into quadrant.
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
    o = pow(o,o-o+.3);
    o *= 1.-dot(N,N);

    glFragColor = o;
}

