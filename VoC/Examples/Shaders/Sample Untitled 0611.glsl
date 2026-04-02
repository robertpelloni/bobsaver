#version 420

// original https://www.shadertoy.com/view/WtVfzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float ni(float x) {
    //return texture(texFFTIntegrated, x).x;
    return 0.0;//texelFetch( iChannel0, ivec2(x * 512.,0), 0 ).x * .0;
}

float hash13(vec3 p) {
    p  = fract(p * .1031);
    p += dot(p, p.zyx + 31.32);
    return fract((p.x + p.y) * p.z);
}

vec3 hash33(vec3 p3) {
    vec3 p = fract(p3 * vec3(.1031,.11369,.13787));
    p += dot(p, p.yxz+19.19);
    return -1.0 + 2.0 * fract(vec3((p.x + p.y)*p.z, (p.x+p.z)*p.y, (p.y+p.z)*p.x));
}

mat2 rot(float a) {
    float c = cos(a);
    float s = sin(a);
  
    return mat2(c, s, -s, c);
}

const float F3 =  0.3333333;
const float G3 =  0.1666667;
float snoise(vec3 p) {
    vec3 s = floor(p + dot(p, vec3(F3)));
    vec3 x = p - s + dot(s, vec3(G3));
     
    vec3 e = step(vec3(0.0), x - x.yzx);
    vec3 i1 = e*(1.0 - e.zxy);
    vec3 i2 = 1.0 - e.zxy*(1.0 - e);
         
    vec3 x1 = x - i1 + G3;
    vec3 x2 = x - i2 + 2.0*G3;
    vec3 x3 = x - 1.0 + 3.0*G3;
     
    vec4 w, d;
     
    w.x = dot(x, x);
    w.y = dot(x1, x1);
    w.z = dot(x2, x2);
    w.w = dot(x3, x3);
     
    w = max(0.6 - w, 0.0);
     
    d.x = dot(hash33(s), x);
    d.y = dot(hash33(s + i1), x1);
    d.z = dot(hash33(s + i2), x2);
    d.w = dot(hash33(s + 1.0), x3);
     
    w *= w;
    w *= w;
    d *= w;
     
    return dot(d, vec4(52.0));
}

float snoiseFractal(vec3 m) {
    return   0.5333333* snoise(m)
                +0.2666667* snoise(2.0*m)
                +0.1333333* snoise(4.0*m)
                +0.0666667* snoise(8.0*m);
}

float fbm (in vec3 st, int o) {
    // Initial values
    float value = 0.0;
    float amplitude = .5;
    float frequency = 0.;
    //
    // Loop of octaves
    for (int i = 0; i < o; i++) {
        value += amplitude * snoise(st);
        st *= 2.;
        amplitude *= .5;
    }
    return value;
}

float worley(vec3 p, float scale){

    vec3 id = floor(p*scale);
    vec3 fd = fract(p*scale);

    float n = 0.;

    float minimalDist = 1.;

    for(float x = -1.; x <=1.; ++x){
        for(float y = -1.; y <=1.; ++y){
            for(float z = -1.; z <=1.; ++z){

                vec3 coord = vec3(x,y,z);
                vec3 rId = hash33(mod(id+coord,scale))*0.5+0.5;

                vec3 r = coord + rId - fd; 

                float d = dot(r,r);

                if(d < minimalDist){
                    minimalDist = d;
                }

            }//z
        }//y
    }//x
    
    return 1.0-minimalDist;
}

float wfbm (in vec3 st, int o, float s) {
    // Initial values
    float value = 0.0;
    float amplitude = .5;
    float frequency = 0.;
    //
    // Loop of octaves
    for (int i = 0; i < o; i++) {
        value += amplitude * worley(st, s);
        st *= 2.;
        amplitude *= .5;
    }
    return value;
}

float sdSphere(vec3 p, vec3 pos, float r) {
    return length(p + pos) - r;
}

float sdBox(vec3 p, vec3 pos, vec3 b) {
    p += pos;
    //p.xz *= rot(0.6);
    //p.xy *= rot(0.5);
  
    p.xz *= rot(time + ni(0.4));
    p.xy *= rot(time + ni(0.2));
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

vec2 map(vec3 p) {
    return vec2(sdBox(p, vec3(0.,0.,5. + sin(ni(0.1) * 100.)), vec3(1., 1., 1.)), 0.);
}

const vec3 sundir = normalize( vec3(0.0,-1.0,-0.0) );

vec3 tr(vec3 ro, vec3 rd, vec2 uv) {
    float td = 1.;
    vec2 h;
  
    vec4 sum = vec4(0);
  
    for (int i = 0; i < 100; i++) {
        h = map(ro + rd * td);
        td += max(h.x, 0.01);
        
            vec3 ip = ro + rd * td;
        if (h.y == 0. && h.x < 0.01) {
            ip.yz *= rot(time / 10.);
            ip.xz *= rot(time / 10.);
            float w = smoothstep(0.6, 1., worley(ip, 2.));
            float s = snoiseFractal(ip*3.);
            float f = fbm(ip, 8);
          
            //return vec3(1);
            // F = 1/ e ^(t * d).
            //c += f * 0.01 * exp(-h.x * 2);
            //return vec3(w);
            float den = f;
            
            if (den > 0.01) {
               float df = fbm(ip + 0.1 * sundir, 8);
               // do lighting
               float dif = clamp((den - df)/0.3, 0.0, 1.0 );
               vec3  lin = vec3(0.65,0.65,0.75)*1.1 + 0.8*vec3(sin(ip.x + time),0.6,cos(ip.y + time))*dif;
               //return vec3(lin);
               vec4  col = vec4( mix( vec3(cos(ip.y + time / 2.) + 0.5,0.95,sin(time / 3. + ip.z) + 0.5), vec3(0.25,0.3,0.35), den ), den );
                
               col.xyz *= lin;
               // fog
               //col.xyz = mix(col.xyz,vec3(0,0,0), 1.0-exp2(-0.075*t));
              
              
                //return col.xyz;
               // composite front to back
               //col.w    = min(col.w*8.0*h.x,1.0);
               //col.rgb *= col.a;
              
               sum += col*0.01*(1.0-sum.a);
            }
            
        }
    }
    
    return sum.xyz;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);
  
  vec3 ro = vec3(0,0,2);
  vec3 rd = normalize(vec3(uv, 0) - ro);
  
  float w = smoothstep(0.6, 1., worley(vec3(uv * 3., time / 20.), 2.));
  float s = snoise(vec3(uv, time));
  float sf = snoiseFractal(vec3(uv, time));
  float f = fbm(vec3(uv.x, uv.y, time), 8);
  float wf = smoothstep(0.2, 1., wfbm(vec3(uv.x, uv.y, time / 10.), 3, 4.));
  float wff = wf * f;
  
  //out_color = vec4(vec3(wff),1);
  
  
  glFragColor = vec4(tr(ro, rd, uv), 1);
}
