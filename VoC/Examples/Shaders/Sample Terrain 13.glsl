#version 420

// original https://www.shadertoy.com/view/fddXWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rotate2D(float r){
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}

void main(void)
{
    float i,e,f,s,g,k=.01;    
    float o;    
    o++;    
    for(int i=0;i<100;i++)
    {
      s=2.;      
      g+=min(f,max(.03,e))*.3;      
      vec3 p=vec3((gl_FragCoord.xy-resolution.xy/s)/resolution.y*g,g-s);
      p.yz*=rotate2D(-.8);
      p.z+=time;
      e=p.y;
      f=p.y;
      for(;s<200.;)
      {
        s/=.6;
        p.xz*=rotate2D(s);
        e+=abs(dot(sin(p*s)/s,p-p+.4));
        f+=abs(dot(sin(p.xz*s*.6)/s,resolution.xy/resolution.xy));
      }

      if(f>k*k)
        o+=e*o*k;
      else
        o+=-exp(-f*f)*o*k;

    }
    glFragColor = vec4(o);
}
