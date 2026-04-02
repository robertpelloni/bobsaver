#version 420

// original https://www.shadertoy.com/view/tl2XD1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int octaves = 4;
  
  float sinnoise(vec3 loc){

      float t = time*0.2;
      vec3 p = loc;

      for (int i=0; i<octaves; i++){
          p += cos( p.xxz * 3. + vec3(0., t, 1.6)) / 3.;
          p += sin( p.yzz + t + vec3(t, 1.6, 0.)) / 2.;
          // p += sin( p.zyx + t * 2. + vec3(0,1.6,t)) / 2.;
          p *= 1.3;
      }

      p += fract(sin(p+vec3(13, 7, 3))*5e5)*.03-.015;

       return dot(p, p);
     // return length(p);

  }
void main(void)
  //void main()
   {
    vec2 uv = .92*(gl_FragCoord.xy - 0.5 * resolution.xy) / min(resolution.y, resolution.x);
    
    float shade = sinnoise(vec3(uv * 5., 1.));
    shade = sin(shade) * .53 + .46;

    glFragColor = vec4(vec3(shade),1.0);
  }
