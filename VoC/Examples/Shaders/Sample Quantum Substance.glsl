#version 420

// original https://www.shadertoy.com/view/ssSfWw

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Heavy performance impact 
#define AA 2
#define raymarchSteps 100
//#define vanillaMarch
#define rotationSpeed 7.
#define ZERO min(frames, 0)

const float pi = 3.14159265359;

float sdBox( in vec3 p, in vec3 b )
{
    vec3 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

mat3 rotx(float a) { mat3 rot; rot[0] = vec3(1.0, 0.0, 0.0); rot[1] = vec3(0.0, cos(a), -sin(a)); rot[2] = vec3(0.0, sin(a), cos(a)); return rot; }
mat3 roty(float a) { mat3 rot; rot[0] = vec3(cos(a), 0.0, sin(a)); rot[1] = vec3(0.0, 1.0, 0.0); rot[2] = vec3(-sin(a), 0.0, cos(a)); return rot; }
mat3 rotz(float a) { mat3 rot; rot[0] = vec3(cos(a), -sin(a), 0.0); rot[1] = vec3(sin(a), cos(a), 0.0); rot[2] = vec3(0.0, 0.0, 1.0); return rot; }

vec4 map(vec3 p) {
    for(int i =0;i<2;i++){
    const float s = .6;
    p *=roty(s*sin(time*0.5)*p.y)*rotz(s*p.z*cos(time*2.1))*rotx(s*p.x*-cos(time));
    p.x += cos(time*2.141)*0.15*abs(p.y);
    p.y += sin(time*1.123123)*0.15*abs(p.z);
    p.z += -cos(time*3.123123)*0.15*abs(p.x);

    }
    float d =  sdBox(p, vec3(1.));//sdSkeleton(p, time);
    
    return vec4(d-0.3, p);
}
#ifndef vanillaMarch 
vec3 intersection(vec3 ro, vec3 rd){
    
    //Boring variables
    float zslice = -.158;//cos(stime);
    vec3 pos = ro;
    vec2 mouseUV = (mouse*resolution.xy.xy-resolution.xy*.5f)/resolution.x * 5.;
    float T = 0.;
    
    //Colour 
    float h = map(pos).x;
    
    
    //The interesting part
    float omega = 1.;
    float pom = 1.;
    float ph = 1e5;
    vec2 gap = vec2(0.,0.);
    for (int i = 0; i<raymarchSteps; ++i) {
    
        //Position and distance estimation
        vec3 p = ro+T*rd;
        h = map(p).x*0.5;
        
        if (h > 20.)
            break;
        
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
//https://www.shadertoy.com/view/wlVGRV
vec3 intersection(vec3 ro, vec3 rd){
    for(int i=0;i < raymarchSteps;i++){
        float dist = map(ro).x*1.;
        ro += rd*dist;
        if(dist <0.01)
            break;
    }
    return ro;
}
#endif

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
    const float h = 1.1;
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

vec3 sky(vec3 rd){
    return vec3(sin(time+rd+vec3(0,2,4)));
}

vec4 render(vec3 ro, vec3 rd){
    
    //world info
     vec3 pos = intersection(ro,rd);
     vec4 sce = map(pos);
    float dis = sce.x;
     vec3 trp = sce.yzw;
    float tpd = distance(trp,pos);
    
    //Shading
     vec3 sun = vec3(0., 1., 0);
    float sha = softshadow(pos, sun, 0.1, 5., 5.)*0.5+0.5;
     vec3 nor = calcNormal(pos);
    float occ = calcAO(pos, nor);
    float lig = (dot(sun,nor)*0.5+0.5);

    //Colors
     vec3 col = vec3(0);
     vec3 bcl = vec3(smoothstep(-2., 1., tpd));
     vec3 scl = sky(nor);
     vec3 amb = vec3(0.9, 0.9, 1.);
    
    //
     //vec3 txs = texture(iChannel0, rd).xyz;
     //vec3 txr = texture(iChannel0, reflect(nor, rd)).xyz;
    
    if (dis < 2.1) {
        //Bones
        //Sun
        col += .75*lig*sha*scl*bcl*(dot(sun,nor)*0.5+0.5);
        //Ambient
        col += 0.6*amb*pow(occ, 0.5);
        //Reflect
        col += 0.7*bcl*sha*sha*sky(reflect(rd,nor))*occ;
    } else
        col = sky(rd);
    return vec4(col, 0.1);
}
void main(void) {

    vec3   ro = vec3(0, 0, -5.5);
    mat3 yrot = roty(mouse.x*resolution.xy.x/resolution.x*rotationSpeed);
    mat3 xrot = rotx(-mouse.y*resolution.xy.y/resolution.y*rotationSpeed);
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

    tot = smoothstep(-.1,1.4,tot);
    
    // Output to screen
    glFragColor = tot;
}
