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
float tur(float f0, float f1) {
    return clamp((f0 * 2.0)-f1, 0.0, 1.0);
}
void main() {
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

    vec2 nhr = vec2( nhcr, 1.0 );
    vec2 nhg = vec2( nhcg, 1.0 );
    vec2 nhb = vec2( nhcb, 1.0 );

            nhr = nh_val ( 1.0, 0.0, psn, 0 );
            nhg = nh_val ( 1.0, 0.0, psn, 1 );
            nhb = nh_val ( 1.0, 0.0, psn, 2 );
// nhr = nh_val ( floor(1.0+(cs*20.0)), floor(0.0+(cs*20.0)), psn, 0 );
// nhg = nh_val ( floor(1.0+(cs*20.0)), floor(0.0+(cs*20.0)), psn, 1 );
// nhb = nh_val ( floor(1.0+(cs*20.0)), floor(0.0+(cs*20.0)), psn, 2 );

    float nhrv = (nhr[0] / nhr[1]);
    float nhgv = (nhg[0] / nhg[1]);
    float nhbv = (nhb[0] / nhb[1]);

// Diffusion
    float dfrv = (nhrv / ((nhr[1]+psn)/psn)) + (nhr[0] / (nhr[1]+psn));
    float dfgv = (nhgv / ((nhg[1]+psn)/psn)) + (nhg[0] / (nhg[1]+psn));
    float dfbv = (nhbv / ((nhb[1]+psn)/psn)) + (nhb[0] / (nhb[1]+psn));

// Cyclic Diffusion
    float cdrgbv = dfrv+(dfgv*(0.1))-(dfbv*(0.1));
    float cdgbrv = dfgv+(dfbv*(0.1))-(dfrv*(0.1));
    float cdbrgv = dfbv+(dfrv*(0.1))-(dfgv*(0.1));

// Turingify
// Neighbourhood Values : nh[i][c]v
// Reactant Values : nh[c]v
// Diffuse Values : df[c]v
// Cyclic Diffusion Values : cd[c0][c1][c2]v

    // ( nri, nri )
    float tnncrcr = tur( nhcrv, nhcrv );
    float tnncrvr = tur( nhcrv, nhvrv );
    float tnncr0r = tur( nhcrv, nh0rv );
    float tnncr1r = tur( nhcrv, nh1rv );
    float tnncr2r = tur( nhcrv, nh2rv );
    float tnncr3r = tur( nhcrv, nh3rv );
    float tnncr4r = tur( nhcrv, nh4rv );
    float tnnvrcr = tur( nhvrv, nhcrv );
    float tnnvrvr = tur( nhvrv, nhvrv );
    float tnnvr0r = tur( nhvrv, nh0rv );
    float tnnvr1r = tur( nhvrv, nh1rv );
    float tnnvr2r = tur( nhvrv, nh2rv );
    float tnnvr3r = tur( nhvrv, nh3rv );
    float tnnvr4r = tur( nhvrv, nh4rv );
    float tnn0rcr = tur( nh0rv, nhcrv );
    float tnn0rvr = tur( nh0rv, nhvrv );
    float tnn0r0r = tur( nh0rv, nh0rv );
    float tnn0r1r = tur( nh0rv, nh1rv );
    float tnn0r2r = tur( nh0rv, nh2rv );
    float tnn0r3r = tur( nh0rv, nh3rv );
    float tnn0r4r = tur( nh0rv, nh4rv );
    float tnn1rcr = tur( nh1rv, nhcrv );
    float tnn1rvr = tur( nh1rv, nhvrv );
    float tnn1r0r = tur( nh1rv, nh0rv );
    float tnn1r1r = tur( nh1rv, nh1rv );
    float tnn1r2r = tur( nh1rv, nh2rv );
    float tnn1r3r = tur( nh1rv, nh3rv );
    float tnn1r4r = tur( nh1rv, nh4rv );
    float tnn2rcr = tur( nh2rv, nhcrv );
    float tnn2rvr = tur( nh2rv, nhvrv );
    float tnn2r0r = tur( nh2rv, nh0rv );
    float tnn2r1r = tur( nh2rv, nh1rv );
    float tnn2r2r = tur( nh2rv, nh2rv );
    float tnn2r3r = tur( nh2rv, nh3rv );
    float tnn2r4r = tur( nh2rv, nh4rv );
    float tnn3rcr = tur( nh3rv, nhcrv );
    float tnn3rvr = tur( nh3rv, nhvrv );
    float tnn3r0r = tur( nh3rv, nh0rv );
    float tnn3r1r = tur( nh3rv, nh1rv );
    float tnn3r2r = tur( nh3rv, nh2rv );
    float tnn3r3r = tur( nh3rv, nh3rv );
    float tnn3r4r = tur( nh3rv, nh4rv );
    float tnn4rcr = tur( nh4rv, nhcrv );
    float tnn4rvr = tur( nh4rv, nhvrv );
    float tnn4r0r = tur( nh4rv, nh0rv );
    float tnn4r1r = tur( nh4rv, nh1rv );
    float tnn4r2r = tur( nh4rv, nh2rv );
    float tnn4r3r = tur( nh4rv, nh3rv );
    float tnn4r4r = tur( nh4rv, nh4rv );

    // ( ngi, ngi )
    float tnncgvg = tur( nhcgv, nhvgv );
    float tnncg0g = tur( nhcgv, nh0gv );
    float tnncg1g = tur( nhcgv, nh1gv );
    float tnncg2g = tur( nhcgv, nh2gv );
    float tnncg3g = tur( nhcgv, nh3gv );
    float tnncg4g = tur( nhcgv, nh4gv );
    float tnnvg0g = tur( nhvgv, nh0gv );
    float tnnvg1g = tur( nhvgv, nh1gv );
    float tnnvg2g = tur( nhvgv, nh2gv );
    float tnnvg3g = tur( nhvgv, nh3gv );
    float tnnvg4g = tur( nhvgv, nh4gv );
    float tnn0g1g = tur( nh0gv, nh1gv );
    float tnn0g2g = tur( nh0gv, nh2gv );
    float tnn0g3g = tur( nh0gv, nh3gv );
    float tnn0g4g = tur( nh0gv, nh4gv );
    float tnn1g2g = tur( nh1gv, nh2gv );
    float tnn1g3g = tur( nh1gv, nh3gv );
    float tnn1g4g = tur( nh1gv, nh4gv );
    float tnn2g3g = tur( nh2gv, nh3gv );
    float tnn2g4g = tur( nh2gv, nh4gv );
    float tnn3g4g = tur( nh3gv, nh4gv );

    // ( nri, ngi )
    float tnncrcg = tur( nhcrv, nhcgv );
    float tnncrvg = tur( nhcrv, nhvgv );
    float tnncr0g = tur( nhcrv, nh0gv );
    float tnncr1g = tur( nhcrv, nh1gv );
    float tnncr2g = tur( nhcrv, nh2gv );
    float tnncr3g = tur( nhcrv, nh3gv );
    float tnncr4g = tur( nhcrv, nh4gv );
    float tnnvrcg = tur( nhvrv, nhcgv );
    float tnnvrvg = tur( nhvrv, nhvgv );
    float tnnvr0g = tur( nhvrv, nh0gv );
    float tnnvr1g = tur( nhvrv, nh1gv );
    float tnnvr2g = tur( nhvrv, nh2gv );
    float tnnvr3g = tur( nhvrv, nh3gv );
    float tnnvr4g = tur( nhvrv, nh4gv );
    float tnn0rcg = tur( nh0rv, nhcgv );
    float tnn0rvg = tur( nh0rv, nhvgv );
    float tnn0r0g = tur( nh0rv, nh0gv );
    float tnn0r1g = tur( nh0rv, nh1gv );
    float tnn0r2g = tur( nh0rv, nh2gv );
    float tnn0r3g = tur( nh0rv, nh3gv );
    float tnn0r4g = tur( nh0rv, nh4gv );
    float tnn1rcg = tur( nh1rv, nhcgv );
    float tnn1rvg = tur( nh1rv, nhvgv );
    float tnn1r0g = tur( nh1rv, nh0gv );
    float tnn1r1g = tur( nh1rv, nh1gv );
    float tnn1r2g = tur( nh1rv, nh2gv );
    float tnn1r3g = tur( nh1rv, nh3gv );
    float tnn1r4g = tur( nh1rv, nh4gv );
    float tnn2rcg = tur( nh2rv, nhcgv );
    float tnn2rvg = tur( nh2rv, nhvgv );
    float tnn2r0g = tur( nh2rv, nh0gv );
    float tnn2r1g = tur( nh2rv, nh1gv );
    float tnn2r2g = tur( nh2rv, nh2gv );
    float tnn2r3g = tur( nh2rv, nh3gv );
    float tnn2r4g = tur( nh2rv, nh4gv );
    float tnn3rcg = tur( nh3rv, nhcgv );
    float tnn3rvg = tur( nh3rv, nhvgv );
    float tnn3r0g = tur( nh3rv, nh0gv );
    float tnn3r1g = tur( nh3rv, nh1gv );
    float tnn3r2g = tur( nh3rv, nh2gv );
    float tnn3r3g = tur( nh3rv, nh3gv );
    float tnn3r4g = tur( nh3rv, nh4gv );
    float tnn4rcg = tur( nh4rv, nhcgv );
    float tnn4rvg = tur( nh4rv, nhvgv );
    float tnn4r0g = tur( nh4rv, nh0gv );
    float tnn4r1g = tur( nh4rv, nh1gv );
    float tnn4r2g = tur( nh4rv, nh2gv );
    float tnn4r3g = tur( nh4rv, nh3gv );
    float tnn4r4g = tur( nh4rv, nh4gv );

    // ( ngi, nri )
    float tnncgcr = tur( nhcgv, nhcrv );
    float tnncgvr = tur( nhcgv, nhvrv );
    float tnncg0r = tur( nhcgv, nh0rv );
    float tnncg1r = tur( nhcgv, nh1rv );
    float tnncg2r = tur( nhcgv, nh2rv );
    float tnncg3r = tur( nhcgv, nh3rv );
    float tnncg4r = tur( nhcgv, nh4rv );
    float tnnvgcr = tur( nhvgv, nhcrv );
    float tnnvgvr = tur( nhvgv, nhvrv );
    float tnnvg0r = tur( nhvgv, nh0rv );
    float tnnvg1r = tur( nhvgv, nh1rv );
    float tnnvg2r = tur( nhvgv, nh2rv );
    float tnnvg3r = tur( nhvgv, nh3rv );
    float tnnvg4r = tur( nhvgv, nh4rv );
    float tnn0gcr = tur( nh0gv, nhcrv );
    float tnn0gvr = tur( nh0gv, nhvrv );
    float tnn0g0r = tur( nh0gv, nh0rv );
    float tnn0g1r = tur( nh0gv, nh1rv );
    float tnn0g2r = tur( nh0gv, nh2rv );
    float tnn0g3r = tur( nh0gv, nh3rv );
    float tnn0g4r = tur( nh0gv, nh4rv );
    float tnn1gcr = tur( nh1gv, nhcrv );
    float tnn1gvr = tur( nh1gv, nhvrv );
    float tnn1g0r = tur( nh1gv, nh0rv );
    float tnn1g1r = tur( nh1gv, nh1rv );
    float tnn1g2r = tur( nh1gv, nh2rv );
    float tnn1g3r = tur( nh1gv, nh3rv );
    float tnn1g4r = tur( nh1gv, nh4rv );
    float tnn2gcr = tur( nh2gv, nhcrv );
    float tnn2gvr = tur( nh2gv, nhvrv );
    float tnn2g0r = tur( nh2gv, nh0rv );
    float tnn2g1r = tur( nh2gv, nh1rv );
    float tnn2g2r = tur( nh2gv, nh2rv );
    float tnn2g3r = tur( nh2gv, nh3rv );
    float tnn2g4r = tur( nh2gv, nh4rv );
    float tnn3gcr = tur( nh3gv, nhcrv );
    float tnn3gvr = tur( nh3gv, nhvrv );
    float tnn3g0r = tur( nh3gv, nh0rv );
    float tnn3g1r = tur( nh3gv, nh1rv );
    float tnn3g2r = tur( nh3gv, nh2rv );
    float tnn3g3r = tur( nh3gv, nh3rv );
    float tnn3g4r = tur( nh3gv, nh4rv );
    float tnn4gcr = tur( nh4gv, nhcrv );
    float tnn4gvr = tur( nh4gv, nhvrv );
    float tnn4g0r = tur( nh4gv, nh0rv );
    float tnn4g1r = tur( nh4gv, nh1rv );
    float tnn4g2r = tur( nh4gv, nh2rv );
    float tnn4g3r = tur( nh4gv, nh3rv );
    float tnn4g4r = tur( nh4gv, nh4rv );

    // ( nri, dr )
    float tndcrdr = tur( nhcrv, dfrv );
    float tndvrdr = tur( nhvrv, dfrv );
    float tnd0rdr = tur( nh0rv, dfrv );
    float tnd1rdr = tur( nh1rv, dfrv );
    float tnd2rdr = tur( nh2rv, dfrv );
    float tnd3rdr = tur( nh3rv, dfrv );
    float tnd4rdr = tur( nh4rv, dfrv );
    // ( nri, dg )
    float tndcrdg = tur( nhcrv, dfgv );
    float tndvrdg = tur( nhvrv, dfgv );
    float tnd0rdg = tur( nh0rv, dfgv );
    float tnd1rdg = tur( nh1rv, dfgv );
    float tnd2rdg = tur( nh2rv, dfgv );
    float tnd3rdg = tur( nh3rv, dfgv );
    float tnd4rdg = tur( nh4rv, dfgv );

    // ( dr, nri )
    float tdndrcr = tur( dfrv, nhcrv );
    float tdndrvr = tur( dfrv, nhvrv );
    float tdndr0r = tur( dfrv, nh0rv );
    float tdndr1r = tur( dfrv, nh1rv );
    float tdndr2r = tur( dfrv, nh2rv );
    float tdndr3r = tur( dfrv, nh3rv );
    float tdndr4r = tur( dfrv, nh4rv );
    // ( dg, nri )
    float tdndgcr = tur( dfgv, nhcrv );
    float tdndgvr = tur( dfgv, nhvrv );
    float tdndg0r = tur( dfgv, nh0rv );
    float tdndg1r = tur( dfgv, nh1rv );
    float tdndg2r = tur( dfgv, nh2rv );
    float tdndg3r = tur( dfgv, nh3rv );
    float tdndg4r = tur( dfgv, nh4rv );

    // ( dc, dc )
    float tdddrdg = tur( dfrv, dfgv );
    float tdddrdb = tur( dfrv, dfbv );
    float tdddgdr = tur( dfgv, dfrv );
    float tdddgdb = tur( dfgv, dfbv );
    float tdddbdr = tur( dfbv, dfrv );
    float tdddbdg = tur( dfbv, dfgv );

// Assemble
    float rw = 0.0;
    float w0 = 1.0;
    float w1 = 1.0;
    float w2 = 1.0;
    float w3 = 1.0;
    rw = (
        tnn0r1r * w0 +
        tnn0r1r * w1 +
        tnn0r1r * w2 +
        tnn0r1r * w3
    ) / ( w0 + w1 + w2 + w3 );

    // [ nri, nr(i+1) ]
    // [ nri, ngi ]
    // [ nri, dr ]
    // [ dr, nri ]
    // [ nri, dg ]
    // [ dc, dc ]

    rw = (tnn1r1g+tdddrdb)/2.0;

// Assign 
    res_r = rw;
    res_g = cdgbrv;
    res_b = cdbrgv;

// Output
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
