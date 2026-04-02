#version 420

// original shader by https://www.reddit.com/user/slackermanz/

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform int frames;
uniform sampler2D txdata;

out vec4 glFragColor;
float seed = 0.0;
float plim(float v, float p) {
    v = v * p;
    v = v - fract(v);
    v = v / p;
    return v;
}
float gv(float x, float y, int v) {
            float div = 1.0;
            float divx = resolution.x / div;
            float divy = resolution.y / div;
    float pxo = 1.0 / resolution.x;
    float pyo = 1.0 / resolution.y;
    float fcxo = gl_FragCoord.x + x;
    float fcyo = gl_FragCoord.y + y;
    float fcx = (mod(fcxo,divx) + floor(gl_FragCoord.x/divx)*divx ) * pxo;
    float fcy = (mod(fcyo,divy) + floor(gl_FragCoord.y/divy)*divy ) * pyo;
    vec4 pxdata = texture2D( txdata, vec2(fcx, fcy) );
    return pxdata[v];
}
float gdv(float x, float y, int v, float div) {
            float divx = resolution.x / div;
            float divy = resolution.y / div;
    float pxo = 1.0 / resolution.x;
    float pyo = 1.0 / resolution.y;
    float fcxo = gl_FragCoord.x + x;
    float fcyo = gl_FragCoord.y + y;
    float fcx = (mod(fcxo,divx) + floor(gl_FragCoord.x/divx)*divx ) * pxo;
    float fcy = (mod(fcyo,divy) + floor(gl_FragCoord.y/divy)*divy ) * pyo;
    vec4 pxdata = texture2D( txdata, vec2(fcx, fcy) );
    return pxdata[v];
}
float cv(float x, float y) {
    if(gv(x, y, 0) != 0.0) { return 1.0; } else { return 0.0; }
}
vec3 nhd( vec2 nbhd, float psn, float thr, int col, float div ) {
    float dist = 0.0;
    float cval = 0.0;
    float c_total = 0.0;
    float c_valid = 0.0;
    float c_value = 0.0;
    for(float i = -nbhd[0]; i <= nbhd[0]; i += 1.0) {
        for(float j = -nbhd[0]; j <= nbhd[0]; j += 1.0) {
            dist = floor(sqrt(i*i+j*j)+0.5);
            if( dist <= nbhd[0] && dist > nbhd[1] && dist != 0.0 ) {
                cval = gdv(i,j,col,div);
                c_total += psn;
                if( cval > thr ) {
                    c_valid += psn;
                    cval = psn * cval;
                    c_value += cval-fract(cval);
                } } } }

    return vec3( c_value, c_valid, c_total );
}
vec3 export_nh() {
    vec3 c = vec3(0.0,0.0,0.0);
    // R: Sign; 0.0 | 1.0
    // G: X Coord; 0-255 : 0.0-1.0
    // B: Y Coord; 0-255 : 0.0-1.0
    
// ( gl_FragCoord.x >= float(int(resolution.x) / 2)+0.5-32.0 )

    return vec3(c[0],c[1],c[2]);
}
float cgol_test(float v, int c, float div) {
    vec3 nh = nhd(vec2(1.0,0.0),1.0,0.99,c,div);
    if(nh[0] <= 1.0) { v = 0.0; }
    if(nh[0] == 3.0) { v = 1.0; }
    if(nh[0] >= 4.0) { v = 0.0; }
    return v;
}
float sn(float s) {
    return (s > 0.0) ? 1.0 : (s < 0.0) ? -1.0 : 0.0;
}
void main() {
    #define PI 3.1415926538
    float psn = 250.0;
    float div = 1.0;
    float divi = floor((gl_FragCoord.x*div)/(resolution.x)) + floor((gl_FragCoord.y*div)/(resolution.y))*div;
    vec3 col = vec3( 0.0, 0.0, 0.0 );

    float[16] ez = float[16]
    ( 0.2, 0.2, 0.5, 0.5, 
        0.2, 0.2, 0.5, 0.5, 
        0.2, 0.2, 0.5, 0.5, 
        0.2, 0.2, 0.5, 0.5 );

    float[16] dvmd = float[16]
    ( 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 );

    float dspace = ((divi+1.0)/(div*div) - (1.0/(div*div)));
                dspace = (div == 1.0) ? 0.5 : dspace;

    for(int i = 0; i < 16; i++) { 
        dvmd[i] = dvmd[i] * dspace
                + ez[i];
    }

    float res_r = gdv( 0.0, 0.0, 0, div );// * psn;
    float res_g = gdv( 0.0, 0.0, 1, div );// * psn;
    float res_b = gdv( 0.0, 0.0, 2, div );// * psn;

    float r0 = res_r;
    float g0 = res_g;
    float b0 = res_b;

    float s = 0.180;

    vec3 nrm = nhd( vec2(1.0,0.0), psn, 0.0, 0, div );
    float nrmw = nrm[0] / nrm[2];

    vec3 nr0 = nhd( vec2(1.0,0.0), psn, 0.0, 0, div );
    vec3 nr1 = nhd( vec2(2.0,0.0), psn, 0.0, 0, div );
    vec3 nr2 = nhd( vec2(4.0,1.0), psn, 0.0, 0, div );
    vec3 nr3 = nhd( vec2(7.0,2.0), psn, 0.0, 0, div );
    vec3 nr4 = nhd( vec2(12.0,4.0), psn, 0.0, 0, div );
    vec3 nr5 = nhd( vec2(20.0,7.0), psn, 0.0, 0, div );
    vec3 nr6 = nhd( vec2(33.0,12.0), psn, 0.0, 0, div );
    vec3 nr7 = nhd( vec2(54.0,20.0), psn, 0.0, 0, div );
    vec3 nr8 = nhd( vec2(87.0,33.0), psn, 0.0, 0, div );

    float nrcw = res_r;
    float nr0w = nr0[0] / nr0[2];
    float nr1w = nr1[0] / nr1[2];
    float nr2w = nr2[0] / nr2[2];
    float nr3w = nr3[0] / nr3[2];
    float nr4w = nr4[0] / nr4[2];
    float nr5w = nr5[0] / nr5[2];
    float nr6w = nr6[0] / nr6[2];
    float nr7w = nr7[0] / nr7[2];
    float nr8w = nr8[0] / nr8[2];

    float s1 = (s * 0.3) + 0.004;

    float nr0w_r0 = nr0w;
// if(nr0w >= 0.000 && nr0w <= 0.500) { nr0w_r0 -= s1; }
// if(nr0w >= 0.400 && nr0w <= 1.600) { nr0w_r0 += s1; }

    float nr1w_r0 = nr1w;
// if(nr1w >= 0.000 && nr1w <= 0.500) { nr1w_r0 -= s1; }
// if(nr1w >= 0.400 && nr1w <= 1.600) { nr1w_r0 += s1; }

    float nr2w_r0 = nr2w;
// if(nr2w >= 0.000 && nr2w <= 0.500) { nr2w_r0 -= s1; }
// if(nr2w >= 0.400 && nr2w <= 1.600) { nr2w_r0 += s1; }

    float nr3w_r0 = nr3w;
// if(nr3w >= 0.000 && nr3w <= 0.300) { nr3w_r0 -= s1; }
// if(nr3w >= 0.200 && nr3w <= 1.600) { nr3w_r0 += s1; }

    float nr4w_r0 = nr4w;
// if(nr4w >= 0.000 && nr4w <= 0.300) { nr4w_r0 -= s1; }
// if(nr4w >= 0.200 && nr4w <= 1.600) { nr4w_r0 += s1; }

    float nr5w_r0 = nr5w;
// if(nr5w >= 0.000 && nr5w <= 0.300) { nr5w_r0 -= s1; }
// if(nr5w >= 0.400 && nr5w <= 1.600) { nr5w_r0 += s1; }

    float nr6w_r0 = nr6w;
    if(nr6w >= 0.000 && nr6w <= 0.100) { nr6w_r0 += s1; }
    if(nr6w >= 0.200 && nr6w <= 1.000) { nr6w_r0 -= s1; }

    float nr7w_r0 = nr7w;
    if(nr7w >= 0.000 && nr7w <= 0.300) { nr7w_r0 += s1; }
    if(nr7w >= 0.400 && nr7w <= 1.000) { nr7w_r0 -= s1; }

    float nr8w_r0 = nr8w;
    if(nr8w >= 0.000 && nr8w <= 0.500) { nr8w_r0 += s1; }
    if(nr8w >= 0.600 && nr8w <= 1.000) { nr8w_r0 -= s1; }

    const int nc = 10;

    float[nc] arrw;
                arrw[0] = nrcw;
                arrw[1] = nr0w_r0;
                arrw[2] = nr1w_r0;
                arrw[3] = nr2w_r0;
                arrw[4] = nr3w_r0;
                arrw[5] = nr4w_r0;
                arrw[6] = nr5w_r0;
                arrw[7] = nr6w_r0;
                arrw[8] = nr7w_r0;
                arrw[9] = nr8w_r0;

    float[nc*nc] ardf;

    for(int i = 0; i < nc; i++) {
        for(int j = 0; j < nc; j++) {
            ardf[i+j*nc] = 0.0; 
// ardf[i+j*nc] = arrw[i] - arrw[j];
    } }

    ardf[0] = (arrw[0] - arrw[1])*1.0;
    ardf[1] = (arrw[1] - arrw[2])*1.0;
    ardf[2] = (arrw[2] - arrw[3])*1.0;
    ardf[3] = (arrw[3] - arrw[4])*1.0;
    ardf[4] = (arrw[4] - arrw[5])*1.0;
    ardf[5] = (arrw[5] - arrw[6])*1.0;
    ardf[6] = (arrw[6] - arrw[7])*1.0;
    ardf[7] = (arrw[7] - arrw[8])*1.0;
    ardf[8] = (arrw[8] - arrw[9])*1.0;

    int[6] minvars;
    for(int i = 0; i < 6; i++) { minvars[i] = 0; }

    for(int i = 0; i < nc*nc; i++) {
        if(abs(ardf[i]) < abs(ardf[minvars[0]]) && abs(ardf[i]) >= 0.004) { 
            minvars[5] = minvars[4];
            minvars[4] = minvars[3];
            minvars[3] = minvars[2];
            minvars[2] = minvars[1];
            minvars[1] = minvars[0];
            minvars[0] = i;
        }
        if(abs(ardf[minvars[0]]) == 0.0) { minvars[0] = i; }
    }

    r0 += sn(ardf[minvars[0]])*s;

    float wsum = 1.0 - (0.003); // Needs a slight boost to hit highest values
    float[nc+1] wt;

        wt[0] = 1.096; wt[1] = 0.512; wt[2] = 0.128; wt[3] = 0.064;
        wt[4] = 0.048; wt[5] = 0.040; wt[6] = 0.034; wt[7] = 0.028;
        wt[8] = 0.024; wt[9] = 0.020; wt[10] = 0.018;
    for(int i = 0; i < nc+1; i++) { wsum += wt[i]; }
    r0 = (
        nrcw * wt[0] + nrmw * wt[1] + nr0w * wt[2] + nr1w * wt[3] +
        nr2w * wt[4] + nr3w * wt[5] + nr4w * wt[6] + nr5w * wt[7] +
        nr6w * wt[8] + nr7w * wt[9] + nr8w * wt[10] + 
        r0
    ) / wsum;

        wsum = 4.000;
        wt[0] = 2.000; wt[1] = 1.000; wt[2] = 0.000; wt[3] = 0.000;
        wt[4] = 0.000; wt[5] = 0.000; wt[6] = 0.000; wt[7] = 0.000;
        wt[8] = -1.000; wt[9] = -1.000; wt[10] = -1.000;
    for(int i = 0; i < nc+1; i++) { wsum += wt[i]; }
    g0 += sn(ardf[minvars[0]])*(s*1.0 + 0.020);
    g0 = (
        nrcw * wt[0] + nrmw * wt[1] + nr0w * wt[2] + nr1w * wt[3] +
        nr2w * wt[4] + nr3w * wt[5] + nr4w * wt[6] + nr5w * wt[7] +
        nr6w * wt[8] + nr7w * wt[9] + nr8w * wt[10] + 
        g0
    ) / wsum;

        wsum = 4.000;
        wt[0] = 5.000; wt[1] = -1.000; wt[2] = 1.000; wt[3] = -1.000;
        wt[4] = -1.000; wt[5] = -1.000; wt[6] = -1.000; wt[7] = -1.000;
        wt[8] = -1.000; wt[9] = -1.000; wt[10] = -1.000;
    for(int i = 0; i < nc+1; i++) { wsum += wt[i]; }
    b0 += sn(ardf[minvars[0]])*(s*4.0 + 0.040) - 0.004;
    b0 = (
        nrcw * wt[0] + nrmw * wt[1] + nr0w * wt[2] + nr1w * wt[3] +
        nr2w * wt[4] + nr3w * wt[5] + nr4w * wt[6] + nr5w * wt[7] +
        nr6w * wt[8] + nr7w * wt[9] + nr8w * wt[10] + 
        b0
    ) / wsum;

    res_r = r0;
    res_g = g0;
    res_b = 0.0;

/*
    if(div > 1.0) {
        res_g = (divi/(div*div) == 0.5) ? ((res_r <= 0.0) ? 0.00 : res_r) : res_r;
        res_g = (mod(gl_FragCoord.x,resolution.x/div) <= 1.0 || (mod(gl_FragCoord.y,resolution.y/div) <= 1.0)) ? ((divi/(div*div) == 0.5) ? 1.0 : 0.15) : res_g;
        res_b = (divi/(div*div) == 0.5) ? ((res_r <= 0.0) ? 0.00 : res_r) : res_r;
        res_b = (mod(gl_FragCoord.x,resolution.x/div) <= 1.0 || (mod(gl_FragCoord.y,resolution.y/div) <= 1.0)) ? ((divi/(div*div) == 0.5) ? 1.0 : 0.15) : res_b;
    } else { res_g = res_r; res_b = res_r; }
*/
// Output
    //if(ub.mrb == 2.0) { res_r = (res_r*0.5) + reseed(); }
    col[0] = res_r;
    col[1] = res_g;
    col[2] = res_b;

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
