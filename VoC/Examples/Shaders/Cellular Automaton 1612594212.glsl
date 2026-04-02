#version 420

// original shader by https://www.reddit.com/user/slackermanz/

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform int frames;
uniform sampler2D txdata;

out vec4 glFragColor;
float plim(float v, float p) {
    v = v * p;
    v = v - fract(v);
    v = v / p;
    return v;
}
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
vec3 nhd( vec2 nbhd, float psn, float thr, int col ) {
    float dist = 0.0;
    float cval = 0.0;
    float c_total = 0.0;
    float c_valid = 0.0;
    float c_value = 0.0;
    for(float i = -nbhd[0]; i <= nbhd[0]; i += 1.0) {
        for(float j = -nbhd[0]; j <= nbhd[0]; j += 1.0) {
            dist = floor(sqrt(i*i+j*j)+0.5);
            if( dist <= nbhd[0] && dist > nbhd[1] && dist != 0.0 ) {
                cval = gv(i,j,col);
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
float cgol_test(float v, int c) {
    vec3 nh = nhd(vec2(1.0,0.0),1.0,0.99,c);
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
    float psn = 200.0;
    float cs = (1.0)*0.001;
    vec3 col = vec3( 0.0, 0.0, 0.0 );

    float res_r = gv( 0.0, 0.0, 0 );// * psn;
    float res_g = gv( 0.0, 0.0, 1 );// * psn;
    float res_b = gv( 0.0, 0.0, 2 );// * psn;

    float r0 = res_r;
    float s = 0.075;//+cs*5.0;

    vec3 nrm = nhd( vec2(1.0,0.0), psn, 0.0, 0 );
    float nrmw = nrm[0] / nrm[2];

    vec3 nr0 = nhd( vec2(1.0,0.0), psn, 0.0, 0 );
    vec3 nr1 = nhd( vec2(2.0,1.0), psn, 0.0, 0 );
    vec3 nr2 = nhd( vec2(4.0,2.0), psn, 0.0, 0 );
    vec3 nr3 = nhd( vec2(9.0,4.0), psn, 0.0, 0 );
    vec3 nr4 = nhd( vec2(16.0,9.0), psn, 0.0, 0 );
    vec3 nr5 = nhd( vec2(24.0,16.0), psn, 0.0, 0 );

    float nrcw = res_r;
    float nr0w = nr0[0] / nr0[2];
    float nr1w = nr1[0] / nr1[2];
    float nr2w = nr2[0] / nr2[2];
    float nr3w = nr3[0] / nr3[2];
    float nr4w = nr4[0] / nr4[2];
    float nr5w = nr5[0] / nr5[2];

    const int nc = 7;

    float[nc] arrw;
                arrw[0] = nrcw;
                arrw[1] = nr0w;
                arrw[2] = nr1w;
                arrw[3] = nr2w;
                arrw[4] = nr3w;
                arrw[5] = nr4w;
                arrw[6] = nr5w;

    float[nc*nc] ardf;
    for(int i = 0; i < nc; i++) {
        for(int j = 0; j < nc; j++) {
// ardf[i+j*nc] = arrw[i] - arrw[j];
            ardf[i+j*nc] = 0.0; 
    } }

    ardf[0] = (arrw[0] - arrw[1])*1.0;
    ardf[1] = (arrw[1] - arrw[2])*1.0;
    ardf[2] = (arrw[2] - arrw[3])*1.0;
    ardf[3] = (arrw[3] - arrw[4])*1.0;
    ardf[4] = (arrw[4] - arrw[5])*1.0;
    ardf[5] = (arrw[5] - arrw[6])*1.0;

    int minvar0 = 0;

    for(int i = 0; i < nc*nc; i++) {
        if(abs(ardf[i]) < abs(ardf[minvar0]) && abs(ardf[i]) >= 0.005) { minvar0 = i; }
    }

    r0 += sn(ardf[minvar0])*s;

    float wsum = 1.0;
    float[9] wt;
                wt[0] = 4.096;
                wt[1] = 0.512;
                wt[2] = 0.128;
                wt[3] = 0.064;
                wt[4] = 0.048;
                wt[5] = 0.040;
                wt[6] = 0.034;
                wt[7] = 0.028+cs;
    for(int i = 0; i < 8; i++) { wsum += wt[i]; }

    r0 = (
        nrcw * wt[0] +
        nrmw * wt[1] +
        nr0w * wt[2] +
        nr1w * wt[3] +
        nr2w * wt[4] +
        nr3w * wt[5] +
        nr4w * wt[6] +
        nr5w * wt[7] + r0
    ) / wsum;

    res_r = r0;

// Output
    col[0] = res_r;
    col[1] = res_r;
    col[2] = res_r;

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
