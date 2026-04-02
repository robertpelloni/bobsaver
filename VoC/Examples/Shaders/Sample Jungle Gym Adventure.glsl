#version 420

// original https://neort.io/art/c3c4gpc3p9f8s59bf8p0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const float PI = acos(-1.);

float hash( in float x )
{
    return fract(sin(x) * 43758.5453);
}

vec3 objColor( in vec3 rPos )
{
    float th = 0.001;
    vec3 Q = fract(rPos) - .5;
    if(length(Q.xy) - .07 < th){
        return vec3(.2, .2, .7);
    }
    if(length(Q.yz) - .07 < th){
        return vec3(.7, .2, .2);
    }
    if(length(Q.zx) - .07 < th){
        return vec3(.2, .7, .2);
    }
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy * 2. - resolution) / min(resolution.x, resolution.y);
    vec3 col = vec3(0);
    
    vec3 cPos = vec3(0, 0, fract(time) + .5);
    vec3 ray = normalize(vec3(p, 1));
    
    float m = cos(time * PI) * .5 + .5;
    if(hash(ceil(time)) < .5) {
        m *= -1.;
    }
    
    cPos.xy += hash(ceil(time) * 1.1) < .5 ? vec2(m, 0) : vec2(0, m);
    
    vec3 rPos = cPos;
    float c = 0.;
    
    for(int i = 0;i < 99;i++){
        vec3 Q = fract(rPos) - .5;
        float d = length(Q.xy) - .07;
        d = min(d, length(Q.yz) - .07);
        d = min(d, length(Q.zx) - .07);
        if(d < 1e-4){
            break;
        }
        rPos += ray * d;
        c++;
    }
    
    float rLen = length(rPos - cPos);
    col = 30. / c * objColor(rPos) * exp(-rLen * rLen * .008);
    
    glFragColor = vec4(col, 1.);
}
