#version 420

// original https://www.shadertoy.com/view/NtlBWj

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA 3.
#define segments 15.0
#define PI 3.14159
#define ZERO min(frames,0)
#define boxScale .9
vec3 erot(vec3 p, vec3 ax, float ro) {
    return mix(dot(p,ax)*ax,p,cos(ro))+sin(ro)*cross(ax,p);
}

float opRepLim( in float p, in float c, in float l)
{
    return p-c*clamp(round(p/c),-l,l);
}

vec2 rot(vec2 p,float a){
    float c = cos(a);
    float s = sin(a);
    return p*mat2(s,c,-c,s);
}
float sdRingBox( vec3 p, vec3 b)
{
    p*=1.4;
  float angper = (2.*3.142)/segments;
  vec2 origin = vec2(0.0,.7);
  float angle = time+atan(p.y,p.x)*2.;
  vec3 pivotSpot = normalize(vec3(p.x,p.y,0.))*origin.y;
  
  
  float r = length(p.xy)-origin.y;
  
  vec2 twistCoords = vec2(r,p.z);
  vec2 new = rot(twistCoords,(time+angle)/(2.));
  r = new.x; p.z = new.y;
  p.z = opRepLim(p.z,.13*((1.1+.6*max(0.0,sin(time)))*boxScale),1.);
  r = opRepLim(r,.11*((1.1+.6*max(0.0,cos(PI/2.+time)))*boxScale),1.);
  
  //because angle is -x,x, ends up being 2x wide, so we divide by 2.
  angle = mod(angle+angper,angper)-angper/2.;
  p.xy = vec2(angle,r);
  b.x/=boxScale;
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0)-.01;
}

float map(vec3 p){
    return sdRingBox(p,boxScale*vec3((2.0*3.142/segments)-.22,0.05,.06));
}

vec3 getNormal(vec3 p){
    vec2 e = vec2(0.001,0.0);
    return normalize(vec3(map(p+e.xyy), map(p+e.yxy),map(p+e.yyx)));
}

float calcAO( in vec3 pos, in vec3 nor, in float time )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=ZERO; i<5; i++ )
    {
        float h = 0.01 + 0.12*float(i)/4.0;
        float d = map( pos+h*nor );
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );
}

vec3 rm(vec3 ro, vec3 rd){
    vec3 p;
    float t, d, r;
    for(int i =0; i<1000; i++){
        p = ro+t*rd;
        d = map(p);
        if(d>10.)
            break;
        if(d<0.0001){
            t+=d;
            p=ro+t*rd;
            vec3 n =  getNormal(p);
            float fre = clamp(1.0+dot(n,rd),0.0,1.0);
            float AO =calcAO(p,n,time);
            return (1.0-pow(fre,2.))*AO*(.5+.5*abs(n.y)*vec3(0.4,0.8,0.9));
        }
        t+=d*.6;
    }
    float ratio = pow(abs(rd.y/rd.z),3.);
    return mix(vec3(.0,.0,.0),vec3(.7,.2,.68),ratio);

}

void main(void)
{
    vec3 col = vec3(0.,0.,0.);
    for(float m = 0.;m<AA;m++){
        for(float n = 0.;n<AA;n++){
        vec2 uv = (gl_FragCoord.xy+(vec2(m,n)/AA)-(resolution.xy*.5))/resolution.x;
        vec3 ro = vec3(cos(time),0.,sin(time))*20.;
        ro = vec3(0.,0.,-1.0);
        vec3 cf = -normalize(ro);
        vec3 cs = normalize(cross(cf,vec3(0.,1.,0.)));
        vec3 cu = normalize(cross(cf, cs));

        vec3 uuv = cf+(uv.x*cs + uv.y*cu)*5.5;

        vec3 rd = normalize(uuv-ro);
        col += rm(ro,rd);
        }
     }
     col/=AA*AA;
        // Output to screen
        col = pow(col, vec3(1.0/2.2));
        glFragColor = vec4(col,1.0);
}
