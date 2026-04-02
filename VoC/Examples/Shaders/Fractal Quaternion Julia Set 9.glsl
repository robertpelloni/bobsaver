#version 420

// original https://www.shadertoy.com/view/wtVyDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ITER 10
#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST 0.00001
#define SPEED 5.

// 3d mandelbulb
float mandel4(in vec3 v, in vec4 c, out vec3 map){
    //float t = sin(time)*.5+.5;
    vec4 mv = vec4(v, 0.);
    
    vec4 r = mv;
    vec4 rNext = r;
    float m = dot(mv, mv);
    vec4 trap = vec4(abs(r));
    
    int i = 0;
    float d = 1.;
    
    float n =  2.;
    
    for(i=0; i<ITER; i++){
        float cr = length(r);
        float nr = pow(cr, n);
        
        d = pow(cr, n-1.) *n * d + 1.0;
        
        rNext.x = pow(r.x, n) - pow(r.y, n) - pow(r.z, n) - pow(r.w, n);
        rNext.y = n*r.x*r.y;
        rNext.z = n*r.x*r.z;
        rNext.w = n*r.x*r.w;
        r = c + rNext;
        
        trap = min(trap, vec4(abs(r)));
        map = vec3(trap.xyz);

        m = dot(r,r);
        
        if(m > 3.5){
            break;
        }
    }
    //return pow(length(r), 2.)+sqrt(m);
    return  .35*log(m) * sqrt(length(m))/d;
}

mat2 Rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

vec3 R(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = p+f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i-p);
    return d; 
}

float RayMarch(in vec3 ro, in vec3 rd, in vec4 c, out vec3 col){
    float dO = 0.;
    
    for(int i=0; i<MAX_STEPS; i++){
        vec3 p = ro+rd*dO;
        //p.xz *= Rot(time/SPEED);
        //p.yz *= Rot(time/SPEED-2.);
        float mbd = mandel4( p, c, col);
        float dS = mbd;
        
        if(dO > MAX_DIST || dS<SURF_DIST) break;
        dO += dS;
    }
    
    return dO;
}
vec3 GetNormal(in vec3 p, in vec4 c){
     vec3 col;
    // my e value made black artifacts
    // so I took a look at iq's normal epsilone. 
    // don't exactly know how this is calculated.
    // looks like it is relevant to some screen pixel size calculation..?
    vec2 e = vec2(1.0,-1.0)*0.5773*0.25*2.0/(resolution.y*1.5);
    
    // getting vector with very small vector
    vec3 n = vec3(
        e.xyy*mandel4(p+e.xyy, c, col)+
        e.yxy*mandel4(p+e.yxy, c, col)+
        e.yyx*mandel4(p+e.yyx, c, col)+
        e.xxx*mandel4(p+e.xxx, c, col ) 
    );
    
    return normalize(n);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/(resolution.y);
    vec2 m = mouse*resolution.xy.xy/resolution.xy;
    vec3 col = vec3(0);
    
    vec3 ro = vec3(0, 1.5, 1.5);
    ro.xz *= Rot(time/5.);
    ro.y = 2.*sin(time/3.);
    vec3 rd = R(uv, ro, vec3(0,.0,0), .7);
    
    vec3 backgrounduv;
    //2.*(sin(time)*.5 +.5)
    //1.5*(sin(time)*.5+.5)
    float time = time*.45;
    vec4 c = 0.45*cos( vec4(0.5,3.9,1.4,1.1) + time*vec4(1.2,1.7,1.3,2.5) ) - vec4(0.3,0.0,0.0,0.0);
    col = vec3(.05, .13, .1);
    float d = RayMarch(ro, rd, c, backgrounduv);
    col += vec3(.6-d*.3);
    //col += .5;
    col += pow(clamp(3. - backgrounduv.y, 0.0, .99), 9.)*vec3(.5, .3, .4);
    //col *= 10.;
    col *= (col+.9)*(col+.6);
    
    //light
    vec3 lp = vec3(0, 3.5, 4.5);
    lp.xz *= Rot(time/3.);
    //lp.yz *= Rot(time/3.);
    vec3 lr = ro+rd*d;
    //lr.xz *= Rot(time/SPEED);
    //lr.yz *= Rot(time/SPEED-2.);
    lr = lr;
    vec3 l = normalize(lp - lr);
    vec3 n = GetNormal(lr, c);
    vec3 shadow = clamp(dot(n, l), 0.1, 1.)*vec3(0., .8, 1.)*.7;
    shadow *= 1.;
    //col *= vec3(pow(shadow, 1.))*vec3(.3, .6, 1.);
    
    
    vec3 lp2 = vec3(3., 0., 4.5);
    lp2.xz *= Rot(time);
    lp2.yz *= Rot(time/3.);
    vec3 lr2 = ro+rd*d;
    //lr2.xz *= Rot(time/SPEED);
    //lr2.yz *= Rot(time/SPEED-2.);
    lr2 = lr2;
    vec3 l2 = normalize(lp2 - lr2);
    vec3 n2 = GetNormal(lr2, c);
    vec3 shadow2 = clamp(dot(n2, l2), 0.1, 1.)*vec3(1., .2, 0.4)*.7;
    shadow2 *= 1.;
    col *= (shadow+shadow2);
    //col += vec3(.09, .04, .09);
    
    glFragColor = vec4(col, 0);
}
