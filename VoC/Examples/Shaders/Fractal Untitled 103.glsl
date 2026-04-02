#version 420

// original https://www.shadertoy.com/view/DsBGWd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// set antialiasing to 1.0 for more fps
#define AA 2.0

void main(void)
{
    float minres = min(resolution.x, resolution.y);
    
    float t = time*0.333;
    float r = t*0.2;
    mat2 rot = mat2(cos(r), sin(r), -sin(r), cos(r));
    
    float zoomBase = (-cos(t*0.2)*0.5+0.5005);
    float zoom = zoomBase*10000.+500.0; 
    
    vec2 center = vec2(0.37);
    
    vec3 aacol = vec3(0);
    float B = 256.0;
    float maxi = zoomBase*40.0+90.0;
    
    // https://www.shadertoy.com/view/csS3Wd
    for (float x = 0.0; x < AA; x++) {
      for (float y = 0.0; y < AA; y++) {
         vec2 uv = 0.5*((2.0*gl_FragCoord.xy+vec2(x,y))-resolution.xy)/minres/zoom;
         uv = uv*rot + center;
    
      
      
        // https://iquilezles.org/articles/msetsmooth/
        float n = 0.0;
        vec2 z  = vec2(0.0);

        for( float i=0.0; i<maxi; i++ ) {
          z = vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + uv;
          if( dot(z,z)>(B*B) ) break;
          n += 1.0;
        }

        float v = n - log2(log2(dot(z,z))) + 4.0;
        float val = 
          (1.0-smoothstep((maxi-1.0)/1.8, (maxi-1.0), v)) * 
          smoothstep(0.45, 0.5, abs(1.0 - mod(v+t*3.0, 2.0)));
        aacol += vec3(val);
      }
    }
    aacol /= (AA*AA);
    aacol = pow(aacol,vec3(0.4545));
    glFragColor = vec4(aacol,1);
}
