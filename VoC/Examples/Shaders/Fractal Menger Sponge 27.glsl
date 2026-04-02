#version 420

// original https://www.shadertoy.com/view/sdSBWc

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Heavy performance impact 
#define AA 2
#define raymarchSteps 100
//
#define ZERO min(frames, 0)

const float pi = 3.14159265359;

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
float sdSphere(vec3 p, float r){
    return length(p) -r;
}

mat2 rotate(float a){
    float s = sin(a);
    float c = cos(a);
    return mat2(c, s,
                -s, c);
}
vec3 trans(vec3 p, float s){
        //Mirror
        p = abs(p)-1.*s;
        p *= -1.;
        //Reflect column
        p.xy = ((p.x - p.y > 0.) ? p.yx : p.xy);  
        p.zy = ((p.z - p.y > 0.) ? p.yz : p.zy);  

        //construct column
        p.y = (abs(p.y-0.5*s)-0.5*s);
        
        return p;
}

// I don't know why but putting the calls to trans in a loop caused some weid behavioirs
vec4 map(vec3 p) {

    const float scale = 150.;

    p*= scale;
    p = trans(p, 27.*27.);
    p = trans(p, 27.*9.);
    p = trans(p, 27.*3.);
    p = trans(p, 27.);
    p = trans(p, 9.);
    p = trans(p, 3.);
    p = trans(p, 1.);

    return vec4(sdBox(p, vec3(.5))/scale - 0.1*smoothstep(.5,1.,sin(time)), p);
}

float softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k )
{
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

vec3 calcNormal( in vec3 p )
{
    const float h = 0.0001;
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(p+e*h).x;
    }
    return normalize(n);
}
float calcAO(vec3 pos, vec3 nor)
{
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

vec3 intersection(vec3 ro, vec3 rd){
    float dist;
    for (int i = 0; i < raymarchSteps; i++){
        dist = map(ro).x;
        ro += dist*rd;
        if (dist < 0.01)
            break;
    }
    
    return ro;

}

vec4 render(vec3 ro, vec3 rd){
    vec3 p = intersection(ro,rd);
    vec3 t = map(p).yzw;
    
    //Shading
     vec3 sun = vec3(0., .6, .9);
    float sha = softshadow(p, sun, .1, .3, 5.)*0.5+0.5;
     vec3 nor = calcNormal(p);
    float occ = calcAO(p, nor);
    float lig = (dot(sun,nor)*0.5+0.5);

    //Colors
    vec3 col = vec3(0.);
    vec3 bcl = vec3(0.7);
    vec3 scl = vec3(0.9, 0.9 ,.8);
    vec3 amb = vec3(0.9, 0.9, 1.);
    //
    if (map(p).x < 0.1) {
        col += 0.75*lig*scl*bcl;
        col += 0.6*amb*occ*occ;
    } else
        col = vec3((rd.y+.5)*.5+0.2);
    return vec4(col, 1);
}
void main(void)
{
    vec3   ro = vec3(0, 0, -12.5);
    
    mat2 rotx = rotate(-0.5);
    mat2 roty = rotate(time *0.3);
    
    ro.yz *= rotx;
    ro.xz *= roty;

    vec4 tot = vec4(0);
    
    //Super sampling
    for(int m=0;m<AA;m++){
    for(int n=0;n<AA;n++){
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 u = ((gl_FragCoord.xy+o) / resolution.xy - 0.5) / vec2(resolution.y / resolution.x, 1);
        vec3 rd = normalize(vec3(u, 1));
        rd.yz *= rotx;
        rd.xz *= roty;
        tot += render(ro, rd) / float(AA*AA);
    }}

    
    tot = smoothstep(-0.1,1.2, tot);
    // Output to screen
    glFragColor = tot;
}
