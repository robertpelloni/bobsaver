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
float df2(float f0, float f1) {
// Difference Subtraction
    return clamp((f0 * 2.0)-f1, 0.0, 1.0);
}
float wa2(float av, float bv, float w) {
// Weighted Average
    return clamp( (av*w+bv)/(w+1.0), 0.0,1.0);
}
float sq2(float av, float bv) {
// Square Rooted
    return clamp( sqrt(sqrt(av*bv)*av), 0.0,1.0);
}
float mn2(float av, float bv) {
// Minimum
    return clamp( (av<bv)?av:bv, 0.0,1.0);
}
float mx2(float av, float bv) {
// Maximum
    return clamp( (av>bv)?av:bv, 0.0,1.0);
}
float sd2(float av, float bv) {
// Subtract Difference
    return clamp( (av * 2.0) - ((0.5-abs(av-bv)) * 2.0), 0.0,1.0);
}
float pd2(float av, float bv) {
// ???
    return clamp( (pow(sqrt(av+bv),1.0/abs(av+bv))), 0.0,1.0);
}
float ds2(float av, float bv) {
// Difference Divided by Sum
    return clamp( ((av - bv)*2.0) / (abs(av + bv) + 1.0), 0.0,1.0);
}
float ga2(float av, float bv, float w) {
// Weighted Geometric Average
    return clamp( pow(av, w/(w+1.0) ) * pow(bv, 1.0/(w+1.0) ), 0.0,1.0);
}
vec2 dc2(float av, float bv, float mv) {
// Difference Choice vs Mediator Value
    float d0 = abs(av-mv);
    float d1 = abs(bv-mv);
    return vec2(
        clamp( (d0<d1)?av:bv, 0.0,1.0), 
        clamp( (d0>d1)?av:bv, 0.0,1.0) 
    );
}
float dn2(vec2 nh, float psn) {
// Diffusion
    return clamp( ((nh[0]/nh[1]) / ((nh[1]+psn)/psn)) + (nh[0] / (nh[1]+psn)), 0.0,1.0);
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

    vec2 nhr = vec2( nhcr, 1.0 );
    vec2 nhg = vec2( nhcg, 1.0 );
    vec2 nhb = vec2( nhcb, 1.0 );

// nhr = nh_val ( 1.0, 0.0, psn, 0 );
// nhg = nh_val ( 1.0, 0.0, psn, 1 );
// nhb = nh_val ( 1.0, 0.0, psn, 2 );
            nhr = nh_val ( floor(1.0+(cs*20.0)), floor(0.0+(cs*20.0)), psn, 0 );
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
    float cydf = 0.1;
    float cdrgbv = dfrv+(dfgv*cydf)-(dfbv*cydf);
    float cdgbrv = dfgv+(dfbv*cydf)-(dfrv*cydf);
    float cdbrgv = dfbv+(dfrv*cydf)-(dfgv*cydf);

// Assemble
    float rw = 0.0;
// - df2 : Difference Subtraction
// - sd2 : Subtract Difference
// - ds2 : Difference Divided by Sum
// wa2 : Weighted Average
// sq2 : Square Rooted
// mn2 : Minimum
// mx2 : Maximum
// pd2 : Product Divided by Difference
// ga2 : Weighted Geometric Average
// dc2 : Difference Choice vs Mediator Value

// rw = df2(nh0rv,nh2rv);
// rw = sd2(nh0rv,nh2rv);
// rw = ds2(nh0rv,nh2rv);

// rw = wa2(nh0rv,nh2rv,1.0,1.0);
// rw = sq2(nh0rv,nh2rv);
// rw = mn2(nh0rv,nh2rv);
// rw = mx2(nh0rv,nh2rv);
// rw = pd2(nh0rv,nh2rv);
// rw = ga2(nh0rv,nh2rv,1.0,1.0);
// vec2 vrw = dc2(nh0rv,nh2rv,nh1rv); rw = vrw[1];

    float res_0 = 0.0;
            res_0 = ds2(nh0rv,nh3rv);
            res_0 = df2(res_0,nh3rv);
            res_0 = wa2(res_0,nh0rv,3.5);
            res_0 = mx2(res_0,nh1rv);

    float res_1 = 0.0;
            res_1 = df2(nh0rv,nh2rv);
            res_1 = df2(res_1,nh2rv);
            res_1 = sd2(res_1,nh4rv);

    float res_2 = 0.0;
            res_2 = wa2(res_0,res_1,6.0);

    float res_3 = 0.0;
            res_3 = df2(nh2rv,nh4rv);
            res_3 = wa2(res_2,res_3,5.0);
            res_3 = wa2(res_3,res_1,9.0);
            res_3 = sq2(res_0,res_3);

    float a = nh3rv;
    float x = nhrv;

// float desmo = 2.0*x - a;
// float desmo = 2.0*x - 2.0*a;
// float desmo = x/((1.0/x)*a);
// float desmo = ((1.0/a)*(x*x))-a;
// float desmo = ((a*a)+(2.0*(x*x)))-0.5;
// float desmo = (((2.0*(a*a))+(1.0*(x*x)))-0.5)/x;
// float desmo = a/(0.25*x+((a/x)*(a/x)));
// float desmo = sqrt((2.0*a-0.5)*(1.0*x+0.0));

// float desmo = (sin(-1.0*PI*x)*cos(PI*x)+1.0)/2.0;
// float desmo = (x*2.0)-a;
// float desmo = (x*x)+(a/2.0);
// float desmo = (((a+1.0)/2.0)*(x*x))+(a/2.0);
// float desmo = (a*(x*x))*(1.0/x); ?
// float desmo = (a*(x*x))*4.0*((a-x)/x); ?
// float desmo = ((a+(1.0/x))*(x*x))*1.0*(abs(a-x)/(a+x));
// float desmo = ((a+1.5)/(x*2.0))*(x*x);
// float desmo = (x*2.0)-a;
// float desmo = ((1.0*a*x)*(1.0*a*x)-(a/2.0))+0.5;
// float desmo = ((1.0*x)*(1.0*a*x)-(a/2.0))+0.5;
// float desmo = ((1.0/a)*(x*x))-a;
// float desmo = (2.0*(a*a))-x;
// float desmo = ((a*a)+(2.0*(x*x)))-0.5;

// float desmo = 2.0*x - a;
// float desmo = 2.0*x - 2.0*a;
// float desmo = x/((1.0/x)*a);
// float desmo = ((1.0/a)*(x*x))-a;
// float desmo = ((a*a)+(2.0*(x*x)))-0.5;
// float desmo = (((2.0*(a*a))+(1.0*(x*x)))-0.5)/x;
// float desmo = a/(0.25*x+((a/x)*(a/x)));
// float desmo = sqrt((2.0*a-0.5)*(1.0*x+0.0));

// float desmo = (x*x+0.5) - ( (a+0.5) / ( (1.0*x) - ((2.0*a-2.0*x)/(1.0*x-a)) ) );
// float desmo = (x*x+0.5) - ( (a+0.5) / ( (1.0*x/a) - ((2.0*a-2.0*x)/(1.0*x-a)) ) );
// float desmo = ((a-1.0) / (x-1.0))-1.0;
// float desmo = ((a-1.0) / (x-a))*x-1.0;
// float desmo = ((x*x+a)/(a*a+x*x))*x;
// float desmo = ((x*x+a)/(1.0*(a*a)+x))*x;
    float desmo = x*8.0*abs(x-a);
// float desmo = abs(a-1.0*x)+(x*x);
// float desmo = x*((1.0/a)-1.0);
// float desmo = x*((1.0/pow(a,0.5))-1.0);
// float desmo = x*((1.0/pow(a,0.5))-x);
// float desmo = x*((1.0/pow(2.0*a,1.0))*0.5*x);
// float desmo = (abs(a-x)+x)+(abs(a-x)/(x-1.5));
// float desmo = (abs(a-x)+x)+((abs(a-x)+0.5)/(x*a-3.0));

    rw = desmo;

// Assign 
    res_r = rw;
    res_g = cdgbrv;
    res_b = cdbrgv;

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
