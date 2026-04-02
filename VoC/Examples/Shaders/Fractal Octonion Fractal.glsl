#version 420

// original https://www.shadertoy.com/view/XdyyzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define volumetric

#define fractalIters 5
#define marchingIters 80

#define close 0.001
#define far 10.0

//Complex+Quaternion+Octonion+Sedenion code
//use with attribution (c) Rodol 2018
//https://www.shadertoy.com/view/ldGyR3

vec4 pi = vec4(0,2,4,8)*atan(1.0);

// (1,i)
vec2 creal(float a){return vec2(a,0);}
float csl (vec2 z){return dot(z,z);}
float cl  (vec2 z){return sqrt(csl(z));}
float csil(vec2 z){return z.y*z.y;}
float cil (vec2 z){return z.y;}
float carg(vec2 z){return atan(cil(z),z.x);}
vec2 cconj(vec2 z){z.x=-z.x;return-z;}
vec2 cmul (vec2 z,float b){return z*b;}
vec2 cmul (vec2 a,vec2 b){return mat2(a,-a.y,a.x)*b;}
vec2 csqr (vec2 z){return vec2(z.x*z.x-z.y*z.y,2.0*z.y*z.x);}
vec2 ccube(vec2 z){return vec2(z.x*z.x-3.0*z.y*z.y,3.0*z.x*z.x-z.y*z.y)*z;}
vec2 cinv (vec2 z){return cconj(z)/csl(z);}
vec2 cdiv (vec2 a,vec2 b){return cmul(a,cinv(b));}
vec2 cexp (vec2 z){float l=cil(z);return sin(l+pi.yx)*exp(z.x);}
vec2 clog (float x){return vec2(log(abs(x)),pi.z*step(0.0,x));}
vec2 cpow (float a,vec2 z){float l=cil(z);return sin(l+pi.yx)*pow(a,z.x);}
vec2 cpow (vec2 z,float n){return pow(csl(z),n*0.5)*sin(carg(z)*n+pi.yx);}
vec2 cpow (vec2 a,vec2 b){return cmul(cpow(csl(a),0.5*b),cexp(carg(a)*b));}

// (1,i,j,k)
vec4 qreal(float a){return vec4(a,vec3(0));}
float qsl (vec4 q){return dot(q,q);}
float ql  (vec4 q){return sqrt(qsl(q));}
float qsil(vec4 q){return dot(q.yzw,q.yzw);}
float qil (vec4 q){return sqrt(qsil(q));}
float qarg(vec4 q){return atan(qil(q),q.x);}
vec4 qconj(vec4 q){q.x=-q.x;return-q;}
vec3 qmul (vec4 q,vec3 v){return v+2.0*cross(cross(v,q.yzw)+q.x*v,q.yzw);}
vec4 qmul (vec4 a,vec4 b){return vec4(a.x*b.x-dot(a.yzw,b.yzw),b.yzw*a.x+a.yzw*b.x+cross(a.yzw,b.yzw));}
vec4 qsqr (vec4 q){return vec4(q.x*q.x-qsil(q),2.0*q.x*q.yzw);}
vec4 qcube(vec4 q){float l=qsil(q);return q*vec2(3.0*q.x*q.x-l,q.x*q.x-3.0*l).yxxx;}
vec4 qinv (vec4 q){return qconj(q)/qsl(q);}
vec4 qdiv (vec4 a,vec4 b){return qmul(a,qinv(b));}
vec4 qexp (vec4 q){float l=qil(q);vec2 z=sin(l+pi.xy)*exp(q.x);q*=z.x/l;q.x=z.y;return q;}
vec4 qlog (float x){return vec4(log(abs(x)),step(0.0,x),vec2(0));}
vec4 qpow (float a,vec4 q){float l=qil(q);vec2 z=sin(l+pi.xy)*pow(a,q.x);q*=z.x/l;q.x=z.y;return q;}
vec4 qpow (vec4 q,float n){return pow(qsl(q),n*0.5)*sin(qarg(q)*n+pi.xy).yxxx;}
vec4 qpow (vec4 a,vec4 b){return qmul(qpow(qsl(a),0.5*b),qexp(qarg(a)*b));}

// (1,i,j,k,l,m,n,o)
mat2x4 oreal(float a){return mat2x4(a,vec3(0),vec4(0));}
float osl (mat2x4 o){return qsl(o[0])+qsl(o[1]);}
float ol  (mat2x4 o){return sqrt(osl(o));}
float osil(mat2x4 o){return qsil(o[0])+qsl(o[1]);}
float oil (mat2x4 o){return sqrt(osil(o));}
float oarg(mat2x4 o){return atan(oil(o),o[0].x);}
mat2x4 oconj(mat2x4 o){o[0].x=-o[0].x;return-o;}
mat2x4 omul (mat2x4 a,mat2x4 b){return mat2x4(qmul(a[0],b[0])-qmul(qconj(b[1]),a[1]),qmul(b[1],a[1])+qmul(a[1],qconj(b[0])));}
mat2x4 osqr (mat2x4 o){return mat2x4(qsqr(o[0])-vec4(qsil(o[1]),vec3(0)),qsqr(o[1])+qmul(o[0],qconj(o[1])));}
//mat2x4 ocube(mat2x4 o)
mat2x4 oinv (mat2x4 o){return oconj(o)/osl(o);}
mat2x4 odiv (mat2x4 a,mat2x4 b){return omul(a,oinv(b));}
mat2x4 oexp (mat2x4 o){float l=oil(o);vec2 z=sin(l+pi.xy)*exp(o[0].x);o*=z.x/l;o[0].x=z.y;return o;}
mat2x4 olog (float x){return mat2x4(log(abs(x)),step(0.0,x),vec2(0),vec4(0));}
mat2x4 opow (float a,mat2x4 o){float l=oil(o);vec2 z=sin(l+pi.xy)*pow(a,o[0].x);o*=z.x/l;o[0].x=z.y;return o;}
mat2x4 opow (mat2x4 o,float n){vec2 z=pow(osl(o),n*0.5)*sin(oarg(o)*n+pi.xy);return mat2x4(z.yxxx,z.xxxx);}
mat2x4 opow (mat2x4 a,mat2x4 b){return omul(opow(osl(a),0.5*b),oexp(oarg(a)*b));}

// (1,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w)
mat4x4 sreal(float a){return mat4x4(a,vec3(0),vec4(0),vec4(0),vec4(0));}
float ssl (mat4x4 s){return qsl(s[0])+qsl(s[1])+qsl(s[2])+qsl(s[3]);}
float sl  (mat4x4 s){return sqrt(ssl(s));}
float ssil(mat4x4 s){return qsil(s[0])+qsl(s[1])+qsl(s[2])+qsl(s[3]);}
float sil (mat4x4 s){return sqrt(ssil(s));}
float sarg(mat4x4 s){return atan(sil(s),s[0].x);}
mat4x4 sconj(mat4x4 s){s[0].x=-s[0].x;return-s;}
mat4x4 smul (mat4x4 a,mat4x4 b){mat2x4 c=omul(mat2x4(a[0],a[1]),mat2x4(b[0],b[1]))-omul(oconj(mat2x4(b[2],b[3])),mat2x4(a[2],a[3]));mat2x4 d=omul(mat2x4(b[2],b[3]),mat2x4(a[2],a[3]))+omul(mat2x4(a[2],a[3]),oconj(mat2x4(b[0],b[1])));return mat4x4(c[0],d[1],c[0],d[1]);}
mat4x4 ssqr (mat4x4 s){mat2x4 a=osqr(mat2x4(s[0],s[1]))-mat2x4(osil(mat2x4(s[2],s[3])),vec3(0),vec4(0));mat2x4 b=osqr(mat2x4(s[2],s[3]))+omul(mat2x4(s[0],s[1]),oconj(mat2x4(s[2],s[3])));return mat4x4(a[0],a[1],b[0],b[1]);}
//mat4x4 scube(mat4x4 s)
mat4x4 sinv (mat4x4 s){return sconj(s)/ssl(s);}
mat4x4 sdiv (mat4x4 a,mat4x4 b){return smul(a,sinv(b));}
mat4x4 sexp (mat4x4 s){float l=sil(s);vec2 z=sin(l+pi.xy)*exp(s[0].x);s*=z.x/l;s[0].x=z.y;return s;}
mat4x4 slog (float x){return mat4x4(log(abs(x)),step(0.0,x),vec2(0),vec4(0),vec4(0),vec4(0));}
mat4x4 spow (float a,mat4x4 s){float l=sil(s);vec2 z=sin(l+pi.xy)*pow(a,s[0].x);s*=z.x/l;s[0].x=z.y;return s;}
mat4x4 spow (mat4x4 s,float n){vec2 z=pow(ssl(s),n*0.5)*sin(sarg(s)*n+pi.xy);return mat4x4(z.yxxx,z.xxxx,z.xxxx,z.xxxx);}
mat4x4 spow (mat4x4 a,mat4x4 b){return smul(spow(ssl(a),0.5*b),sexp(sarg(a)*b));}

vec3 hsv2rgb(vec3 c){return (2.0-c.y-sin(c.x-pi.xzw/3.0)*c.y)*c.z*0.5;}

mat4x4 rand1 = mat4x4( //courtesy of Random.org (gaussian)
     1.1593834080e-1,   1.3775394660e-1,
     5.3141528240e-1,  -9.2197713630e-1,
     9.9250190800e-2,  -9.9445872570e-1,
    -3.1061433050e-1,   1.0464928420e-1,
    -1.0364798210e+0,   1.2225079270e-1,
     1.7464582160e-2,  -9.0843988340e-1,
     6.8511932050e-1,   5.6274976480e-1,
     4.5539237810e-1,  -4.7145843960e-2
);

mat4x4 rand2 = mat4x4( //courtesy of Random.org (gaussian)
    -1.6286628530e-1,   5.4371144610e-2,
     1.3572019950e-1,   6.4559986970e-2,
    -6.8500334680e-1,   4.4710113270e-1,
     9.4101242240e-2,  -3.5224937520e-2,
    -1.4861947450e-1,   5.2194770830e-1,
    -9.7530016410e-1,   5.6408309780e-1,
     1.1661108920e+0,  -2.7485361890e-1,
     7.8126680870e-1,  -5.0644988960e-1
);

mat4x4 rand3 = mat4x4( //courtesy of Random.org (gaussian)
     8.6324789700e-1,   7.3956859870e-1,
    -5.3717888280e-1,  -3.6349861560e-1,
     1.1642346260e-1,  -7.0595935620e-2,
     1.6893859320e-1,  -5.4608794640e-1,
    -1.0161218400e+0,   3.6012778120e-1,
    -1.3112304220e-2,  -6.1305132510e-1,
     5.6552559430e-1,  -1.1049970990e-2,
     2.0906878620e-1,  -1.1049500920e+0
);

mat2x4 f(mat2x4 o,mat2x4 c){return osqr(o) + c;}

float sdf(mat2x4 p,mat2x4 c){
    mat2x4 deriv = oreal(1.0);
    for(int i = 0; i < fractalIters; i++){
        deriv = omul(2.0*p, deriv);
        p = f(p,c);
    }
    float lp = ol(p);
    #ifdef volumetric
    float r = 0.5*log(lp)/exp2(float(fractalIters));
    #else
    float r = 0.25*lp*log(lp)*inversesqrt(osl(deriv));
    #endif
    if (r != r) return 0.0;
    return r;
}

vec3 getCol(mat2x4 o,mat2x4 c)
{
    mat2x4 randO = mat2x4(0.48580,0.94783,-1.14336,1.18596,1.59351,-1.03305,-0.25321,0.20268);
    vec3 e = vec3(-0.1,0.0,0.1);
    /*return (sdf(o) - vec3(
        sdf(o+mat2x4(e.xyzx,e.yzxy)),
        sdf(o+mat2x4(e.yzxy,e.xxyz)),
        sdf(o+mat2x4(e.zxyz,e.zyzx))
    )) * 10.0 + 0.5;*/
    #ifdef volumetric
    float value = 1.0-0.25*osl(o);
    float satur = value;
    value *= value;
    value *= value;
    value *= value*sdf(o*1.1,c);
    float sharp = sdf(omul(randO/ol(randO),o),c);
    return hsv2rgb(vec3(sharp*20.0,satur,value));
    #else
    float satur = 1.0;
    float value = sdf(o*1.1);
    float sharp = sdf(omul(randO/ol(randO),o),c);
    return hsv2rgb(vec3(sharp*40.0,satur,value*20.0));
    #endif
}

vec4 iSphere(vec3 ro, vec3 rd){
    float rdro = dot(rd, ro);
    float disc = rdro*rdro - dot(ro, ro) + 4.0;
    if(disc < 0.0) return vec4(9e9);
    disc = sqrt(disc);
    float d = -rdro - disc;
    return vec4(ro + d*rd, 2.0*disc);
}

vec3 render(vec3 ro, vec3 rd, vec4 m){
    mat2x4 c = mat2x4(vec4(0.05), m.wzwz);
    vec4 sphere = iSphere(ro, rd);
    mat2x4 p = mat2x4(vec4(0), sphere.xyz, 0);
    #ifdef volumetric
    vec3 col = vec3(0.0);
    #else
    bool hit = false;
    #endif
    
    if(sphere.w < far){
        mat2x4 dir = mat2x4(vec4(0), rd, 0);
        float t = 0.0;
        
        for(int i = 0; i < marchingIters; i++){
            float d = sdf(p,c);
            t += d;
            p += d * dir;//4.0/float(marchingIters);
            #ifdef volumetric
            col += max(0.0,1.0-d)*getCol(p,c);
            #else
            if (d < close)
            {
                hit = true;
                break;
            }
            #endif
            if(t > sphere.w) break;
        }
    }
    #ifdef volumetric
    return col;
    #else
    if (hit) return getCol(p,c);
    else return vec3(0);
    #endif
}

vec3 r(vec3 v, vec2 r)
{
    vec4 t = sin(vec4(r, r + 1.5707963268));
    float g = dot(v.yz, t.yw);
    return vec3(v.x * t.z - g * t.x,
                v.y * t.w - v.z * t.y,
                v.x * t.x + g * t.z);
}

void main(void)
{
    vec4 m = (2.0*vec4(gl_FragCoord.xy,mouse*resolution.xy.xy)-resolution.xyxy)/resolution.y;
    //if (mouse*resolution.xy.z==0.0) m.zw = vec2(0.6,0.6)*sin(time*vec2(0.4,0.7)+vec2(0.9,1.5));
    vec3 ro = vec3(0, 0, -4);
    vec3 rd = normalize(vec3(m.xy, 3));
    ro = r(ro, vec2(0.5,0.2)*time);
    rd = r(rd, vec2(0.5,0.2)*time);
    glFragColor.a = 0.0;
    glFragColor.rgb = render(ro, rd, m);
}
