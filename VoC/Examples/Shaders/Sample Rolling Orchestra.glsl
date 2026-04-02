#version 420

// original https://www.shadertoy.com/view/fssyWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14

#ifdef HW_PERFORMANCE
    #if HW_PERFORMANCE==0
    #define AA 1.
    #else
    #define AA 2.   // make this 2 or 3.. for better antialiasing
    #endif
#else
#define AA 1.
#endif

const float MAXD = 100.;
const float MAXSHD = 3.;
const float MAXRD = 15.;
float t;
// 2d rotation
vec2 rot(vec2 p, float r) {
    float c = cos(r), s = sin(r);
    return vec2(p.x * c - p.y * s, p.x * s + p.y * c);
}
float H = .4; //size of the cross sphere raduis is cqlculated based on this
// rolling a vector u in a closed path (square of length h, in plan y=0)
// f is the animation parametre (time)
vec3 roll4(vec3 u, float h, float f)
{
    float s=.5;
    float c = .03; //this add a clamping effect i think it look cooler
    f = floor(f)+smoothstep(s,1.+c,fract(f));
    f*=pi;
    float b = f/pi/2.;
    float a = b + .5;
    a =(max(0., 2.*fract(a) - 1. ) + floor(a));  
    b = abs(  max(0., 2.*fract(b)-1.) + floor(b)- floor(b/2.+.25)*2.);
    u.x += (2.-h)*  (4.*abs(fract(a/2.)-.5)-1.);
    u.z += (2.-h)*  (4.*abs(fract(b/2.)-.5)-1.);
    u.zy = rot(u.zy,b*pi);
    u.xy = rot(u.xy,a*pi);
    return u;   
}
// rolling wheel (1/4 of a sphere)
float wheel(vec3 p,float r)
{
    float d = length(p) - r;
    return max(-p.z,max(-p.x,d));
}
// 1d-elongated cylindre
float cyl(in vec3 p, in float r,in float h)
{
    p.x -=clamp(p.x,-h,h);    
    vec2 d = abs(vec2(length(p.yx),p.z)) - vec2(r,h);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
// 2d-elongated sphere 
float sph(in vec3 p, in float r,in float h)
{
    p.xz -=clamp(p.xz,-h,h);    
    return length(p)-r;
    vec2 d = abs(vec2(length(p.yx),p.z)) - vec2(r,h);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
float cros(in vec3 p, in float r,in float h)
{
    float d = min(cyl(p,r,h),cyl(p.zyx,r,h));
    /*
    for(int i=0;i<6;i++)
    {
        p.y -= r/2. + r/2.;// r*2.-.5+r/4.;
        r/=1.4;
        h-=r/sqrt(2.);
        d = min(d, sph(p,r,h));
    }
    */
    return d;
}
// surface texture
float text(vec3 u)
{
    return  0.; //remove this to apply surface textures
    u *= 6.28*10.;
    //u = abs(fract(u/10.)-.5)*4.-1.;
    u = sin(u/2.);
    return 0.015*( u.x*u.y*u.z )  ;
}
vec4 opu(vec4 a,vec4 b){ return (a.x<b.x) ? a : b;}
vec4 map(vec3 p)
{
    vec3 blue = normalize(vec3(.3,.4,.8));
    vec3 q=p;
    p.xz=mod(p.xz,4.)-2.;
    vec2 s = (q.xz-p.xz)/4.-.5;
    vec3 u = p;        
    
    float h = H;
    float r = (4.-h*2.)/3.14;
    u.y-=r;
    
    q = u;
    q.xz = abs(u.xz) - vec2(2.);
    float frame = cros(q,r,h);
    if(fract(s.x/2.+s.y/2.)>.25) frame += text(u);
    vec4 plan = vec4(p.y,blue-.1);
    vec4 wall = vec4(frame,blue);

    float c = t*.2 +s.y+2.*s.x; //; -  0.*s.y/2.;
    float c2 = c +1.+mod(s.x*s.y,2.); //; -  0.*s.y/2.;
    p = roll4(u,h,c);
    float w1 = wheel(p , r);
    w1 += text(p);
    p = roll4(u,h,c2);
    float w2 = wheel(p , r);
    //w2 += text(p);
    vec4 wheel1 = vec4(w1, blue); 
    vec4 wheel2 = vec4(w2, blue*0.65);
    wheel1 = opu(wheel1,wheel2);

    vec4 o = opu(plan,opu(wheel1,wall));
    o.x -= .04;//+0.01*(sin(p.x*40.)*sin(p.y*40.));
    o.yzw = vec3(1.,.8,.9); //color 
    
    return o;//vec4(d,1.,0.,0.);
}
//simple raymarch
vec4 rayMarch(vec3 rO, vec3 rD)
{   
    float d = 0.;
    vec4 D;
    for (int i = 0; i<130 &&  d < MAXD; i++)
    {
        D = map(rO + rD * d);
        //d += D.x;
        if (D.x > .5)  d += D.x*.5;   else d += D.x;
        if (D.x < 3e-4)  break;
    }
    return vec4(d, D.yzw);
}

//to learn about normal using sdf
//https://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 normal(vec3 p)
{
    vec2 N = vec2(0., 1e-2);
    return normalize(vec3(map(p-N.yxx).x, map(p-N.xyx).x, map(p-N.xxy).x));
}
vec3 simpleSky(vec3 p){   
    return vec3(.5,.6,1.-p.y);
}
// you can learn more about soft shadows in this article https://iquilezles.org/www/articles/rmshadows/rmshadows.htm
float shadows(vec3 or, vec3 lD)
{
    const float k = 1.5;
    float res = 1.;
    float t = 0.;
    for (int i = 0; i < 40; i++)
    {
        float d = map(or + lD*t).x;
        res = min(res, .5 + d * k / t);
        if (res < .01|| t > MAXSHD) break;
        t += d;
    }
    res = max(res, 0.);
    return smoothstep(.3, 1., res);
}
vec4 render(in vec2 glFragCoord )
{
    float fov = resolution.x;
    vec2 uv = glFragCoord.xy - resolution.xy / 2.;
    uv = uv - .5;
    uv /= fov;
    float ww=t*.025;
    vec3 or = vec3(cos(ww),.6+sin(ww*1.5345)*.2,sin(ww))*10.*(sin(ww*1.37)+3.);
    //or.y = 20.;
    //or.y-=17.5;
    vec3 w = normalize(vec3(0.,0.,0.)-or);
    vec3 u = normalize(cross(w, vec3(0., 1., 0.)));
    vec3 v = cross(u, w);
    vec3 rD = normalize(w*1.5+uv.x*u+uv.y*v);
       
    vec4 d = rayMarch(or, rD);
    vec3 col = vec3(0,0,0);
    
    if (d.x < MAXD)
    {
        vec3 p = or + d.x * rD;
        vec3 nrm = normal(p);
        vec3 sun = -normalize(vec3(.4, 2., .8));
        
        col = vec3(dot(sun,nrm)) *d.yzw;
        //col *= d.yzw; //colloring
        col *= vec3(shadows(p - sun * 0.01, -sun));

    }
    else 
    {
        col = simpleSky(rD);
    }
    
    return vec4(col,1.0);
}
void main(void)
{
    glFragColor = vec4(0.);
    t = time*2.25; // globale time
    for(float a=0.;a<AA;a++)
        glFragColor += render(gl_FragCoord.xy + a/AA);
    glFragColor /=AA;
}
