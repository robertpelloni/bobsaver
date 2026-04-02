#version 420

// original https://www.shadertoy.com/view/wdccRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// inspired by evvvil's ray marching videos on twitch <3

#define bpm (121./60.)
#define FOV .55
#define ITER 128
#define PI  (atan(1.0) * 4.0)
#define TAU (atan(1.0) * 8.0)
#define tt mod(time,100.)
#define st clamp(cos(tt),0.,1.) 

float t;
vec2 sc;
vec3 np, no, al, po, ld, ro;

float ssub( float d1, float d2, float k ) 
{
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); 
}

float smin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5*(b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h*(1.0 - h);
}

// rotation function
mat2 r2 (float a) { return mat2(cos(a), sin(a), -sin(a), cos(a)); }

//sphere
float sp(vec3 p, float r) { return length(p)-r; }

//diamond
float di (vec3 p, float s) 
{
    float lx = length(p.x);
    float ly = length(p.y);
    float lz = length(p.z);
    return sqrt(lx+ly+lz)-s;   
}

// octahedron
float oh ( vec3 p, float s)
{
  p = abs(p);
  return (p.x+p.y+p.z-s)*0.57735027;
}

// the thing
vec2 bs (vec3 p)
{   
    np=p;
    for(int i=0;i<5;i++) { // let'S clone and rotate stuff
        np=abs(np)-vec3(2.,2.5,1.5);
        np.xy *= r2(1.3+cos(tt*.5));
        np.y -= 1.6*.5+sin(tt*.5);
        np.xz *=r2(tt*.25);     
    }
    //vec2 h,t=vec2(oh(np,2.3),10.); // octahedron iq
    vec2 h,t=vec2(di(np,1.5),10.); // octahedron
    h=vec2(sp(np,1.45),5.); // mix with blue sphere
    t=(t.x<h.x)?t:h;
    return t;
}

// noise function stolen from evvvil
float noise(vec3 p)
{
  vec3 ip=floor(p),s=vec3(7.,157.,113.);
  p-=ip;
  vec4 h=vec4(0,s.yz,s.y+s.z)+dot(ip,s);
  p=p*p*(3.-2.*p);
  h=mix(fract(sin(h)*43758.5),fract(sin(h+s.x)*43758.5),p.x);
  h.xy=mix(h.xz,h.yw,p.y);
  return mix(h.x,h.y,p.z);
}

// lighting
float li (vec3 n, vec3 l)
{
  return max(0., dot(n, l));
}

// Camera
 vec3 cam (vec3 ro, vec2 uv, float fov)
{
    vec3 cw=normalize(vec3(0.)-ro),
        cu=normalize(cross(cw, vec3(0.,1.,0.))),
        cv=normalize(cross(cu,cw));
    return mat3(cu,cv,cw)*normalize(vec3(uv,FOV));
} 

// the scene
vec2 mp (vec3 p) 
{   
    p.xy*=r2((p.z-ro.z)*st*0.1);
    vec2 h,t=bs(p);
    t.x=max(t.x,-0.5*(length(p-ro)-2.)); // stopping our camera from colliding with things
    t.x*=0.7; // reduce artifacts
    return t;
}

// main raymarching function
vec2 tr (vec3 ro, vec3 rd) 
{
    vec2 h,t=vec2(0.1);
    for(int i=0;i<ITER;i++){
        h=mp(ro+rd*t.x);
        if(h.x<.0001||t.x>30.) break;
        t.x+=h.x;t.y=h.y;
    }
    if (t.x>30.) t.x=0.;
    return t;
}

// get Normals (iq)
vec3 calcNormal( in vec3 po )
{   
    vec2 e=vec2(.00035,-.00035);
    return normalize(e.xyy*mp(po+e.xyy).x+
        e.yyx*mp(po+e.yyx).x+
        e.yxy*mp(po+e.yxy).x+
        e.xxx*mp(po+e.xxx).x); 
}

// AO
#define a(d) clamp(mp(po+no*d).x/d,0.,1.) 
// SSS
#define s(d) smoothstep(0.,1.,mp(po+ld*d).x/d)

void main(void)
{
    vec2 uv = vec2(gl_FragCoord.xy / resolution.xy);
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);
    
    
      
    // ray_origin / camera
    ro = vec3(0.,3.+sin(tt),17.+cos(tt*.5)); //ray origin
    
    vec3 rd=cam(ro,uv,FOV),
    co,fo,ld=normalize(vec3(0.,0.,10.));
    co=fo=vec3(0.55,0.22,0.05)-rd.y*.4;
      
    sc=tr(ro,rd); // sc.x = distance geometry, sc.y = colour
    t=sc.x; // t is the result of the geometry
    
    if (t>0.) 
    {   
        po=ro+rd*t;
        vec3 no=calcNormal(po),
        al=mix(vec3(0.,0.10,0.45),vec3(0.1,0.30,0.55),.5); // albedo
     
        // Material colouring
        if(sc.y<5.) al=vec3(0.);
        if(sc.y>5.) al=vec3(1.);
        if(sc.y>9.) al=vec3(0.8, 0.3, 0.01);
        
        float dif=li(no,ld), // diffuse
        fr=pow(1.+dot(no,rd),4.), // fresnel
        sp=pow(max(dot(reflect(-ld,no),-rd),0.),55.); // specular by shane.
        co=mix(sp+al*(a(.1)*a(.3)+.2)*(vec3(1.)*dif+s(.5)*1.5),fo,min(fr,.5)); // final lights
        co=mix(co,vec3(0.12,0.03,0.01),1.-exp(-0.00020*t*t*t)); // add fog
        
        // Subtle vignette by Shane
        uv = gl_FragCoord.xy/resolution.xy;
        co = mix(vec3(0.),co,pow(16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y),.125)*.5 +.5);
          
        glFragColor = vec4(pow(co,vec3(0.45)),1.); // add gamma correction
    }
}
