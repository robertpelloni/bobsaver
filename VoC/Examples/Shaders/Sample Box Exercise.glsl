#version 420

// original https://www.shadertoy.com/view/7djyDD

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define VIEW 1.

#define ADD(d,a) min(d,a);

#define PI acos(-1.)
#define FAR 50.
#define S(a) smoothstep(0.,0.05,a)

#define  load0(p) texture(iChannel0,p/resolution.xy).rgb
#define  load1(p) texture(iChannel1,p/resolution.xy).rgb
#define  load2(p) texture(iChannel2,p/resolution.xy).rgb

#define  load0_uv(p) texture(iChannel0,p).rgb
#define  load1_uv(p) texture(iChannel1,p).rgb
#define  load2_uv(p) texture(iChannel2,p).rgb

mat2 rot(float a){
    float s = sin(a), c = cos(a);
    return mat2(c,-s,s,c);
}

float sdBox(vec3 pos, vec3 dim){
    vec3 aPos = abs(pos) - dim;
    float d = min(max(aPos.x, max(aPos.y,aPos.z) ),0.) + 
          length(max(aPos,0.)) - 0.02;
    return d;
}

vec3 lr(vec3 sp, float shift, float t){
    sp.y += shift; sp.yz*=rot(t); sp.y -= shift;
    return sp;//-tn(sp.xy*0.02).yyx;
}

float map(vec3 p){

    vec3 boxDim = vec3(0.7,0.7,0.005);
    float time = time*-2.5;
    float t = smoothstep(PI*0.5, -PI*0.5, 
              PI*0.5-mod(time ,PI))*-PI+PI*0.5;
    p.z += boxDim.x*2.*smoothstep(0.,1.,(mod(time ,PI)/PI));
    
    float alle = sdBox(p, boxDim );

    vec3 sp = lr(p, boxDim.y, -t);
    alle = ADD(alle,sdBox(sp-vec3(0.,-boxDim.y*2.05,0.),boxDim));
    
    sp = lr(p, -boxDim.y, t);
    alle = ADD(alle,sdBox(sp-vec3(0.,boxDim.y*2.05,0.), boxDim ));
    
    sp.yxz = lr(p.yxz, -boxDim.x, t);
    alle = ADD(alle,sdBox(sp-vec3(boxDim.x*2.05,0.,0.), boxDim ));
    
    sp.yxz = lr(p.yxz, boxDim.x, -t);
    alle = ADD(alle,sdBox(sp-vec3(-boxDim.x*2.05,0.,0.), boxDim ));
    
    sp.yxz = lr(sp.yxz, boxDim.x*3.05, PI-t);
    alle = ADD(alle,sdBox(sp-vec3(-boxDim.x*1.99,0.,0.), boxDim ));
    
    
    alle = ADD(alle,length(p-vec3(0.,0.,boxDim.x+pow((t+PI*0.5)/PI,4.)))
    -0.4+0.4*pow((t+PI*0.5)/PI,4.));
    
    alle = ADD(alle,length(p+vec3(0.,0.,boxDim.x+1.-pow((t+PI*0.5)/PI,4.)))
    -0.4*pow((t+PI*0.5)/PI,2.));
    
    
    return alle;
}

float trace(vec3 ro, vec3 rd){
    float t = 0., d;
    for (int i = 0; i < 96; i++){
        d = map(ro + rd*t);
        if(abs(d)<.001 || t>FAR) break;        
        t += d*.5;
    }
    return t;
}

vec3 getNormal(in vec3 p)
{
    vec3 n = vec3(0.0);
    for( int i=min(frames,0); i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(p+0.001*e);
    }
    return normalize(n);
}

vec3 getCameraDirection(vec2 uv, vec3 ro, vec3 ta){

    vec3 fwd = normalize(ta-ro);
    vec3 uu = vec3(0.,1.,0.);
    vec3 ri = normalize(cross(uu,fwd));
    vec3 up = normalize(cross(fwd,ri));
    return normalize(uv.x*ri + uv.y*up + fwd*1.2);
}

void main(void) {

    vec2 uv = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.y;
    vec3 col = vec3(0.9), ta = vec3(0.,0.,0.), ro = vec3(0.2,-7.,3.5);
    vec3 lp = ro + vec3(0., 0., 1.);
    
    //if(mouse*resolution.xy.z > 0.5){
    //    vec2 m = mouse*resolution.xy.xy/resolution.xy;
    //    ro.yz *= rot(-m.y*PI+1.); ro.xz *= rot(-m.x*PI*2.);
    //}

    vec3 rd = getCameraDirection(uv,ro,ta);
    float t = trace(ro, rd);
    
    if(t < FAR){
        vec3 pos = ro + rd*t; 
        float diff = max(dot(getNormal(pos), normalize(lp-pos)), 0.);
        col = vec3(.4,0.6,0.9)*diff;
    }

    //vignette
    uv = gl_FragCoord.xy/resolution.xy;
    uv *=  1.0 - uv.yx;
    float vig = uv.x*uv.y * 15.0;
    vig = pow(vig, 0.15); 
    
    glFragColor = vec4(col*vig,1.);
}
