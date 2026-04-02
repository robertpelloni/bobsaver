#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

// Bleeding tie-dye!

vec2 center(vec2 pos) {
    pos -= 0.5;
    pos.y *= resolution.y / resolution.x;
    return pos;
}

vec2 uncenter(vec2 pos) {
    pos.y /= resolution.y / resolution.x;
    pos += 0.5;
    return pos;
}

float pxrand(int seed) {
    return fract(sin(time*152.234+gl_FragCoord.x*37.2342-gl_FragCoord.y*41.2342+float(seed)*372.2354)*532.234);
}

float grand(int seed) {
    return fract(sin(time*321.234+float(seed)*372.2354)*532.234);
}

void main( void ) {
    vec2 pos = center(gl_FragCoord.xy / resolution);
    float spin = 0.003 + 0.0005 * pxrand(1);
    vec2 samplepos = vec2(pos.x*cos(spin) - pos.y*sin(spin), pos.y*cos(spin) + pos.x*sin(spin));
    samplepos.x += (pxrand(5)-0.5)/resolution.x;
    samplepos.y += (pxrand(9)-0.5)/resolution.x;
    vec4 here = texture2D(backbuffer, uncenter(pos));
    vec4 sample = texture2D(backbuffer, uncenter(samplepos));
    vec4 drip = texture2D(backbuffer, uncenter(samplepos * 0.995));

    vec2 mdist = mouse - gl_FragCoord.xy / resolution;
    mdist.y *= resolution.y / resolution.x;
    float blend = 0.1;
    float pensize = 0.003 + 0.01 * grand(3);
    if (length(mdist) < pensize) {
        float col = time * 2.5;
        float offset = 3.14159 * 2.0 / 3.0;
        glFragColor.a = (1.0 - length(mdist)/pensize) * grand(8) + 0.2;
        glFragColor.r = sin(time*2.503)+1.0;
        glFragColor.g = cos(time*2.685)+1.0;
        glFragColor.b = sin(time*2.732)+1.0;
    } else {
        vec4 source = sample;
        if (drip.a > pxrand(83)) {
            source = drip;
            blend = 0.0;
        }
        glFragColor.rgb = source.rgb*(1.0-blend) + here.rgb*blend;
        glFragColor.a = source.a - pxrand(73)*5.0/255.0;
    }    
}
