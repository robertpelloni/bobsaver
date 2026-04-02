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
                /*|| (cos(nh_val*cosmod[1])+1.0)*0.5 <= cosmod[0]*/ ) {
                    nhsz_c += 1.0;
                    if(gv(i,j,0) > 0.0) {
                        cnt+=1.0;
                        wgt+=1.0-(nh_val/nhsz);
                    } } } } }
    return vec3(cnt, nhsz_c, wgt);
}
vec2 nh_val(float nhsz, float rnsz, int col) {
    float nhsz_c = 0.0;
    float val = 0.0;
    float nh_val = 0.0;
    float cval = 0.0;
    for(float i = -nhsz; i <= nhsz; i += 1.0) {
        for(float j = -nhsz; j <= nhsz; j += 1.0) {
            nh_val = floor(sqrt(i*i+j*j)+0.5);
            if(nh_val <= nhsz && nh_val > rnsz && nh_val != 0.0) {
                nhsz_c += 1.0;
                cval = gv(i,j,col);
                for(int ii = 1; ii < 20; ii++) {
                    val += (cval >= (float(ii) / 20.0)) ? 0.05 : 0.0;
                }
            } } }
    return vec2(val, nhsz_c);
}
void main() {
    vec3 col = vec3 ( 0.0, 0.0, 0.0 );
    float res_r = gv ( 0.0, 0.0, 0 );
    float res_g = gv ( 0.0, 0.0, 1 );
    float res_b = gv ( 0.0, 0.0, 2 );
    float res = res_r;
    float outval = res;

    float cs = 1.0*0.01;
    float cv = gv(0.0,0.0,0);

    vec2 c0 = nh_val ( 8.0, 0.0, 0 );
    float c0v = (c0[0] / c0[1]);

    vec2 nh0 = nh_val ( 1.0, 0.0, 0 );
    vec2 nh1 = nh_val ( 3.0, 1.0, 0 );
    vec2 nh2 = nh_val ( 6.0, 5.0, 0 );
    vec2 nh3 = nh_val ( 12.0, 11.0, 0 );
    vec2 nh4 = nh_val ( 24.0, 23.0, 0 );

    float nh0v = (nh0[0] / nh0[1])*1.045;
    float nh1v = (nh1[0] / nh1[1])*1.050;
    float nh2v = (nh2[0] / nh2[1])*1.058;
    float nh3v = (nh3[0] / nh3[1])*1.064;
    float nh4v = (nh4[0] / nh4[1])*1.076;

    float rd01 = (nh0v * (2.0+cs)) - nh1v;
    float rd10 = (nh1v * (2.0+cs)) - nh0v;
    float rdr01 = (nh0[1]<nh1[1]) ? rd01 : rd10;

    float rd02 = (nh0v * (2.0+cs)) - nh2v;
    float rd20 = (nh2v * (2.0+cs)) - nh0v;
    float rdr02 = (nh0[1]<nh2[1]) ? rd02 : rd20;

    float rd03 = (nh0v * (2.0+cs)) - nh3v;
    float rd30 = (nh3v * (2.0+cs)) - nh0v;
    float rdr03 = (nh0[1]<nh3[1]) ? rd03 : rd30;

    float rd04 = (nh0v * (2.0+cs)) - nh4v;
    float rd40 = (nh4v * (2.0+cs)) - nh0v;
    float rdr04 = (nh0[1]<nh4[1]) ? rd04 : rd40;

    float rd12 = (nh1v * (2.0+cs)) - nh2v;
    float rd21 = (nh2v * (2.0+cs)) - nh1v;
    float rdr12 = (nh1[1]<nh2[1]) ? rd12 : rd21;

    float rd13 = (nh1v * (2.0+cs)) - nh3v;
    float rd31 = (nh3v * (2.0+cs)) - nh1v;
    float rdr13 = (nh1[1]<nh3[1]) ? rd13 : rd31;

    float rd14 = (nh1v * (2.0+cs)) - nh4v;
    float rd41 = (nh4v * (2.0+cs)) - nh1v;
    float rdr14 = (nh1[1]<nh4[1]) ? rd14 : rd41;

    float rd23 = (nh2v * (2.0+cs)) - nh3v;
    float rd32 = (nh3v * (2.0+cs)) - nh2v;
    float rdr23 = (nh2[1]<nh3[1]) ? rd23 : rd32;

    float rd24 = (nh2v * (2.0+cs)) - nh4v;
    float rd42 = (nh4v * (2.0+cs)) - nh2v;
    float rdr24 = (nh2[1]<nh4[1]) ? rd24 : rd42;

    float rd34 = (nh3v * (2.0+cs)) - nh4v;
    float rd43 = (nh4v * (2.0+cs)) - nh3v;
    float rdr34 = (nh3[1]<nh4[1]) ? rd34 : rd43;

    float d01 = abs(sqrt(nh0v*nh1v)-rdr01);
    float d02 = abs(sqrt(nh0v*nh2v)-rdr02);
    float d03 = abs(sqrt(nh0v*nh3v)-rdr03);
    float d04 = abs(sqrt(nh0v*nh4v)-rdr04);
    float d12 = abs(sqrt(nh1v*nh2v)-rdr12);
    float d13 = abs(sqrt(nh1v*nh3v)-rdr13);
    float d14 = abs(sqrt(nh1v*nh4v)-rdr14);
    float d23 = abs(sqrt(nh2v*nh3v)-rdr23);
    float d24 = abs(sqrt(nh2v*nh4v)-rdr24);
    float d34 = abs(sqrt(nh3v*nh4v)-rdr34);

    float q_01_02 = (d01<d02) ? rdr01 : rdr02;
    float q_01_03 = (d01<d03) ? rdr01 : rdr03;
    float q_01_04 = (d01<d04) ? rdr01 : rdr04;
    float q_01_12 = (d01<d12) ? rdr01 : rdr12;
    float q_01_13 = (d01<d13) ? rdr01 : rdr13;
    float q_01_14 = (d01<d14) ? rdr01 : rdr14;
    float q_01_23 = (d01<d23) ? rdr01 : rdr23;
    float q_01_24 = (d01<d24) ? rdr01 : rdr24;
    float q_01_34 = (d01<d34) ? rdr01 : rdr34;

    float q_02_03 = (d02<d03) ? rdr02 : rdr03;
    float q_02_04 = (d02<d04) ? rdr02 : rdr04;
    float q_02_12 = (d02<d12) ? rdr02 : rdr12;
    float q_02_13 = (d02<d13) ? rdr02 : rdr13;
    float q_02_14 = (d02<d14) ? rdr02 : rdr14;
    float q_02_23 = (d02<d23) ? rdr02 : rdr23;
    float q_02_24 = (d02<d24) ? rdr02 : rdr24;
    float q_02_34 = (d02<d34) ? rdr02 : rdr34;

    float q_03_04 = (d03<d04) ? rdr03 : rdr04;
    float q_03_12 = (d03<d12) ? rdr03 : rdr12;
    float q_03_13 = (d03<d13) ? rdr03 : rdr13;
    float q_03_14 = (d03<d14) ? rdr03 : rdr14;
    float q_03_23 = (d03<d23) ? rdr03 : rdr23;
    float q_03_24 = (d03<d24) ? rdr03 : rdr24;
    float q_03_34 = (d03<d34) ? rdr03 : rdr34;

    float q_04_12 = (d04<d12) ? rdr04 : rdr12;
    float q_04_13 = (d04<d13) ? rdr04 : rdr13;
    float q_04_14 = (d04<d14) ? rdr04 : rdr14;
    float q_04_23 = (d04<d23) ? rdr04 : rdr23;
    float q_04_24 = (d04<d24) ? rdr04 : rdr24;
    float q_04_34 = (d04<d34) ? rdr04 : rdr34;

    float q_12_13 = (d12<d13) ? rdr12 : rdr13;
    float q_12_14 = (d12<d14) ? rdr12 : rdr14;
    float q_12_23 = (d12<d23) ? rdr12 : rdr23;
    float q_12_24 = (d12<d24) ? rdr12 : rdr24;
    float q_12_34 = (d12<d34) ? rdr12 : rdr34;

    float q_13_14 = (d13<d14) ? rdr13 : rdr14;
    float q_13_23 = (d13<d23) ? rdr13 : rdr23;
    float q_13_24 = (d13<d24) ? rdr13 : rdr24;
    float q_13_34 = (d13<d34) ? rdr13 : rdr34;

    float q_14_23 = (d14<d23) ? rdr14 : rdr23;
    float q_14_24 = (d14<d24) ? rdr14 : rdr24;
    float q_14_34 = (d14<d34) ? rdr14 : rdr34;

    float q_23_24 = (d23<d24) ? rdr23 : rdr24;
    float q_23_34 = (d23<d34) ? rdr23 : rdr34;

    float q_24_34 = (d24<d34) ? rdr24 : rdr34;

    res_r = q_02_34;

    col[0] = res_r;
    col[1] = res_r;
    col[2] = res_r;

    //mouse handling/drawing code
    vec2 position = vec2(gl_FragCoord.x/resolution.x,gl_FragCoord.y/resolution.y);
    //first few frames random static
    if(frames<3){
        float rnd1 = mod(fract(sin(dot(position + time * 0.001, vec2(14.9898,78.233))) * 43758.5453), 1.0);
        if (rnd1 > 0.5) { glFragColor = vec4(1.0); } else { glFragColor = vec4(0.0); }
        return;
    }
    /**    //cursor at left edge clears the screen
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
