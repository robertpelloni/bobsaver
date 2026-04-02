#version 420

// original https://www.shadertoy.com/view/WtjyWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a){
    return mat2(cos(a),-sin(a),sin(a),cos(a));
}

float box( vec3 p, vec3 b ) {
     vec3 d = abs(p) - b;
     return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float cros(vec3 p){
    return min(box(p.xyy,vec3(1,1,9999)),min(box(p.xxz,vec3(1,9999,1)),box(p.yyz,vec3(9999,1,1))));
}

float sponge(vec3 p, float size){
    float res = box(p,vec3(size));
    float c = 2.*size;
    float crSiz =3.; 
    for(int i = 0; i < 4; i++){
      vec3 q = mod(p+0.5*c,c)-0.5*c;
      float subt = cros(q*(crSiz/size))/(crSiz/size);  
      res=max(-subt,res);
      c/=3.;
      crSiz*=3.;
    }
    return res;
}
float map(vec3 p){
    return sponge(p,1.7);
}

vec3 normal(vec3 p){
    vec2 e = vec2(0,0.01);
    return normalize(vec3(map(p+e.yxx)-map(p-e.yxx),
                map(p+e.xyx)-map(p-e.xyx),
                map(p+e.xxy)-map(p-e.xxy))); 
}

vec3 addLight(vec3 lightCol, vec3 lightdir,vec3 rd){
    vec3 light = vec3(0.);
    float li = max(dot(lightdir,rd),0.);
    light+=pow(lightCol,vec3(2))*pow(li,2.);
    light+=lightCol*pow(li,200.9);
    return light;
}

vec3 skyColor(vec3 rd){
    vec3 outLight = vec3(0.125);
    outLight+=addLight(10.*vec3(0.7,0.2,0.3),normalize(-vec3(0.2,0.05,0.2)),rd);
    outLight+=addLight(10.*vec3(0.1,0.3,0.7),normalize(-vec3(-0.2,0.05,-0.2)),rd);
    return outLight;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.x;
    vec3 ro = vec3(0.,0.,-11.);
    vec3 rd = normalize(vec3(uv,1));
    rd.xy*=rot(time/8.);
    ro.xz*=rot(time/8.);
    rd.xz*=rot(time/8.);   
    vec3 color = vec3(0);
    vec3 accum = vec3(0);
    float tot = 0.;
    for(int i = 0; i<80;i++){
        vec3 p = ro+rd*tot;
        float dst = map(p);
        tot+=dst;
        vec3 n = normal(p);
        if(dst>0.01){
            color = skyColor(rd)/2.;
        }
        else{    
            color  = vec3(tot/1000.);    
        }
        accum+=color*0.04;
    }
    glFragColor = vec4(1.-(accum),1.0);
}
