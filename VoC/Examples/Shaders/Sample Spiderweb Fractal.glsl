#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/WsBSzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 c2p(vec2 p){return vec2(atan(p.y,p.x),length(p));}
vec2 p2c(vec2 p){return vec2(cos(p.x),sin(p.x))*p.y;}
vec3 getPixel(vec2 gl_FragCoord2) {
    vec2 uv = gl_FragCoord2.xy/resolution.xy;
    uv -= 0.5; uv.x *= (resolution.x/resolution.y); uv *= 20./pow(time,3.1);
    for(int i=0;i<13;i++) {
        uv.xy = p2c(c2p(uv.xy)*vec2(float(((i+4)%9)),1.1)-vec2(0.1,0.));
        uv.xy += 0.0275;
    }
    if(length(uv)<0.3) return vec3(1.);
    return vec3(0.);
}
void main(void)
{
    #define SSAA 4
    vec3 col = vec3(0.);
    for(int x=-SSAA/2;x<SSAA/2;x++)
        for(int y=-SSAA/2;y<SSAA/2;y++)
            col += getPixel(vec2(gl_FragCoord.x+float(x)/float(SSAA),
                                 gl_FragCoord.y+float(y)/float(SSAA)));
    glFragColor = vec4(col/pow(2.,float(SSAA)),1.);
}
