#version 420

// original https://www.shadertoy.com/view/4cXfW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int N = 4;

// SDF from IQ
float sdPolygon( in vec2[N] v, in vec2 p )
{
    float d = dot(p-v[0],p-v[0]);
    float s = 1.0;
    for( int i=0, j=N-1; i<N; j=i, i++ )
    {
        vec2 e = v[j] - v[i];
        vec2 w =    p - v[i];
        vec2 b = w - e*clamp( dot(w,e)/dot(e,e), 0.0, 1.0 );
        d = min( d, dot(b,b) );
        bvec3 c = bvec3(p.y>=v[i].y,p.y<v[j].y,e.x*w.y>e.y*w.x);
        if( all(c) || all(not(c)) ) s*=-1.0;  
    }
    return s*sqrt(d);
}

// 3d simplex noise from https://www.shadertoy.com/view/XsX3zB
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
     vec3 s = floor(p + dot(p, vec3(F3)));
     vec3 x = p - s + dot(s, vec3(G3));
     
     /* calculate i1 and i2 */
     vec3 e = step(vec3(0.0), x - x.yzx);
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
     return dot(d, vec4(52.0));
}

float TAU = 2.*3.14159;

void main(void)
{
   vec2 uv = ( gl_FragCoord.xy - .5* resolution.xy ) /resolution.y;
   vec3 col = vec3(0.);   
   float tt = fract(.3*time);
     
   float scale = 35.;
   uv *= scale;  
   vec2 cellID = round(uv);
   uv = fract(uv +.5) - .5;
   
   float nS = 5.;
   float minVal = 1E20;
   for (float i = -1.; i <= 1.; i++)
     for(float j = -1.; j <= 1.; j++){
     
       float off = fract(324.6*sin(46.7*(cellID.x + i)) + 641.*sin(33.1*(cellID.y + j)));
     //  float off = simplex3d(vec3(cellID.x + i, cellID.y + j, 1.0));
       
       // Switch to see the connected polygon mesh
       // float meshDim = .5;
       float meshDim = .25 + .2*sin(TAU*(tt + off));
     
       vec2 uvCenter = (cellID + vec2(i,j)) / scale;   
       float v1delta = 3.*TAU*simplex3d(vec3(uvCenter + vec2(-meshDim/scale,meshDim/scale), nS));
       float v2delta = 3.*TAU*simplex3d(vec3(uvCenter + vec2(-meshDim/scale,-meshDim/scale), nS));
       float v3delta = 3.*TAU*simplex3d(vec3(uvCenter + vec2(meshDim/scale,-meshDim/scale), nS));
       float v4delta = 3.*TAU*simplex3d(vec3(uvCenter + vec2(meshDim/scale,meshDim/scale), nS));
      
       vec2[4] verts; 
       float r = 1.;
       verts[0] = vec2(i,j) + vec2(-meshDim,meshDim) + vec2(r*sin(TAU*tt + v1delta),r*cos(TAU*tt + v1delta));
       verts[1] = vec2(i,j) + vec2(-meshDim,-meshDim)+ vec2(r*sin(TAU*tt + v2delta),r*cos(TAU*tt + v2delta));
       verts[2] = vec2(i,j) + vec2(meshDim, -meshDim)+ vec2(r*sin(TAU*tt + v3delta),r*cos(TAU*tt + v3delta));
       verts[3] = vec2(i,j) + vec2(meshDim, meshDim) + vec2(r*sin(TAU*tt + v4delta),r*cos(TAU*tt + v4delta));;
  
       float poly = sdPolygon(verts, uv);
       minVal = min(poly, minVal);
     }

 
  minVal = abs(minVal) - .1;
  
  float w = 36./resolution.y;
   
  col += smoothstep(w,-w,minVal);
   
    
   glFragColor = vec4(col,1.0);
} 
