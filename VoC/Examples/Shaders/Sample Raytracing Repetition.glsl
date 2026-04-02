#version 420

// original https://www.shadertoy.com/view/4lSGzG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* with help from: http://www.iquilezles.org/www/articles/distfunctions/distfunctions.html */
float PI=3.14159265;

vec2 obj_floor(in vec3 p)
{
     return vec2(p.y+10.0,0);
}

vec2 obj_union(in vec2 obj0, in vec2 obj1)
{
    if (obj0.x < obj1.x)
        return obj0;
    else
        return obj1;
}

vec2 obj_round_box(vec3 p)
{
      float d = length(max(abs(p)-vec3(2.0,0.5,2.0),0.0))-0.2;
     return vec2(d,1);
}

vec2 op_rep(vec3 p, vec3 c)
{
      vec3 q = mod(p,c)-0.5*c;
      return obj_round_box(q);
}

vec2 distance_to_obj(in vec3 p)
{
      return obj_union(obj_floor(p), op_rep(p, vec3(8.0, 8.0, 8.0)));
}

//Floor Color (checkerboard)
vec3 floor_color(in vec3 p)
{
    if (fract(p.x*0.2)>0.2)
      {
        if (fract(p.z*0.2)>0.2)
              return vec3(0,0.1,0.2);
        else
              return vec3(1,1,1);
      }
      else
      {
        if (fract(p.z*.2)>.2)
              return vec3(1,1,1);
            else
              return vec3(0.3,0,0);
       }
}

vec3 prim_c(in vec3 p)
{
      return vec3(sin(time*0.6),cos(time),0.8);
}

void main(void)
{
      vec2 vPos = gl_FragCoord.xy/resolution.xy - 0.5;

      // Camera up vector.
      vec3 vuv=vec3(0,1,0); 
  
      // Camera lookat.
      vec3 vrp=vec3(0,0,0);

      vec3 prp=vec3(cos(time)*sin(time),cos(time)*0.5,cos(time)*cos(time))*6.0; 
    
      // Camera setup.
      vec3 vpn=normalize(vrp-prp);
      vec3 u=normalize(cross(vuv,vpn));
      vec3 v=cross(vpn,u);
    vec3 vcv=(prp+vpn);
      vec3 scrCoord=vcv+vPos.x*u*resolution.x/resolution.y+vPos.y*v;
      vec3 scp=normalize(scrCoord-prp);

      // Raymarching.
      const vec3 e=vec3(0.02,0,0);
      const float maxd=100.0; //Max depth
      vec2 d=vec2(0.1,0.0);
      vec3 c,p=vec3(0.0),N;

      float f=1.0;
      for(int i=0;i<256;i++)
      {
        if ((abs(d.x) < .001) || (f > maxd)) 
              break;
    
        f+=d.x;
        p=prp+scp*f;
        d = distance_to_obj(p);
      }
  
     if (f < maxd)
      {
        // y is used to manage materials.
        if (d.y==0.0) 
              c=floor_color(p);
        else
              c=prim_c(p);
    
        vec3 n = vec3(d.x-distance_to_obj(p-e.xyy).x,
                  d.x-distance_to_obj(p-e.yxy).x,
                  d.x-distance_to_obj(p-e.yyx).x);
        N = normalize(n);
        vec3 L = vec3(sin(time)*40.0,10,cos(time)*20.0);
        float b=dot(N,normalize(prp-p+L));
        //simple phong lighting, LightPosition = CameraPosition
        glFragColor=vec4((b*c+pow(b,16.0))*(1.0-f*.01),1.0);
      }
      else 
        glFragColor=vec4(0,0,0,1); //background color
}
