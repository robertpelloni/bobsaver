#version 420

// original shader by https://www.reddit.com/user/slackermanz/

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform int frames;
uniform sampler2D txdata;

out vec4 glFragColor;
float seed = 0.0;
float gv(float x, float y, int v) {
    float pxo = 1.0 / resolution.x;
    float pyo = 1.0 / resolution.y;
    float fcx = (gl_FragCoord.x*pxo)+(x*pxo);
    float fcy = (gl_FragCoord.y*pyo)+(y*pyo);
    vec4 pxdata = texture2D( txdata, vec2(fcx, fcy) );
    return pxdata[v];
}
float cv(float x, float y) {
    if(gv(x, y, 0) != 0.0) { return 1.0; } else { return 0.0; }
}
vec3 nh_ring(float nhsz, float rnsz, float sinmod, float cosmod) {
    float nhsz_c = 0.0;
    float cnt = 0.0;
    float wgt = 0.0;
    float nh_val = 0.0;
    for(float i = -nhsz; i <= nhsz; i += 1.0) {
        for(float j = -nhsz; j <= nhsz; j += 1.0) {
            nh_val = floor(sqrt(i*i+j*j)+0.5);
            if(nh_val <= nhsz && nh_val > rnsz && nh_val != 0.0) {
                if((sin(nh_val)+1.0)*0.5 <= sinmod || (cos(nh_val)+1.0)*0.5 <= cosmod) {
                    nhsz_c += 1.0;
                    if(gv(i,j,0) > 0.0) {
                        cnt+=1.0;
                        wgt+=1.0-(nh_val/nhsz);
                    } } } } }
    return vec3(cnt, nhsz_c, wgt);
}
void main() {
    vec3 col = vec3 ( 0.0, 0.0, 0.0 );
    float res = gv ( 0.0, 0.0, 0 );
    float ps = (floor(seed * 0.025) + 1.0) * 0.005;

    vec3 nh0 = nh_ring ( 7.0, 1.0, 0.0, 0.32 );
    float nh0c = nh0[0] / nh0[1];
    float nh0w = nh0[2] / nh0[1];
        if( nh0c >= 0.010 && nh0c <= 0.045 ) { res = 0.0; }
        if( nh0c >= 0.226 && nh0c <= 0.385 ) { res = 0.0; }
        if( nh0c >= 0.145 && nh0c <= 0.180 ) { res = 1.0; }
        if( nh0c >= 0.420 && nh0c <= 0.873 ) { res = 1.0; }

    vec3 nh1 = nh_ring ( 2.0, 0.0, 0.925, 0.0 );
    float nh1c = nh1[0] / nh1[1];
    float nh1w = nh1[2] / nh1[1];
        if( nh1c >= 0.548 && nh1c <= 0.866 ) { res = 1.0; }

    vec3 nh2 = nh_ring ( 4.0, 1.0, 0.5, 0.0 );
    float nh2c = nh2[0] / nh2[1];
    float nh2w = nh2[2] / nh2[1];
        if( nh2c >= 0.420 && nh2c <= 0.510 ) { res = 1.0; }
        if( nh2c >= 0.145 && nh2c <= 0.234 ) { res = 0.0; }

    vec3 nh3 = nh_ring ( 9.0, 3.0, 0.0, 0.73 );
    float nh3c = nh3[0] / nh3[1];
    float nh3w = nh3[2] / nh3[1];
        if( nh3c >= 0.690 && nh3c <= 1.000 ) { res = 0.0; }
        if( nh3c >= 0.363 && nh3c <= 0.468 ) { res = 0.0; }

    float res_r = res;
    float res_g = res;
    float res_b = res;

    res_g = (nh1c - nh3c) * res;
    res_b = 0.0;

    col[0] = res_r;
    col[1] = res_g;
    col[2] = res_b;
    //mouse handling/drawing code
    vec2 position = vec2(gl_FragCoord.x/resolution.x,gl_FragCoord.y/resolution.y);
    //first few frames random static
    if(frames<3){
        float rnd1 = mod(fract(sin(dot(position + time * 0.001, vec2(14.9898,78.233))) * 43758.5453), 1.0);
        if (rnd1 > 0.5) { glFragColor = vec4(1.0); } else { glFragColor = vec4(0.0); }
        return;
    }
    /**
    //cursor at left edge clears the screen
    if(mouse.x<0.01){
        glFragColor=vec4(vec3(0.0),1.0);
        return;
    }
    //cursor at right edge randomizes screen
    if(mouse.x>0.99){
        float rnd1 = mod(fract(sin(dot(position + time * 0.001, vec2(14.9898,78.233))) * 43758.5453), 1.0);
        if (rnd1 > 0.5) { glFragColor = vec4(1.0); } else { glFragColor = vec4(0.0); }
        return;
    }
    //cursor at top edge stops random circle being drawn
    if(mouse.y>0.99){
    }
    //random circle at mouse location
    else if (length(position-mouse) < 0.025) {
        float rnd1 = mod(fract(sin(dot(position + time * 0.001, vec2(14.9898,78.233))) * 43758.5453), 1.0);
        if (rnd1 > 0.5) { glFragColor = vec4(1.0); } else { glFragColor = vec4(0.0); }
        return;
    }
    **/
    glFragColor = vec4(col, 1.0);
}
