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
vec3 nh_ring(float nhsz, float rnsz, vec2 sinmod) {
    float nhsz_c = 0.0;
    float cnt = 0.0;
    float wgt = 0.0;
    float nh_val = 0.0;
    for(float i = -nhsz; i <= nhsz; i += 1.0) {
        for(float j = -nhsz; j <= nhsz; j += 1.0) {
            nh_val = floor(sqrt(i*i+j*j)+0.5);
            if(nh_val <= nhsz && nh_val > rnsz && nh_val != 0.0) {
                if( (sin(nh_val*sinmod[1])+1.0)*0.5 <= sinmod[0] ) {
                    nhsz_c += 1.0;
                    if(gv(i,j,0) > 0.0) {
                        cnt+=1.0;
                        wgt+=1.0-(nh_val/nhsz);
                    } } } } }
    return vec3(cnt, nhsz_c, wgt);
}
vec2 nh_val(float nhsz, float rnsz, float psn, int col) {
    float nhsz_c = 0.0;
    float val = 0.0;
    float nh_val = 0.0;
    float cval = 0.0;
    for(float i = -nhsz; i <= nhsz; i += 1.0) {
        for(float j = -nhsz; j <= nhsz; j += 1.0) {
            nh_val = floor(sqrt(i*i+j*j)+0.5);
            if(nh_val <= nhsz && nh_val > rnsz && nh_val != 0.0) {
                nhsz_c += psn;
                cval = gv(i,j,col)*psn;
                val += cval-fract(cval);
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
    float psn = 200.0;

    float cvr = gv(0.0,0.0,0);
    float cvg = gv(0.0,0.0,1);
    float cvb = gv(0.0,0.0,2);
    float cv = cvr;

    vec2 nhv = vec2( gv ( 0.0, -1.0, 0 )
                            + gv ( -1.0, 0.0, 0 )
                            + gv ( 1.0, 0.0, 0 )
                            + gv ( 0.0, 1.0, 0 ), 4.0 );
    vec2 nhvg = vec2( gv ( 0.0, -1.0, 1 )
                            + gv ( -1.0, 0.0, 1 )
                            + gv ( 1.0, 0.0, 1 )
                            + gv ( 0.0, 1.0, 1 ), 4.0 );
    vec2 nh0 = nh_val ( 1.0, 0.0, psn, 0 );
    vec2 nh1 = nh_val ( 3.0, 1.0, psn, 0 );
    vec2 nh2 = nh_val ( 6.0, 5.0, psn, 0 );
    vec2 nh3 = nh_val ( 12.0, 11.0, psn, 0 );
    vec2 nh4 = nh_val ( 24.0, 23.0, psn, 0 );
    float nhvv = (nhv[0] / nhv[1]);
    float nh0v = (nh0[0] / nh0[1]);
    float nh1v = (nh1[0] / nh1[1]);
    float nh2v = (nh2[0] / nh2[1]);
    float nh3v = (nh3[0] / nh3[1]);
    float nh4v = (nh4[0] / nh4[1]);

// Red: Wobble Height / Growth Speed
// Green: Sharpness / Intersection Space
// Blue: Spacing / (B >= nhr) && (B > nhg)

    vec2 nhr = vec2 ( cvr, 1.0 );
    vec2 nhg = vec2 ( cvg, 1.0 );//nhvg;//
    vec2 nhb = vec2 ( cvb, 1.0 );

            nhr = nh_val ( floor(1.0+(cs*20.0)), floor(0.0+(cs*20.0)), psn, 0 );
// nhg = nh_val ( floor(1.0+(cs*30.0)), floor(0.0+(cs*10.0)), psn, 1 );
// nhb = nh_val ( floor(1.0+(cs*20.0)), floor(0.0+(cs*20.0)), psn, 2 );

    float nhrv = (nhr[0] / nhr[1]);
    float nhgv = (nhg[0] / nhg[1]);
    float nhbv = (nhb[0] / nhb[1]);

    float rdcg = clamp( (cvr * (2.0)) - nhgv, 0.0,1.0);
    float rdvg = clamp( (nhvv * (2.0)) - nhgv, 0.0,1.0);
    float rd0g = clamp( (nh0v * (2.0)) - nhgv, 0.0,1.0);
    float rd1g = clamp( (nh1v * (2.0)) - nhgv, 0.0,1.0);
    float rd2g = clamp( (nh2v * (2.0)) - nhgv, 0.0,1.0);
    float rd3g = clamp( (nh3v * (2.0)) - nhgv, 0.0,1.0);
    float rd4g = clamp( (nh4v * (2.0)) - nhgv, 0.0,1.0);

    float r0 = (cvr / ((nhr[1]+psn)/psn)) + (nhr[0] / (nhr[1]+psn));
    float g0 = (cvg / ((nhg[1]+psn)/psn)) + (nhg[0] / (nhg[1]+psn));
    float b0 = (cvb / ((nhb[1]+psn)/psn)) + (nhb[0] / (nhb[1]+psn));

    float rr0 = r0+(g0*(0.1))-(b0*(0.1));
    float rg0 = g0+(b0*(0.1))-(r0*(0.1));
    float rb0 = b0+(r0*(0.1))-(g0*(0.1));

    res_r = rd0g;
    res_g = rg0;
    res_b = rb0;

    float rdcv = clamp( (cvr * (2.0)) - nhvv, 0.0,1.0);
    float rdc0 = clamp( (cvr * (2.0)) - nh0v, 0.0,1.0);
    float rdc1 = clamp( (cvr * (2.0)) - nh1v, 0.0,1.0);
    float rdc2 = clamp( (cvr * (2.0)) - nh2v, 0.0,1.0);

    float rdv0 = clamp( (nhvv * (2.0)) - nh0v, 0.0,1.0);
    float rdv1 = clamp( (nhvv * (2.0)) - nh1v, 0.0,1.0);
    float rdv2 = clamp( (nhvv * (2.0)) - nh2v, 0.0,1.0);

    float rd01 = clamp( (nh0v * (2.0)) - nh1v, 0.0,1.0);
    float rd02 = clamp( (nh0v * (2.0)) - nh2v, 0.0,1.0);

    float rd12 = clamp( (nh1v * (2.0)) - nh2v, 0.0,1.0);

    float rd23 = clamp( (nh2v * (2.0)) - nh3v, 0.0,1.0);

    float rdc4 = clamp( (cvr * (2.0)) - nh4v, 0.0,1.0);
    float rdv4 = clamp( (nhvv * (2.0)) - nh4v, 0.0,1.0);
    float rd04 = clamp( (nh0v * (2.0)) - nh4v, 0.0,1.0);
    float rd14 = clamp( (nh1v * (2.0)) - nh4v, 0.0,1.0);
    float rd24 = clamp( (nh2v * (2.0)) - nh4v, 0.0,1.0);
    float rd34 = clamp( (nh3v * (2.0)) - nh4v, 0.0,1.0);

    //res_r = (((rd34*0.2+rd0g*0.5+rd01*1.3+rdv0*2.0)/4.0)+((rd23+rd2g*0.4)/1.4))/2.0;
    res_r = ((rd23+rd2g*0.4)/1.4);

    //res_r = sqrt(((rd01*1.0+rdcg*1.4+rd12*1.0)/3.4)*rd23);

    //res_g = res_r;
    //res_b = res_r;

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
