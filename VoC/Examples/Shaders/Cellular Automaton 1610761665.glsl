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
    float psn = 200.0;
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

    float cv = (gv(0.0,-1.0,0)+gv(-1.0,0.0,0)+gv(0.0,1.0,0)+gv(1.0,0.0,0))/4.0;
    float cvr = gv(0.0,0.0,0);
    float cvg = gv(0.0,0.0,1);
    float cvb = gv(0.0,0.0,2);

    vec2 nh0 = nh_val ( 1.0, 0.0, 0 );
    vec2 nh1 = nh_val ( 3.0, 1.0, 0 );
    vec2 nh2 = nh_val ( 6.0, 5.0, 0 );
    vec2 nh3 = nh_val ( 12.0, 11.0, 0 );
    vec2 nh4 = nh_val ( 24.0, 23.0, 0 );
    float nh0v = (nh0[0] / nh0[1]);
    float nh1v = (nh1[0] / nh1[1]);
    float nh2v = (nh2[0] / nh2[1]);
    float nh3v = (nh3[0] / nh3[1]);
    float nh4v = (nh4[0] / nh4[1]);

    vec2 nhg = nh_val ( 1.0, 0.0, 1 );
    vec2 nhb = nh_val ( 1.0, 0.0, 2 );
    float nhgv = (nhg[0] / nhg[1]);
    float nhbv = (nhb[0] / nhb[1]);

    float rdcg = clamp( (cv * (2.0)) - nhgv ,0.0,1.0);
    float rdgc = clamp( (nhgv * (2.0)) - cv ,0.0,1.0);
    float rdrcg = (4.0*200.0<nhg[1]) ? rdcg : rdgc;

    float rd0g = clamp( (nh0v * (2.0)) - nhgv ,0.0,1.0);
    float rdg0 = clamp( (nhgv * (2.0)) - nh0v ,0.0,1.0);
    float rdr0g = (nh0[1]<nhg[1]) ? rd0g : rdg0;

    float rd1g = clamp( (nh1v * (2.0)) - nhgv ,0.0,1.0);
    float rdg1 = clamp( (nhgv * (2.0)) - nh1v ,0.0,1.0);
    float rdr1g = (nh1[1]<nhg[1]) ? rd1g : rdg1;

    float rd2g = clamp( (nh2v * (2.0)) - nhgv ,0.0,1.0);
    float rdg2 = clamp( (nhgv * (2.0)) - nh2v ,0.0,1.0);
    float rdr2g = (nh2[1]<nhg[1]) ? rd2g : rdg2;

    float rd3g = clamp( (nh3v * (2.0)) - nhgv ,0.0,1.0);
    float rdg3 = clamp( (nhgv * (2.0)) - nh3v ,0.0,1.0);
    float rdr3g = (nh3[1]<nhg[1]) ? rd3g : rdg3;

    float rd4g = clamp( (nh4v * (2.0)) - nhgv ,0.0,1.0);
    float rdg4 = clamp( (nhgv * (2.0)) - nh4v ,0.0,1.0);
    float rdr4g = (nh4[1]<nhg[1]) ? rd4g : rdg4;

    float r0 = cvr / ((nh0[1]+200.0)/200.0);
    float r1 = r0+(nh0[0] / (nh0[1]+200.0));
    float r2 = cvg / ((nhg[1]+200.0)/200.0);
    float r3 = r2+(nhg[0] / (nhg[1]+200.0));
    float r4 = cvb / ((nhb[1]+200.0)/200.0);
    float r5 = r4+(nhb[0] / (nhb[1]+200.0));

    float rr0 = r1+(r3*(0.1))-(r5*(0.1));
    float rg0 = r3+(r5*(0.1))-(r1*(0.1));
    float rb0 = r5+(r1*(0.1))-(r3*(0.1));

    res_r = rdcg;
    res_g = rg0;
    res_b = rb0;

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
