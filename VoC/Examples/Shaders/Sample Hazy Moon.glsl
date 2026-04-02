#version 420

// original https://www.shadertoy.com/view/tdsyRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define FAR 20.
#define AA 2

float t,depth;
vec3 cp = vec3(0.,-4.,-15.);

vec2 rot(vec2 p,float a){return vec2(mat2( cos(a),sin(a),-sin(a),cos(a))*p );}
float bo(vec3 p,vec3 s){p = abs(p) - s;return max(max(p.x,p.y),p.z);}
float rand(vec2 p){return fract(sin(dot(p,vec2(127.1,317.2))));}

//https://www.shadertoy.com/view/XsX3zB
//---------------------------------------------------------
vec3 random3(vec3 c) {
    float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
    vec3 r;
    r.z = fract(512.0*j);
    j *= .125;
    r.x = fract(512.0*j);
    j *= .125;
    r.y = fract(512.0*j);
    return r-0.5;
}

/* skew constants for 3d simplex functions */
const float F3 =  0.3333333;
const float G3 =  0.1666667;

/* 3d simplex noise */
float simplex3d(vec3 p) {
    /* 1. find current tetrahedron T and it's four vertices */
    /* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
    /* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/

    /* calculate s and x */
    vec3 s = floor(p + dot(p, vec3(F3,F3,F3)));
    vec3 x = p - s + dot(s, vec3(G3,G3,G3));

    /* calculate i1 and i2 */
    vec3 e = step(vec3(0.,0.,0.), x - x.yzx);
    vec3 i1 = e*(1.0 - e.zxy);
    vec3 i2 = 1.0 - e.zxy*(1.0 - e);

    /* x1, x2, x3 */
    vec3 x1 = x - i1 + G3;
    vec3 x2 = x - i2 + 2.0*G3;
    vec3 x3 = x - 1.0 + 3.0*G3;

    /* 2. find four surflets and store them in d */
    vec4 w, d;

    /* calculate surflet weights */
    w.x = dot(x, x);
    w.y = dot(x1, x1);
    w.z = dot(x2, x2);
    w.w = dot(x3, x3);

    /* w fades from 0.6 at the center of the surflet to 0.0 at the margin */
    w = max(0.6 - w, 0.0);

    /* calculate surflet components */
    d.x = dot(random3(s), x);
    d.y = dot(random3(s + i1), x1);
    d.z = dot(random3(s + i2), x2);
    d.w = dot(random3(s + 1.0), x3);

    /* multiply d by w^4 */
    w *= w;
    w *= w;
    d *= w;

    /* 3. return the sum of the four surflets */
    return dot(d, vec4(52.0,52.0,52.0,52.0));
}
//---------------------------------------------------------

float noise (vec3 st) 
{
    float f = 0.;
    vec3 q = st;
    for(int i = 1 ;i < 3;i++){
        f += simplex3d(q)/pow(2.,float(i));
        q = q * (2.0+float(i)/100.);
    }
    return f;
}

vec2 map(vec3 p)
{
    vec2 d = vec2(0.);
    vec2 area = floor((p.xz)/(.8));
    p.xz = mod(p.xz,(.8 ))-(.8)/2.;
    
    //p.y += wave(area ,time) ;
    for(int i = 1; i< 5; i++)
    {
        p.y += pow( sin(area.x + t) * cos(area.y + t) ,2.);
        area = rot(area,acos(-1.)/3.);
        area += .8 * 60.;
        area = floor(area /(float(i ) *2.) );
    }
    float s = bo(p,vec3(.25,cos(length(p.xz)*1.3),.25));
    //s = length(p)-.5;
    d.x = s *.1;
    return d;
}

vec2 march(vec3 p,vec3 rd)
{
    depth = 0.;
    vec2 d = vec2(.0);
    for(int i = 0; i <128; i++)
    {
        d = map(p + rd * depth);
        if(abs(d.x) < 0.00001 || d.x > FAR){break;}
        depth += d.x;
    }
     if(d.x > FAR){d.x = -1.;}
    return d;
}

void moon(out vec3 color,in vec3 cp,in vec3 rd)
{
    color += clamp( pow(  mix( 1.,.5 - noise((cp + rd) * 18. + vec3(0.8,1.7,0.6) * (t + sin(t))/5. ) ,.5),1.5 ),0.,1. );
}

void scene(out vec3 ocolor,in vec2 fragcoord)
{
    vec2 p = (fragcoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    
    vec3 target = vec3(0.,-7.,0.);
    vec3 cd = normalize(target - cp);
    vec3 cs = normalize(cross(vec3(0.,1.,0.),cd));
    vec3 cu = normalize(cross(cs,cd));
    
    float fov = 2. + dot(p,p) * .3;
    vec3 rd = normalize(cs * p.x + cu * p.y + cd * fov);
    vec3 skycolor = vec3(.2,.4,.8);
    vec3 color = skycolor;
    //vec3(0.5,0.4,-1.)
    
    vec3 moonpos = vec3(p.x,p.y - .7,depth);
    vec3 light = normalize(vec3(.0,.3,.0) - mix(rd , moonpos,0.01));
    
   // light.xz = rot(light.xz,sin(time) );
    vec2 d = vec2(-1.);
    skycolor += (1. - pow( length(moonpos.xy + cos(moonpos.xy*200.)),2.) )/3.;
    
    if(length(moonpos.xy) < .125)
    {
        moon(color,cp,rd);
        color = mix(color,skycolor,pow( length(moonpos.xy) * 8.,6. ) );
    }else{
        d = march(cp,rd);
    }
    if(d.x > 0.)
    {
        vec2 e = vec2(0.0001,0.);
        vec3 pos = depth * rd + cp;
        vec3 N = -normalize(map(pos).x - vec3(map(pos - e.xyy).x,map(pos - e.yxy).x,map(pos - e.yyx).x));
        color = vec3(0.,.5,1.);
        float dif = pow( max(0.,dot(light,N))*.5+.5,2. );
        float sp = pow(max(0.,dot(normalize(light + rd),N)),150.);
        color =color * dif + sp * vec3(1.,1.,1.);
        
    }
    ocolor += mix(color,skycolor,1.-exp(-.000001 *depth * depth* depth));
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
