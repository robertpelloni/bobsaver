#version 420

// original https://www.shadertoy.com/view/Xs3cDM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}
float sdCross( in vec3 p )
{
  float da = sdBox(p.xyz,vec3(9999.0,1.0,1.0));
  float db = sdBox(p.yzx,vec3(1.0,9999.0,1.0));
  float dc = sdBox(p.zxy,vec3(1.0,1.0,9999.0));
  return min(da,min(db,dc));
}
vec3 map( in vec3 p )
{
   float d = sdBox(p,vec3(1.0));
   vec3 res = vec3( d, 1.0, 0.0);

   float s = 1.0;
   for( int m=0; m<4; m++ )
   {
      vec3 a = mod( p*s, 2.0 )-1.0;
      s *= 3.0;
      vec3 r = abs(1.0 - 3.0*abs(a));

      float da = max(r.x,r.y);
      float db = max(r.y,r.z);
      float dc = max(r.z,r.x);
      float c = (min(da,min(db,dc))-1.0)/s;

      if( c>d )
      {
          d = c;
          res = vec3( d, 0.2*da*db*dc, (1.0+float(m))/4.0 );
       }
   }

   return res;
}
vec3 intersect( in vec3 ro, in vec3 rd ) //RAY TRACING ALGO
{
    for(float t=0.0; t<10.0; )
    {
        vec3 h = map(ro + rd*t); //vec3 dist = sceneSDF(eye + depth * viewRayDirection);
        if( h.x<0.001 )             //if dist.x < EPSILON
            return vec3(t,h.yz);    //return depth
        t += h.x;                //viewRay += "safe distance"
    }
    return vec3(-1.0);
}

void main(void)
{
    vec2 p = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy;
    p.x *= resolution.x/resolution.y;

    float ctime = time;
    // CAMERA
    //ray origin
    vec3 ro = 1.5*vec3(2.5*sin(0.25*ctime),1.0+1.0*cos(ctime*.13),2.0*cos(0.25*ctime));
    vec3 ww = normalize(vec3(0.0) - ro);
    vec3 uu = normalize(cross( vec3(0.0,1.0,0.0), ww ));
    vec3 vv = normalize(cross(ww,uu));
    //ray direction
    vec3 rd = normalize( p.x*uu + p.y*vv + 2.5*ww );

    vec3 col = intersect( ro, rd );
    
    glFragColor = vec4(col,1.0);
}
