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

    float nh0s = 4.0;
    vec2 nh0 = nh_val ( nh0s, 1.0, 0 );
    float nh0v = nh0[0] / nh0[1];

    float nh1s = 12.0;
    vec2 nh1 = nh_val ( nh1s, 8.0, 0 );
    float nh1v = nh1[0] / nh1[1];

    float nh2s = 22.0;
    vec2 nh2 = nh_val ( nh2s, 16.0, 0 );
    float nh2v = nh2[0] / nh2[1];

    float var_0 = clamp(pow(1.0-abs(nh0v-nh1v),6.25),0.0,1.0);
    float var_1 = clamp(pow(1.0-abs(nh1v-nh2v),24.4),0.0,1.0);
    float var_2 = clamp(pow(1.0-abs(nh2v-nh0v),0.96),0.0,1.0);

    float res_0 = nh0v*var_0*(1.0+1.0/(9.7));
    float res_1 = nh1v*var_0*(1.0+1.0/(2.5));
    float res_2 = nh2v*var_0*(1.0+1.0/(4.3));
    float res_3 = nh0v*var_1*(1.0+1.0/(4.1));
    float res_4 = nh1v*var_1*(1.0+1.0/(1.1));
    float res_5 = nh2v*var_1*(1.0+1.0/(4.1));
    float res_6 = nh0v*var_2*(1.0+1.0/(2.1));
    float res_7 = nh1v*var_2*(1.0+1.0/(6.3));
    float res_8 = nh2v*var_2*(1.0+1.0/(3.8));

    float old_0 = abs(gv(0.0,0.0,0) - res_0);
    float old_1 = abs(gv(0.0,0.0,0) - res_1);
    float old_2 = abs(gv(0.0,0.0,0) - res_2);
    float old_3 = abs(gv(0.0,0.0,0) - res_3);
    float old_4 = abs(gv(0.0,0.0,0) - res_4);
    float old_5 = abs(gv(0.0,0.0,0) - res_5);
    float old_6 = abs(gv(0.0,0.0,0) - res_6);
    float old_7 = abs(gv(0.0,0.0,0) - res_7);
    float old_8 = abs(gv(0.0,0.0,0) - res_8);

    float res_r0 = (old_0 <= old_1) ? res_0 : res_1;
    float res_r1 = (old_1 <= old_2) ? res_1 : res_2;
    float res_r2 = (old_2 <= old_3) ? res_2 : res_3;
    float res_r3 = (old_3 <= old_4) ? res_3 : res_4;
    float res_r4 = (old_4 <= old_5) ? res_4 : res_5;
    float res_r5 = (old_5 <= old_6) ? res_5 : res_6;
    float res_r6 = (old_6 <= old_7) ? res_6 : res_7;
    float res_r7 = (old_7 <= old_8) ? res_7 : res_8;
    float res_r8 = (old_8 <= old_0) ? res_8 : res_0;

    float resv0 = abs(res_r0-res_r1);
    float resv1 = abs(res_r2-res_r3);
    float resv2 = abs(res_r4-res_r5);
    float resv3 = abs(res_r6-res_r7);
    float resv4 = abs(res_r8-res_r0);

    float resvr0 = pow(
                    (( res_r0 
                    + res_r1 
                    + res_r2 
                    + res_r3 
                    + res_r4 
                    + res_r5 
                    + res_r6 
                    + res_r7 
                    + res_r8 ) / 9.0),0.95);
    float resvr1 = pow((resv0+resv1+resv2+resv3+resv4)/(0.89),0.97+cs);

    // res_r = pow(( ((res_r0 + res_r1 + res_r2 + res_r3 + res_r4 + res_r5 + res_r6 + res_r7 + res_r8) / 9.0)),0.95);

    res_r = resvr0;

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
