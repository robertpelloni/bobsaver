#version 420

// original https://www.shadertoy.com/view/Mcs3RX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 r;

float sph (vec3 p, float r) {
    return length(p) - r;
}
float box(vec3 p, vec3 d) {
    p = abs(p) - d;
    return max(max(p.x,p.y),p.z);
}

float aabb(vec3 p, vec3 d) {
  
    vec3 neg = -(d / 2. - p)/r;
    vec3 pos =  (d / 2. - p)/r;

    vec3 bot = min(neg, pos);
 
    float top = max(max(bot.x, bot.y), bot.z);

    return max(0.0, top); // Ensure we don't return a negative value
}
float hash31(vec3 p3)
{
    p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float hash21(vec2 p){
    p = fract(p*vec2(234.34,435.345));
    p += dot(p, p+34.23);
    return fract(p.x*p.y);
}
float field (vec3 p, float scale) {
  
   p *= scale;
   vec3 id = floor(p)-.5; 
   p = fract(p) -.5;
   
   float f1 = hash31(id);
 
  
   float shape = box(p, vec3(f1 * .46));

   float bound = aabb(p, vec3(scale*1.01));
   
   return min(bound , shape)/scale;
}
float map(vec3 p) {
    vec3 q = p;
    float pos = p.y + 1.;

    for (float i = 1.; i < 9.; i++) {
      
            pos = max(pos, -field(q,pow(1.8,i)/16.));
     
    }
    
    return pos;
}

vec3 norm(vec3 p) {
  vec2 off=vec2(0.01,0.0);
  return normalize(map(p)-vec3(map(p-off.xyy), map(p-off.yxy), map(p-off.yyx)));
}

float occ ( vec3 p, vec3 n, float ni, float L) {
    float occ = 1.;
    for (float i =1.; i < ni; i++) {
        float l = i * L / ni;
        float d = map(p + n * l);
        occ -= max(0., l -d ) / l / ni;
    
    }
    return max(0.,occ);

}
mat2 rot(float a) {
    return mat2(cos(a),sin(a),-sin(a),cos(a));
}

float rand(float t) {
  return fract( sin(t * 7361.994) * 4518.442);
}

void main(void)
{
    vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);
    
    
    float tt = time ;
    // nav 
    vec3 s = vec3(0,2,-15);
    vec3 arm = vec3(0,0,1);
    vec3 fwd = vec3(.1,0,5)*tt;
    s += fwd;
    arm.xz *= rot(cos(tt)/2.);
    arm.yz *= rot(sin(tt/2.)/3. - .8);
    vec3 t = s + arm;
    

    
    
    vec3 z = normalize(t-s);
    vec3 x = normalize(cross(vec3(0,-1,0),z));
    vec3 y = cross(x,z);  
    r = mat3(x,y,z) * normalize(vec3(uv,1));
    vec3 p = s;
    float l;
    
    float L = 300.;
    

    for (float i = 0.; i < 100.; i++) {
        float d = map(p) ;
        
        if ( d < .0001) {
            break;
        }
        if ( l > L) {
            break;
        }
        p += r * d;
        l += d;
    }
    
    vec3 col = vec3(0);
   
    //col += l/L;
    
    vec3 n = norm(p);
    
    
    col += occ(p, n , 10., 3.);
    
    
    //col=mix(col,vec3(1),l/L);
    col *= vec3(232.,220.,202.)/256.;
    col=mix(vec3(1),col,exp(-.00002*l*l*l));
    
    

   // col = sqrt(col);
 
   
   
    glFragColor = vec4(col,1.0);
}
