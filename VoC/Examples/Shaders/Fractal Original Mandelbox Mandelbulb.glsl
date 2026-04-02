#version 420

// original https://www.shadertoy.com/view/tslfWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 lightdir = normalize(vec3(-1., 1, -0.5));

const float detail = .00002;
float det = 0.;

float de2(vec3 p) {
    vec3 op = p;
    p = abs(1.0 - mod(p, 2.));
    float r = 0., power = 8., dr = 1.;
    vec3 z = p;
    
    for (int i = 0; i < 7; i++) {
        op = -1.0 + 2.0 * fract(0.5 * op + 0.5);
        float r2 = dot(op, op);
        r = length(z);

        if (r > 1.616) break;
        float theta = acos(z.z / r);
        float phi = atan(z.y, z.x);

        dr = pow(r, power - 1.) * power * dr + 1.;
        float zr = pow(r, power);
        theta = theta * power;
        phi = phi * power;
        z = zr * vec3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta));
        z += p;
    }
    return (.5 * log(r) * r / dr);
}

float de1(vec3 p) {
    float s = 1.;
    float d = 0.;
    vec3 r,q;
        r = p;
      q = r;
    
    for (int j = 0; j < 6; j++) {
       
        r = abs(mod(q * s + 1.5, 2.) - 1.);    
        r = max(r, r.yzx);
        //r = max(r = abs(mod(q * s + 1., 2.) - 1.), r.yzx);
        
        d = max(d, (.3 - length(r *0.985) * .3) / s);
        
    s *= 2.1;
    }
    return d;
}

float map(vec3 p) {
    return min(de1(p), de2(p));;
}

vec3 normal( in vec3 p) {
    //vec2 e = vec2(0.005, -0.005);
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize(e.xyy * map(p + e.xyy) + e.yyx * map(p + e.yyx) + e.yxy * map(p + e.yxy) + e.xxx * map(p + e.xxx));
}

float shadow( in vec3 ro, in vec3 rd){
    float res = .0;
        float t = 0.05;
    float h;    
        for (int i = 0; i < 4; i++)
    {
        h = map( ro + rd*t );
        res = min(6.0*h / t, res);
        t += h;
    }
    return max(res, 0.0);
}

float calcAO(const vec3 pos,const vec3 nor) {
    float aodet = detail * 80.;
    float totao = 0.0;
    float sca = 10.0;
    
    for (int aoi = 0; aoi < 5; aoi++) {
        float hr = aodet + aodet * float(aoi * aoi);
        vec3 aopos = nor * hr + pos;
        float dd = map(aopos);
        totao += -(dd - hr) * sca;
        sca *= 0.75;
    }
    //return clamp(1.0 - 5.0 * totao, 0.0, 1.0);
    return clamp(1.0 - 4.0 * totao, 0.0, 1.0);
}

float kset(vec3 p) {
        p = abs(.5 - fract(p * 80.));
    float es, l = es = 0.;
    for (int i = 0; i < 13; i++) {
        float pl = l;
        l = length(p);
        p = abs(p) / dot(p, p) - .5;
        es += exp(-1. / abs(l - pl));
    }
    return es;
}

vec3 light( in vec3 p, in vec3 dir) {

    vec3 n = normal(p);
    float sh = min(5., shadow(p, lightdir));

    float ao = calcAO(p, n);

    float diff = max(0., dot(lightdir, -n)) * sh * 1.3;
    float amb = max(0.2, dot(dir, -n)) * .4;
    vec3 r = reflect(lightdir, n);
    float spec = pow(max(0., dot(dir, -r)) * sh, 10.) * (.5 + ao * .5);
    float k = kset(p) * .18;
    vec3 col = mix(vec3(k * 1.1, k * k * 1.3, k * k * k), vec3(k), .45) * 2.;
    col = col * ao * (amb * vec3(.9, .85, 1.) + diff * vec3(1., .9, .9)) + spec * vec3(1, .9, .5) * .7;
    return col;
}

vec3 raymarch( in vec3 from, in vec3 dir) {
    vec3 color, pos;
    float t = 0.;
    float td = 0.;
    float d = 0.;
    for (int i = 0; i < 128; i++) {
        pos = from + t * dir;
        float precis = 0.001 * t;
        d = map(from + dir * t);
    det=detail*(1.+t*55.);
   
        if (d < 0.0002) break;
            t += d;
    }
    vec3 backg = vec3(.4,0.5,0.8);
    //vec3 backg = vec3(.5);

    color = light(pos - det * dir * 1.5, dir);
    color *= vec3(1., .75, .8) * .9;
    color = mix(color, backg, 1.0 - exp(-1.3 * pow(t, 1.3)));

    return color;
}

vec3 camPath(float time) {
    vec2 p = 600.0 * vec2(cos(1.4 + 0.37 * time),cos(3.2 + 0.31 * time));
    return vec3(p.x, 0.0, p.y);
}

float hash(vec2 p)
{
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 33758.5453)-.5;
} 

vec3 postprocess(vec3 rgb, vec2 xy)
{
    rgb = pow(rgb, vec3(0.67));
    
    //#define CONTRAST 1.4
    #define CONTRAST 1.6
    
    #define SATURATION 1.4
    #define BRIGHTNESS 1.2
    
    
    rgb = mix(vec3(.5), mix(vec3(dot(vec3(.2125, .7154, .0721), rgb*BRIGHTNESS)), rgb*BRIGHTNESS, SATURATION), CONTRAST);
    //rgb = clamp(rgb+hash(xy*time)*.1, 0.0, 1.0);
    return rgb;
}

void main(void) {

    vec2 uv = (gl_FragCoord.xy / resolution.xy) - .5;
    float t = time * 0.5;
    vec2 s = uv * vec2(1.75, 1.0);

    vec3 campos = camPath(t * 0.001);
    vec3 camtar = camPath(t + 2.0);
    //float roll = 15.0*sin(t*.5+.4);
    
    float roll = 0.4 * cos(0.4 * t);
    vec3 cw = normalize(camtar - campos);
    vec3 cp = vec3(sin(roll), cos(roll), 0.0);
    vec3 cu = normalize(cross(cw, cp));
    vec3 cv = normalize(cross(cu, cw));
    vec3 rd = normalize(s.x * cu + s.y * cv + .6 * cw);

    vec3 col = raymarch(campos, rd);
    col = postprocess(col,s);
    glFragColor  = vec4(col, 0.0);

}
