#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wtXSDM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//--------------------------------------------------------------------------
// refs.
// https://thebookofshaders.com/13/?lan=jp
// http://www.iquilezles.org/www/articles/warp/warp.htm
// http://www.iquilezles.org/www/articles/palettes/palettes.htm
//--------------------------------------------------------------------------

// t: 0-1, a: contrast, b: brightness, c: times, d: offset
vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(6.28318 * (c * t + d));
}

const int[] font = int[](0x75557, 0x22222, 0x74717, 0x74747, 0x11574, 0x71747, 0x71757, 0x74444, 0x75757, 0x75747);
const int[] powers = int[](1, 10, 100, 1000, 10000, 100000, 1000000);

int PrintInt(in vec2 uv, in float value, const int maxDigits) {
    if(abs(uv.y - .5) < .5) {
        int iu = int(floor(uv.x));
        if(iu >= 0 && iu < maxDigits) {
            int n = (int(value) / powers[maxDigits - iu - 1]) % 10;
            uv.x = fract(uv.x); //(uv.x-float(iu)); 
            ivec2 p = ivec2(floor(uv * vec2(4. ,5.)));
            return (font[n] >> (p.x + p.y * 4)) & 1;
        }
    }
    return 0;
}

// Get random value
float random(in vec2 st)
{
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

#define OCTAVES 4
float fbm(in vec2 st) {
      float value = 0.;
      float amp = .55;
      float freq = 0.;

      for(int i = 0; i < OCTAVES; i++) {
        value += amp * noise(st);
        st *= 2.1;
        amp *= .35;
      }
      return value;
}

float pattern(in vec2 p, float o) {
      float f = 0.;

      vec2 q = vec2(
        fbm(p + o + vec2(0.)),
        fbm(p + o + vec2(2.4, 4.8))
      );

      vec2 r = vec2(
        fbm(q + o + 4. * q + vec2(3., 9.)),
        fbm(q + o + 8. * q + vec2(2.4, 8.4))
      );
      f = fbm(p + r * 2. + time * .09);
    return f;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    uv *= 4.;
    float fr = pattern(uv, time * 1.);    
    float fg = fbm(uv + time + fr * .20);
    float fb = fbm(uv + time + fg * .30);
    
    vec3 lightDir = normalize(vec3(1., 1., 2.));
    vec3 normal = normalize(vec3(fr, fg, fb));
    float angle = clamp(dot(lightDir, normal), 0., 1.);
    vec3 eye = vec3(0., 0., 3.);
    vec3 halfed = reflect(-eye, normal);
    float spec = pow(clamp(dot(halfed, lightDir), 0., 1.), 64.);
    
    vec3 lightColor = vec3(1.);
    
    vec3 objColor = palette(
        (fr + fg + fb) / 3.,
        vec3(.5),
        vec3(.5),
        vec3(4.),
        vec3(.1, .2, .3)
    );
    vec3 specularColor = vec3(objColor * 1.2);
    
    vec3 color = vec3(
        objColor * lightColor * angle +
        specularColor * lightColor * spec
    );
    
    color = pow(color, vec3(.4545));
    
    glFragColor = vec4(color, 1.);
}
