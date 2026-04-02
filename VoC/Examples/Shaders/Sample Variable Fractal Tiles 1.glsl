#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wtycRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define FIELD_OF_VIEW 7.

mat2 r2(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c,-s,s,c);
}

float triwave(float x) {
    return 1.-abs(fract(x)-.5)*2.;
}
vec3 triwave(vec3 x) {
    return vec3(1)-abs(fract(x)-.5)*2.;
}

//Credit: IQ, integer hash 2 https://www.shadertoy.com/view/XlXcW4
vec3 hash(uvec3 x) {
    x = ((x>>8U)^x.yzx)*1103515245U;
    x = ((x>>8U)^x.yzx)*1103515245U;
    x = ((x>>8U)^x.yzx)*1103515245U;
    return vec3(x)*(1.0/float(0xffffffffU));
}

void main(void)
{
    vec2 pos = ((gl_FragCoord.xy)*2.-resolution.xy)*FIELD_OF_VIEW/resolution.y+10.+time,
        ipos = pos;

    //hash from local tile coordinate
    vec3 h = hash(uvec3(floor(pos/10.),0));
    pos = mod(pos,10.)-5.;
    
    //apply folds based off hash
    for (int i = 0; i < 6; i++) {
        float fi = h[i/2], rv = h[i%3+1];
        if (i%2 == 0) fi = fract(fi*10.);
        else fi = floor(fi*10.);
           
        int id = int(fi)%3;
        if (id == 0) {//mirror rotate fold
            pos = (abs(pos)-.5)*r2(rv*6.28);
        } else if (id == 1) {//plane fold
            rv *= 6.28;
            vec2 pnorm = vec2(sin(rv),cos(rv));
            pos -= pnorm*2.*min(0.,dot(pos,pnorm));
        } else {//polar fold
            float sz = .04+rv*1.6,
                ang = mod(atan(pos.y,pos.x),sz)-sz*.5;
            pos = vec2(sin(ang),cos(ang))*length(pos);
        }
        //apply box fold
        float ext = h[i%3];
        pos = clamp(pos,-ext,ext)*2.-pos;
    }

    //coloring
    glFragColor = vec4(pow(triwave(length(pos)*vec3(4,5,6)),vec3(1.6)),1);
    
}
