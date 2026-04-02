#version 420

// original https://www.shadertoy.com/view/tsXyRH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define FAR 20.
#define M(x,y) mod(x,y) - y/2.

//If you want to make it worse, you need to make AA more than 2.
#define GetsEvenWorse false
#define AA 1

#define OnlyEye false

float pi = acos(-1.);
float pi2 = acos(-1.) * 2.;

float t,depth;

vec3 cp = vec3(10.,5.,-11.);

vec2 rot(vec2 p,float a){return vec2(mat2( cos(a),sin(a),-sin(a),cos(a))*p );}

vec3 RotMat(vec3 p,vec3 axis, float angle)
{
    // http://www.neilmendoza.com/glsl-rotation-about-an-arbitrary-axis/
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return p * mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s, 
                    oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s, 
                    oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c          );
}

vec2 random2(vec2 st){return -1.0 + 2.0*fract(sin( vec2( dot(st,vec2(127.1,311.7)),dot(st,vec2(269.5,183.3)) ))*43758.5453123);}

float noise(vec2 st) 
{
    vec2 p = floor(st);
    vec2 f = fract(st);
    vec2 u = f*f*(3.0-2.0*f);
    vec2 v00 = random2(p+vec2(0,0));
    vec2 v10 = random2(p+vec2(1,0));
    vec2 v01 = random2(p+vec2(0,1));
    vec2 v11 = random2(p+vec2(1,1));
    return mix( mix( dot( vec2(v00), f - vec2(0,0) ), dot( vec2(v10), f - vec2(1,0) ), u.x ),
                 mix( dot( vec2(v01), f - vec2(0,1) ), dot( vec2(v11), f - vec2(1,1) ), u.x ), 
                 u.y)+0.5;
}

// https://gam0022.net/blog/2019/06/25/unity-raymarching/
float deMengerSponge2(vec3 p, vec3 offset, float scale) {
    vec4 z = vec4(p, 1.0);
    for (int i = 0; i < 3; i++) {
        z = abs(z);
        if (z.x < z.y) z.xy = z.yx;
        if (z.x < z.z) z.xz = z.zx;
        //if (z.y < z.z) z.yz = z.zy;
        z *= scale;
        z.xyz -= offset * (scale - 1.0);
        if (z.z < -0.5 * offset.z * (scale - 1.0))
            z.z += offset.z * (scale - 1.0);
    }
    return (length(max(abs(z.xyz) - vec3(1.0, 1.0, 1.0), 0.0))) / z.w;
}

vec2 pmod(vec2 p, float r)
{
    float a = atan(p.x, p.y) + pi / r;
    float n = pi2 / r;
    a = floor(a / n) * n;
    return rot(p,-a);
}

vec2 Polar(vec2 i)
{
    vec2 pl = vec2(0.);
    pl.y = sqrt(i.x*i.x+i.y*i.y)*2.+1.;
    pl.x = atan(i.y,i.x)/acos(-1.);
    return pl;
}

vec3 eyemove(vec3 p)
{
    float tt = time;
    
    p = RotMat(p,vec3(0.3,0.2,0.6),noise(vec2(tt))/4.);
    p = RotMat(p,vec3(0.1,0.7,0.9),noise(vec2(tt/2.))/4.);
    p= RotMat(p,vec3(0.,1.,0.),pow(clamp(cos(tt/2.),-.2,.2)*3.,3.));
    p= RotMat(p,vec3(1.,0.,0.),pow(clamp(sin(tt/3.5),-.3,.3)*1.,3.));
    p = RotMat(p,vec3(1.,1.,0.),pow(clamp(sin(tt/1.5),-.17,.17)*4.,3.));
    return p;
}

vec2 map(vec3 p)
{
    vec2 d = vec2(0.);
    vec3 ee = p;
    p -= vec3(0.,1.7,7.5);
    vec3 pp = p;
    float w = length(ee) - 2.;
    float w2 = length(ee) - 2.5;
    float camera = length((ee - cp)/vec3(1.,1.,5.)) - 10.5;
    ee = eyemove(ee);
    ee += vec3(0.,0.,.67) ;
    float soul = min(w,length(ee) - 1.5);
    pp.xz = rot(pp.xz,t /17.);
    
    p = mod(p,18.)-9.;
    for(int i = 0 ; i< 3; i++)
    {
        p.xz = abs(p.xz) - 1.6;
        p.xy = rot(p.xy, 3. );
        p.yz = rot(p.yz,5.);
        p.zx = rot(p.zx,-1.);
        
        p.yx = abs(p.yx) - .9;
        p.zy = rot(p.zy, -7. );
        p.xz = rot(p.xz,5.);
        p.xz = rot(p.xz,-1.);
    }
    p.xz = rot(p.xz,length(pp.xy) * 1.16 );
    float menger = deMengerSponge2(p, vec3(1.), 3.);
    menger = max(menger,-w2);
    menger = max(menger,-camera);
    if(OnlyEye)
    {
        d = vec2(soul,2.);;
    }else{
        
        vec2 s = vec2(soul,2.);
        vec2 m = vec2(menger * .3,1.);
        d = (m.x < s.x)?m:s;
    }
    //d = m;
    return d;
}
vec2 march(vec3 p,vec3 rd)
{
    depth = 0.;
    vec2 d = vec2(.0);
    for(int i = 0; i <55; i++)
    {
        d = map(p + rd * depth);
        if(abs(d.x) < 0.001 || d.x > FAR){break;}
        depth += d.x;
    }
    if(d.x > FAR){d.x = -1.;}
    return d;
}

vec3 eyecolor(vec3 p)
{
    p = eyemove(p);
    vec3 w = vec3(.8,0.8,.8);
    vec3 b = vec3(0.);
    vec2 P = Polar(p.xy);
    vec3 i = vec3(1.,1.,0.) * sin(P.y*2. - 3.5);
    
    b += i;
    b *= vec3(1.,1.,1.) * noise(p.xy * 9.) * .5 +.5;
    vec3 o = mix(w,b,step( length(p.xy),1.15) * step( p.z,.1));
    return o;
}

vec3 mengcolor(vec3 p)
{
    vec3 b = vec3(0.,.5,1.);
    b += mix(vec3(0.,0.,0.),b,step(sin(Polar(p.xy).y + p.z + t),0.));
    return b;
}

 float B(float nh, float roughness)
{
    nh *= nh;
    roughness *= roughness;
    return exp((nh - 1.) / (roughness * nh))/ (pi * roughness * nh * nh);
}

float C(float nl, float nv, float nh, float vh)
{
    return min(1. ,min(2. * nh * nv / vh,2. * nh * nl  / vh ));
}

float fresnelSchlick(float nv, float fresnel)
{
    return max(0.,fresnel + (1. - fresnel) * pow(1. - nv, 5.));
}

void scene(inout vec3 ocolor,in vec2 f)
{
    if( !GetsEvenWorse)cp = vec3(10.,5.,-11.);
    if(OnlyEye)
    {
        cp.xz = rot(cp.xz,-pi/4.);
    }else{
        cp.z += clamp(sin(time/12.),-.9,.1)*10.;
        cp.xz = rot(cp.xz,t/2. - cos(t/2.));
    }
    
    vec2 p = (f.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    vec3 target = vec3(0.,0.,0.);
    vec3 cd = normalize(target - cp);
    vec3 cs = normalize(cross(vec3(0.,1.,0.),cd));
    vec3 cu = normalize(cross(cs,cd));
    
    float fov = 2.;
    vec3 rd = normalize(cs * p.x + cu * p.y + cd * fov);
    vec3 skycolor = vec3(.2,.4,.8);
    vec3 color = skycolor;
    
    vec3 light = normalize(vec3(.8,.4,.2));
    vec2 d = vec2(-1.);
    d = march(cp,rd);
    if(d.x > 0.)
    {
        vec2 e = vec2(0.0001,0.);
        vec3 pos = depth * rd + cp;
        vec3 N = -normalize(map(pos).x - vec3(map(pos - e.xyy).x,map(pos - e.yxy).x,map(pos - e.yyx).x));

     
        color = mix(eyecolor(pos),mengcolor(pos),step(d.y,1.));
        vec3 view = rd;
        vec3 hlf = normalize(light + view);
        float nl = dot(N,light);
        float nv = dot(N,view);
        float nh = dot(N,hlf);
        float vh = dot(view,hlf);
        
        float fresnel = 2.;
        float roughness = .1;
        //vec2(fresnel,roughness)
        vec2 para = mix(vec2(4.,.07),vec2(3.,.1),step(d.y,1.));
        
        float dte = B(nh , para.y);
        float gte = C(nl,nv,nh,vh);
        float fte = fresnelSchlick(nv,para.x);

        float sp = max(0.,dte * gte * fte / (nl * nv * 4.) * nl);

        float dif = pow( max(0.,dot(light,N))*.5+.5,2. );
        color =color * dif + sp * vec3(1.,1.,1.);
        
        
    }
    ocolor += color;
}

void main(void)
{
    t = time/2.;
    depth = 55.;
    vec3 color = vec3(0.);
    for(int i = 0;i < AA;i++ )
    {
        for(int j = 0; j < AA;j++)
        {
            vec2 d = vec2(float(i),float(j)) - vec2(float(i),float(j))/2.;
            d /= float(AA);
            scene(color,gl_FragCoord.xy + d);
        }
    }
    color /= float(AA * AA);
    
    glFragColor = vec4(color, 1.0);
}
