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
vec3 nh_ring(float nhsz, float rnsz, vec2 sinmod, float thresh) {
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
                    if(gv(i,j,0) > thresh) {
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
vec2 nhcv_val(float nhsz, float rnsz, float psn, int col) {
    float nhsz_c = 0.0;
    float val = 0.0;
    float nh_val = 0.0;
    float cval = 0.0;
    for(float i = -nhsz; i <= nhsz; i += 1.0) {
        for(float j = -nhsz; j <= nhsz; j += 1.0) {
            nh_val = ceil(sqrt(i*i+j*j));
            if(nh_val < nhsz && nh_val != 0.0) {
                nhsz_c += psn;
                cval = gv(i,j,col)*psn;
                val += cval-fract(cval);
            } } }
    return vec2(val, nhsz_c);
}
vec3 export_nh() {
    vec3 c = vec3(0.0,0.0,0.0);
    // R: Sign; 0.0 | 1.0
    // G: X Coord; 0-255 : 0.0-1.0
    // B: Y Coord; 0-255 : 0.0-1.0
    
// ( gl_FragCoord.x >= float(int(resolution.x) / 2)+0.5-32.0 )

    return vec3(c[0],c[1],c[2]);
}
void main() {
    #define PI 3.1415926538
// init
    vec3 col = vec3 ( 0.0, 0.0, 0.0 );
    float cs = 1.0*0.01;
    float psn = 200.0;
    float res_r = gv( 0.0, 0.0, 0 );
    float res_g = gv( 0.0, 0.0, 1 );
    float res_b = gv( 0.0, 0.0, 2 );

// Neighbourhood Definitions & average values
    float nhcr = gv ( 0.0, 0.0, 0 );
    vec2 nhvr = nhcv_val ( 2.0, 0.0, psn, 0 );
    vec2 nh0r = nh_val ( 1.0, 0.0, psn, 0 );
    vec2 nh1r = nh_val ( 3.0, 1.0, psn, 0 );
    vec2 nh2r = nh_val ( 6.0, 5.0, psn, 0 );
    vec2 nh3r = nh_val ( 12.0, 11.0, psn, 0 );
    vec2 nh4r = nh_val ( 24.0, 23.0, psn, 0 );
    float nhcrv = nhcr;
    float nhvrv = (nhvr[0] / nhvr[1]);
    float nh0rv = (nh0r[0] / nh0r[1]);
    float nh1rv = (nh1r[0] / nh1r[1]);
    float nh2rv = (nh2r[0] / nh2r[1]);
    float nh3rv = (nh3r[0] / nh3r[1]);
    float nh4rv = (nh4r[0] / nh4r[1]);

    float nhcg = gv ( 0.0, 0.0, 1 );
    vec2 nhvg = nhcv_val ( 2.0, 0.0, psn, 1 );
    vec2 nh0g = nh_val ( 1.0, 0.0, psn, 1 );
    vec2 nh1g = nh_val ( 3.0, 1.0, psn, 1 );
    vec2 nh2g = nh_val ( 6.0, 5.0, psn, 1 );
    vec2 nh3g = nh_val ( 12.0, 11.0, psn, 1 );
    vec2 nh4g = nh_val ( 24.0, 23.0, psn, 1 );
    float nhcgv = nhcg;
    float nhvgv = (nhvg[0] / nhvg[1]);
    float nh0gv = (nh0g[0] / nh0g[1]);
    float nh1gv = (nh1g[0] / nh1g[1]);
    float nh2gv = (nh2g[0] / nh2g[1]);
    float nh3gv = (nh3g[0] / nh3g[1]);
    float nh4gv = (nh4g[0] / nh4g[1]);

    float nhcb = gv ( 0.0, 0.0, 2 );
    vec2 nhvb = nhcv_val ( 2.0, 0.0, psn, 2 );
    vec2 nh0b = nh_val ( 1.0, 0.0, psn, 2 );
    vec2 nh1b = nh_val ( 3.0, 1.0, psn, 2 );
    vec2 nh2b = nh_val ( 6.0, 5.0, psn, 2 );
    vec2 nh3b = nh_val ( 12.0, 11.0, psn, 2 );
    vec2 nh4b = nh_val ( 24.0, 23.0, psn, 2 );
    float nhcbv = nhcb;
    float nhvbv = (nhvb[0] / nhvb[1]);
    float nh0bv = (nh0b[0] / nh0b[1]);
    float nh1bv = (nh1b[0] / nh1b[1]);
    float nh2bv = (nh2b[0] / nh2b[1]);
    float nh3bv = (nh3b[0] / nh3b[1]);
    float nh4bv = (nh4b[0] / nh4b[1]);

// Reaction Controls
// Red: Wobble Height / Growth Speed
// Green: Sharpness / Intersection Space
// Blue: Spacing / (B >= nhr) && (B > nhg)

    vec2 nhr = vec2 ( nhcr, 1.0 );
    vec2 nhg = vec2 ( nhcg, 1.0 );
    vec2 nhb = vec2 ( nhcb, 1.0 );
            nhr = nh_val ( floor(8.0+(1.0*20.0)), floor(0.0+(0.0*20.0)), psn, 0 );
            nhg = nh_val ( floor(1.0+(cs*20.0)), floor(0.0+(cs*20.0)), psn, 1 );
            nhb = nh_val ( floor(1.0+(cs*20.0)), floor(0.0+(cs*20.0)), psn, 2 );

    float nhrv = (nhr[0] / nhr[1]);
    float nhgv = (nhg[0] / nhg[1]);
    float nhbv = (nhb[0] / nhb[1]);

// Diffusion
    float dfrv = (nhrv / ((nhr[1]+psn)/psn)) + (nhr[0] / (nhr[1]+psn));
    float dfgv = (nhgv / ((nhg[1]+psn)/psn)) + (nhg[0] / (nhg[1]+psn));
    float dfbv = (nhbv / ((nhb[1]+psn)/psn)) + (nhb[0] / (nhb[1]+psn));

// Cyclic Diffusion
// float cydf = 0.1;
// float cdrgbv = dfrv+(dfgv*cydf)-(dfbv*cydf);
// float cdgbrv = dfgv+(dfbv*cydf)-(dfrv*cydf);
// float cdbrgv = dfbv+(dfrv*cydf)-(dfgv*cydf);

// Assemble

    float a = nh1rv*2.0 - nh2rv;
    float b = dfrv;
    float c = ( a + b*0.4 + res_r*0.6 ) / 2.0;
    float r = c;

    float e = (nh3rv / ((nh3r[1]+psn)/psn)) + (nh3r[0] / (nh3r[1]+psn));

    vec3 dd = nh_ring(12.0,3.0,vec2(1.0,1.0),e);
    float d = dd[0]/dd[1];

    if(b >= 0.340 && b <= 0.520) { r -= 0.040; }
    if(b >= 0.215 && b <= 0.280) { r += 0.040; }
    if(b >= 0.450 && b <= 0.600) { r += 0.130; }
    if(b >= 0.270 && b <= 0.310) { r -= 0.250; }
    if(b >= 0.535 && b <= 0.575) { r -= 0.250; }

    res_r = ( e*1.5 + d*0.5 ) / 2.0; //r-0.005;

// Output
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
