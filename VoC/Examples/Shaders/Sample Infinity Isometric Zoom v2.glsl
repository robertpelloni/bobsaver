#version 420

// original https://www.shadertoy.com/view/sdsyW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: bitless
// Title: Infinity isometric zoom v.2

// Thanks to Patricio Gonzalez Vivo & Jen Lowe for "The Book of Shaders"
// and Fabrice Neyret (FabriceNeyret2) for https://shadertoyunofficial.wordpress.com/
// and Inigo Quilez (iq) for  http://www.iquilezles.org/www/index.htm
// and whole Shadertoy community for inspiration.

#define D 5.  //cycle duration
#define  CLR vec4(.0,.005,.05,1)   //back color
#define rot(a)   mat2(cos(a + vec4(0,11,33,0)))                             //rotate 2d
#define p(t, a, b, c, d) ( a + b*cos( 6.28318*(c*t+d) ) )                   //iq's palette
#define K 1.7320508 //sqr(3)
#define B(x, a, b) ( x >= a && x <= b) //boolean: check x between a and b  

float h21(vec2 p)  //hash21
{
    return fract(sin(dot(p.xy,vec2(12.9898,78.233)))*43758.5453123);
}

float noise( in vec2 f ) //gradient noise
{
    vec2 i = floor( f );
    f -= i;
    
    vec2 u = f*f*(3.-2.*f);

    return mix( mix( h21( i + vec2(0,0) ), 
                     h21( i + vec2(1,0) ), u.x),
                mix( h21( i + vec2(0,1) ), 
                     h21( i + vec2(1,1) ), u.x), u.y);
}

//  Minimal Hexagonal Grid - Shane
//  https://www.shadertoy.com/view/Xljczw
vec4 getHex(vec2 p) //hex grid coords 
{
    vec2 s = vec2(1, K);
    vec4 hC = floor(vec4(p, p - vec2(.5, 1))/s.xyxy) + .5;
    vec4 h = vec4(p - hC.xy*s, p - (hC.zw + .5)*s);
    return dot(h.xy, h.xy)<dot(h.zw, h.zw) ? vec4(h.xy, hC.xy) : vec4(h.zw, hC.zw + .5);
}

vec3 HexToSqr (vec2 st, inout vec3 n) //hexagonal cell coords to square face coords + face normal 
{ 
    vec3 r;
    if (st.y > -abs(st.x)*1./K)
        if (st.x > 0.) 
            {r = vec3((vec2(st.x,(st.y+st.x/K)*K/2.)*2.),2); n = vec3(1,0,0);} //right face
        else
            {r = vec3(-(vec2(st.x,-(st.y-st.x/K)*K/2.)*2.),3); n = vec3(0,1,0);} //left face
    else 
        {r = vec3 (-(vec2(st.x+st.y*K,-st.x+st.y*K)),1); n = vec3(0,0,1);} //top face
    return r;
}

vec3 L; //light vector
float N, I, F, R, CN, CH; //cycle number, layer number, transition phase, random factor, num of cells, num of cubes  

vec4 Pal (float t) //return color from palette
{
    return vec4(p(t,vec3(.5),vec3(.5),vec3(1.),vec3(.0,.2,.4)),1);
}

vec4 Face(vec4 C, vec2 uv, vec3 nr, float h, float g) //draw face of cube
{
    float m =  dot (nr,L); //face lighting
    vec2 id = uv*((g==0.)?5.:(floor(h*3.)+3.)) //cell id
        ,l = fract(id); //local cell coord
    id -= l;
    l -= .5;
    nr.z += h21(id+R+h+g) + noise(l*100.)*.2; //cell normal deviation + gradient noise
    nr.xy += l*.25*rot(F*12.56+nr.z*2.); //rotate cell normal for "glass effect"
    return mix (C*dot(nr,L)*m, vec4(0), smoothstep (-.5,.5,max(l.x,l.y))*.6); //mix face color + face lighting + cell lighting + inner edge 
}

void Voxel (vec2 uv, vec2 lc, vec2 sh, inout vec4 C, bool m) //cubes on floor
{
    uv += sh*vec2(-1,1./K/2.) ;
    vec2 id = floor(vec2((uv.x+uv.y*K),(uv.x-uv.y*K))); //isometric grid cell's id

    float   h = h21(id+R) //random factor for cube 
            ,sz = 1. + fract(h*10.)*.75 //voxel size variation
            ,sm = 3./resolution.y; //smoothing factor
      
    vec3 nr  //face normal
        ,vx = HexToSqr(lc-vec2(sh.x,(sh.y-1./sz)/K/2.),nr);  //voxel face coords, face id and face normal
  
    nr.xy = nr.yx;
    vx.xy *= sz;
    
    vec4 V = Pal(fract(h*5.)); //color of a cube

    V = mix (Face(V, vx.xy, nr, h, vx.z), CLR, smoothstep(1.,4.,I-F)); //decrease color variation of small cubes for noise reducing 
    
    C = mix (C, vec4(V.rgb,1) , smoothstep(1.+sm,1.-sm,max(vx.x,vx.y))
                * float(m                                           //cell mask
                        && B(id.x, 0., CN-1.) && B(id.y, -CN, -1.)     //cube on floor of celll
                        && (id.x - id.y) > CN-CH
                        && (fract(h*100.) > .4))                    //cube visibility random factor
    ); 
}
 

void main(void)
{
	vec2 g = gl_FragCoord.xy;
	vec4 O = gl_FragColor;

    vec2 r = resolution.xy
        ,u = (g+g-r)/-r.y/2.
        ,lc;
    
    L = normalize(vec3(abs(sin(time*.5))*.8+.5,abs(cos(time*.5))*.8+.5,sin(time*1.3)*1.+2.)); //light vector direction

    float  T = mod(time,D);
    
    N = floor(time/D);            //cycle number
    F = T/D;                       //cycle duration 0..1
    
    R = h21(vec2(0,1)+N-1.);        //random factor for current layer
    float   Rn = h21(vec2(0,1)+N),    //random factor for second layer
            CNn = floor(Rn*5.)+4.,  //num of cells for second layer 4..8
            CHn = floor(fract(Rn*10.)*(CNn-3.)),  //num of cubes for next layer 0..4
            f = smoothstep(0.,1.,F), //cycle duration 0..1 (for smoother transition)
            a = 1.,  //alpha mask of curent layer 
            an,  //alpha mask of previuos layer
            n;
            
    CN = floor(R*5.)+4.;//num of cells for first layer 4..8
    CH = floor(fract(R*10.)*(CN-3.));//num of cubes for first layer 0..4
    f =  f*(log2(f+1.));

    u /= exp (log(CNn)*F); //zoom during transition 
    u.y -= ((CN-CH-4.) + (CNn-CHn-4.)*f/(1.+(CNn-1.)*f))/K;  //move camera to next cell during transition
    
    O -= O;

    vec3 s,nr;
    vec4 C = vec4(0), h, CL;

    vec2[4] sh = vec2[4] (vec2(0,0),vec2(.5,1),vec2(-.5,1),vec2(0,2)); //coordinate offsets for voxel neighbors 
    
    for (I=0.; I < 6. && (a>0.); I++)  //draw 5 layers of cubes
    {
        O = mix(O, Face(O, s.xy, nr, R, 0.),an); //draw previous layer cell sides   
        
        h = getHex(u+vec2(0,(CN-CH-2.)/K));  //hexagonal grid of curent layer
        
        s = HexToSqr(h.xy, nr);  //cell sides coordinates
        an = a * float( B (h.w, abs(h.z), (CN-CH)/2.-1.)); //cell mask
        
        CL = mix (Pal(h21(h.zw+R)), CLR, smoothstep(1.,3.5,I-F));  //cell sides color + decrease color variation of small cubes for noise reducing 
        O = mix (O, CL, an);
    
        lc = floor(vec2((u.x+u.y*K),(u.x-u.y*K))); //cell id
        f = mod(lc.x+lc.y+1.,2.);  //even and odd cells
        lc = fract(vec2((1.-f)*.5-u.x,u.y*K-f*.5)) - .5;  //local cell corrdinates
        lc.y /= K;
        
        for (int j = 0 ; j<4 ; j++) Voxel (u, lc, sh[j], C, (a>0.) && h.w > ((CN-CH)/2.-2.)); //draw cube and his neighbors
        
        O = mix (O, C, C.a); //mix cell with cubes on floor
    
        u.y += (CN-CH-1.)/K; //shift for next layer
        h = getHex(u); //hexagonal grid of next layer
        a *= float B(h.w, abs(h.z), ((CN-CH)/2.-.5)) * (1.-C.a);  //check visibility for next layer
        
        R = h21(h.zw+N+I); //random factor for a next layer
        CN = floor(R*5.)+4.; //num of cells  for a next layer
        CH = floor(fract(R*10.)*(CN-3.)); //num of cubes for a next layer

        u = h.xy*CN;
    }
    
    glFragColor = pow(O ,vec4(1./1.8)); //gamma correction
}
