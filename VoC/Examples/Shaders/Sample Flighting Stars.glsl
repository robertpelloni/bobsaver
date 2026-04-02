#version 420

// original https://www.shadertoy.com/view/XlSBDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float TIME;

mat3 lookat(vec3 d, vec3 up)
{
    vec3 w = normalize(d),u = normalize(cross(w,up));
    return (mat3(u,cross(u,w),w));
}

vec3 rotate(vec3 p, vec3 v, float a) 
{
     vec4 q = vec4(sin(a/2.)*v, cos(a/2.)); // quaternion
    return cross(cross(p, q.xyz)-q.w*p, q.xyz)*2.+p;
}

mat2 rotate(float a)
{
    return mat2(cos(a), sin(a), -sin(a), cos(a));    
}

float sdTorus(vec3 p, vec2 t)
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float map(vec3 p)
{   
    p =  rotate(p,normalize(vec3(rotate(TIME/3.)*vec2(1,2),3)),TIME);
    float r = 1.5, s= 0.05;
    float n = radians(72.);
    p.xy *= rotate(floor(atan(-p.x, p.y) / n) * n-radians(54.));
    float de = 1.;
    de = min(de,sdTorus(p,vec2(r,s)));
    float h = 3., b = radians(90.)/h;    
    for(float i=0.;i<h;i++)
    {
        vec3 q =p;
        float a = b*i;
        q.z = abs(q.z)-r*sin(a);
        de = min(de,sdTorus(q.xzy,vec2(r*cos(a),s)));
    }
    return de;
}

vec3 calcNormal(vec3 pos){
  vec2 e = vec2(1,-1) * 0.002;
  return normalize(
    e.xyy*map(pos+e.xyy)+e.yyx*map(pos+e.yyx)+ 
    e.yxy*map(pos+e.yxy)+e.xxx*map(pos+e.xxx)  );
}

vec3  hsv(float h,float s,float v)
{
    return((clamp(abs(fract(h+vec3(0,2,1)/3.)*6.-3.)-1.,0.,1.)-1.)*s+1.)*v;
}

vec3 doColor(vec3 p)
{
    return hsv(0.05, 1., 1.);
}

vec3 billboard(vec3 ro, vec3 rd, vec3 pos, vec3 nor, vec3 up)
{
    float z = dot(pos-ro,nor)/dot(rd,nor);
    vec3 p=ro+rd*z, a=p-pos, u=normalize(cross(nor,up)), v=normalize(cross(u,nor));
    return vec3(dot(a,u),dot(a,v),z);
}

// https://www.shadertoy.com/view/XlXcW4
vec2 hash(float p)
{
    uvec2 x = uvec2(p*vec2(0x1234,0x5678));
    x = ((x>>8U)^x.yx)*1103515245U;
    x = ((x>>8U)^x.yx)*1103515245U;
    return vec2(x)/float(0xffffffffU);
}

vec3 shpereRandom(float n)
{
  vec2 h = hash(n);
  float z = h.x * 2.0 -1.0;
  float t = radians(360.) * h.y;
  float v = sqrt(1.0-z*z);
  return vec3(v*cos(t), v*sin(t), z);
}

vec3 randomCircuit(float t, float n)
{
    vec3 p = vec3(0);
    for (int i=0; i<6; i++)
    {
      p += shpereRandom(n) * cos(t) + shpereRandom(n*2.356) * sin(t);
      n +=12.78; t *= 1.36456;
    }
    return p;
}

float deStar(vec2 p)
{
  float a = radians(72.); 
  p = rotate(floor(0.5 + atan(p.x, p.y) /a) *a) *p;
  return dot(abs(p), normalize(vec2(2, 1)));
}    

void main(void)
{
    vec2 p = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;
    float A=5.,B=3.;
    TIME =floor(time/(A+B))*A+ min(A,mod(time,(A+B)));
    float t = clamp(0.,B,mod(time-A,(A+B)))/B;
    t = t * t;
    vec3 ro = vec3(0,0,5);
    ro.xz = rotate(sign(mod(time/(A+B),2.)-1.0) * radians(360.)*t) * ro.xz;
    vec3 rd = lookat(-ro,vec3(0,1,0))*normalize(vec3(p,2));    
    vec3 col = hsv(0.7,0.3,0.3)*p.y*p.y;
    const float maxd = 10.0, precis = 0.001;
    float z = 0.0, d;
     for(int i = 0; i < 32; i++)
     {
        z += d = min(map(ro + rd * z),10.);
        if(d < precis || z > maxd) break;
      }
    if(d < precis)
    {
          vec3 p = ro + rd * z;
         vec3 nor = calcNormal(p);
        vec3 li = normalize(vec3(1));
        col = doColor(p);
        float dif = clamp(dot(nor, li), 0.3, 1.0);
        float amb = max(0.5 + 0.5 * nor.y, 0.0);
        float spc = pow(clamp(dot(reflect(normalize(p - ro), nor), li), 0.0, 1.0), 50.0);
        col *= dif * amb ;
        col += spc;
        col = clamp(col,0.0,1.0);
      }
    
    for(float i=0.;i<12.;i++)
    for(float j=0.;j<7.;j++)
    {
        vec3 pos = randomCircuit(0.6*TIME-i*0.03,2532.+25698.*j);
        vec3 c = billboard(ro, rd, pos, vec3(0,0,1), pos.xzy);
        if (c.z<z)
        {
            float de = deStar(c.xy*10.);
            col = mix(col,
                    hsv(TIME*0.5+i/20.0+j/5.0,0.5,1.0) * pow(0.8,i),
                    smoothstep(1.,0.8,de)*pow(0.8,i)
                );
        }
    }
    glFragColor = vec4(col, 1.0);
}

