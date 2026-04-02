#version 420

// original https://www.shadertoy.com/view/fssXzj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MDIST 120.0
#define STEPS 164.0
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define sat(a) clamp(a,0.0,1.0)
#define pi 3.141592
vec3 col3 (vec3 col,float index){
    if(index==1.0)col.rg=1.0-col.rg;
    if(index==2.0)col.gb=1.0-col.gb;
    return col;
}
//I'm so happy about this function, I will use it forever now (it remaps time without %&*$ing everything)
float timeRemap2 (float t, float s1, float s2, float c){
    return 0.5*((s1-s2)*sqrt(c*c+1.0)*asin((c*cos(pi*t))/ sqrt(c*c+1.0))+(s1+s2)*c*t*pi)/(c*pi);
}
float SU( float d1, float d2, float k ) {
    float h = sat( 0.5 + 0.5*(d2-d1)/k);    
    return mix( d2, d1, h ) - k*h*(1.0-h);   
} 
float box( vec3 p, vec3 b ){
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) -0.3;
}
vec3 glw = vec3(0);
float map2(vec3 p){
    float a = length(p-vec3(0,sin(time)*4.0,0))-1.5;
    glw +=(0.01/(0.01+a*a))*vec3(0.867,0.000,0.259);
    float b = box(p,vec3(0.6,20.5,0.5));
    a = min(a,b);
    return a;
}
float map(vec3 p){
    vec3 np = p;
    float t = mod(time+7.2,200.0);
    float anim = smoothstep(-.2,.2,sin(t*0.5));
    
    
    float s1 = 8.5;
    float s2 = 1.0;
    t = timeRemap2(t/(2.0*pi),s1,s2,10.0);//amazing
    
    np.xy*=rot(mod(t,2.0*pi+pi)*anim*0.2);
    
    float modd = 55.0+anim*400.0;//Banish the extra versions when it expands
    
    //vec2 id = abs(floor((p.xz+modd/2.0)/modd));
    
    np.xz = mod(np.xz+0.5*modd,modd)-0.5*modd;
    np = abs(np)-vec3(0,0,anim*30.0);
    np.x = abs(np.x)-(20.0*anim);
    
    np*=1.0-anim*0.3;
    
    t = floor(t)+pow(fract(t),2.0-anim*1.0);
    for(int i = 0; i< 5; i++){
        np = abs(np)-vec3(1.5+4.5*anim);
        np.xy*=rot(0.3+t*0.7*1.1);
        np.zy*=rot(0.5+t*0.7*1.1);
    }
    
    float a = map2(np);
    float b = p.y+3.0;
    a = SU(a,b,1.0);
    
    b = length(p-vec3(0,-4.5+anim*10.0,0))-9.0;
    glw +=0.01/(0.01+b*b)*vec3(0.035,0.690,0.000);
    
    a = SU(a,b,1.0);
    float cir = 35.0;
    t=0.5*time;
    
    vec3 ro = vec3(cir*sin(t),4.0+sin(t),cir*cos(t));
    float camHole = length(p-ro)-3.5;
    a = max(-camHole,a);
    
    return a;
}

vec3 norm(vec3 p) {
    vec2 off=vec2(0.01,0);
    return normalize(map(p)-vec3(map(p-off.xyy),map(p-off.yxy),map(p-off.yyx)));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0);
    float t = time*0.5;
    float cir = 35.0;
    vec3 ro = vec3(cir*sin(t),4.0+sin(t),cir*cos(t));
    vec3 ro2 = ro;
    vec3 look = vec3(0,0,0); float z = 1.0;
    vec3 f = normalize(look-ro);
    vec3 r = normalize(cross(vec3(0,1,0),f));
    vec3 rd = f*z+uv.x*r+uv.y*cross(f,r);
        
    float dO = 0.0;
    float shad = 1.0;
    float bnc = 0.0;
    float dist = 0.0;
    float dO2;
    for(float i = 0.0; i<STEPS; i++){
    
        vec3 p = ro + rd * dO;
        
        float d = map(p)*0.9;

        dO += d;
        dO2 +=d;
        if(dO2>MDIST || d < 0.01) {
            shad = float(i)/(STEPS);
            if(bnc == 0.0)dist=dO;
            if(bnc == 1.0)break;
            
            ro += rd*dO;
            vec3 sn = norm(ro);
    
            rd = reflect(rd,sn);
            ro +=  sn*0.1;
            dO = 0.0;
            i=0.0;
            bnc++;
            
        }
    }
    
    col = vec3(shad)*mix(vec3(0.082,0.941,0.902),vec3(0.557,0.067,1.000),sin(dO*0.01))*4.0;
    
    col = mix(col,vec3(0.067,0.000,0.910),sat(dist/MDIST)*sat(dist/MDIST));
    col+=glw*0.13*(1.0-sat(dist/(MDIST)));
    col=pow(col,vec3(0.7));
    float index = floor(mod(t*0.7,3.0));
    //col = col3(col,index); //Uncomment for color swaps
    //col.rb*=rot(sin(t*0.25+pi)*0.5+0.4); //actually this one is better :)
    glFragColor = vec4(col,1.0);
}
