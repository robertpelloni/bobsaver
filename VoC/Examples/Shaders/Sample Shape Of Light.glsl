#version 420

// original https://neort.io/art/bn4prgc3p9f80jer8fr0

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
float gTime = 0.0;

// 回転行列
mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c,s,-s,c);
}
float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float steel(vec3 pos) {
    //p.yz * rot(.5);
    //return min(min(bar_x, bar_y),bar_z);
    vec3 pos_origin  = pos;
    pos.xy = pos_origin.xy;
    float side1 = sdSphere(pos, .1+ .4 *  abs(sin(gTime * 0.5)));
    pos.xy = pos_origin.xy;
    pos.x =  pos.x  + sin(time *.1);
    pos.y =  pos.y  +  sin(time *.1);
    float side2 = sdSphere(pos, .1+.4 *  abs(sin(gTime * 0.25)));
    pos.xy = pos_origin.xy;
    pos.x =  pos.x  -  sin(time *.1);
    pos.y =  pos.y  +  sin(time *.1);
    float side3 = sdSphere(pos, .1+.4 *  abs(sin(gTime * 0.25)));
    pos.xy = pos_origin.xy;
    pos.x =  pos.x  +  sin(time *.1);
    pos.y =  pos.y  -  sin(time *.1);
    float side4 = sdSphere(pos,.1+ .4 *  abs(sin(gTime * 0.25)));
    pos.xy = pos_origin.xy;
    pos.x =  pos.x  - sin(time *.1);
    pos.y =  pos.y  -  sin(time *.1);
    float side5 = sdSphere(pos,.1+ .4 *  abs(sin(gTime * 0.25)));
    pos.xy = pos_origin.xy;
    pos.y =  pos.y  -  sin(time *.1);
    float side6 = sdSphere(pos,.1+ .4 *  abs(sin(gTime * 0.25)));
    pos.xy = pos_origin.xy;
    pos.y =  pos.y  +  sin(time *.1);
    float side7 = sdSphere(pos,.1+ .4 *  abs(sin(gTime * 0.25)));
    pos.xy = pos_origin.xy;
    pos.x =  pos.x  +  sin(time *.1);
    float side8 = sdSphere(pos,.1+ .4 *  abs(sin(gTime * 0.25)));
    pos.xy = pos_origin.xy;
    pos.x =  pos.x  -  sin(time *.1);
    float side9 = sdSphere(pos,.1+ .4 *  abs(sin(gTime * 0.25)));

    return min(min(min(min(min(min(min(side2,side3), side4), side5),side6), side7), side8),side9) * 3.6;
}

void main( void ) {
    vec2 p = (gl_FragCoord.xy * 2. - resolution.xy) / min(resolution.x, resolution.y);
    vec3 ro = vec3(0., 0. , 0. + time * 5.);
    vec3 ray = normalize(vec3(p, 2.5));
    ray.xy = ray.xy * rot(sin(time * .01) * 4.);
    ray.yz = ray.yz * rot(sin(time * .1) * .2);
    float t = 5.;
    vec3 col = vec3(0.);
    float ac = 0.0;

    for (int i = 0; i < 180; i++){
        vec3 pos = ro + ray * t;
        gTime = sin(time) - float(i) * 0.0000001;
        pos = mod(pos-2., 4.) -2.;
        float d = steel(pos);

        d = max(abs(d), 0.2);
        ac += exp(-d*3.);

        t += d* 0.1;
    }
    col = vec3(ac * 0.01);
        col.x += col.x * abs(sin(time * 0.1)) * 2. + 0.2;
        col.y += col.y * abs(sin(time * 0.2)) * 2. + 0.2;
        col.z += col.z * sin(time * 0.25) * 0.4 + 0.4;
    glFragColor = vec4(col ,1.0);
}
