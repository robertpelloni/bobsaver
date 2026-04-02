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
    float cv = gv(0.0,0.0,0);

    vec2 c0 = nh_val ( 8.0, 0.0, 0 );
    float c0v = (c0[0] / c0[1]);

    vec2 nh0 = nh_val ( 1.0, 0.0, 0 );
    vec2 nh1 = nh_val ( 3.0, 2.0, 0 );
    vec2 nh2 = nh_val ( 6.0, 5.0, 0 );
    vec2 nh3 = nh_val ( 12.0, 11.0, 0 );

    float nh0v = (nh0[0] / nh0[1])*1.045;
    float nh1v = (nh1[0] / nh1[1])*1.050;
    float nh2v = (nh2[0] / nh2[1])*1.058;
    float nh3v = (nh3[0] / nh3[1])*1.064;

    float rd01 = (nh0v * (2.0+cs)) - nh1v;
    float rd10 = (nh1v * (2.0+cs)) - nh0v;
    float rdr01 = (nh0[1]<nh1[1]) ? rd01 : rd10;

    float rd02 = (nh0v * (2.0+cs)) - nh2v;
    float rd20 = (nh2v * (2.0+cs)) - nh0v;
    float rdr02 = (nh0[1]<nh2[1]) ? rd02 : rd20;

    float rd03 = (nh0v * (2.0+cs)) - nh3v;
    float rd30 = (nh3v * (2.0+cs)) - nh0v;
    float rdr03 = (nh0[1]<nh3[1]) ? rd03 : rd30;

    float rd12 = (nh1v * (2.0+cs)) - nh2v;
    float rd21 = (nh2v * (2.0+cs)) - nh1v;
    float rdr12 = (nh1[1]<nh2[1]) ? rd12 : rd21;

    float rd13 = (nh1v * (2.0+cs)) - nh3v;
    float rd31 = (nh3v * (2.0+cs)) - nh1v;
    float rdr13 = (nh1[1]<nh3[1]) ? rd13 : rd31;

    float rd23 = (nh2v * (2.0+cs)) - nh3v;
    float rd32 = (nh3v * (2.0+cs)) - nh2v;
    float rdr23 = (nh2[1]<nh3[1]) ? rd23 : rd32;

    float d0 = abs(cv - rdr03);

    float tip = (cv < rdr03) ? (rdr03*0.2) : ((rdr03*0.2)*-1.0);

    res_r = res_r+tip;

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
