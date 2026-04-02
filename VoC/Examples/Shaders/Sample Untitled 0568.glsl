#version 420

// original https://www.shadertoy.com/view/wtfcRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define E 0.01
#define INF 1000.0
#define MAXT 200.0

vec2 rot( vec2 p, float l ){
  return vec2(
    cos(l)*p.x - sin(l)*p.y,
    sin(l)*p.x + cos(l)*p.y
  );
}

vec3 mapLight;

float map(vec3 p){
  float r=p.z+1.0, rc;
  vec3 ph;
  mapLight= vec3(INF);
  
  r= min( r, length(p) );
  
  ph= p;
  ph.y= mod( ph.y, 7.0 ) - 3.5;
  ph.x= mod( ph.x - 0.0, 4.0 ) - 2.0;
  rc= length(ph.xy) - 0.1;
  ph.z= mod( ph.z - time, 8.0 ) - 4.0;
    //rc= min( rc, length(ph)-0.2-0.1*texture( texFFT, 0.01 ).r );
    rc= min( rc, length(ph)-0.2);
    r= min( r, rc );
  
  ph= p;
  ph.y= mod( ph.y, 5.0 ) - 2.5;
  ph.x= mod( ph.x - 2.0, 4.0 ) - 2.0;
  
  rc= length( vec2( ph.y, length(ph.xz)-3.0 ) )-0.1;
  r= min( r, rc );
  
  ph= p;
  ph.y= mod( ph.y, 4.0 ) - 2.0;
  ph.xz= rot( ph.xz, 4.0*time + 0.1*p.y );
  ph.z -= 5.0;
  rc= length(ph);
  r= min( r, rc );
  mapLight.x= min( mapLight.x, rc );

  ph= p;
  ph.y= mod( ph.y, 4.0 ) - 2.0;
  ph.xz= rot( ph.xz, -4.0*time - 0.1*p.y );
  ph.z -= 5.0;
  rc= length(ph);
  r= min( r, rc );
  mapLight.y= min( mapLight.y, rc );
  
  ph= p;
  ph.y= mod( ph.y, 4.0 ) - 2.0;
  ph.x -= 7.0 * sin( time + 0.1 * p.y );
    //ph.z -= 2.0 + 1000.0*texture( texFFT, fract(0.1*p.y) ).r + sin(8.0*time+0.1*p.y);
    ph.z -= 2.0 + sin(8.0*time+0.1*p.y);
  rc= length(ph);
  r= min( r, rc );
  mapLight.z= min( mapLight.z, rc );
  
  return r;
}

vec3 render( vec3 sp, vec3 dir ){
  vec3 r= vec3(0);
  vec3 light= vec3(INF);
  float power = 1.0;
  
  for( int i=0;i<2;i++){
    vec3 p= sp;
    float dis= map(p);
    float t= dis;
    
    for( int i=0;i<0x100;i++){
      p= sp + t*dir;
      dis= map(p);
      light= min( light, mapLight );
      t += dis;
      if( dis < E && MAXT < t ){
        break;
      }
    }
    
    vec3 plight= mapLight;
    vec3 nor;
    
    if( t < MAXT ){
      
      nor= normalize(vec3(
        map(vec3(p.x+E,p.y,p.z))-map(vec3(p.x-E,p.y,p.z)),
        map(vec3(p.x,p.y+E,p.z))-map(vec3(p.x,p.y-E,p.z)),
        map(vec3(p.x,p.y,p.z+E))-map(vec3(p.x,p.y,p.z-E))
      ));
      
      r= vec3(power)
        * (0.5+0.5*dot(nor,-dir))
        * (0.5+0.5*dot(nor,vec3(0,0,1)))
        * (1.0 / (1.0 + t ) )
      ;
      r += power * (1.0 / (1.0 + 2.1*plight ) );
      
      
      dir= reflect( dir, nor );
      sp= p;
      power *= 0.1;
      
    }else{
      break;
    }
  }
  
  return r
     + ( 1.0 / (1.0 + light ) )
  ;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy - vec2(.5);
    uv.x *= resolution.x / resolution.y;
     
    vec3 dir= normalize( vec3( uv.x, 4.0, uv.y ) );
  
    glFragColor.xyz= render( vec3( 0, 40.0*time, 1 ), dir );
}
