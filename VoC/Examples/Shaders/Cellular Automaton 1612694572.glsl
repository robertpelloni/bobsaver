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

    float s = 0.033 + 0.030 + cs;

    float r0 = res_r;
    vec3 n00r = nhd(vec2(2.0,1.0),psn,0.0,0);
    vec3 n01r = nhd(vec2(5.0,3.0),psn,0.0,0);
    float n00rw = n00r[0] / n00r[2];
    float n01rw = n01r[0] / n01r[2];

    if( n00rw >= 0.180 && n00rw <= 0.400 ) { r0 += s; }
    if( n01rw >= 0.100 && n01rw <= 1.000 ) { r0 -= s; }
            r0 -= 0.005;

    float r1 = res_r;
    vec3 n10r = nhd(vec2(6.0,0.0),psn,0.0,0);
    vec3 n11r = nhd(vec2(8.0,3.0),psn,0.0,0);
    float n10rw = n10r[0] / n10r[2];
    float n11rw = n11r[0] / n11r[2];

    if( n10rw >= 0.220 && n10rw <= 0.500 ) { r1 += s; }
    if( n11rw >= 0.270 && n11rw <= 1.000 ) { r1 -= s; }
            r1 -= 0.005;

    vec3 nmr = nhd(vec2(1.0,0.0),psn,0.0,0);
    float nmrw = nmr[0] / nmr[2];
    
            r0 = (res_r*0.1+r0+nmrw*0.05)/1.15;
            r1 = (res_r*0.1+r1+nmrw*0.05)/1.15;

    float d0 = abs(res_r - r0);
    float d1 = abs(res_r - r1);
    float r2 = (d0 > d1) ? ((d0 >= 0.005) ? r0 : r1) : ((d1 >= 0.005) ? r1 : r0);

    vec3 n20r = nhd(vec2(16.0,8.0),psn,0.0,0);
    float n20rw = n20r[0] / n20r[2];
    float r3 = (n20rw*-0.1+res_r*0.1+r2)/(1.11);

    res_r = r3;

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
