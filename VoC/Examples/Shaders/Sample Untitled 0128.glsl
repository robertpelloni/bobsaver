#version 420

// complex ln(sin(z)-t) iterated 10 times

uniform float time;

out vec4 glFragColor;
//uniform vec2 mouse;
uniform vec2 resolution;

float t = 1.0*time;

#define MAX_ITER 10

mat2 complex(float zr, float zi)
{
   return mat2(zr,-zi,zi,zr);
}

mat2 complexp(float zl, float zp)
{
   return complex(zl*cos(zp),zl*sin(zp));
}

float RZ(mat2 z)
{
   return z[0][0];
}

float IZ(mat2 z)
{
   return z[0][1];
}

float LZ(mat2 z)
{
   float x = RZ(z);
   float y = IZ(z);
   return sqrt(x*x+y*y);
}

float PZ(mat2 z)
{
   float x = RZ(z);
   float y = IZ(z);
   return atan(y,x);
}

mat2 cdiv(mat2 z1, mat2 z2)
{
   float x2 = RZ(z2);
   float y2 = IZ(z2);
   float l2sq = x2*x2+y2*y2;
   mat2 inv_z2 = complex(x2/(l2sq),-y2/(l2sq));
   return z1*inv_z2;
}

mat2 CZ(mat2 z)
{
   return complex(RZ(z),-IZ(z));
}

mat2 CE = complex(1.0,0.0);
mat2 CI = complex(0.0,1.0);

float sinh(float x)
{
   return 0.5*exp(-x)-0.5*exp(x);
}
float cosh(float x)
{
   return 0.5*exp(-x)+0.5*exp(x);
}
mat2 ccos(mat2 z)
{
   float x = RZ(z);
   float y = IZ(z);
   return cos(x)*cosh(y)*CE+sin(x)*sinh(y)*CI;
}
mat2 csin(mat2 z)
{
   float x = RZ(z);
   float y = IZ(z);
   return sin(x)*cosh(y)*CE-cos(x)*sinh(y)*CI;
}
mat2 cexp(mat2 z)
{
   float x = RZ(z);
   float y = IZ(z);
   return exp(x)*(cos(y)*CE+sin(y)*CI);
}
mat2 csqrt(mat2 z)
{
   float x = RZ(z);
   float y = IZ(z);
   float p = y/(sqrt(2.0*(sqrt(x*x+y*y)-x)));
   float q = sqrt((sqrt(x*x+y*y)-x)/2.0);
   return complex(p,q);
}
mat2 cln(mat2 z)
{
   float x = RZ(z);
   float y = IZ(z);
   return complex(0.5*log(x*x+y*y),atan(y,x));
}
mat2 cpow(mat2 z, mat2 w)
{
   float x = RZ(z);
   float y = IZ(z);
   float a = RZ(w);
   float b = IZ(w);
   float rs = x*x+y*y;
   float phi = atan(y,x);
   float xt = a*0.5*log(rs)-b*phi;
   float yt = b*0.5*log(rs)+a*phi;
   return cexp(complex(xt,yt));
}

mat2 t1(mat2 z)
{
   //return cdiv(CE,CE-z)+4.0*(sin(t/16.0)+1.0)*cdiv(CE,CE-z*z);
   //return cdiv(CE,CE-z)+f1R*cdiv(CE,CE-z*z);
   //return csin(cdiv(CE,z)-t/100.0*CE);
   //return csin(csqrt(z)-CE*t);
   //return csqrt(cdiv(CE,CE+z*z*z));
   return cln(csin(z-CE*t/100.0)*cexp(CI*t));
}

void main(void)
{
   float x = gl_FragCoord.x;
   float y = gl_FragCoord.y;
   float w = resolution.x;
   float h = resolution.y;
   float pi = 3.14159265;
   float X1 = -4.0;
   float X2 = 4.0;
   float Y1 = -4.0;
   float Y2 = 4.0;

   float X = (((X2-X1)/w)*x+X1)/1.0;
   float Y = ((((Y2-Y1)/h)*y+Y1)*h/w)/1.0;

   //mat2 z = mat2(sin(X),-cos(Y-X),Y,X);
   //mat2 z = complex(X,Y);
    vec2 surfacePosition = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y * 10.0;
   mat2 z = complex(surfacePosition.x,surfacePosition.y);
    
   //mat2 z = complexp(LZ(z1),PZ(z1)-t);
   const int N = MAX_ITER;
   mat2 fn = z;
   for (int n=0;n<N;n++)
   {
      fn = t1(fn);
   }
   mat2 f = fn;
   f = cpow(f,CI);
   float phase = PZ(f);
   float c = phase/pi;
#if 0
   glFragColor = vec4(vec3(abs(c)),1.0);
#else
   if (c>=0.0 && c<=0.5)
   {
      glFragColor = vec4(2.0*c,0.0,0.0,1.0);
   }
   if (c>0.5 && c<=1.0)
   {
      glFragColor = vec4(1.0,c*2.0-1.0,c*2.0-1.0,1.0);
   }
   if (c<0.0 && c>=-0.5)
   {
      glFragColor = vec4(0.0,abs(c)*2.0,0.0,1.0);
   }
   if (c<-0.5 && c>-1.0)
   {
      glFragColor = vec4(abs(c)*2.0-1.0,1.0,abs(c)*2.0-1.0,1.0);
   }
#endif   
}
