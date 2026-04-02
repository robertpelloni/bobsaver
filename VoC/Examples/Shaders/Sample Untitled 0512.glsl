#version 420

// original https://neort.io/art/bp9qtes3p9fcqlgn9mtg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float beat = 60.0/135.0;

float PI = acos(-1.0);

float hash(vec2 p){
  return fract(45316.13616 * sin(dot(p,vec2(12.451,79.631))));
}

mat2 rot(float a){
  float c =cos(a),s = sin(a);
  return mat2(c,s,-s,c);
}

float rect(vec2 p){
  return step(p.x,0.95) * step(0.05,p.x) * step(p.y,0.95) * step(0.05,p.y);
}

float tex(vec2 p){
  p *= 2.0;
  vec2 ip = floor(p);
  vec2 fp = fract(p);

  float h = hash(ip + floor(time * beat * 16.0));
  float c = 0.0;
  if(fp.x < h){
    fp.x/=h;
    h =hash(ip + vec2(h));
    c = h;
  } else{
    h = hash(ip - vec2(h));
    fp.x = (fp.x -h)/(1.0 -h);
  }

  if(fp.y < h){
    fp.y /= h;
    c = h;
    h = hash(ip + vec2(h));
  } else{
    fp.y = (fp.y - h)/(1.0 -h);
    h = hash(ip - vec2(h));
    c = h;
  }

  c = rect(fp);

  return c;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x,resolution.y);
    float t = beat *time *2.0;
    float t0 = mod(t,beat);
    float t1 = mod(t - beat,beat);
    t0 = clamp(t0,0.0,beat * 0.5);
    t1 = clamp(t1,0.0,beat * 0.5);
    vec2 p = uv;// * fract(t * 4.0);

    p *= rot(t);
    p += vec2(0.55,0.25);
    float r0 =length(p);
    float th =atan(p.x,p.y)/PI;

    p = vec2(r0,th + time * 0.125);
    p.x *= 0.5 + 1.0 - fract(t * 2.0);
    float c = tex(p * vec2(1.0 - pow(t0,2.0) * 2.0,1.0)) *( 0.0 + smoothstep(0.0,1.0,t0));
    float c1 = tex(p * vec2(1.0 - pow(t1,2.0) * 2.0,1.0)) *(0.0 + smoothstep(0.0,1.0,t1));
    c += c1;
    c *= 3.0;
    float r = length(uv) - 1.0 *(1.0 + fract(time));
    float rc = p.x;
    rc = smoothstep(0.1,0.0,rc);
    // c = mix(c,0.0,rc);

    vec3 co = mix(vec3(0.8,0.7,0.6),vec3(0.0),c);
    co = mix(co,vec3(0.0),r);
    co = mix(co,vec3(1.0),rc);
    glFragColor = vec4(co,1.0);
}
