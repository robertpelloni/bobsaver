#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3ttfDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*Ethan Alexander Shulman 2021 - https://xaloez.com/
License: CC0, public domain*/

#define PI 3.141592653589793

//Modified FNV-1A hash https://www.shadertoy.com/view/WtdfRX
uvec4 hash(uvec4 seed) {
    uvec4 h = (0x6A7F8FAAu^seed)*0x01000193u;
    h = ((h.wxyz>>3u)^h^seed.yzwx)*0x01000193u;
    h = ((h.zwxy>>8u)^h^seed.wxyz)*0x01000193u;
    return h^(h>>11u);
}
#define I2F (1./float(0xFFFFFFFFu))

mat2 r2(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c,-s,s,c);
}

vec3 triwave(vec3 x) {
    return vec3(1)-abs(fract(x)-.5)*2.;
}

void main(void)
{
    vec2 pos = ((gl_FragCoord.xy)*2.-resolution.xy)/resolution.y*5.+5.+time;

    //hash from local tile coordinate
    vec4 h = vec4(hash(uvec4(floor(pos/10.),0,0)))*I2F;
    pos = mod(pos,10.)-5.;
    
    //apply folds based off hash
    for (int i = 0; i < 8; i++) {
        float fi = h[i/2], rv = h[(i+1)%3];
        if (i%2 == 0) fi = fract(fi*2435.123)*10.;
        else fi = floor(fi*10.);
           
        int id = int(fi)%3;
        if (id == 0) {//mirror rotate fold
            pos = (abs(pos)-.5)*r2(rv*PI*2.);
        } else if (id == 1) {//plane fold
            rv *= PI*2.;
            vec2 pnorm = vec2(sin(rv),cos(rv));
            pos -= pnorm*2.*min(0.,dot(pos,pnorm));
        } else {//polar fold
            float sz = PI/floor(1.+rv*7.),
                ang = mod(atan(pos.y,pos.x),sz)-sz*.5;
            pos = vec2(sin(ang),cos(ang))*length(pos);
        }
        //apply box fold
        float ext = h[i%3];
        pos = abs(pos);
        pos = clamp(pos,-ext,ext)*2.-pos;
    }
    
    //distance hue coloring
    h = fract(h*1e4/PI);
    float dst = length(pos);
    glFragColor.xyz = clamp(abs(mod((dst+h.x)*(5.+h.y*60.)+vec3(0,4,2),6.)-3.)-1.,0.,1.)*
                    (.5+.5*cos((dst+h.z)*(5.+h.w*120.)));
    glFragColor. w = 1.;

}
