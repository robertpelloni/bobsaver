#version 420

// original https://www.shadertoy.com/view/wdXyz7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Python code to generate the coefficients

/*

import matplotlib.pyplot as plt
import numpy as np

sc =  1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
re = -1768010207885292485096455932501431452787808619665428630688176866932880890752608130523302708235225880005923084318330000000000
im = -6549734413678931050066077600995564782557871706977125749218220354322280587594010179686199993596850414977125832770000000000

def mIter(r, i, c_re, c_im):
    nr = ((r*r)-(i*i))//sc+c_re
    ni = (2*r*i)//sc+c_im
    return (nr, ni)

def mSample(os):
    u = sc // 100000000000000000000000000000000000000000000000000000000000000000000000000000000000
    reo = re + u * os[0]
    imo = im + u * os[1]
    r = 0
    i = 0
    N = 2900
    #rk = np.zeros((2,N))
    its = 0
    for k in range(N):
        r, i = mIter(r, i, reo, imo)

        fr = r/sc
        fi = i/sc
        #rk[0,k] = fr
        #rk[1,k] = fi
        if ( (((r*r)+(i*i))//sc)/sc > 4. ):
            return k
    return (fr, fi)

offsets = [[16*x-400,16*y-400] for x in range(50) for y in range(50)]
x=np.array([mSample(os) for os in offsets])
data = x.reshape((50,50,2))[...,0] + x.reshape((50,50,2))[...,1]*1j
data_center = data[25,25]
data -= data_center
ydata = data[25,:]
xaxis=(np.arange(50)-25)/25
coefs = np.polyfit(xaxis,ydata,16)
polyfit = (np.power(xaxis.reshape((50,1)), np.arange(17).reshape((1,17)))*coefs[::-1]).sum(axis=-1)
xaxis_cx = np.array([[[(x-25)-(y-25)*1j] for x in range(50)] for y in range(50)])/25
polyfit_cx = (np.power(xaxis_cx.reshape((50,50,1)), np.arange(17).reshape((1,1,17)))*coefs[::-1]).sum(axis=-1)
plt.plot(np.real(ydata))
plt.plot(np.real(polyfit))
plt.show()
plt.imshow(np.log(np.abs(data)));plt.show()
plt.imshow(np.log(np.abs(polyfit_cx)));plt.show()

print(data_center)
[print("vec2("+str(np.real(c)) + "," + str(np.imag(c))+"),") for c in coefs]

*/

vec2 c = vec2(-1.7680102078852924, -0.006549734413678931);
vec2 z_center_start = vec2(-1.745137460714392, 5.342842875921161e-06);

vec2[] coefs = vec2[](
       vec2(-4.283056027444665e-10,-7.148960471521885e-10),
vec2(2.492899591470072e-13,-8.191077881903552e-14),
vec2(-7.423929651835989e-10,-5.586147507015157e-11),
vec2(-8.137467699773936e-13,2.673782887391839e-13),
vec2(-1.8453154321635335e-10,2.3213797706158293e-10),
vec2(1.054456457852924e-12,-3.4647048080723866e-13),
vec2(1.959737745790168e-11,5.957586592943925e-11),
vec2(-6.897713336051537e-13,2.2664367378176241e-13),
vec2(4.810621610887565e-06,-5.92671585553072e-06),
vec2(2.391899593907184e-13,-7.859273373949845e-14),
vec2(-9.475787498902431e-07,-3.2774207967475432e-06),
vec2(-4.206751535016167e-14,1.3822523701024451e-14),
vec2(-5.416729239862756e-07,-1.8316405836739592e-07),
vec2(3.2152639366090903e-15,-1.0564714321274122e-15),
vec2(-3.423535374756122e-08,2.5340913185805886e-08),
vec2(-6.983908156570175e-17,2.2947768063996074e-17)
);

void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y*3.;

    vec2 dz = vec2(0);
    vec2 uvr = uv;
    int i;
    for(i = 15; i > 0; i--){
        dz += mat2(uvr,-uvr.y,uvr.x) * (coefs[i]*vec2(1,-1));
        uvr = mat2(uvr,-uvr.y,uvr.x) * uv;
    }
    vec4 O = vec4(sin(.1*abs(log(length(dz)))));
    vec2 z = z_center_start;
    for(i = 0; i < 150; i++){
        vec2 zn = mat2(z,-z.y,z.x) * z + c;
        vec2 dzn =  2.*mat2(z,-z.y,z.x)*dz + mat2(dz,-dz.y,dz.x)*dz;// + ∆0 //dont add delta z zero because it would be incredibly tiny
        z = zn;
        dz = dzn;
        if(length(z+dz)>2.) break;
    }
    O = .5+.5*vec4(cos(.2*vec4(3,4,5,0)*log(float(i))));
    glFragColor = O;
}
