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
                || (cos(nh_val*cosmod[1])+1.0)*0.5 <= cosmod[0] ) {
                    nhsz_c += 1.0;
                    if(gv(i,j,0) > 0.0) {
                        cnt+=1.0;
                        wgt+=1.0-(nh_val/nhsz);
                    } } } } }
    return vec3(cnt, nhsz_c, wgt);
}
void main() {
    vec3 col = vec3 ( 0.0, 0.0, 0.0 );
    float res_r = gv ( 0.0, 0.0, 0 );
    float res_g = gv ( 0.0, 0.0, 1 );
    float res_b = gv ( 0.0, 0.0, 2 );
    float res = res_r;
    float outval = res;

    float nhd0=cv(-14.0,-1.0)+cv(-14.0,0.0)+cv(-14.0,1.0)+cv(-13.0,-4.0)+cv(-13.0,-3.0)+cv(-13.0,-2.0)+cv(-13.0,2.0)+cv(-13.0,3.0)+cv(-13.0,4.0)+cv(-12.0,-6.0)+cv(-12.0,-5.0)+cv(-12.0,5.0)+cv(-12.0,6.0)+cv(-11.0,-8.0)+cv(-11.0,-7.0)+cv(-11.0,7.0)+cv(-11.0,8.0)+cv(-10.0,-9.0)+cv(-10.0,-1.0)+cv(-10.0,0.0)+cv(-10.0,1.0)+cv(-10.0,9.0)+cv(-9.0,-10.0)+cv(-9.0,-4.0)+cv(-9.0,-3.0)+cv(-9.0,-2.0)+cv(-9.0,2.0)+cv(-9.0,3.0)+cv(-9.0,4.0)+cv(-9.0,10.0)+cv(-8.0,-11.0)+cv(-8.0,-6.0)+cv(-8.0,-5.0)+cv(-8.0,5.0)+cv(-8.0,6.0)+cv(-8.0,11.0)+cv(-7.0,-11.0)+cv(-7.0,-7.0)+cv(-7.0,-2.0)+cv(-7.0,-1.0)+cv(-7.0,0.0)+cv(-7.0,1.0)+cv(-7.0,2.0)+cv(-7.0,7.0)+cv(-7.0,11.0)+cv(-6.0,-12.0)+cv(-6.0,-8.0)+cv(-6.0,-4.0)+cv(-6.0,-3.0)+cv(-6.0,3.0)+cv(-6.0,4.0)+cv(-6.0,8.0)+cv(-6.0,12.0)+cv(-5.0,-12.0)+cv(-5.0,-8.0)+cv(-5.0,-5.0)+cv(-5.0,-1.0)+cv(-5.0,0.0)+cv(-5.0,1.0)+cv(-5.0,5.0);
    float nhd1=cv(-5.0,8.0)+cv(-5.0,12.0)+cv(-4.0,-13.0)+cv(-4.0,-9.0)+cv(-4.0,-6.0)+cv(-4.0,-3.0)+cv(-4.0,-2.0)+cv(-4.0,2.0)+cv(-4.0,3.0)+cv(-4.0,6.0)+cv(-4.0,9.0)+cv(-4.0,13.0)+cv(-3.0,-13.0)+cv(-3.0,-9.0)+cv(-3.0,-6.0)+cv(-3.0,-4.0)+cv(-3.0,-1.0)+cv(-3.0,0.0)+cv(-3.0,1.0)+cv(-3.0,4.0)+cv(-3.0,6.0)+cv(-3.0,9.0)+cv(-3.0,13.0)+cv(-2.0,-13.0)+cv(-2.0,-9.0)+cv(-2.0,-7.0)+cv(-2.0,-4.0)+cv(-2.0,-2.0)+cv(-2.0,2.0)+cv(-2.0,4.0)+cv(-2.0,7.0)+cv(-2.0,9.0)+cv(-2.0,13.0)+cv(-1.0,-14.0)+cv(-1.0,-10.0)+cv(-1.0,-7.0)+cv(-1.0,-5.0)+cv(-1.0,-3.0)+cv(-1.0,-1.0)+cv(-1.0,0.0)+cv(-1.0,1.0)+cv(-1.0,3.0)+cv(-1.0,5.0)+cv(-1.0,7.0)+cv(-1.0,10.0)+cv(-1.0,14.0)+cv(0.0,-14.0)+cv(0.0,-10.0)+cv(0.0,-7.0)+cv(0.0,-5.0)+cv(0.0,-3.0)+cv(0.0,-1.0)+cv(0.0,1.0)+cv(0.0,3.0)+cv(0.0,5.0)+cv(0.0,7.0)+cv(0.0,10.0)+cv(0.0,14.0)+cv(1.0,-14.0)+cv(1.0,-10.0)+cv(1.0,-7.0);
    float nhd2=cv(1.0,-5.0)+cv(1.0,-3.0)+cv(1.0,-1.0)+cv(1.0,0.0)+cv(1.0,1.0)+cv(1.0,3.0)+cv(1.0,5.0)+cv(1.0,7.0)+cv(1.0,10.0)+cv(1.0,14.0)+cv(2.0,-13.0)+cv(2.0,-9.0)+cv(2.0,-7.0)+cv(2.0,-4.0)+cv(2.0,-2.0)+cv(2.0,2.0)+cv(2.0,4.0)+cv(2.0,7.0)+cv(2.0,9.0)+cv(2.0,13.0)+cv(3.0,-13.0)+cv(3.0,-9.0)+cv(3.0,-6.0)+cv(3.0,-4.0)+cv(3.0,-1.0)+cv(3.0,0.0)+cv(3.0,1.0)+cv(3.0,4.0)+cv(3.0,6.0)+cv(3.0,9.0)+cv(3.0,13.0)+cv(4.0,-13.0)+cv(4.0,-9.0)+cv(4.0,-6.0)+cv(4.0,-3.0)+cv(4.0,-2.0)+cv(4.0,2.0)+cv(4.0,3.0)+cv(4.0,6.0)+cv(4.0,9.0)+cv(4.0,13.0)+cv(5.0,-12.0)+cv(5.0,-8.0)+cv(5.0,-5.0)+cv(5.0,-1.0)+cv(5.0,0.0)+cv(5.0,1.0)+cv(5.0,5.0)+cv(5.0,8.0)+cv(5.0,12.0)+cv(6.0,-12.0)+cv(6.0,-8.0)+cv(6.0,-4.0)+cv(6.0,-3.0)+cv(6.0,3.0)+cv(6.0,4.0)+cv(6.0,8.0)+cv(6.0,12.0)+cv(7.0,-11.0)+cv(7.0,-7.0)+cv(7.0,-2.0);
    float nhd3=cv(7.0,-1.0)+cv(7.0,0.0)+cv(7.0,1.0)+cv(7.0,2.0)+cv(7.0,7.0)+cv(7.0,11.0)+cv(8.0,-11.0)+cv(8.0,-6.0)+cv(8.0,-5.0)+cv(8.0,5.0)+cv(8.0,6.0)+cv(8.0,11.0)+cv(9.0,-10.0)+cv(9.0,-4.0)+cv(9.0,-3.0)+cv(9.0,-2.0)+cv(9.0,2.0)+cv(9.0,3.0)+cv(9.0,4.0)+cv(9.0,10.0)+cv(10.0,-9.0)+cv(10.0,-1.0)+cv(10.0,0.0)+cv(10.0,1.0)+cv(10.0,9.0)+cv(11.0,-8.0)+cv(11.0,-7.0)+cv(11.0,7.0)+cv(11.0,8.0)+cv(12.0,-6.0)+cv(12.0,-5.0)+cv(12.0,5.0)+cv(12.0,6.0)+cv(13.0,-4.0)+cv(13.0,-3.0)+cv(13.0,-2.0)+cv(13.0,2.0)+cv(13.0,3.0)+cv(13.0,4.0)+cv(14.0,-1.0)+cv(14.0,0.0)+cv(14.0,1.0);
    float fin_0=nhd0+nhd1+nhd2+nhd3;
    if(fin_0>=100.0){
        outval=0.0;
    }
    if(fin_0>=80.0&&fin_0<=99.0){
        outval=1.0;
    }
    if(fin_0>=65.0&&fin_0<=79.0){
        outval=0.0;
    }
    if(fin_0>=30.0&&fin_0<=55.0){
        outval=1.0;
    }
    float nhd4=cv(-3.0,-1.0)+cv(-3.0,0.0)+cv(-3.0,1.0)+cv(-2.0,-2.0)+cv(-2.0,2.0)+cv(-1.0,-3.0)+cv(-1.0,-1.0)+cv(-1.0,0.0)+cv(-1.0,1.0)+cv(-1.0,3.0)+cv(0.0,-3.0)+cv(0.0,-1.0)+cv(0.0,1.0)+cv(0.0,3.0)+cv(1.0,-3.0)+cv(1.0,-1.0)+cv(1.0,0.0)+cv(1.0,1.0)+cv(1.0,3.0)+cv(2.0,-2.0)+cv(2.0,2.0)+cv(3.0,-1.0)+cv(3.0,0.0)+cv(3.0,1.0);
    float fin_1=nhd4;
    if(fin_1>=0.0&&fin_1<=6.0){
        outval=0.0;
    }
    if(fin_1>=16.0&&fin_1<=20.0){
        outval=1.0;
    }
    if(fin_1>=7.0&&fin_1<=7.0){
        outval=1.0;
    }

    res = outval;
    float trail = 0.38;
    res_r = res;
    res_b = res;
    if(res_r == 0.0) {
        if(res_g >= trail) { res_g = trail; } }
     else { res_g = res_r; }
    if(res_g > 0.0) { res_g = res_g - 0.008; }
    if(res_g <= 0.0) { res_g = 0.0; }

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
