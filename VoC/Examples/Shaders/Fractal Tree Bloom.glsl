#version 420

// original https://www.shadertoy.com/view/wsdGWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//-----------------CONSTANTS MACROS-----------------

#define PI 3.14159265359
#define E 2.7182818284
#define GR 1.61803398875
#define MAX_DIM (max(resolution.x,resolution.y))
#define FAR (PI*GR*E*5.)

//-----------------UTILITY MACROS-----------------

#define time2 ((sin(float(__LINE__))/PI/GR+1.0)*time/PI/GR/E)
#define sphereN(uv) (clamp(1.0-length(uv*2.0-1.0), 0.0, 1.0))
#define clip(x) (smoothstep(0.0, 1.0, x))
#define time2S_DETAILED (1.0)
#define angle(uv) (atan(uv.y, uv.x))
#define angle_percent(uv) ((angle(uv)/PI+1.0)/2.0)
#define hash(p) (fract(sin(vec2( dot(p,vec2(127.5,313.7)),dot(p,vec2(239.5,185.3))))*43458.3453))

#define flux(x) (vec3(cos(x),cos(4.0*PI/3.0+x),cos(2.0*PI/3.0+x))*.5+.5)
#define rormal(x) (normalize(sin(vec3(time2, time2/GR, time2*GR)+seedling)*.25+.5))
#define rotatePoint(p,n,theta) (p*cos(theta)+cross(n,p)*sin(theta)+n*dot(p,n) *(1.0-cos(theta)))
#define circle(x) (vec2(cos((x)*PI), sin((x)*PI)))
#define saw(x) fract( sign( 1.- mod( abs(x), 2.) ) * abs(x) )

#define TAO 6.283
vec2 Rotate(in vec2 v, float angle) {return v*mat2(cos(angle),sin(angle),-sin(angle),cos(angle));}
vec2 Kaleido(in vec2 v,float power){return Rotate(v,floor(.5+atan(v.x,-v.y)*power/TAO)*TAO/power);}
float HTorus(in vec3 z, float radius1, float radius2){return max(-z.y-0.055,length(vec2(length(z.xy)-radius1,z.z))-radius2-z.x*0.035);}

mat2 rot(float x) {
    return mat2(cos(x), sin(x), -sin(x), cos(x));
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}
vec3 mcol;
float dB;
float dfScene(in vec3 z0){
    vec4 z=vec4(z0,1.0);
    float d=max(abs(z.y+1.0)-1.0,length(z.xz)-0.13);
    for(int i=0;i<5;i++){
        z.xz=Kaleido(z.xz,float(i+2)*2.);
        z.yz=Rotate(z.yz,(saw(time2*PI)-1.));
        
        float dcap = sdCapsule(z.xyz+vec3(0., 0., 1.), vec3(0.,0.,1.), vec3(0.,2.0,0.),0.1);
        dB += dcap/z.w/10.;
        d=min(d,dcap/z.w);
        z.z+=1.0;
        z.y -= 2.;
        z*=vec4(2.0,2.0,2.0,2.0);
    }
    //dB=(length(z.xyz)-1.0)/z.w;
    return d;
}

vec3 surfaceNormal(vec3 p, vec3 rd) { 
    vec2 e = vec2(5.0 / resolution.y, 0);
    float d1 = dfScene(p + e.xyy), d2 = dfScene(p - e.xyy);
    float d3 = dfScene(p + e.yxy), d4 = dfScene(p - e.yxy);
    float d5 = dfScene(p + e.yyx), d6 = dfScene(p - e.yyx);
    float d = dfScene(p) * 2.0;    
    return normalize(vec3(d1 - d2, d3 - d4, d5 - d6));
}

//IQ
float calcAO(vec3 pos, vec3 nor, vec3 rd) {   
    float occ = 0.0;
    float sca = 1.0;
    for(int i = 0; i < 5; i++) {
        float hr = 0.01 + 0.05*float(i);
        vec3 aopos = pos + nor*hr;
        occ += smoothstep(0.0, 0.7, hr - dfScene(aopos)) * sca;
        sca *= 0.97;
    }
    return clamp(1.0 - 3.0 * occ , 0.0, 1.0);
}

//main march
vec3 marchScene(vec3 ro, vec3 rd) {
    
    vec3 pc = vec3(0.0); //returned pixel colour
    float d = 0.0; //distance marched
    vec3 rp = vec3(0.0); //ray position
    vec3 lp = normalize(vec3(5.0, 8.0, -3.0)); //light position
   
    for (int i = 0; i < 64; i++) {
        rp = ro + rd * d;
        float ns = dfScene(rp);
        d += ns;
        if (ns < 1.0/MAX_DIM || d > FAR) break;
    }
    
    if (d < FAR) {

        vec3 sc = flux(dB+time2); //surface colour
        vec3 n = surfaceNormal(rp, rd);
        float ao = calcAO(rp, n, rd);
        
        float diff = max(dot(n, lp), 0.0); //diffuse
        pc = sc * 0.5 + diff * sc * ao;
        float spe = pow(max(dot(reflect(rd, n), lp), 0.), 16.); //specular.
        pc = sc;//pc + spe * vec3(1.0);
    }
    
    return pc;
}

void main(void) {
    
    
    //coordinate system
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    //camera
    vec3 rd = normalize(vec3(uv, 2.));
    vec3 ro = vec3(0.0, 1./GR, -PI)*2.;
    
    //rotate camera
    ro.yz *= rot(sin(time2) * 0.25);
    rd.yz *= rot(sin(time2) * 0.25); 
    ro.xz *= rot(time2 * 0.5);
    rd.xz *= rot(time2 * 0.5);
    //*/
    
    
    glFragColor = vec4(marchScene(ro, rd), 1.0);    
}
