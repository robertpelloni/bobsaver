#version 420

// original https://www.shadertoy.com/view/XdVczy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

Clothoid IFS fractal.

Author: Joseph Eagar
*/

#define PI 3.14159265453

#define IFSSTEPS 10 //fractal levels

#define STEPS 4 //base clothoid integration steps
#define ISTEPS 10 //steps for distance-to-clothoid solver

#define df 0.001 //for finding numerical derivatives

float tent(float f) {
    return 1.0 - abs(fract(f)-0.5)*2.0;
}

float ctent(float f) {
    return cos(f*PI*2.0)*0.5 + 0.5;
}

vec2 tent(vec2 v) {
    return vec2(
        tent(v.x),
        tent(v.y)
    );
}

vec2 ctent(vec2 v) {
    return vec2(
        ctent(v.x),
        ctent(v.y)
    );
}

vec2 rot2d(vec2 v, float a) {
    return vec2(
      v[1]*sin(a) + v[0]*cos(a),
      -v[0]*sin(a) + v[1]*cos(a)
    );
}

vec2 f(float s1) {
    float s = 0.0, ds = s1/float(STEPS);
    float ds2=ds*ds, ds3=ds2*ds;
    vec2 ret = vec2(0, 0);
    float t = 1.0, t2 = 1.0;
    
    for (int i=0; i<STEPS; i++) {
        float th = s*s*t;
        float sinth=sin(th), costh = cos(th);
        //float sinth=tent(th/3.14159/2.0-0.25)*2.0-1.0, costh = tent(th/3.14159/2.0)*2.0-1.0;
        float th2=th*th;
        
        /*
        //2nd-order taylor approximation
        ret[0] += sinth + costh*s*t*ds;
        ret[1] += costh - sinth*s*t*ds;
        //*/
        
        //4rd-order taylor approximation
        //*
        ret[0] += sinth + costh*s*t*ds + 
             0.1666666*(t2*(costh - 2.0*sinth*th))*ds2 -
             0.0416666*4.0*(2.0*costh*th + 3.0*sinth)*s*t*t*ds3;
        ret[1] += costh - sinth*s*t*ds -
            2.0*t*(0.1666666)*(2.0*costh*th + sinth)*ds2 - 
            0.0416666*4.0*(3.0*costh-2.0*sinth*th)*s*t*t*ds3;
        //*/
        
        s += ds;
    }
    
    return ret*ds;
}

vec2 dv(float s) {
    return (f(s+df) - f(s-df)) / (2.0*df);
}

//error function for point to clothoid distance solver
float err(float s, vec2 uv) {
    vec2 v = (f(s) - uv);
    
    return dot(v, v);
}

float atan2(float y, float x) {
    float th = atan(y / x);
    
    if (x > 0.0)
        return atan(y / x);
    if (x < 0.0 && y >= 0.0)
        return atan(y / x) + PI;
    if (x < 0.0 && y < 0.0)
        return atan(y / x) - PI;
       if (x == 0.0 && y > 0.0)
        return PI*0.5;
    if (x == 0.0 && y < 0.0)
        return -PI*0.5;
    return 0.0;
}

//finds distance of point uv to clothoid
float clothoid(vec2 uv) {
    float s;
    float d = 1.0;
    
    for (int i=0; i<ISTEPS; i++) {
        float e1 = err(s, uv);
        float e2 = err(s+df, uv);
        
        float de = (e2 - e1) / df;
        
        //just do simple gradient descent
        float fac = -e1/de;
        
        s += -de*0.3;
        
        //enforce parameter-space boundsZ
        s = min(max(s, 0.0), 2.25);
    }
    
    
    d = length(f(s) - uv);
    return pow(d, 1.0);
}

vec3 sample1(vec2 uv) {
    float mx = 0.5; //mouse*resolution.xy.x / resolution.x;
    float my = 0.5; //0.6 + 0.2*mouse*resolution.xy.y / resolution.y;
    
    float th = -0.6 + mx + cos(time)*0.1;
    float thscale = 1.035 + (cos(time*1.2)*0.5+0.5)*0.3;
    float f1, f2;    

    int i;

    vec2 lastp;
    
    float s = 1.25 + my*2.0;
    
    float dscale = 2.0;
     
    f2 = 1.0;
    
  
    float trap = 0.0;
    float tottrap = 0.0;
    float trap2 = 0.0;
    float minfac = 1.0;
    vec2 startuv = uv;
    vec2 uv2=uv, lastuv=uv;

    //uv = abs(uv);
    for (i=0; i<IFSSTEPS; i++) {
        /*mirror about x axis
        if (uv[1] < 0.0) {
            uv = -uv;
            startuv = -startuv;
        }
        */

        uv2=uv;
         
        //so-called trap for coloring
        vec2 trapuv = tent(uv);

        float trapval = length(trapuv - uv)*(1.0-f2)*1.5;
        float trapval2 = length(trapuv - lastuv)*(1.0-f2);
        float trapw = pow(1.0 - float(i)/float(IFSSTEPS), 2.0);
        
        lastuv = uv2;
        
        trap += trapval*trapw;
        trap2 += trapval2*trapw;
        tottrap += trapw;
        
        //get distance to clothoid
        f1 = clothoid(uv2);
        
        if (f1 < f2) {
            f2 = f1;
            
            //shade lower levels less
            float fac = 1.0 -(float(i+1) / float(IFSSTEPS+1));
            minfac = pow(1.0-f1, 50.0)*fac;
        }
         
        //rotate to be tangent with curve at f(s)
        vec2 p = f(s);
        vec2 dp = f(s+df);
        
        //set up derivative
        dp = (dp - p) / df;
        dp.xy = dp.yx;
        dp.x = -dp.x;
        
        //rotate
        uv2 -= p;
        uv2 = rot2d(uv2, atan(dp.y / dp.x)+PI*0.5);
        lastp = p;
        
        //translate in y a bit
        float yadd = my;
        uv2.y += yadd;
        uv2 = abs(uv2);
        uv2.y -= yadd;
        
        //now do an arbitrary rotation
        uv2 = rot2d(uv2, th);
        th *= thscale;
        uv2 = uv2*dscale;// - (dscale - 1.0);
        
        //bailout condition
        if (dot(uv2, uv2) > 15.0) {
            break;
        }
        
        uv = uv2;
    }
    
    f2 = 1.0 - f2;
    f2 *= minfac*0.4+0.8;
    
    //normalize traps
    trap /= tottrap;
    trap2 /= tottrap;
    
    //multiple traps with base fractal
    trap *= f2;
    trap2 *= f2;
    
    vec3 trapclr = vec3(trap*0.9, trap2, trap*0.2);
    vec3 clr = vec3(f2, f2, f2);
    
    //blend base fractal with traps
    clr = clr*(trapclr*0.5+0.5)*0.5 + trapclr*1.3;

    return clr;
}

void main(void)
{
    float size = max(resolution.x, resolution.y);
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float x=0.0, y=0.0;
    
    uv[0] *= resolution.x / resolution.y;
    uv -= 0.5;
    
    uv *= 2.0;
    
    uv[0] -= 0.0;
    uv[1] += 0.8;
    
    vec3 clr = sample1(uv);
    
    glFragColor = vec4(clr, 1.0);
}
