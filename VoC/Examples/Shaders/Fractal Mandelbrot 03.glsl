#version 420

// original https://www.shadertoy.com/view/tsXBRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
 Formula by IQ, with added translation (qd) and elongation/compression (qc)
*/
vec3 pal(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d, in float qc, in float qd){
    return a + b * sin(2.0 * 3.14159265359 * (c * t * qc + d  + qd));
}

/*
 From http://www.flong.com/texts/code/shapers_circ/
*/
float trafoDCircSeat(in float x, in float a){
    float b = clamp(a,0.0,1.0);
    if(x <=b ){
        return b - sqrt(b * b - x * x);
    }else{
        return b + sqrt((1.0-b)*(1.0-b)-(x-1.0)*(x-1.0));
    }
}

/*
Default z*z+c, scaled a bit for 16/9
*/
float mb(in vec2 ri, in float time){
    float r = (ri.x-0.5)*4.5-0.5;
    float i = (ri.y-0.5)*3.0;
    float zr = 0.0;
    float zi = 0.0;
    float max = time;
    for(float k=0.0;k<max;k++){
        float t = zr*zr - zi*zi + r;
        zi = 2.0*zr*zi + i;
        zr = t;
        if(zr*zr+zi*zi > 4.0){
            return k/max;
        }
    }
    return 1.0;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    // Coloring
    float t2 = trafoDCircSeat(uv.x, 0.5)*0.5 + 0.5*trafoDCircSeat(uv.y,0.5);
    vec3 col = pal(t2, vec3(0.5),vec3(0.25),vec3(0.5),vec3(0.2,0.5,0.7),3.0,time);
    float u = 0.1+mod(time*0.25,0.9);
    u = u*u*200.0;
    if(u > 100.0){
        u = 200.0-u;
    }
    col = col*0.3 + col*vec3(mb(uv,u));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
