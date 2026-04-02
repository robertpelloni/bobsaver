#version 420

// original https://www.shadertoy.com/view/tlBSzd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 draw_line(float d, float thickness) {
  const float aa = 3.0;
  return vec3(smoothstep(0.0, aa / resolution.y, max(0.0, abs(d) - thickness)));
}
vec3 draw_line(float d) {
  return draw_line(d, 0.0025);
}

float draw_solid(float d) {
  return smoothstep(0.0, 3.0 / resolution.y, max(0.0, d));
}

vec3 draw_distance(float d, vec2 p) {
  float t = clamp(d * 0.85, 0.0, 1.0);
  vec3 grad = mix(vec3(1, 0.8, 0.5), vec3(0.3, 0.8, 1), t);

  float d0 = abs(1.0 - draw_line(mod(d + 0.1, 0.2) - 0.1).x);
  float d1 = abs(1.0 - draw_line(mod(d + 0.025, 0.05) - 0.025).x);
  float d2 = abs(1.0 - draw_line(d).x);
  vec3 rim = vec3(max(d2 * 0.85, max(d0 * 0.25, d1 * 0.06125)));

  grad -= rim;
  grad -= mix(vec3(0.05, 0.35, 0.35), vec3(0.0), draw_solid(d));

  return grad;
}

float rand(float n) {
    return fract(sin(n) * 43758.5453123);
}

float srand(float n) {
    return rand(n)*2.-1.;
}

float lineDist(vec2 p, vec2 start, vec2 end, float width)
{
    vec2 dir = start - end;
    float lngth = length(dir);
    dir /= lngth;
    vec2 proj = max(0.0, min(lngth, dot((start - p), dir))) * dir;
    return length( (start - p) - proj ) - (width / 2.0);
}
float smoothMerge(float d1, float d2, float k)
{
    float h = clamp(0.5 + 0.5*(d2 - d1)/k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0-h);
}
#define PI (3.1415*2.)

void main(void)
{
    vec2 _uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

    float d = 10000000.;
    float i = float(int(time/10.)+1234);
    i = rand(i);
    for(int b=0;b<3;b++){
        vec2 last = vec2(0.0);
        float la = 0.0;
        for(int x=0;x<10;x++){
            float a = srand(i++)*3.1415;
            float s = .5+.5*rand(i++);
            s*=.2;
            // move
            a += smoothstep(-.4,.4,sin(time*1.5))* srand(i++)*.2;
            // preparation
            a += sin(time*3.0)* srand(i++)*.05;
            // breathe
            a += sin(time*1.0)* srand(i++)*.04;
            // pulse
            a += smoothstep(.5,1.,sin(time*6.))* srand(i++)*.01;
            a += la;
            vec2 opos = last + vec2(sin(a),cos(a))*s;
            float bs = rand(i++);
            float ls = rand(i++);
            float ma = rand(i++);
            for(int k=0;k<2;k++){
                vec2 uv = k==1?_uv:_uv*vec2(-1.,1.);

                float o1 = lineDist(uv,opos,last,.02+ls*.03);
                float o2= length( uv - opos)- (.01+bs*.02);
                float o = min(o1,o2);
                d = smoothMerge(d,o,.01 + ma * .05);        
            }        
            la = a;
            last = opos;        
        }
    }

    
    vec3 col = draw_distance(d,_uv);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
