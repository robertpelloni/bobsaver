#version 420

// original https://www.shadertoy.com/view/Msyfzw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

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

vec3 hsv2rgb(vec3 c){return (2.0-c.y+c.y*sin(c.x+pi.xzw/1.5))*c.z*0.5;}

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

vec2 theta(vec2 t, vec2 z)
{
    vec2 sum = vec2(0.0);
    //t = cexp(t.yx);
    //z = cexp(z);
    for (int i = -24; i < 24; i++)
    {
        sum += cpow(t,float(i*i)) * cpow(z,float(i));
    }
    return sum;
}

void main(void)
{
    vec4 uv = (vec4(gl_FragCoord.xy, mouse*resolution.xy.xy) * 2.0 - resolution.xyxy)/resolution.y;
    uv.xy *= 1.5;
    float d = dot(uv.xy, uv.xy);
    if (d > 1.0) uv.xy /= -d;
    vec2 th = theta(uv.xy, uv.zw);
    //th = theta(th, th);
    //vec2 th = theta(uv.zw, uv.xy);
    
    float ang = atan(th.y,th.x);
    float len = length(th);
    vec3 col = hsv2rgb(vec3(ang*2.0+3.3,1.0-exp(-len),exp(-len*0.01)));

    glFragColor = vec4(col,1.0);
}
