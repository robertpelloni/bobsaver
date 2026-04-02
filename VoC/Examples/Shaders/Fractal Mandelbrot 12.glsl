#version 420

// original https://www.shadertoy.com/view/3sGfRy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float ITERATIONS = 256.0;
float LIMIT = 4.0;

vec4 hsv2rgb(vec3 c) {
  vec3 rgb = clamp(abs(mod(c.x*6.+vec3(1.,2.,2.),6.)-3.)-1.,0.,1.);
  //vec3 rgb = clamp(abs(mod(c.x*6.+vec3(0.,4.,2.),6.)-3.)-1.,0.,1.);

  rgb = rgb * rgb * (3.0 - 2.0 * rgb);
  vec3 color = c.z * mix(vec3(1.0), rgb, c.y);
   return vec4(color,1);
}

vec4 colormap(float i)
{
    if(i == ITERATIONS)
        return vec4(0,0,0,1);
    vec3 hsv = vec3(float(i)/ITERATIONS,1,1);
    
    return hsv2rgb(hsv);
}

vec4 MandelbrotColor( vec2 c )
{
    vec2 z = vec2(0,0);
    float i = 0.0;
    for (i=0.0;i<ITERATIONS;i++) {
    
    //Z = Z^2 + C - Algorithm for mandlebrot set
    vec2 znew = vec2(z.x * z.x - z.y *z.y, 2.0 * z.x* z.y) + c;
      if (dot(znew,znew) > LIMIT)
         break;
         z = znew;
   }
   
   return colormap(i);
}

void main(void)
{
    
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    //Shrank image to see the whole of the set
    uv = (2.5 *gl_FragCoord.xy - resolution.xy) / resolution.xy;
    //Centres image 
    uv -= vec2(0.3, -0.3);
    uv.x *= resolution.x/resolution.y;
    
            /* POINTS OF INTEREST
    vec2 centre = vec2(-0.761574, -0.0847596);
    vec2 centre = vec2(-0.412 , 0.609);
    vec2 centre = vec2(0.278039575 , -0.007910056);
    vec2 centre = vec2(-0.107631967 , -0.908353935);
    vec2 centre = vec2(-0.290693391 , 0.670809656);*/
    vec2 centre = vec2(-0.384264141 , -0.600523952);
    
    float angle = time* 0.75;
    mat2 rotationMatrix = mat2( cos(angle), sin(angle),
                                   -sin(angle),  cos(angle));
                                
    //Makes a cos curve that oscillates equally above / below 0, used minus to start zoomed out
    float cc = 4.5*-cos(0.25 * time) + 4.25; 
    //Smooths out the curve, making it less erratic 
    float zoom = pow(0.25, cc);
    //Zooms in and out on the centre coordinates
    uv *= zoom;
    uv += centre;
    //Applies rotation matrix about centre point
    uv = rotationMatrix *(uv - centre) + centre ;
    
    // Output to screen
    glFragColor = MandelbrotColor(uv);
}
