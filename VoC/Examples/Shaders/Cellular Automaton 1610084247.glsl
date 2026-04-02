#version 420

// original shader by https://www.reddit.com/user/slackermanz/

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform int frames;
uniform sampler2D txdata;

out vec4 glFragColor;
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
vec3 nh_ring(float nhsz, float rnsz, vec2 sinmod, vec2 cosmod) {
    float nhsz_c = 0.0;
    float cnt = 0.0;
    float wgt = 0.0;
    float nh_val = 0.0;
    for(float i = -nhsz; i <= nhsz; i += 1.0) {
        for(float j = -nhsz; j <= nhsz; j += 1.0) {
            nh_val = floor(sqrt(i*i+j*j)+0.5);
            if(nh_val <= nhsz && nh_val > rnsz && nh_val != 0.0) {
                if( (sin(nh_val*sinmod[1])+1.0)*0.5 <= sinmod[0]
                || (cos(nh_val*cosmod[1])+1.0)*0.5 <= cosmod[0] ) {
                    nhsz_c += 1.0;
                    if(gv(i,j,0) > 0.0) {
                        cnt+=1.0;
                        wgt+=1.0-(nh_val/nhsz);
                    } } } } }
    return vec3(cnt, nhsz_c, wgt);
}
void main() {
    vec3 col = vec3 ( 0.0, 0.0, 0.0 );
    float res_r = gv ( 0.0, 0.0, 0 );
    float res_g = gv ( 0.0, 0.0, 1 );
    float res_b = gv ( 0.0, 0.0, 2 );
    float res = res_r;

    float nh0s = 6.0;
    vec3 nh0 = nh_ring ( nh0s, 2.0, vec2(1.0, 0.0), vec2(0.0, 0.0) );
    float nh0c = nh0[0] / nh0[1];
    float nh0w = nh0[2] / nh0[1];
        if( nh0c >= 0.129 && nh0c <= 0.311 ) { res = 0.0; }
        if( nh0c >= 0.198 && nh0c <= 0.233 ) { res = 1.0; }
        if( nh0c >= 0.411 && nh0c <= 0.431 ) { res = 0.0; }
        if( nh0c >= 0.043 && nh0c <= 0.087 ) { res = 0.0; }

    float nh1s = 3.0;
    vec3 nh1 = nh_ring ( nh1s, 0.0, vec2(1.0, 0.0), vec2(0.0, 0.0) );
    float nh1c = nh1[0] / nh1[1];
    float nh1w = nh1[2] / nh1[1];
        if( nh1c >= 0.159 && nh1c <= 0.199 ) { res = 0.0; }
        if( nh1c >= 0.527 && nh1c <= 0.748 ) { res = 1.0; }
        if( nh1c >= 0.834 && nh1c <= 1.000 ) { res = 0.0; }

    float trail = 0.45;
    res_r = res;
    res_b = res;
    if(res_r == 0.0) {
        if(res_g >= trail) { res_g = trail; } }
     else { res_g = res_r; }
    if(res_g > 0.0) { res_g = res_g - 0.008; }
    if(res_g <= 0.0) { res_g = 0.0; }

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
