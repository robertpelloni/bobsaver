#version 420

// original https://www.shadertoy.com/view/Nt2Szw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Made with love by Peleg Gefen <3

//#define Time_And_Zoom //Allows you to use the horizontal mouse axis to "peek into the future" to see the full evolution of the wave.

//#define Grass_Like //Animates the cubes in a cool low poly growing grass thing.

vec2 rot (vec2 p,float a)
{
    float c = cos(a);
    float s = sin(a);
    return p*mat2(c,s,-s,c);
}

float hexDist(vec2 p) {
    p = abs(p);
    //distance to the diagonal line
    float c = dot(p, normalize(vec2(1., 1.73)));

    // distance to the vertical line
    c = max(c, p.x);
    c += sin(time + 4000.) *5. +5.;
    return c;
  }

vec4 hexCoords(vec2 uv) {
    vec2 r = vec2(1., 1.73);
    vec2 h = r * 0.5;
    vec2 a = mod(uv, r) - h;
    vec2 b = mod(uv - h, r) - h;

    vec2 gv;
    if(length(a) < length(b))
      gv = a;
    else
      gv = b;

    float y = .5 - hexDist(gv);
    float x = atan(gv.x, gv.y);
    vec2 id = uv - gv;
    return vec4(x, y, id.x, id.y);

}
void main(void)
{
    float time = time * .25;
    time += 800.;
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)
    /resolution.y;
    
    
     vec4 col = vec4(0.);
     vec2 uv1 = uv;
     //uv *= 3.;
     uv -= 2.;
     uv *= (sin(time * .75)*1.5+1.5) + 3.;
     uv += vec2(time *     .01);

     #ifdef Time_And_Zoom
     time += mouse*resolution.xy.x * 10.;
     uv *= mouse*resolution.xy.y * .007;
     #else
     uv -= (mouse*resolution.xy.xy / resolution.xy) * 2. ;
     #endif

     uv += rot(uv , (cos(time)*.5+.5));

 
 
     vec4 uvid = hexCoords(uv * 2.);
     
     float t = smoothstep(.5,.5
          ,uvid.y 
          * sin(( length(uvid.zw))
           * time *0.1)*.5+.5);
   
    
    col = vec4(
    t * tan(time * .5)*.5+.5 * sin(time * 2.5)*.5+.5
    , t*cos(time * .25)*.5+.5* sin(time * 5.)*.5+.5
    , t * sin(time * .1275)*.5+.5 * sin(time * 10.)*.5+.5
    ,1.);
    
    
         
         
    //lit face
    col += vec4(smoothstep(.99,.991,uvid.x));
    
    
    //shading
    col += vec4(smoothstep(-1.,-1.,uvid.x)) * .4;

      
      //hexagons shrinking and expanding, wave form
      col *= vec4(smoothstep(.000001,.00001
          ,uvid.y 
        
        #ifdef Grass_Like
          * uvid.x
        #endif
        * sin(( length(uvid.zw))
           * time *.01)*.5+.5));
         
      
    glFragColor = vec4( col);
}
