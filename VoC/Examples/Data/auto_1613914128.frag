#version 460

// original shader by https://www.reddit.com/user/slackermanz/

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform int frames;
uniform sampler2D txdata;
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
                    c_value += cval-fract(cval); } } } } 
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
float get_xc(float x, float y, float xmod) {
    float sq = sqrt(mod(x*y+y, xmod)) / sqrt(xmod);
    float xc = mod((x*x)+(y*y), xmod) / xmod;
    return clamp((sq+xc)*0.5, 0.0, 1.0);
}
float shuffle(float x, float y, float xmod, float val) {
    val = val * mod( x*y + x, xmod );
    return (val-floor(val));
}
float get_xcn(float x, float y, float xm0, float xm1, float ox, float oy) {
    float xc = get_xc(x+ox, y+oy, xm0);
    return shuffle(x+ox, y+oy, xm1, xc);
}
float get_lump(float x, float y, float nhsz, float xm0, float xm1) {
    float nhsz_c = 0.0;
    float xcn = 0.0;
    float nh_val = 0.0;

    if(xm0 < 3.0) { xm0 = 3.0; }
    if(xm1 < 6.0) { xm1 = 6.0; }

    for(float i = -nhsz; i <= nhsz; i += 1.0) {
        for(float j = -nhsz; j <= nhsz; j += 1.0) {
            nh_val = floor(sqrt(i*i+j*j)+0.5);
            if(nh_val <= nhsz) {
                xcn = xcn + get_xcn(x, y, xm0, xm1, i, j);
                nhsz_c = nhsz_c + 1.0; } } }

    float xcnf = ( xcn / nhsz_c );
    float xcaf = xcnf;
    for(float i = 0.0; i <= nhsz; i += 1.0) {
            xcaf = clamp((xcnf*xcaf + xcnf*xcaf) * (xcnf+xcnf), 0.0, 1.0); }

    return xcaf;
}
float reseed2() {
    float r0 = get_lump(gl_FragCoord.x, gl_FragCoord.y, 2.0, 19.0 + mod(frames,17.0), 23.0 + mod(frames,43.0));
    float r1 = get_lump(gl_FragCoord.x, gl_FragCoord.y, 24.0, 13.0 + mod(frames,29.0), 17.0 + mod(frames,31.0));
    float r2 = get_lump(gl_FragCoord.x, gl_FragCoord.y, 8.0, 13.0 + mod(frames,11.0), 51.0 + mod(frames,37.0));
    return clamp((r0+r1)-r2,0.0,1.0);
}
void main() {
    const int VMX = 32;
    const int SPNH = 12;
    #define PI 3.1415926538
    float psn = 250.0;
    float mnp = 0.004;//1.0 / psn;
    float div = 1.0;
    float divi = floor((gl_FragCoord.x*div)/(resolution.x)) + floor((gl_FragCoord.y*div)/(resolution.y))*div;
    vec3 col = vec3( 0.0, 0.0, 0.0 );

    float dspace = (divi+1.0)/(div*div);
                dspace = (div == 1.0) ? 0.5 : dspace;

    float ezv = 0.0;
    float[VMX] dvmd;
    for(int i = 0; i < VMX; i++) { 
        dvmd[i] = ubvn[i] * 1.0
                ; }

// ---- ---- ---- ---- ---- ---- ---- ----
// Evo32 Selective MNCA
    float res_r = gdv( 0.0, 0.0, 0, div );// * psn;
    float res_g = gdv( 0.0, 0.0, 1, div );// * psn;
    float res_b = gdv( 0.0, 0.0, 2, div );// * psn;

    const int sets = 4;
    float[sets] rslt;
                rslt[0] = res_r;
                rslt[1] = res_r;
                rslt[2] = res_r;
                rslt[3] = res_r;

    float s = mnp * 12.0;

// ---- ---- ---- ---- ---- ---- ---- ----
// STAGE:MNCA
// DOMAIN: Totalistic Multiple Neighbourhood Continuous
// REQUIRES: Conditional Range
// UPDATE: Additive
// VALUE: Origin
// BLUR: Relative
// RESULT: Multiple

// MNCA 0
    vec3 n00r = nhd( vec2(1.0, 0.0), psn, 0.0, 0, div );
    vec3 n01r = nhd( vec2(3.0, 0.0), psn, 0.0, 0, div );
    float n00rw = n00r[0] / n00r[2];
    float n01rw = n01r[0] / n01r[2];
    if( n00rw >= dvmd[0] && n00rw <= dvmd[1] ) { rslt[0] += s; }
    if( n00rw >= dvmd[2] && n00rw <= dvmd[3] ) { rslt[0] -= s; }
    if( n01rw >= dvmd[4] && n01rw <= dvmd[5] ) { rslt[0] += s; }
    if( n01rw >= dvmd[6] && n01rw <= dvmd[7] ) { rslt[0] -= s; }
    rslt[0] = (rslt[0] + (n00rw * mnp * 4.0) + (n01rw * mnp * 4.0) + (res_r * 0.15)) / (1.15 + (mnp * 4.0 * 2.0));

// MNCA 1
    vec3 n10r = nhd( vec2(5.0, 2.0), psn, 0.0, 0, div );
    vec3 n11r = nhd( vec2(10.0, 7.0), psn, 0.0, 0, div );
    float n10rw = n10r[0] / n10r[2];
    float n11rw = n11r[0] / n11r[2];
    if( n10rw >= dvmd[8] && n10rw <= dvmd[9] ) { rslt[1] += s; }
    if( n10rw >= dvmd[10] && n10rw <= dvmd[11] ) { rslt[1] -= s; }
    if( n11rw >= dvmd[12] && n11rw <= dvmd[13] ) { rslt[1] += s; }
    if( n11rw >= dvmd[14] && n11rw <= dvmd[15] ) { rslt[1] -= s; }
    rslt[1] = (rslt[1] + (n10rw * mnp * 4.0) + (n11rw * mnp * 4.0) + (res_r * 0.15)) / (1.15 + (mnp * 4.0 * 2.0));

// MNCA 2
    vec3 n20r = nhd( vec2(4.0, 0.0), psn, 0.0, 0, div );
    vec3 n21r = nhd( vec2(12.0, 6.0), psn, 0.0, 0, div );
    float n20rw = n20r[0] / n20r[2];
    float n21rw = n21r[0] / n21r[2];
    if( n20rw >= dvmd[16] && n20rw <= dvmd[17] ) { rslt[2] += s; }
    if( n20rw >= dvmd[18] && n20rw <= dvmd[19] ) { rslt[2] -= s; }
    if( n21rw >= dvmd[20] && n21rw <= dvmd[21] ) { rslt[2] += s; }
    if( n21rw >= dvmd[22] && n21rw <= dvmd[23] ) { rslt[2] -= s; }
    rslt[2] = (rslt[2] + (n20rw * mnp * 4.0) + (n21rw * mnp * 4.0) + (res_r * 0.15)) / (1.15 + (mnp * 4.0 * 2.0));

// MNCA 3
    vec3 n30r = nhd( vec2(7.0, 3.0), psn, 0.0, 0, div );
    vec3 n31r = nhd( vec2(9.0, 5.0), psn, 0.0, 0, div );
    float n30rw = n30r[0] / n30r[2];
    float n31rw = n31r[0] / n31r[2];
    if( n30rw >= dvmd[24] && n30rw <= dvmd[25] ) { rslt[3] += s; }
    if( n30rw >= dvmd[26] && n30rw <= dvmd[27] ) { rslt[3] -= s; }
    if( n31rw >= dvmd[28] && n31rw <= dvmd[29] ) { rslt[3] += s; }
    if( n31rw >= dvmd[30] && n31rw <= dvmd[31] ) { rslt[3] -= s; }
    rslt[3] = (rslt[3] + (n30rw * mnp * 4.0) + (n31rw * mnp * 4.0) + (res_r * 0.15)) / (1.15 + (mnp * 4.0 * 2.0));

// ---- ---- ---- ---- ---- ---- ---- ----
// STAGE:Variance
// DOMAIN: MNCA
// REQUIRES: Unconditional
// UPDATE: Subtract
// VALUE: Origin
// BLUR: Specific
// RESULT: Multiple

    float[sets] variance;
    for(int i = 0; i < sets; i++) { variance[i] = res_r - rslt[i]; }

// ---- ---- ---- ---- ---- ---- ---- ----
// STAGE:Output
// DOMAIN: MNCA, Variance
// REQUIRES: Maximum Selection Match
// UPDATE: Select
// VALUE: Domain
// BLUR: Specific
// RESULT: Single

    int vi = 0;

    for(int i = 0; i < sets; i++) { if(abs(variance[vi]) < abs(variance[i])) { vi = i; } }

    res_r = rslt[vi];

// ---- ---- ---- ---- ---- ---- ---- ----

// Output
    if(div > 1.0) {
        res_g = (mod(gl_FragCoord.x,resolution.x/div) <= 1.0 || (mod(gl_FragCoord.y,resolution.y/div) <= 1.0)) ? 0.15 : res_r;
        res_b = (mod(gl_FragCoord.x,resolution.x/div) <= 1.0 || (mod(gl_FragCoord.y,resolution.y/div) <= 1.0)) ? 0.15 : res_r;
    } else { res_g = res_r; res_b = res_r; }

    col[0] = res_r;
    col[1] = res_g;
    col[2] = res_b;

    if(frames<3) col = vec3(reseed2(),reseed2(),reseed2());
    gl_FragColor = vec4(col, 1.0);
}
