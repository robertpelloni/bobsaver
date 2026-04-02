#version 420

// original https://www.shadertoy.com/view/7d2BWm

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Heavy performance impact 
#define AA 2
#define raymarchSteps 40
#define vanillaMarch
#define rotationSpeed 7.
#define ZERO min(frames, 0)
#define post
#define vignet

const float pi = 3.14159265359;
mat3 rotx(float a) { mat3 rot; rot[0] = vec3(1.0, 0.0, 0.0); rot[1] = vec3(0.0, cos(a), -sin(a)); rot[2] = vec3(0.0, sin(a), cos(a)); return rot; }
mat3 roty(float a) { mat3 rot; rot[0] = vec3(cos(a), 0.0, sin(a)); rot[1] = vec3(0.0, 1.0, 0.0); rot[2] = vec3(-sin(a), 0.0, cos(a)); return rot; }
mat3 rotz(float a) { mat3 rot; rot[0] = vec3(cos(a), -sin(a), 0.0); rot[1] = vec3(sin(a), cos(a), 0.0); rot[2] = vec3(0.0, 0.0, 1.0); return rot; }

// Base primitive
float sdBox( vec3 p, vec3 b )
{
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

//The main part
vec4 map(vec3 p) {
    mat3 rot = rotx(sin (2. * time*0.1)*pi + sin(pi * time*0.1)*pi)*rotz(cos(time/4.)*pi)*roty(sin(time/4.+12313.123)*pi);
    int maxI = 8;
    float scale = 1.;
    const float factor = 2.;
    const float baseSize = .7;
    float d = 10e10;
    for (int i=ZERO;i<maxI;i++){ 
        p = abs(p)-.4*factor;
        p *= factor;
        scale /= factor;
        p *= rot;

    }
            d = min(d,
             sdBox(p-vec3(0,.44*factor,0), (vec3(baseSize)))*scale-(0.4*scale)
             );
    return vec4(d,p);
}
#ifndef vanillaMarch 
//https://www.shadertoy.com/view/wlVGRV
vec3 intersection(vec3 ro, vec3 rd){
    
    //Boring variables
    vec3 pos = ro;
    float T = 0.; 
    float h = map(pos).x;

    float omega = 1.;
    float pom = 1.;
    float ph = 1e5;
    vec2 gap = vec2(0.,0.);
    for (int i = 0; i<raymarchSteps; ++i) {
    
        //Position and distance estimation
        vec3 p = ro+T*rd;
        h = map(p).x;
        
        
        //Overstep recovery
        float om = (ph+h)/ph;
        if (om<pom && pom > 1.) { //ph+h<ph*pom
            
            gap = vec2(h,T);
            T+=(1.-pom)*ph;
            pom = 1.;
            
        } else {
            
            //Variable updates
            T += h * omega;
            ph = h;
            pom = omega;
            
            //Back to the place where the gap opened (foward)
            if (T>=gap.y-gap.x && gap.y+gap.x > T) {T = gap.y+gap.x*omega; ph = gap.x;};
        }
        
          
        //Dynamic Omega 
        //omega = clamp((omega+om)*.5,1.,3.);
        omega = clamp(omega+(om-omega)*.6,1.,3.);
    }
    return ro+T*rd;;
}
#else
vec3 intersection(vec3 ro, vec3 rd){
    for(int i=0;i < raymarchSteps;i++){
        float dist = map(ro).x;
        ro += rd*dist;
        if(dist <0.01 || dist > 4.)
            break;
    }
    return ro;
}
#endif
//iq ---
float softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k ){
    float res = 1.0;
    for( float t=mint; t<maxt; )
    {
        float h = map(ro + rd*t).x;
        if( h<0.001 )
            return 0.0;
        res = min( res, k*h/t );
        t += h;
    }
    return res;
}
vec3 calcNormal( in vec3 p ){
    const float h = 0.0001;
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(p+e*h).x;
    }
    return normalize(n);
}
float calcAO(vec3 pos, vec3 nor){
    float occ = 0.0;
    float sca = .4;
    for( int i=ZERO; i<5; i++ )
    {
            float h = 0.01 + 0.25*float(i)/4.0;
        float d = map( pos+h*nor).x;
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );
}
// ---
vec4 render(vec3 ro, vec3 rd){
    //world info
    vec3 pos = intersection(ro,rd);
    vec4 d_t = map(pos);
    vec3 trp = d_t.yzw;
   float dis = d_t.x;
   float trd = distance(pos, trp);
    //Shading
     vec3 sun = vec3(1., 1., 1.1);
    float sha = softshadow(pos, sun, 0.1, 5., 1.)*0.5+0.5;
     vec3 nor = calcNormal(pos);
    float occ = calcAO(pos, nor);
    float lig = (dot(sun,nor)*0.5+0.5);

    //Colors
    vec3 col = vec3(0);
    vec3 bcl = vec3(log(trd),0.5,cos(trd));
    vec3 scl = vec3(1., 0.8 ,.7);
    vec3 amb = vec3(0.7, 0.9, 1.);
    //
    if (dis < 0.1) {
        //Bones
        col += 0.75*lig*sha*scl*bcl;
        col += 0.6*amb*occ;
    } else
        col = vec3(.7-0.5*abs(rd.y))*scl;
    return vec4(col, 1);
}
void main(void) {

    vec3   ro = vec3(0, 0, -5.5);
    mat3 yrot = roty(time*0.2);
    mat3 xrot = rotx(.9);
           ro*=xrot*yrot;

    vec4 tot = vec4(0);
    
    //Super sampling
    for(int m=0;m<AA;m++){
    for(int n=0;n<AA;n++){
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 u = ((gl_FragCoord.xy+o) / resolution.xy - 0.5) / vec2(resolution.y / resolution.x, 1);
        vec3 rd = normalize(vec3(u, 1));
        tot += render(ro, rd*xrot*yrot) / float(AA*AA);
    }}

    
    #ifdef vignet
    vec2 uv = gl_FragCoord.xy/resolution.xy-0.5;
    tot *= smoothstep(1.34, 0., length(uv));
    #endif
    
    // Output to screen
    #ifdef post
    glFragColor = smoothstep(0.,1.3,tot);
    #else
    glFragColor = tot;
    #endif
}
