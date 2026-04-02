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
void main() {
    #define PI 3.1415926538
    float psn = 200.0;
    float cs = 1.0*0.001;
    vec3 col = vec3( 0.0, 0.0, 0.0 );

    float res_r = gv( 0.0, 0.0, 0 );// * psn;
    float res_g = gv( 0.0, 0.0, 1 );// * psn;
    float res_b = gv( 0.0, 0.0, 2 );// * psn;

// res_r = (res_r - fract(res_r) ) / psn;
// res_g = (res_g - fract(res_g) ) / psn;
// res_b = (res_b - fract(res_b) ) / psn;

    vec3 nhdr0 = nhd( vec2(16.0,6.0), psn, 0.0, 0 );
    float nhdr0_avg = nhdr0[0] / nhdr0[2];
    float nhdr0_cnt = nhdr0[1] / nhdr0[2];
    float nhdr0_wgt = nhdr0[0] / nhdr0[1];

    float r0 = res_r;

    res_g = 0.0;
    res_b = 0.0;

    if( nhdr0_avg >= 0.000 && nhdr0_avg <= 1.000 ) { r0 -= 0.010; }

    if( nhdr0_avg >= 0.270+cs && nhdr0_avg <= 0.320+cs ) { r0 += 0.120; res_g = 1.0; }
// if( nhdr0_avg >= 0.562 && nhdr0_avg <= 0.640+cs ) { r0 += 0.120; res_g = 0.6; }
// if( nhdr0_avg >= 0.720 && nhdr0_avg <= 0.820 ) { r0 += 0.120; res_g = 0.3; }

    if( nhdr0_avg >= 0.080 && nhdr0_avg <= 0.250 ) { r0 -= 0.250; }
    if( nhdr0_avg >= 0.700 && nhdr0_avg <= 1.000 ) { r0 -= 0.060; }

    if(r0 == 0.0) { res_g = 0.0; res_b = 0.0; }

/*
    if( nhdr0_avg >= 0.335 && nhdr0_avg <= 0.447 ) { r0 += 0.12; }
    if( nhdr0_avg >= 0.172 && nhdr0_avg <= 0.252 ) { r0 += 0.04; }
    if( nhdr0_avg >= 0.283 && nhdr0_avg <= 0.420 ) { r0 -= 0.09; }
    if( nhdr0_avg >= 0.130 && nhdr0_avg <= 0.190 ) { r0 -= 0.14; }
    if( nhdr0_avg >= 0.630 && nhdr0_avg <= 0.730+cs ) { r0 += 0.12; }

    if( nhdr0_avg >= 0.272 && nhdr0_avg <= 0.378 ) { r0 -= 0.06; }

// if( nhdr0_avg >= 0.705+cs && nhdr0_avg <= 0.800 ) { r0 -= 0.32; }*/

    res_r = r0;

// Output
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
