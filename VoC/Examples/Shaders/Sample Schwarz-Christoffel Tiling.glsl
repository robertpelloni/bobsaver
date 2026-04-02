#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3lsBDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Schwarz-Christoffel tiling
// 
// Colling Patrik, 2020
// - inverse Mobius (use mouse)
// - Schwarz-Christoffel
// - square tiling with cyclic mirroring
// - triangle2hexagon => hexagonal tiling with cyclic mirroring
//
// "The Schwarz-Christoffel mapping:" code is from
// Matthew Arcus, 2020.    https://www.shadertoy.com/view/tsfyRj
//
// NOTE:
// The code has not been optimized for demonstration reasons;
// SEE:TODO:
// - triangle tiling with normalized barycentric coord's
//     FabriceNeyret2 https://www.shadertoy.com/view/XdKXz3
// - hexagonal tiling
//   Matthew Arcus https://www.shadertoy.com/view/WsjXWm
////////////////////////////////////////////////////////////////////////////////

// const
const float PI = 3.14159265359,
    PI_2 = PI/2., PI_3 = PI/3., PI_4 = PI/4., PI_6 = PI/6.,
    SQRT2 = sqrt(2.), SQRT_2 = 1./SQRT2,  
    SQRT3 = sqrt(3.), SQRT_3 = 1./SQRT3;

// 1D-transformations: float => float
float csteps(float x,float b){
    //centered step, step width b
    return b*floor((x/b+0.5));
}
float signeveodd(float x){
    return sign(mod(x-0.5,2.)-1.);
}
float smoothpuls(float x,float b){
    return smoothstep(abs(b),0.,abs(x));
}
    
// 2D-transformations: vec2 => vec2
// complex operations
vec2 cmul(vec2 z, vec2 w) {
  return vec2(z.x*w.x-z.y*w.y,
              z.x*w.y+z.y*w.x);
}
vec2 cinv(vec2 z) {
  return z*vec2(1,-1)/dot(z,z);
}
vec2 cdiv(vec2 z, vec2 w) {
  return cmul(z,cinv(w));
}
vec2 cpow(vec2 z, int n) {
  float r = length(z);
  float theta = atan(z.y,z.x);
  return pow(r,float(n))*normalize(vec2(cos(float(n)*theta),sin(float(n)*theta)));
}
vec2 rot2(vec2 z,float a){
    float si = sin(a), co = cos(a);
    return mat2(co,-si,si,co)*z;
}
// grid's
vec2 rec2recgrid(in vec2 Z, out vec2 Z_id, out float  z_sr){  
    // given: unit-square inside of the unit-circle
    // with edge orientation pointing in x plus direction
    // maps a grid of unit-squares to one unit-square
    Z = rot2(Z,PI_4);        // F:orientation-offset of cell
    Z/= SQRT_2;                // F:scale cell
    Z_id = 2.*floor(Z*.5+0.5);    // global cell offset id (...,-4,-2,0,+2,+4,...)
    vec2 Z_lo = Z-Z_id;            // local cell coord's
    z_sr = signeveodd(0.5*(Z_id.x+Z_id.y));// sense of rotation of local cell
    Z = Z_lo;                // mape grid-cell to unit-cell
    z_sr = signeveodd(0.5*(Z_id.x+Z_id.y));// sense of rotation of local cell    
    Z_id = vec2(signeveodd(Z_id.x*0.5),signeveodd(Z_id.y*0.5));//(...,-2,-1,0,+1,+2,...)
    Z.x *= Z_id.x;//mirror x
    Z.y *= Z_id.y;//mirror y
    Z *= SQRT_2;            // B:scale cell
    Z = rot2(Z,-PI_4);    // B:orientation-offset of cell
    return Z;
}
vec2 hex2hexgrid(in vec2 Z, out vec3 U_id){        
    // given: unit-hexagon inside of the unit-circle
    // with edge orientation pointing in x plus direction
    // maps a grid of unit-hexagons to one unit-hexagon
    // using cubic coordinates 
    // ==> https://www.redblobgames.com/grids/hexagons/
    // ==> https://bl.ocks.org/patricksurry/0603b407fa0a0071b59366219c67abca
    const mat2 M = mat2(SQRT_3,-1.,-SQRT_3,-1.),
        iM = 0.5*mat2(SQRT3,-SQRT3,-1.,-1.);
    Z = rot2(Z,PI_6);        // F:orientation-offset of cell     
    Z = iM*Z/0.75;          // F:scale cell
    vec3 U = vec3(Z.x,-Z.x-Z.y,Z.y);// plane: x+y+z=0
    U_id = 2.*floor(U*0.5+0.5);        // global cell offset id 
    vec3 U_lo = U-U_id;                // local cell coord's
    vec3 aU_lo = abs(U_lo);
    if (aU_lo.x > aU_lo.y && aU_lo.x > aU_lo.z) U_lo.x = -U_lo.y-U_lo.z;
    if (aU_lo.y > aU_lo.z) U_lo.y = -U_lo.x-U_lo.z;
    else U_lo.z = -U_lo.x-U_lo.y;
    Z = U_lo.rb;             // mape grid-zell to unit-zell
    Z = M*Z*0.75;             // B:scale of cell
    return rot2(Z,-PI_6);    // B:orientation-offset of cell  
} 
vec2 tri2hex(in vec2 Z, out float a_id, out float a_cy){
    // given: unit-hexagon inside of the unit-circle
    // with edge orientation pointing in x plus direction
    // maps a grid of unit-hexagons to one unit-hexagon
    Z = rot2(Z,-PI_6);         // orientation adaption  tri2hex ==> hex2hexgrid 
    Z = rot2(Z,PI_3);        // F:orientation-offset of simplex  
    float a = atan(Z.y,Z.x);   
    a_id = floor(a/PI_3+0.5);// global simplex offset id (-3,-2,-1,0,1,2,3)
    float a_lo = a-PI_3*a_id;            // local coord's angle
    a_cy = signeveodd(a/PI_3);            // cycle even +1, odd -1
    Z = rot2(Z,PI_3*a_id);                // mape grid-zell to unit-simplex
    Z = (Z-vec2(SQRT_3,0.))*SQRT3;         // translation,scale unit-simplex
    Z.y *= a_cy;                        // y-mirror cyclic
    return rot2(Z,-PI_3);                // B:orientation-offset of unit-simplex
    }

// 3D-transformations: vec3 => vec3
//color
vec3 hsv2rgb(float h, float s, float v){        // hue, saturation, value
  vec3 rgb = clamp( abs(mod(h*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
  rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing       
  return v * mix( vec3(1.0), rgb, s);
}

// inface: vec2 => bool
bool inudisk(vec2 z){
    // in unit disk
    return (length(z)<1.);
}

bool inupoly(vec2 z,int k){
    const float PI = 3.14159265359;
    // in unit polygon
    k = abs(k);            //poly-num-edges
    bool m = true;        //bit-mask    
    if (k<3) m = false;
    else{   
        float a = PI/float(k);
        float h = cos(a);//
        for (int i=0; i<k; i++){
            float a1 = 2.*a*float(i);
            vec2 w = vec2(cos(a1),sin(a1));
            if(dot(w,z)>h) m = false;
        }
    }
    return m;
}

////////////////////////////////////////////////////////////////////////////////
// This code is from Matthew Arcus, 2020. "The Schwarz-Christoffel mapping:"
// https://www.shadertoy.com/view/tsfyRj
////////////////////////////////////////////////////////////////////////////////
float binomial(float a, int n) {
   float s = 1.0;
   for (int i = n; i >= 1; i--,a--) {
     s *= float(a)/float(i);
   }
   return s;
}
vec2 expi(float x) {
  return vec2(cos(x),sin(x));
}
// The Lanczos approximation, should only be good for z >= 0.5,
// but we get the right answers anyway.
float gamma(float z) {
  const float[8] p = float[](
    676.5203681218851,
    -1259.1392167224028,
    771.32342877765313,
    -176.61502916214059,
    12.507343278686905,
    -0.13857109526572012,
    9.9843695780195716e-6,
    1.5056327351493116e-7
  );
  z -= 1.0;
  float x = 0.99999999999980993; // Unnecessary precision
  for (int i = 0; i < 8; i++) {
    float pval = p[i];
    x += pval/(z+float(i+1));
  }
  float t = z + 8.0 - 0.5;
  return sqrt(2.0*PI) * pow(t,z+0.5) * exp(-t) * x;
}

// The Beta function
float B(float a, float b) {
  return (gamma(a)*gamma(b))/gamma(a+b);
}

// Original Octave/Matlab code for main function:
// w=z(inZ).*( 1-cn(1)*h+(-cn(2)+(K+1)*cn(1)^2)*h.^2+
// (-cn(3)+(3*K+2)*(cn(1)*cn(2)-(K+1)/2*cn(1)^3))*h.^3+
// (-cn(4)+(2*K+1)*(2*cn(1)*cn(3)+cn(2)^2-(4*K+3)*(cn(1)^2*cn(2)-(K+1)/3*cn(1)^4)))*h.^4+
// (-cn(5)+(5*K+2)*(cn(1)*cn(4)+cn(2)*cn(3)+(5*K+3)*(-.5*cn(1)^2*cn(3)-.5*cn(1)*cn(2)^2+
//   (5*K+4)*(cn(1)^3*cn(2)/6-(K+1)*cn(1)^5/24))))*h.^5./(1+h/C^K) );

vec2 inversesc(vec2 z, int K) {
  float cn[6];
  for (int n = 1; n <= 5; n++) {
    cn[n] = binomial(float(n)-1.0+2.0/float(K),n)/float(1+n*K); // Series Coefficients
  }
  float C = B(1.0/float(K),1.0-2.0/float(K))/float(K); // Scale factor
  z *= C; // Scale polygon to have diameter 1
  vec2 h = cpow(z,int(K));
  float T1 = -cn[1];
  float T2 = -cn[2]+float(K+1)*pow(cn[1],2.0);
  float T3 = -cn[3]+float(3*K+2)*(cn[1]*cn[2]-float(K+1)/2.0*pow(cn[1],3.0));
  float T4 = -cn[4]+float(2*K+1)*(2.0*cn[1]*cn[3]+pow(cn[2],2.0)-float(4*K+3)*
                                  (pow(cn[1],2.0)*cn[2]-float(K+1)/3.0*pow(cn[1],4.0)));
  float T5 = -cn[5]+float(5*K+2)*(cn[1]*cn[4]+cn[2]*cn[3]+float(5*K+3)*
            (-0.5*pow(cn[1],2.0)*cn[3]-0.5*cn[1]*pow(cn[2],2.0)+float(5*K+4)*
            (pow(cn[1],3.0)*cn[2]/6.0-float(K+1)*pow(cn[1],5.0)/24.0)));
  vec2 X = vec2(1,0)+h/pow(C,float(K));
  vec2 w = cmul(z,vec2(1,0) + T1*h + T2*cpow(h,2) + T3*cpow(h,3) + T4*cpow(h,4) + cdiv(T5*cpow(h,5),X));
  return w;
}

vec3 getcolor(vec2 z, int K) {
  /**
  if (mouse*resolution.xy.x > 0.0) {
    // Apply an inversion/Mobius transformation
    vec2 m = (2.0*mouse*resolution.xy.xy-resolution.xy)/min(resolution.y,resolution.y); 
    m /= dot(m,m); // m inverted in unit circle
    z -= m;
    z *= (dot(m,m)-1.0)/dot(z,z);
    z += m;
  }
  **/
  // And a rotation (also a Mobius transformation)
  z = rot2(z,0.5*time);
  float r = length(z);
  float theta = atan(z.y,z.x)*1.; //CHANGE: frequenz!!
  vec3 col = hsv2rgb(theta/(2.0*PI),1.0,1.0);
  float A = 4.0;
  float B = 2.0*float(K);
  float a = -log(r)*A;
  float ds = 0.07;
  if (a <= 6.0+ds) {
    a = fract(a);
    float b = fract(theta/PI*B);
    float d = min(min(a,1.0-a),min(b,1.0-b));
    col *= mix(0.2,1.0,smoothstep(-ds,ds,d));
  }
  return col;
}
////////////////////////////////////////////////////////////////////////////////
void main(void) {
  vec2 z = 2.*(2.*gl_FragCoord.xy - resolution.xy)/min(resolution.x,resolution.y);
    
  int K = (3+int(0.2*time)%2);
  //  
  if (K==4){
      vec2 recgrid_id = vec2(0.); float recgrid_sr;
      z = rec2recgrid(z, recgrid_id, recgrid_sr);
  }
  //  
  if (K==3){
  vec3 U_id = vec3(1.,1.,1.); float a_id = 1.; float a_cy =0.;
  z = hex2hexgrid(z, U_id);
  z = tri2hex(z, a_id, a_cy);
  }      
  //
  z = inversesc(z,K);  
  // color  
  vec3 col = vec3(0.5); 
  col = getcolor(z,K);
  glFragColor = vec4(col,1);
}
