#version 420

// Scale Variance Agoniser (Slackermanz MSTP variant)
// original shader by https://www.reddit.com/user/slackermanz/

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform int frames;
uniform sampler2D txdata;

out vec4 glFragColor;
float seed = 0.0;
float gdv(float x, float y, int v, float div) {
// Get Div Value: Return the value of a specified pixel
// x, y : Relative integer-spaced coordinates to origin [ 0.0, 0.0 ]
// v : Colour channel [ 0, 1, 2 ]
// div : Integer-spaced number of toroidal divisions of the surface/medium
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
vec3 nhd( vec2 nbhd, float psn, float thr, int col, float div ) {
// Neighbourhood: Return information about the specified group of pixels
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
float get_xc(float x, float y, float xmod) {
// Used to reseed the surface with noise
    float sq = sqrt(mod(x*y+y, xmod)) / sqrt(xmod);
    float xc = mod((x*x)+(y*y), xmod) / xmod;
    return clamp((sq+xc)*0.5, 0.0, 1.0);
}
float shuffle(float x, float y, float xmod, float val) {
// Used to reseed the surface with noise
    val = val * mod( x*y + x, xmod );
    return (val-floor(val));
}
float get_xcn(float x, float y, float xm0, float xm1, float ox, float oy) {
// Used to reseed the surface with noise
    float xc = get_xc(x+ox, y+oy, xm0);
    return shuffle(x+ox, y+oy, xm1, xc);
}
float get_lump(float x, float y, float nhsz, float xm0, float xm1) {
// Used to reseed the surface with noise
    float nhsz_c = 0.0;
    float xcn = 0.0;
    float nh_val = 0.0;
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
// Used to reseed the surface with noise
    float r0 = get_lump(gl_FragCoord.x, gl_FragCoord.y, 2.0, 19.0 + mod(time,17.0), 23.0 + mod(time+4,43.0));
    float r1 = get_lump(gl_FragCoord.x, gl_FragCoord.y, 24.0, 13.0 + mod(time+2,29.0), 17.0 + mod(time+5,31.0));
    float r2 = get_lump(gl_FragCoord.x, gl_FragCoord.y, 8.0, 13.0 + mod(time+3,11.0), 51.0 + mod(time+6,37.0));
    return clamp((r0+r1)-r2,0.0,1.0);
}
void main() {
// ---- ---- ---- ---- ---- ---- ---- ----
// Initilisation
// ---- ---- ---- ---- ---- ---- ---- ----
    const int VMX = 32; // Evolution Variables
    float psn = 250.0; // Precision
    float mnp = 0.004; // Minimum Precision Value : (1.0 / psn);
    float div = 1.0; // Toroidal Surface Divisions
    float divi = floor((gl_FragCoord.x*div)/(resolution.x)) 
                        + floor((gl_FragCoord.y*div)/(resolution.y))*div; // Division Index
    float dspace = (divi+1.0)/(div*div);
                dspace = (div == 1.0) ? 0.5 : dspace; // Division Weight
    vec3 col = vec3( 0.0, 0.0, 0.0 ); // Final colour value output container

    float[VMX] dvmd; // Division Weighted V number
    //for(int i = 0; i < VMX; i++) { dvmd[i] = ubvn[i] * 1.0; }

// ---- ---- ---- ---- ---- ---- ---- ----
// RULE:Scale Variance Agoniser (Slackermanz MSTP variant)
// ---- ---- ---- ---- ---- ---- ---- ----
// Rule Initilisation

// Get the reference frame's origin pixel values
    float res_r = gdv( 0.0, 0.0, 0, div );
    float res_g = gdv( 0.0, 0.0, 1, div );
    float res_b = gdv( 0.0, 0.0, 2, div );

// Intended rate of change
    float s = mnp * 12.0;

// ---- ---- ---- ---- ---- ---- ---- ----
// STAGE:Scales
// DOMAIN: Totalistic Individual Neighbourhood Continuous
// REQUIRES: Unconditional
// UPDATE: Select
// VALUE: Origin
// BLUR: Relative
// RESULT: Multiple

// Number of Individual Neighbourhoods
    const int sets = 7;

// Container for STAGE:Scales results
            float[sets] rslt;

// Define and assess the Individual Neighbourhoods
    /**
    //original sizes
    vec3 n0r = nhd( vec2( 1.0, 0.0 ), psn, 0.0, 0, div );
    vec3 n1r = nhd( vec2( 3.0, 0.0 ), psn, 0.0, 0, div );
    vec3 n2r = nhd( vec2( 6.0, 1.0 ), psn, 0.0, 0, div );
    vec3 n3r = nhd( vec2( 12.0, 3.0 ), psn, 0.0, 0, div );
    vec3 n4r = nhd( vec2( 24.0, 6.0 ), psn, 0.0, 0, div );
    vec3 n5r = nhd( vec2( 38.0, 12.0 ), psn, 0.0, 0, div );
    vec3 n6r = nhd( vec2( 52.0, 24.0 ), psn, 0.0, 0, div );
    **/
    //sizes x 3
    vec3 n0r = nhd( vec2( 1.0, 0.0 ), psn, 0.0, 0, div );
    vec3 n1r = nhd( vec2( 3.0, 0.0 ), psn, 0.0, 0, div );
    vec3 n2r = nhd( vec2( 18.0, 3.0 ), psn, 0.0, 0, div );
    vec3 n3r = nhd( vec2( 36.0, 9.0 ), psn, 0.0, 0, div );
    vec3 n4r = nhd( vec2( 72.0, 18.0 ), psn, 0.0, 0, div );
    vec3 n5r = nhd( vec2( 114.0, 36.0 ), psn, 0.0, 0, div );
    vec3 n6r = nhd( vec2( 156.0, 72.0 ), psn, 0.0, 0, div );

// Get the Totalistic value of each Individual Neighbourhood
    rslt[0] = n0r[0] / n0r[2];
    rslt[1] = n1r[0] / n1r[2];
    rslt[2] = n2r[0] / n2r[2];
    rslt[3] = n3r[0] / n3r[2];
    rslt[4] = n4r[0] / n4r[2];
    rslt[5] = n5r[0] / n5r[2];
    rslt[6] = n6r[0] / n6r[2];

// Apply a BLUR:Relative to the VALUE:Origin
    rslt[0] = (res_r + rslt[0] * s) / (1.0 + s );
    rslt[1] = (res_r + rslt[1] * s) / (1.0 + s );
    rslt[2] = (res_r + rslt[2] * s) / (1.0 + s );
    rslt[3] = (res_r + rslt[3] * s) / (1.0 + s );
    rslt[4] = (res_r + rslt[4] * s) / (1.0 + s );
    rslt[5] = (res_r + rslt[5] * s) / (1.0 + s );
    rslt[6] = (res_r + rslt[6] * s) / (1.0 + s );

// ---- ---- ---- ---- ---- ---- ---- ----
// STAGE:Variance
// DOMAIN: Scales
// REQUIRES: Previous
// UPDATE: Subtract
// VALUE: Domain
// BLUR: Specific
// RESULT: Multiple

// Container for STAGE:Variance results
    float[sets] variance;

// UPDATE:Subtract the REQUIRES:Previous value
    for(int i = 0; i < sets; i++) { 
        if(i == 0) { variance[i] = res_r - rslt[i]; }
        else { variance[i] = rslt[i-1] - rslt[i]; } }

// ---- ---- ---- ---- ---- ---- ---- ----
// STAGE:MinimumSelection
// DOMAIN: Variance
// REQUIRES: MinimumABS
// UPDATE: Select
// VALUE: Domain
// BLUR: Specific
// RESULT: Single

// Index of an element in DOMAIN:Variance
    int vsn = 0;

// Get the index of the element in DOMAIN:Variance that meets REQUIRES:MinimumABS
    for( int i = 0; i < sets; i++ ) { if( abs(variance[vsn]) > abs(variance[i]) ) { vsn = i; } }

// UPDATE:Select the DOMAIN:Variance value with the REQUIRES:MinimumABS index
    float minvar = variance[vsn];

// ---- ---- ---- ---- ---- ---- ---- ----
// STAGE:Output
// DOMAIN: MinimumSelection
// REQUIRES: Unconditional
// UPDATE: AdditiveSign
// VALUE: Origin
// BLUR: Diffuse
// RESULT: Single

// UPDATE:AdditiveSign the VALUE:Origin
    res_r = res_r + sign(minvar) * s;

// BLUR:Diffuse the result
    vec3 blr = nhd( vec2( 1.0, 0.0 ), psn, 0.0, 0, div );
    float blrt = blr[0] / blr[2];
    res_r = (res_r + blrt * s) / (1.0 + s);

// ---- ---- ---- ---- ---- ---- ---- ----
// Presentation Filtering
// ---- ---- ---- ---- ---- ---- ---- ----
    vec3 n0g = nhd( vec2( 1.0, 0.0 ), psn, 0.0, 1, div );
    vec3 n0b = nhd( vec2( 2.0, 0.0 ), psn, 0.0, 2, div );
    float n0gw = n0g[0] / n0g[2];
    float n0bw = n0b[0] / n0b[2];
    res_g = (res_g + n0gw * mnp * 8.0 + res_r * mnp * 8.0 ) / (1.0 + mnp * 16.0);
    res_b = (res_b + n0bw * mnp * 4.0 + res_r * mnp * 4.0 ) / (1.0 + mnp * 8.0);

// ---- ---- ---- ---- ---- ---- ---- ----
// Fragment Shader Output
// ---- ---- ---- ---- ---- ---- ---- ----

    col[0] = res_r;
    col[1] = res_g;
    col[2] = res_b;

    if(frames<3) col = vec3(reseed2(),reseed2(),reseed2());
    glFragColor = vec4(col, 1.0);
}
