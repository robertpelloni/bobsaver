#version 420

// original https://www.shadertoy.com/view/MlffDB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform int frames;

out vec4 glFragColor;

// Bessel code taken from https://www.atnf.csiro.au/computing/software/gipsy/sub/bessel.c
// Any errors in conversion are mine

#define ACC 10.0
#define BIGNO 1.0e10
#define BIGNI 1.0e-10

float bessj0( float x )
/*------------------------------------------------------------*/
/* PURPOSE: Evaluate Bessel function of first kind and order  */
/*          0 at input x                                      */
/*------------------------------------------------------------*/
{
   float ax,z;
   float xx,y,ans,ans1,ans2;

   if ((ax=abs(x)) < 8.0) {
      y=x*x;
      ans1=57568490574.0+y*(-13362590354.0+y*(651619640.7
         +y*(-11214424.18+y*(77392.33017+y*(-184.9052456)))));
      ans2=57568490411.0+y*(1029532985.0+y*(9494680.718
         +y*(59272.64853+y*(267.8532712+y*1.0))));
      ans=ans1/ans2;
   } else {
      z=8.0/ax;
      y=z*z;
      xx=ax-0.785398164;
      ans1=1.0+y*(-0.1098628627e-2+y*(0.2734510407e-4
         +y*(-0.2073370639e-5+y*0.2093887211e-6)));
      ans2 = -0.1562499995e-1+y*(0.1430488765e-3
         +y*(-0.6911147651e-5+y*(0.7621095161e-6
         -y*0.934935152e-7)));
      ans=sqrt(0.636619772/ax)*(cos(xx)*ans1-z*sin(xx)*ans2);
   }
   return ans;
}

float bessj1( float x )
/*------------------------------------------------------------*/
/* PURPOSE: Evaluate Bessel function of first kind and order  */
/*          1 at input x                                      */
/*------------------------------------------------------------*/
{
   float ax,z;
   float xx,y,ans,ans1,ans2;

   if ((ax=abs(x)) < 8.0) {
      y=x*x;
      ans1=x*(72362614232.0+y*(-7895059235.0+y*(242396853.1
         +y*(-2972611.439+y*(15704.48260+y*(-30.16036606))))));
      ans2=144725228442.0+y*(2300535178.0+y*(18583304.74
         +y*(99447.43394+y*(376.9991397+y*1.0))));
      ans=ans1/ans2;
   } else {
      z=8.0/ax;
      y=z*z;
      xx=ax-2.356194491;
      ans1=1.0+y*(0.183105e-2+y*(-0.3516396496e-4
         +y*(0.2457520174e-5+y*(-0.240337019e-6))));
      ans2=0.04687499995+y*(-0.2002690873e-3
         +y*(0.8449199096e-5+y*(-0.88228987e-6
         +y*0.105787412e-6)));
      ans=sqrt(0.636619772/ax)*(cos(xx)*ans1-z*sin(xx)*ans2);
      if (x < 0.0) ans = -ans;
   }
   return ans;
}

float bessj( float n, float x )
/*------------------------------------------------------------*/
/* PURPOSE: Evaluate Bessel function of first kind and order  */
/*          n at input x                                      */
/* The function can also be called for n = 0 and n = 1.       */
/*------------------------------------------------------------*/
{
   float    j, jsum, m;
   float ax, bj, bjm, bjp, sum, tox, ans;

   if (n < 0.) return 0.; // setdblank

   ax=abs(x);
   if (n == 0.)
      return( bessj0(ax) );
   if (n == 1.)
      return( bessj1(ax) );
      
   if (ax == 0.0)
      return 0.0;
   else if (ax > float(n)) {
      tox=2.0/ax;
      bjm=bessj0(ax);
      bj=bessj1(ax);
      for (j=1.;j<n;j+=1.) {
         bjp=j*tox*bj-bjm;
         bjm=bj;
         bj=bjp;
      }
      ans=bj;
   } else {
      tox=2.0/ax;
      m=2.*((n+floor(sqrt(ACC*n)))/2.);
      jsum=0.;
      bjp=ans=sum=0.0;
      bj=1.0;
      for (j=m;j>0.;j-=1.) {
         bjm=j*tox*bj-bjp;
         bjp=bj;
         bj=bjm;
         if (abs(bj) > BIGNO) {
            bj *= BIGNI;
            bjp *= BIGNI;
            ans *= BIGNI;
            sum *= BIGNI;
         }
         if (jsum != 0.) sum += bj;
         jsum=(jsum == 0.) ? 1. : 0.;
         if (j == n) ans=bjp;
      }
      sum=2.0*sum-bj;
      ans /= sum;
   }
   return  x < 0.0 && mod(n,2.) == 1. ? -ans : ans;
}

// Goal is to find the n_th (positive) zero of J_m
// This is my homebrew zero finder, caveat emptor
// Initial guess calibrated for 0<=m<=10, 1<=n<=5
float GetLambda(float m, float n) {
    float guess = -0.98368854 + 1.3045853*m + 3.4110198*n +
        (-0.0134096)*m*m + (-0.0491151)*n*n + 0.04748184*m*n;
    // Take 1 Newton steps, use d/dx J_m(x) = (m/x)*J_m(x) - J_{m+1}(x)
    for (int i = 0; i < 1; i++) {
        float numer = bessj(m, guess);
        float denom = numer*m/guess - bessj(m+1., guess);
        guess -= numer/denom;
    }
    return guess;
}

// calculate the height function for p in unit disc
// m,n,lmda harmonics parameters, t is time parameter
// height between 0 and 1
float GetHeight(vec2 p, float m, float n, float lmda, float t) {
    float theta = m*atan(p.y,p.x);
    return .5+.25*(cos(8.*t) + sin(8.*t))*bessj(m, lmda * length(p)) * (cos(theta)+sin(theta));
}

void main(void)
{
    vec2 uv = 2.0 * (gl_FragCoord.xy / resolution.xy) - 1.0;

    // m and n are the mode parameters
    float m,n;
    if (uv.x < 0. && uv.y < 0.) { m = 2.; n = 1.; }
    else if (uv.x < 0. && uv.y > 0.) { m = 0.; n = 2.; }
    else if (uv.x > 0. && uv.y > 0.) { m = 1.; n = 3.; }
    else { m = 2.; n = 3.; }
    float lmda = GetLambda(m, n);

    // Redo uv per quadrant
    uv = 2.*vec2(mod(uv.x, 1.), mod(uv.y, 1.)) - vec2(1.);
    uv.x *= resolution.x/resolution.y;
    
    float scale = 4.;
    float time = 6.283185*float(frames)/480.;
    mat3 rotate = mat3(cos(time),0.,-sin(time),0.,1.,0.,sin(time),0.,cos(time));
    vec3 ro = rotate*vec3( 2., 2., 2.);
    vec3 center = vec3( 0.0, 0.5, 0.0 );
    vec3 ww = normalize( center - ro );
    vec3 uu = normalize(cross(ww, vec3(0.0,1.0,0.0) ));
    vec3 vv = cross(uu,ww);
    vec3 rd = normalize( uv.x*uu + uv.y*vv + scale*ww );

    const int steps=30;
    float t0=(1.-ro.y)/rd.y;
    float t1=(0.-ro.y)/rd.y;

    vec3 prevp = ro+rd*t0;
    vec3 p = prevp;
    float ph = 1.;
    float pt = t0;
    
    // Raymarch through the heightfield with a fixed number of steps.
    // https://www.shadertoy.com/view/MdBSRW
    for(int i=1; i<steps; i++)
    {
        float t=mix(t0,t1,float(i)/float(steps));
        p=ro+rd*t;
        float h = GetHeight(p.xz, m, n, lmda, time);

        if(h>p.y)
        {
            // Refine the intersection point.
            float lrd=length(rd.xz);
            vec2 v0=vec2(lrd*pt, prevp.y);
            vec2 v1=vec2(lrd*t, p.y);
            vec2 v2=vec2(lrd*pt, ph);
            vec2 dv=vec2(h-v2.y,v2.x-v1.x);
            float inter=dot(v2-v0,dv)/dot(v1-v0,dv);
            p=mix(prevp,p,inter);

            // Re-evaluate the height using the refined intersection point.
            ph=GetHeight(p.xz, m, n, lmda, time);
            
            break;
        }
        prevp=p;
        ph = h;
        pt = t;
    }
    
    // color by height and constrain to circle (+antialias)
    glFragColor = mix(vec4(.8, ph, 0.,1.), 
                    vec4(105., 105., 105., 256.)/256.,
                    smoothstep(.999, 1.001, length(p.xz)));
}
