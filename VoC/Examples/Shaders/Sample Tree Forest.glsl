#version 420

// original https://www.shadertoy.com/view/wscGWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//-----------------CONSTANTS MACROS-----------------

#define PI 3.14159265359
#define E 2.7182818284
#define GR 1.61803398875
#define MAX_DIM (max(resolution.x,resolution.y))
#define FAR (20.)

//-----------------UTILITY MACROS-----------------

#define time ((sin(float(__LINE__))/PI/GR+1.0)*time/PI)
#define sphereN(uv) (clamp(1.0-length(uv*2.0-1.0), 0.0, 1.0))
#define clip(x) (smoothstep(0.0, 1.0, x))
#define TIMES_DETAILED (1.0)
#define angle(uv) (atan(uv.y, uv.x))
#define angle_percent(uv) ((angle(uv)/PI+1.0)/2.0)
#define hash(p) (fract(sin(vec2( dot(p,vec2(127.5,313.7)),dot(p,vec2(239.5,185.3))))*43458.3453))

#define flux(x) (vec3(cos(x),cos(4.0*PI/3.0+x),cos(2.0*PI/3.0+x))*.5+.5)
#define rormal(x) (normalize(sin(vec3(time, time/GR, time*GR)+seedling)*.25+.5))
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

float scale = 3.;
float seed;
vec3 mcol;
float dfScene(in vec3 z0){
    vec4 z=vec4(z0,1.0);
    float d = 1E32;
    
    float height =1.;
    float width = .05;
    const int iterations = 4;
    float loop = float(1.)/float(iterations);
    float dB=sdCapsule(z0.xyz, vec3(0.,width,0.), vec3(0.,-height*2.,0.),width); 
    
    if(dB < d)
    {
        d = dB;
        mcol = vec3(loop/GR+(1.-loop)/E, loop, 0.);
    }
    
    dB = z0.y+height*2.;
    
    if(dB < d)
    {
        d = dB;
        float grass = pow(cos(z0.x*2.*PI/scale)*cos(z0.z*2.*PI/scale)*.5+.5, 4.);
        mcol = vec3(loop/GR+(1.-loop)/E, loop+grass/PI/GR, 0.);
    }
    
    
    for(int i=0;i<5;i++){
        z.xz=Kaleido(z.xz,float(i+2)*(1.+floor(saw(seed*float(i+1))*4.)));
        z.yz=Rotate(z.yz,(saw(time*PI+seed)*.5-.5));
        
        float dcap = sdCapsule(z.xyz+vec3(0., 0., .5), vec3(0.,0.,.5), vec3(0.,.5,0.),width);
        dB = dcap/z.w;
        if(dB < d)
        {
            d=dB;
            loop = float(i+1)/float(iterations);
            mcol = vec3(loop/GR+(1.-loop)/GR, loop, 0.);
        }
        z.z+=.5;
        z.y -= .5;
        z*=vec4(2.0,2.0,2.0,2.0);
    }
    //dB=(length(z.xyz)-1.0)/z.w;
    return d;
    return d;
}

vec3 surfaceNormal(vec3 p) { 
    vec2 e = vec2(5.0 / resolution.y, 0);
    float d1 = dfScene(p + e.xyy), d2 = dfScene(p - e.xyy);
    float d3 = dfScene(p + e.yxy), d4 = dfScene(p - e.yxy);
    float d5 = dfScene(p + e.yyx), d6 = dfScene(p - e.yyx);
    float d = dfScene(p) * 2.0;    
    return normalize(vec3(d1 - d2, d3 - d4, d5 - d6));
}

//main march
vec3 marchScene(vec3 ro, vec3 rd) {
    
    vec3 pc = vec3(0.0); //returned pixel colour
    float d = 0.0; //distance marched
    vec3 rp = vec3(0.0); //ray position
    vec3 lp = normalize(vec3(5.0, 8.0, -3.0)); //light position
       float ns;
    vec3 p;
    for (int i = 0; i <32; i++) {
        rp = ro + rd * d;
        p = rp;
        seed = floor((rp.x)/scale)*1.2345+floor((rp.z)/scale)*5.4321;
        p.xz = (fract((rp.xz)/scale)-.5)*scale;
        ns = dfScene(p);
        d += ns;
        if(d > FAR)
        {
            break;
        }
        
    }
    vec3 sky_color = vec3(.35, .35, .85);
    float fog = smoothstep(.75, .9, d/FAR);
    

    vec3 n = surfaceNormal(p);
    vec3 sc = mcol; //surface colour

    float diff = max(dot(n, lp), 0.0); //diffuse
    pc = sc * 0.5 + diff * sc ;
    float spe = pow(max(dot(reflect(rd, n), lp), 0.), 16.); //specular.
    pc = (pc + spe * vec3(1.0))*(1.-fog)+fog*sky_color;
    
    return pc;
}

void main(void) {
    
    
    //coordinate system
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    //camera
    vec3 rd = normalize(vec3(uv, 2.));
    vec3 ro = vec3(0.0, -.5, -PI)*2.;
    
    float movement = time;
    
    ro += vec3((sin(movement*PI))*scale, 0., (movement+.5)*scale);
    //rotate camera
    rd.yz *= rot(.25+sin(movement/GR)*.1); 
    rd.xz *= rot(cos(movement*PI) * 0.5);
    //*/
    
    
    glFragColor = vec4(marchScene(ro, rd), 1.0);    
}
